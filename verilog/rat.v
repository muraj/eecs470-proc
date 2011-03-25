
module rat (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in,
						// PRF i/o
						prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in,
						// enable signals for rat and rrat
						issue, retire
				 	 );
	//synopsys template		
  parameter ARF_IDX = 5;
  parameter RAT_SZ  = 1<<ARF_IDX;
						
  input   clk, reset, flush;
  input   [`SCALAR*ARF_IDX-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
  input   [`SCALAR-1:0] issue, retire;
  input   [`SCALAR*`PRF_IDX-1:0] retire_pdest_idx_in;

  output  [`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out;

	// Free list storage
	reg [`PRF_SZ-1:0] fl;
	reg [`PRF_SZ-1:0] rfl;

	// Internal wires
	wire [`PRF_SZ-1:0] fl_rev;
	wire [`PRF_SZ-1:0] fl_sel0;
	wire [`PRF_SZ-1:0] fl_sel1;
	wire [`PRF_SZ-1:0] fl_sel1_rev;

  wire    [RAT_SZ*`PRF_IDX-1:0] rrat_data;   			// for flush
  wire    [RAT_SZ*`PRF_IDX-1:0] rat_data;   			// for flush
	wire    [`SCALAR*`PRF_IDX-1:0] retire_prev_prf;	// for freeing up PRF
	wire    [`SCALAR*`PRF_IDX-1:0] free_prf;	// output of priority encoder
  wire    [`SCALAR*`PRF_IDX-1:0] prega_idx_out_file, pregb_idx_out_file; // output of rat regfile
  wire    [`SCALAR-1:0] issue_file;

	// Deal with zero register reads
	assign prega_idx_out[`SEL(`PRF_IDX,1)] = (rega_idx_in[`SEL(5,1)] == `ZERO_REG)? `ZERO_PRF : prega_idx_out_file[`SEL(`PRF_IDX,1)];
	assign prega_idx_out[`SEL(`PRF_IDX,2)] = (rega_idx_in[`SEL(5,2)] == `ZERO_REG)? `ZERO_PRF : prega_idx_out_file[`SEL(`PRF_IDX,2)];
	assign pregb_idx_out[`SEL(`PRF_IDX,1)] = (regb_idx_in[`SEL(5,1)] == `ZERO_REG)? `ZERO_PRF : pregb_idx_out_file[`SEL(`PRF_IDX,1)];
	assign pregb_idx_out[`SEL(`PRF_IDX,2)] = (regb_idx_in[`SEL(5,2)] == `ZERO_REG)? `ZERO_PRF : pregb_idx_out_file[`SEL(`PRF_IDX,2)];

	// Deal with zero register writes
	assign issue_file[0] = (dest_idx_in[`SEL(5,1)] == `ZERO_REG)? 1'b0 : issue[0];
	assign issue_file[1] = (dest_idx_in[`SEL(5,2)] == `ZERO_REG)? 1'b0 : issue[1];
	assign pdest_idx_out[`SEL(`PRF_IDX,1)] = (dest_idx_in[`SEL(5,1)] == `ZERO_REG)? `ZERO_PRF: free_prf[`SEL(`PRF_IDX,1)];
	assign pdest_idx_out[`SEL(`PRF_IDX,2)] = (dest_idx_in[`SEL(5,2)] == `ZERO_REG)? `ZERO_PRF: free_prf[`SEL(`PRF_IDX,2)];

	regfile #(.IDX_WIDTH(ARF_IDX), .DATA_WIDTH(`PRF_IDX), .ZERO_REG_VAL(`ZERO_REG))
        file_rat (.wr_clk(clk), .reset(reset), .copy(flush),
				 					.rda_idx(rega_idx_in), .rda_out(prega_idx_out_file), // reg A
                  .rdb_idx(regb_idx_in), .rdb_out(pregb_idx_out_file), // reg B
        	  	    .wr_idx(dest_idx_in), .wr_data(free_prf), .wr_en(issue_file), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rat_data) //not needed
								  ); // write port
  
	regfile #(.IDX_WIDTH(ARF_IDX), .DATA_WIDTH(`PRF_IDX), .ZERO_REG_VAL(`ZERO_REG))
       file_rrat (.wr_clk(clk), .reset(reset), .copy(1'b0),
				 					.rda_idx(retire_dest_idx_in), .rda_out(retire_prev_prf), // not needed
                  .rdb_idx(10'b0), .rdb_out(), // not needed
         	  	    .wr_idx(retire_dest_idx_in), .wr_data(retire_pdest_idx_in), .wr_en(retire), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rrat_data)
								  ); // write port

	
	// Revert free list to select for superscalar
	generate
		genvar i;
		for(i=0; i<`PRF_SZ;i=i+1) begin: REV_FL
			assign fl_rev[i] = fl[`PRF_SZ-1-i];
			assign fl_sel1_rev[i] = fl_sel1[`PRF_SZ-1-i];
		end
	endgenerate

  ps #(.NUM_BITS(`PRF_SZ)) free_sel0(.req(fl), .en(!reset), .gnt(fl_sel0), .req_up()); 
  ps #(.NUM_BITS(`PRF_SZ)) free_sel1(.req(fl_rev), .en(!reset), .gnt(fl_sel1), .req_up()); 

	pe #(.OUT_WIDTH(`PRF_IDX)) free_encode0(.gnt(fl_sel0), .enc(free_prf[`SEL(`PRF_IDX,1)])); 
	pe #(.OUT_WIDTH(`PRF_IDX)) free_encode1(.gnt(fl_sel1_rev), .enc(free_prf[`SEL(`PRF_IDX,2)])); 

	always @(posedge clk) begin
		
		if (reset) begin
			// free list for zero register should always be 0
			fl  <= `SD {{`PRF_SZ-1{1'b1}},1'b0};
			rfl <= `SD {{`PRF_SZ-1{1'b1}},1'b0};
		end else if (flush) begin
			fl <= `SD rfl;

		end else begin

			if (issue_file[0])
				fl[free_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf allocated
			if (issue_file[1])
				fl[free_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf allocated

			if (retire[0] && (retire_pdest_idx_in[`SEL(`PRF_IDX,1)] != `ZERO_PRF)) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already
				rfl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
				// in the regular free list as well
				fl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
			end
			if (retire[1] && (retire_pdest_idx_in[`SEL(`PRF_IDX,2)] != `ZERO_PRF)) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already
				rfl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
				// in the regular free list as well
				fl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
			end

		end

	end

endmodule
