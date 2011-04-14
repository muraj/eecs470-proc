/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  regfile.v                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  // 
//                 WB Stages of the Pipeline.                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps

module regfile(rda_idx, rda_out,                // read port A
               rdb_idx, rdb_out,                // read port B
               reg_vals_out,
               wr_idx, wr_data, wr_en, clock); // write port

  //synopsys template
  parameter IDX_WIDTH = `PRF_IDX;
  parameter DATA_WIDTH  = 64;
  parameter ZERO_REGISTER = `ZERO_REG;
  parameter ZERO_REG_VAL = 0;
  parameter RESET_TO = 0;
  parameter REG_SZ  = 1<<IDX_WIDTH;

  input   [`SCALAR*IDX_WIDTH-1:0] rda_idx, rdb_idx, wr_idx;
  input   [`SCALAR*DATA_WIDTH-1:0] wr_data;
  input   [`SCALAR-1:0] wr_en;
  input   clock;

  output reg [`SCALAR*DATA_WIDTH-1:0] rda_out, rdb_out;
  output wire [DATA_WIDTH*REG_SZ-1:0] reg_vals_out;
  
  reg    [DATA_WIDTH-1:0] registers[REG_SZ-1:0];   // 32, 64-bit Registers

  generate
  genvar i;
    for(i=0;i<REG_SZ;i=i+1) begin : REG_OUT
      assign reg_vals_out[`SEL(DATA_WIDTH, i+1)] = registers[i];
    end
  endgenerate

  //
  // Read port A
  //
  always @* begin
    if (rda_idx[`SEL(IDX_WIDTH,1)] == ZERO_REGISTER)
      rda_out[`SEL(DATA_WIDTH,1)] = ZERO_REG_VAL;
    else
      rda_out[`SEL(DATA_WIDTH,1)] = registers[rda_idx[`SEL(IDX_WIDTH,1)]];
  `ifdef SUPERSCALAR
    if (rda_idx[`SEL(IDX_WIDTH,2)] == ZERO_REGISTER)
      rda_out[`SEL(DATA_WIDTH,2)] = ZERO_REG_VAL;
    else
      rda_out[`SEL(DATA_WIDTH,2)] = registers[rda_idx[`SEL(IDX_WIDTH,2)]];
  `endif
  end

  //
  // Read port B
  //
  always @* begin
    if (rdb_idx[`SEL(IDX_WIDTH,1)] == ZERO_REGISTER)
      rdb_out[`SEL(DATA_WIDTH,1)] = ZERO_REG_VAL;
    else
      rdb_out[`SEL(DATA_WIDTH,1)] = registers[rdb_idx[`SEL(IDX_WIDTH,1)]];
  `ifdef SUPERSCALAR
    if (rdb_idx[`SEL(IDX_WIDTH,2)] == ZERO_REGISTER)
      rdb_out[`SEL(DATA_WIDTH,2)] = ZERO_REG_VAL;
    else
      rdb_out[`SEL(DATA_WIDTH,2)] = registers[rdb_idx[`SEL(IDX_WIDTH,2)]];
  `endif
  end

  always @(posedge clock) begin
	    if(wr_en[0])
  	    registers[wr_idx[`SEL(IDX_WIDTH,1)]] <= `SD wr_data[`SEL(DATA_WIDTH,1)];
    	if(wr_en[1])
      	registers[wr_idx[`SEL(IDX_WIDTH,2)]] <= `SD wr_data[`SEL(DATA_WIDTH,2)];
  end

endmodule // regfile
