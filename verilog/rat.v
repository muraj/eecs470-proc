
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
  input   [`SCALAR-1:0] wr_en;
  wire    [REG_SZ*`PRF_IDX-1:0] rrat_data;   // 32, 64-bit Registers

  output  [`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in;

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
				 					.rda_idx(0), .rda_out(), // not needed
                  .rdb_idx(0), .rdb_out(), // not needed
         	  	    .wr_idx(retire_dest_idx_in), .wr_data(pdest_idx_in), .wr_en(commit), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rrat_data)
								  ); // write port

	regfile #(.IDX_WIDTH(5), .DATA_WIDTH(`PRF_IDX))
       free_list (.wr_clk(clk), .reset(reset), .copy(0),
				 					.rda_idx(0), .rda_out(), // reg A
                  .rdb_idx(0), .rdb_out(), // reg B
         	  	    .wr_idx(retire_dest_idx_in), .wr_data(free_idx), .wr_en(), 
        	        .reg_vals_in(rrat_data),
        	        .reg_vals_out(rrat_data)
								  ); // write port

