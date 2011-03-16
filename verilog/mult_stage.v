// This is one stage of an 8 stage (9 depending on how you look at it)
// pipelined multiplier that multiplies 2 64-bit integers and returns
// the low 64 bits of the result.  This is not an ideal multiplier but
// is sufficient to allow a faster clock period than straight *
module mult_stage(clock, reset, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done);

  input clock, reset, start;
  input [63:0] product_in, mplier_in, mcand_in;

  output done;
  output [63:0] product_out, mplier_out, mcand_out;

  reg  [63:0] prod_in_reg, partial_prod_reg;
  wire [63:0] partial_product, next_mplier, next_mcand;

  reg [63:0] mplier_out, mcand_out;
  reg done;
  
  assign product_out = prod_in_reg + partial_prod_reg;

  assign partial_product = mplier_in[7:0] * mcand_in;

  assign next_mplier = {8'b0,mplier_in[63:8]};
  assign next_mcand = {mcand_in[55:0],8'b0};

  always @(posedge clock)
  begin
    prod_in_reg      <= #1 product_in;
    partial_prod_reg <= #1 partial_product;
    mplier_out       <= #1 next_mplier;
    mcand_out        <= #1 next_mcand;
  end

  always @(posedge clock)
  begin
    if(reset)
      done <= #1 1'b0;
    else
      done <= #1 start;
  end

endmodule

