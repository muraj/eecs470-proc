
module rat (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in, cdb_en, cdb_tag,
						// PRF i/o
						prega_idx_out, prega_valid_out, pregb_idx_out, pregb_valid_out, pdest_idx_out, retire_pdest_idx_in,
						// enable signals for rat and rrat
						issue, retire
				 	 );
	//synopsys template		
  parameter ARF_IDX = `ARF_IDX;
  parameter RAT_SZ  = 1<<ARF_IDX;
						
  input   clk, reset, flush;
  input   [`SCALAR*ARF_IDX-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
  input   [`SCALAR-1:0] issue, retire;
  input   [`SCALAR-1:0] cdb_en;
  input   [`SCALAR*`PRF_IDX-1:0] cdb_tag;
  input   [`SCALAR*`PRF_IDX-1:0] retire_pdest_idx_in;

  output reg [`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out;
  output reg [`SCALAR-1:0] prega_valid_out;
  output reg [`SCALAR-1:0] pregb_valid_out;
  output wire [`SCALAR*`PRF_IDX-1:0] pdest_idx_out;

	// Free list storage
	reg [`PRF_SZ-1:0] fl;
	reg [`PRF_SZ-1:0] rfl;

  // Valid list storage
  reg [`PRF_SZ-1:0] valid_list;

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
  wire    [`SCALAR-1:0] issue_file, retire_file;

  always @* begin
    if(issue[0]) begin
      if(cdb_en[0] && cdb_tag[`SEL(`PRF_IDX, 1)] == prega_idx_out[`SEL(`PRF_IDX, 1)])
        prega_valid_out[0] = 1'b1;
      `ifdef SUPERSCALAR
      else if(cdb_en[1] && cdb_tag[`SEL(`PRF_IDX, 2)] == prega_idx_out[`SEL(`PRF_IDX, 1)])
        prega_valid_out[0] = 1'b1;
      `endif
      else
        prega_valid_out[0] = valid_list[prega_idx_out[`SEL(`PRF_IDX,1)]];
    end
    if(issue[0]) begin
      if(cdb_en[0] && cdb_tag[`SEL(`PRF_IDX, 1)] == pregb_idx_out[`SEL(`PRF_IDX, 1)])
        pregb_valid_out[0] = 1'b1;
      `ifdef SUPERSCALAR
      else if(cdb_en[1] && cdb_tag[`SEL(`PRF_IDX, 2)] == pregb_idx_out[`SEL(`PRF_IDX, 1)])
        pregb_valid_out[0] = 1'b1;
      `endif
      else
        pregb_valid_out[0] = valid_list[pregb_idx_out[`SEL(`PRF_IDX,1)]];
    end
  `ifdef SUPERSCALAR
    if(issue[1]) begin
      if(cdb_en[0] && cdb_tag[`SEL(`PRF_IDX, 1)] == prega_idx_out[`SEL(`PRF_IDX, 2)])
        prega_valid_out[1] = 1'b1;
      else if(cdb_en[1] && cdb_tag[`SEL(`PRF_IDX, 2)] == prega_idx_out[`SEL(`PRF_IDX, 2)])
        prega_valid_out[1] = 1'b1;
      else
        prega_valid_out[1] = valid_list[prega_idx_out[`SEL(`PRF_IDX,2)]];
    end
    if(issue[1]) begin
      if(cdb_en[0] && cdb_tag[`SEL(`PRF_IDX, 1)] == pregb_idx_out[`SEL(`PRF_IDX, 2)])
        pregb_valid_out[1] = 1'b1;
      else if(cdb_en[1] && cdb_tag[`SEL(`PRF_IDX, 2)] == pregb_idx_out[`SEL(`PRF_IDX, 2)])
        pregb_valid_out[1] = 1'b1;
      else
        pregb_valid_out[1] = valid_list[pregb_idx_out[`SEL(`PRF_IDX,2)]];
    end
  `endif
  end
  always @(posedge clk) begin
    if(cdb_en[0])
      valid_list[cdb_tag[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
    `ifdef SUPERSCALAR
    if(cdb_en[1])
      valid_list[cdb_tag[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
    `endif
  end
`ifdef SUPERSCALAR
  always @* begin       //Write forwarding for superscalar (do not forward on general writes, just to second inst)
    if(issue[1]) begin
      prega_idx_out[`SEL(`PRF_IDX,1)] = prega_idx_out_file[`SEL(`PRF_IDX,1)];
      pregb_idx_out[`SEL(`PRF_IDX,1)] = pregb_idx_out_file[`SEL(`PRF_IDX,1)];
      if(dest_idx_in[`SEL(ARF_IDX,1)] == rega_idx_in[`SEL(ARF_IDX,2)])
        prega_idx_out[`SEL(`PRF_IDX,2)] = pdest_idx_out[`SEL(`PRF_IDX,1)];
      else
        prega_idx_out[`SEL(`PRF_IDX,2)] = prega_idx_out_file[`SEL(`PRF_IDX,2)];
      if(dest_idx_in[`SEL(ARF_IDX,1)] == regb_idx_in[`SEL(ARF_IDX,2)])
        pregb_idx_out[`SEL(`PRF_IDX,2)] = pdest_idx_out[`SEL(`PRF_IDX,1)];
      else
        pregb_idx_out[`SEL(`PRF_IDX,2)] = pregb_idx_out_file[`SEL(`PRF_IDX,2)];
    end
    else begin
      prega_idx_out = prega_idx_out_file;
      pregb_idx_out = pregb_idx_out_file;
    end
  end
`endif

	// Deal with zero register writes
	assign issue_file[0] = (dest_idx_in[`SEL(ARF_IDX,1)] == `ZERO_REG)? 1'b0 : issue[0];
	assign issue_file[1] = (dest_idx_in[`SEL(ARF_IDX,2)] == `ZERO_REG)? 1'b0 : issue[1];
	assign retire_file[0] = (retire_dest_idx_in[`SEL(ARF_IDX,1)] == `ZERO_REG)? 1'b0 : retire[0];
	assign retire_file[1] = (retire_dest_idx_in[`SEL(ARF_IDX,2)] == `ZERO_REG)? 1'b0 : retire[1];
	assign pdest_idx_out[`SEL(`PRF_IDX,1)] = (dest_idx_in[`SEL(ARF_IDX,1)] == `ZERO_REG)? `ZERO_PRF: free_prf[`SEL(`PRF_IDX,1)];
	assign pdest_idx_out[`SEL(`PRF_IDX,2)] = (dest_idx_in[`SEL(ARF_IDX,2)] == `ZERO_REG)? `ZERO_PRF: free_prf[`SEL(`PRF_IDX,2)];

	regfile #(.IDX_WIDTH(ARF_IDX), .DATA_WIDTH(`PRF_IDX), .ZERO_REG_VAL(`ZERO_PRF), .RESET_TO(`ZERO_PRF))
        file_rat (.wr_clk(clk), .reset(reset), .copy(flush),
				 					.rda_idx(rega_idx_in), .rda_out(prega_idx_out_file), // reg A
                  .rdb_idx(regb_idx_in), .rdb_out(pregb_idx_out_file), // reg B
        	  	    .wr_idx(dest_idx_in), .wr_data(free_prf), .wr_en(issue_file), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rat_data) //not needed
								  ); // write port
  
	regfile #(.IDX_WIDTH(ARF_IDX), .DATA_WIDTH(`PRF_IDX), .ZERO_REG_VAL(`ZERO_PRF), .RESET_TO(`ZERO_PRF))
       file_rrat (.wr_clk(clk), .reset(reset), .copy(1'b0),
				 					.rda_idx(retire_dest_idx_in), .rda_out(retire_prev_prf),
                  .rdb_idx(10'b0), .rdb_out(), // not needed
         	  	    .wr_idx(retire_dest_idx_in), .wr_data(retire_pdest_idx_in), .wr_en(retire_file), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rrat_data)
								  ); // write port

	
	// Reverse free list to select for superscalar
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
			// free list for zero PRF should always be `ZERO_PRF, which is 0... FIXME
			fl  <= `SD {{`PRF_SZ-1{1'b1}},1'b0};
			rfl <= `SD {{`PRF_SZ-1{1'b1}},1'b0};
      valid_list <= `SD {{`PRF_SZ-1{1'b0}}, 1'b1};
		end //reset
    else if (flush) begin
			fl <= `SD rfl;
      valid_list <= `SD (~rfl & valid_list);
		end //flush
//    else begin

			if (issue_file[0])
				fl[free_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf allocated
			if (issue_file[1])
				fl[free_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf allocated

			if (retire_file[0]) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already; unless it's zero PRF
				if (retire_prev_prf[`SEL(`PRF_IDX,1)] != `ZERO_PRF) begin
					rfl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
					// in the regular free list as well
					fl[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
          // Invalidate the valid bit
          valid_list[retire_prev_prf[`SEL(`PRF_IDX,1)]] <= `SD 1'b0;
	  			// if way2 overwrites way1, then need to free up way1
  				if (retire_file[1] && retire_dest_idx_in[`SEL(ARF_IDX,1)] == retire_dest_idx_in[`SEL(ARF_IDX,2)]) begin
  					rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
  					// in the regular free list as well
  					fl[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b1;
            // Invalidate the valid bit
            valid_list[retire_pdest_idx_in[`SEL(`PRF_IDX,1)]] <= `SD 1'b0;
	  			end //retire_dest_idx_in
				end //retire_pref_prf

			end //retire_file[0]
			if (retire_file[1]) begin
				rfl[retire_pdest_idx_in[`SEL(`PRF_IDX,2)]] <= `SD 1'b0; // new prf retired
				// need to free up the overwritten prf, if it weren't free already
				if (retire_prev_prf[`SEL(`PRF_IDX,2)] != `ZERO_PRF) begin
					rfl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
					// in the regular free list as well
					fl[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b1;
          // Invalidate the valid bit
          valid_list[retire_prev_prf[`SEL(`PRF_IDX,2)]] <= `SD 1'b0;
				end //retire_file[1]
			end
//		end
	end

endmodule
