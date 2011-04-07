module cachemem128x64 (// inputs
                       clock,
                       reset, 
                       wr1_en,
                       wr1_tag,
                       wr1_idx,
                       wr1_data,
                       rd1_tag,
                       rd1_idx,

                       // outputs
                       rd1_data,
                       rd1_valid
                      );

  //synopsys template
  parameter TAG_IDX = 22;
  parameter IDX_IDX = 7;
  parameter LINE_SIZE = 1 << IDX_IDX;
  parameter DATA_SIZE = 64;
input clock, reset, wr1_en;
input [IDX_IDX-1:0] wr1_idx, rd1_idx;
input [TAG_IDX-1:0] wr1_tag, rd1_tag;
input [DATA_SIZE-1:0] wr1_data; 
output [DATA_SIZE-1:0] rd1_data;
output rd1_valid;

reg [DATA_SIZE:0] data [LINE_SIZE-1:0];
reg [TAG_IDX:0] tags [LINE_SIZE-1:0]; 
reg [LINE_SIZE:0] valids;

assign rd1_data = data[rd1_idx];
assign rd1_valid = valids[rd1_idx]&&(tags[rd1_idx] == rd1_tag);

always @(posedge clock)
begin
  if(reset) valids <= `SD {LINE_SIZE{1'b0}};
  else if(wr1_en) 
    valids[wr1_idx] <= `SD 1'b1;
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
