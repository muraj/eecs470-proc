/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  regfile.v                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  // 
//                 WB Stages of the Pipeline.                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`timescale 1ns/100ps
module rattable (clock, reset, copy,
                issue_a, issue_a_out,    //reg A on issue
                issue_b, issue_b_out,    //reg B on issue
                commit_d, commit_d_out,  //reg B on commit
                issue_wr, issue_wr_data, issue_en,      //reg Dest on issue
                commit_wr, commit_wr_data, commit_en    //reg Dest on retire
               );
 
  //synopsys template
  parameter IDX_WIDTH = `PRF_IDX;
  parameter DATA_WIDTH  = 64;
  parameter ZERO_REGISTER = `ZERO_REG;
  parameter ZERO_REG_VAL = 0;
  parameter RESET_TO = 0;
  parameter REG_SZ  = 1<<IDX_WIDTH;

  input wire clock, reset, copy;

  input wire [`SCALAR-1:0] issue_en, commit_en;

  input wire [`SCALAR*IDX_WIDTH-1:0] issue_a;
  input wire [`SCALAR*IDX_WIDTH-1:0] issue_b;
  input wire [`SCALAR*IDX_WIDTH-1:0] issue_wr;
  input wire [`SCALAR*IDX_WIDTH-1:0] commit_d;
  input wire [`SCALAR*IDX_WIDTH-1:0] commit_wr;

  input wire [`SCALAR*DATA_WIDTH-1:0] issue_wr_data, commit_wr_data;

  output wor [`SCALAR*DATA_WIDTH-1:0] issue_a_out;
  output wor [`SCALAR*DATA_WIDTH-1:0] issue_b_out;
  output wor [`SCALAR*DATA_WIDTH-1:0] commit_d_out;


  wire [`SCALAR*REG_SZ-1:0] issue_a_en;
  wire [`SCALAR*REG_SZ-1:0] issue_b_en;
  wire [`SCALAR*REG_SZ-1:0] issue_wr_en;
  wire [`SCALAR*REG_SZ-1:0] commit_d_en;
  wire [`SCALAR*REG_SZ-1:0] commit_wr_en;

  bin_decoder #(.IN_WIDTH(IDX_WIDTH), .OUT_WIDTH(REG_SZ)) issue_a_sel   [`SCALAR-1:0] (.in(issue_a), .out(issue_a_en));  //Bigger ick, 5*n comparators
  bin_decoder #(.IN_WIDTH(IDX_WIDTH), .OUT_WIDTH(REG_SZ)) issue_b_sel   [`SCALAR-1:0] (.in(issue_b), .out(issue_b_en));
  bin_decoder #(.IN_WIDTH(IDX_WIDTH), .OUT_WIDTH(REG_SZ)) issue_wr_sel  [`SCALAR-1:0] (.in(issue_wr), .out(issue_wr_en));
  bin_decoder #(.IN_WIDTH(IDX_WIDTH), .OUT_WIDTH(REG_SZ)) commit_d_sel  [`SCALAR-1:0] (.in(commit_d), .out(commit_d_en));
  bin_decoder #(.IN_WIDTH(IDX_WIDTH), .OUT_WIDTH(REG_SZ)) commit_wr_sel [`SCALAR-1:0] (.in(commit_wr), .out(commit_wr_en));

  generate
  genvar i;
  for(i=0;i<REG_SZ;i=i+1) begin : ENTRIES
    rat_rrat_entry #(.DATA_WIDTH(DATA_WIDTH), .RESET_TO(RESET_TO))
           entry(clock, reset, copy,
                {issue_a_en[i+REG_SZ],issue_a_en[i]}, issue_a_out,          //reg A on issue
                {issue_b_en[i+REG_SZ],issue_b_en[i]}, issue_b_out,          //reg B on issue
                {commit_d_en[i+REG_SZ], commit_d_en[i]}, commit_d_out,      //reg   on commit
                {issue_wr_en[i+REG_SZ], issue_wr_en[i]} & issue_en, issue_wr_data,     //reg Dest on issue
                {commit_wr_en[i+REG_SZ], commit_wr_en[i]} & commit_en, commit_wr_data    //reg Dest on retire
               );
  end
  endgenerate

endmodule // rattable

module bin_decoder(in, out);  //Parameterized one-hot decoder
  //synopsys template
  parameter IN_WIDTH = `ARF_IDX;
  parameter OUT_WIDTH = 1<<IN_WIDTH;
  input wire  [IN_WIDTH-1:0]  in;
  output wire [OUT_WIDTH-1:0] out;
  generate
  genvar i;
    for(i=0;i<OUT_WIDTH;i=i+1) begin : BIN_DECODE1
      assign out[i] = in == i;  //Ick
    end
  endgenerate
endmodule

module rat_rrat_entry (clock, reset, copy,
                issue_a_en, issue_a_out,    //reg A on issue
                issue_b_en, issue_b_out,    //reg B on issue
                commit_d_en, commit_d_out,  //reg B on commit
                issue_wr_en, issue_wr_data,     //reg Dest on issue
                commit_wr_en, commit_wr_data    //reg Dest on retire
               );
  //synopsys template
  parameter DATA_WIDTH = `PRF_IDX;
  parameter RESET_TO = {DATA_WIDTH{1'b0}};
  input clock, reset, copy;
  input [`SCALAR-1:0] issue_a_en, issue_b_en, commit_d_en;  //Read enables
  input [`SCALAR-1:0] issue_wr_en, commit_wr_en;
  input [`SCALAR*DATA_WIDTH-1:0] issue_wr_data, commit_wr_data;

  reg [DATA_WIDTH-1:0] issue_reg, commit_reg;

  output [`SCALAR*DATA_WIDTH-1:0] issue_a_out;
  output [`SCALAR*DATA_WIDTH-1:0] issue_b_out;
  output [`SCALAR*DATA_WIDTH-1:0] commit_d_out;

  assign issue_a_out[`SEL(DATA_WIDTH,1)] = issue_a_en[0] ? issue_reg : {DATA_WIDTH{1'b0}};
  assign issue_b_out[`SEL(DATA_WIDTH,1)] = issue_b_en[0] ? issue_reg : {DATA_WIDTH{1'b0}};
  assign commit_d_out[`SEL(DATA_WIDTH,1)] = commit_d_en[0] ? commit_reg : {DATA_WIDTH{1'b0}};
  `ifdef SUPERSCALAR
  assign issue_a_out[`SEL(DATA_WIDTH,2)] = issue_a_en[1] ? issue_reg : {DATA_WIDTH{1'b0}};
  assign issue_b_out[`SEL(DATA_WIDTH,2)] = issue_b_en[1] ? issue_reg : {DATA_WIDTH{1'b0}};
  assign commit_d_out[`SEL(DATA_WIDTH,2)] = commit_d_en[1] ? commit_reg : {DATA_WIDTH{1'b0}};
  `endif

  always @(posedge clock) begin
    if(reset) begin
      issue_reg <= `SD RESET_TO;
      commit_reg <= `SD RESET_TO;
    end
    else if(copy) //Copy the data
      issue_reg  <= `SD (commit_wr_en ? commit_wr_data : commit_reg);  //Write forwarding
    //Issue logic
    else if(issue_wr_en[1]) //Second instruction has priority
      issue_reg  <= `SD issue_wr_data[`SEL(DATA_WIDTH,2)];
    else if(issue_wr_en[0])
      issue_reg  <= `SD issue_wr_data[`SEL(DATA_WIDTH,1)];
    //Commit logic
    if(commit_wr_en[1])     //Second instruction has priority
      commit_reg <= `SD commit_wr_data[`SEL(DATA_WIDTH,2)];
    else if(commit_wr_en[0])
      commit_reg <= `SD commit_wr_data[`SEL(DATA_WIDTH,1)];
  end

endmodule
