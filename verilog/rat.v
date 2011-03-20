
module rat (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in,
						// PRF i/o
						prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in,
						// enable signals for rat and rrat
						issue, commit
				 	 );
						
  parameter IDX_WIDTH = 5;
  parameter REG_SZ  = 1<<IDX_WIDTH;
						
  input   clk, reset, flush;
  input   [`SCALAR*IDX_WIDTH-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
  input   [`SCALAR*`PRF_IDX-1:0] wr_data;
  input   [`SCALAR-1:0] issue, commit;
  input   [`SCALAR*`PRF_IDX-1:0] retire_pdest_idx_in;

  output  [`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out;

  wire    [REG_SZ*`PRF_IDX-1:0] rrat_data;   			// for flush
	wire    [`SCALAR*`PRF_IDX-1:0] retire_prev_prf;	// for freeing up PRF

	regfile #(.IDX_WIDTH(5), .DATA_WIDTH(`PRF_IDX))
        file_rat (.wr_clk(clk), .reset(reset), .copy(flush),
				 					.rda_idx(rega_idx_in), .rda_out(prega_idx_out), // reg A
                  .rdb_idx(regb_idx_in), .rdb_out(pregb_idx_out), // reg B
         	  	    .wr_idx(dest_idx_in), .wr_data(free_idx), .wr_en(issue), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out() //not needed
								  ); // write port
  
	regfile #(.IDX_WIDTH(5), .DATA_WIDTH(`PRF_IDX))
       file_rrat (.wr_clk(clk), .reset(reset), .copy(0),
				 					.rda_idx(retire_dest_idx_in), .rda_out(retire_prev_prf), // not needed
                  .rdb_idx(0), .rdb_out(), // not needed
         	  	    .wr_idx(retire_dest_idx_in), .wr_data(pdest_idx_in), .wr_en(commit), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rrat_data)
								  ); // write port

	reg [`PRF_SZ-1:0] fl;
	reg [`PRF_SZ-1:0] fl_rev;
	reg [`PRF_SZ-1:0] rfl;

	generate
		genvar i;
		for(i=0; i<`PRF_SZ;i=i+1) begin: REV_FL
			fl_rev[i] = fl_[`PRF_SZ-1];
		end
	endgenerate

  ps #(.NUM_BITS(`PRF_SZ)) free_sel0(.req(fl), .en(!reset), .gnt(fl_sel0), .req_up()); 
  ps #(.NUM_BITS(`PRF_SZ)) free_sel1(.req(fl_rev), .en(!reset), .gnt(fl_sel1), .req_up()); 

	pe #(.OUT_WIDTH(`RS_IDX)) free_encode0(.gnt(fl_sel0), .enc(free_prf[`SEL(`PRF_IDX,1)])); 
	pe #(.OUT_WIDTH(`RS_IDX)) free_encode1(.gnt(fl_sel1), .enc(free_prf[`SEL(`PRF_IDX,2)])); 

	always @(posedge clk) begin
		
		if (reset) begin
			fl  <= `SD {`PRF_SZ{1'b1}}
			rfl <= `SD {`PRF_SZ{1'b1}}
		end else if (flush) begin
			fl <= `SD rfl;

		else

			if (issue[0])
				fl[free_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf allocated
			if (issue[1])
				fl[free_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf allocated

			if (commit[0]) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already
				rfl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
				// in the regular free list as well
				fl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
			end
			if (commit[1]) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already
				rfl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
				// in the regular free list as well
				fl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
			end

		end

	end




		end
	end


	regfile #(.IDX_WIDTH(`PRF_IDX), .DATA_WIDTH(1))
       			fl (.wr_clk(clk), .reset(reset), .copy(flush),
				 				.rda_idx(0), .rda_out(), // reg A
                .rdb_idx(0), .rdb_out(), // reg B
         	      .wr_idx(retire_dest_idx_in), .wr_data(free_idx), .wr_en(), 
        	      .reg_vals_in(rfree_list_data),
        	      .reg_vals_out(free_list_data)
							  ); // write port

endmodule
