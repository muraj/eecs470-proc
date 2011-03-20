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
               wr_idx, wr_data, wr_en, wr_clk, reset, copy, reg_vals_in); // write port

  //synopsys template
  parameter IDX_WIDTH = `PRF_IDX;
  parameter DATA_WIDTH  = 64;
  parameter ZERO_REG_VAL = 0;
  parameter RESET_TO = 0;
  parameter REG_SZ  = 1<<IDX_WIDTH;

  input   [`SCALAR*IDX_WIDTH-1:0] rda_idx, rdb_idx, wr_idx;
  input   [`SCALAR*DATA_WIDTH-1:0] wr_data;
  input   [`SCALAR-1:0] wr_en;
  input   wr_clk, reset, copy;
  input wire   [REG_SZ*DATA_WIDTH-1:0] reg_vals_in;   // 32, 64-bit Registers

  output [`SCALAR*DATA_WIDTH-1:0] rda_out, rdb_out;
  
  reg    [`SCALAR*DATA_WIDTH-1:0] rda_out, rdb_out;
  reg    [DATA_WIDTH-1:0] registers[REG_SZ-1:0];   // 32, 64-bit Registers
  output wire   [REG_SZ*DATA_WIDTH-1:0] reg_vals_out;   // 32, 64-bit Registers

  wire   [`SCALAR*DATA_WIDTH-1:0] rda_reg = {registers[rda_idx[`SEL(IDX_WIDTH, 2)]], registers[rda_idx[`SEL(IDX_WIDTH, 1)]]};
  wire   [`SCALAR*DATA_WIDTH-1:0] rdb_reg = {registers[rdb_idx[`SEL(IDX_WIDTH, 2)]], registers[rdb_idx[`SEL(IDX_WIDTH, 1)]]};

  //
  // Read port A
  //
  always @* begin
    if (rda_idx[`SEL(IDX_WIDTH,1)] == `ZERO_REG)
      rda_out[`SEL(DATA_WIDTH,1)] = ZERO_REG_VAL;
/*    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,1)] == rda_idx[`SEL(IDX_WIDTH, 1)]))
      rda_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(DATA_WIDTH,1)];  // internal forwarding
  `ifdef SUPERSCALAR
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,2)] == rda_idx[`SEL(IDX_WIDTH, 1)]))
      rda_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(DATA_WIDTH,2)];  // internal forwarding
  `endif
  */  else
      rda_out[`SEL(DATA_WIDTH,1)] = rda_reg[`SEL(DATA_WIDTH,1)];
  `ifdef SUPERSCALAR
    if (rda_idx[`SEL(IDX_WIDTH,2)] == `ZERO_REG)
      rda_out[`SEL(DATA_WIDTH,2)] = ZERO_REG_VAL;
/*    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,1)] == rda_idx[`SEL(IDX_WIDTH, 2)]))
      rda_out[`SEL(DATA_WIDTH,2)] = wr_data[`SEL(DATA_WIDTH,1)];  // internal forwarding
    else if ( wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,2)] == rda_idx[`SEL(IDX_WIDTH, 2)]))
      rda_out[`SEL(DATA_WIDTH,2)] = wr_data[`SEL(64,2)];  // internal forwarding
*/    else
      rda_out[`SEL(DATA_WIDTH,2)] = rda_reg[`SEL(DATA_WIDTH,2)];
  `endif
  end

  //
  // Read port B
  //
  always @* begin
    if (rdb_idx[`SEL(IDX_WIDTH,1)] == `ZERO_REG)
      rdb_out[`SEL(DATA_WIDTH,1)] = ZERO_REG_VAL;
/*    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,1)] == rdb_idx[`SEL(IDX_WIDTH, 1)]))
      rdb_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(DATA_WIDTH,1)];  // internal forwarding
  `ifdef SUPERSCALAR
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,2)] == rdb_idx[`SEL(IDX_WIDTH, 1)]))
      rdb_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(DATA_WIDTH,2)];  // internal forwarding
  `endif
*/    else
      rdb_out[`SEL(DATA_WIDTH,1)] = rdb_reg[`SEL(DATA_WIDTH,1)];
  `ifdef SUPERSCALAR
    if (rdb_idx[`SEL(IDX_WIDTH,2)] == `ZERO_REG)
      rdb_out[`SEL(DATA_WIDTH,2)] = ZERO_REG_VAL;
/*    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,1)] == rdb_idx[`SEL(IDX_WIDTH, 2)]))
      rdb_out[`SEL(DATA_WIDTH,2)] = wr_data[`SEL(DATA_WIDTH,1)];  // internal forwarding
    else if ( wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,2)] == rdb_idx[`SEL(IDX_WIDTH, 2)]))
      rdb_out[`SEL(DATA_WIDTH,2)] = wr_data[`SEL(64,2)];  // internal forwarding
*/    else
      rdb_out[`SEL(DATA_WIDTH,2)] = rdb_reg[`SEL(DATA_WIDTH,2)];
  `endif
  end

  generate
  genvar i;
  for(i=0;i<REG_SZ;i=i+1) begin : REG_RESET
      assign reg_vals_out[`SEL(DATA_WIDTH, i+1)] = registers[i];
      always @(posedge wr_clk) begin
        if (i == `ZERO_REG)
            registers[i] <= `SD ZERO_REG_VAL;
        else if (reset)
            registers[i] <= `SD RESET_TO;
        else if (copy)
            registers[i] <= `SD reg_vals_in[`SEL(DATA_WIDTH, i+1)];

      end
  end
  endgenerate


  //
  // Write port
  //
  always @(posedge wr_clk) begin
    if(~reset && ~copy) begin
        if (wr_en[0])
          registers[wr_idx[`SEL(IDX_WIDTH, 1)]] <= `SD wr_data[`SEL(DATA_WIDTH, 1)];
        if (wr_en[1])
          registers[wr_idx[`SEL(IDX_WIDTH, 2)]] <= `SD wr_data[`SEL(DATA_WIDTH, 2)];    //For overwrites, the last in super scalar structure should be prefered
    end
  end

endmodule // regfile
