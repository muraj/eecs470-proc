//////////////////////////////////////////////////
// Data Cache Memory
//////////////////////////////////////////////////

module dcachemem (clock, reset,
                  wr1_en, wr1_tag, wr1_idx, wr1_data,
                  rd1_tag, rd1_idx, rd1_data, rd1_valid);

input clock, reset, wr1_en;
input [`DCACHE_IDX_BITS-1:0] wr1_idx, rd1_idx;
input [`DCACHE_TAG_BITS-1:0] wr1_tag, rd1_tag;
input [63:0] wr1_data;

output [63:0] rd1_data;
output rd1_valid;

reg [63:0]									data		[`DCACHE_LINES-1:0];
reg [`DCACHE_TAG_BITS-1:0]	tags		[`DCACHE_LINES-1:0];
reg [`DCACHE_LINES-1:0]			valids;

assign rd1_data		= data[rd1_idx];
assign rd1_valid	= valids[rd1_idx]&&(tags[rd1_idx] == rd1_tag);

always @(posedge clock)
begin
  if(reset) valids <= `SD 0;
  else if(wr1_en)
    valids[wr1_idx] <= `SD 1;
end

always @(posedge clock)
begin
  if(wr1_en)
  begin
    data[wr1_idx] <= `SD wr1_data;
    tags[wr1_idx] <= `SD wr1_tag;
  end
end

endmodule


