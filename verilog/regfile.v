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
               wr_idx, wr_data, wr_en, wr_clk); // write port

  //synopsys template
  parameter IDX_WIDTH = `PRF_IDX;
  parameter DATA_WIDTH  = 64;
  `define REG_SZ 1<<IDX_WIDTH;

  input   [`SCALAR*IDX_WIDTH-1:0] rda_idx, rdb_idx, wr_idx;
  input   [`SCALAR*DATA_WIDTH-1:0] wr_data;
  input   [`SCALAR-1:0] wr_en;
  input   wr_clk;

  output [`SCALAR*DATA_WIDTH-1:0] rda_out, rdb_out;
  
  reg    [`SCALAR*DATA_WIDTH-1:0] rda_out, rdb_out;
  reg    [DATA_WIDTH-1:0] registers[`REG_SZ-1:0];   // 32, 64-bit Registers

  wire   [`SCALAR*DATA_WIDTH-1:0] rda_reg = {registers[rda_idx[`SEL(IDX_WIDTH, 1)]], registers[rda_idx[`SEL(IDX_WIDTH, 0)]]};
  wire   [`SCALAR*DATA_WIDTH-1:0] rdb_reg = {registers[rdb_idx[`SEL(IDX_WIDTH, 1)]], registers[rdb_idx[`SEL(IDX_WIDTH, 0)]]};

  //
  // Read port A
  //
  always @* begin
    if (rda_idx[`SEL(IDX_WIDTH,0)] == `ZERO_REG)
      rda_out[`SEL(DATA_WIDTH,0)] = 0;
    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,0) == rda_idx[`SEL(IDX_WIDTH, 0)]))
      rda_out[`SEL(DATA_WIDTH,0)] = wr_data[`SEL(IDX_WIDTH,0)];  // internal forwarding
  `ifdef SUPERSCALAR
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,1) == rda_idx[`SEL(IDX_WIDTH, 0)]))
      rda_out[`SEL(DATA_WIDTH,0)] = wr_data[`SEL(IDX_WIDTH,1)];  // internal forwarding
  `endif
    else
      rda_out[`SEL(DATA_WIDTH,0)] = rda_reg[`SEL(DATA_WIDTH,0)];
  `ifdef SUPERSCALAR
    if (rda_idx[`SEL(IDX_WIDTH,1)] == `ZERO_REG)
      rda_out[`SEL(DATA_WIDTH,1)] = 0;
    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,0) == rda_idx[`SEL(IDX_WIDTH, 1)]))
      rda_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(IDX_WIDTH,0)];  // internal forwarding
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,1) == rda_idx[`SEL(IDX_WIDTH, 1)]))
      rda_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(IDX_WIDTH,1)];  // internal forwarding
    else
      rda_out[`SEL(DATA_WIDTH,1)] = rda_reg[`SEL(DATA_WIDTH,1)];
  `endif
  end

  //
  // Read port B
  //
  always @* begin
    if (rdb_idx[`SEL(IDX_WIDTH,0)] == `ZERO_REG)
      rdb_out[`SEL(DATA_WIDTH,0)] = 0;
    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,0) == rdb_idx[`SEL(IDX_WIDTH, 0)]))
      rdb_out[`SEL(DATA_WIDTH,0)] = wr_data[`SEL(IDX_WIDTH,0)];  // internal forwarding
  `ifdef SUPERSCALAR
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,1) == rdb_idx[`SEL(IDX_WIDTH, 0)]))
      rdb_out[`SEL(DATA_WIDTH,0)] = wr_data[`SEL(IDX_WIDTH,1)];  // internal forwarding
  `endif
    else
      rdb_out[`SEL(DATA_WIDTH,0)] = rdb_reg[`SEL(DATA_WIDTH,0)];
  `ifdef SUPERSCALAR
    if (rdb_idx[`SEL(IDX_WIDTH,1)] == `ZERO_REG)
      rdb_out[`SEL(DATA_WIDTH,1)] = 0;
    else if (wr_en[0] && (wr_idx[`SEL(IDX_WIDTH,0) == rdb_idx[`SEL(IDX_WIDTH, 1)]))
      rdb_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(IDX_WIDTH,0)];  // internal forwarding
    else if (wr_en[1] && (wr_idx[`SEL(IDX_WIDTH,1) == rdb_idx[`SEL(IDX_WIDTH, 1)]))
      rdb_out[`SEL(DATA_WIDTH,1)] = wr_data[`SEL(IDX_WIDTH,1)];  // internal forwarding
    else
      rdb_out[`SEL(DATA_WIDTH,1)] = rdb_reg[`SEL(DATA_WIDTH,1)];
  `endif
  end

  //
  // Write port
  //
  always @(posedge wr_clk)
    if (wr_en)
    begin
      registers[wr_idx[`SEL(IDX_WIDTH, 0)]] <= `SD wr_data[`SEL(DATA_WIDTH, 0)];
      registers[wr_idx[`SEL(IDX_WIDTH, 1)]] <= `SD wr_data[`SEL(DATA_WIDTH, 1)];    //For overwrites, the last in super scalar structure should be prefered
    end

endmodule // regfile
