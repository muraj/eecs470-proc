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
  parameter DATA_SIZE = 64;

input clock, reset, wr1_en;
input [`ICACHE_IDX_BITS-1:0] wr1_idx, rd1_idx;
input [`ICACHE_TAG_BITS-1:0] wr1_tag, rd1_tag;
input [DATA_SIZE-1:0] wr1_data; 
output [DATA_SIZE-1:0] rd1_data;
output rd1_valid;

reg [DATA_SIZE-1:0] data [`ICACHE_LINES-1:0];
reg [`ICACHE_TAG_BITS-1:0] tags [`ICACHE_LINES-1:0]; 
reg [`ICACHE_LINES-1:0] valids;

assign rd1_data = data[rd1_idx];
assign rd1_valid = valids[rd1_idx]&&(tags[rd1_idx] == rd1_tag);
//synopsys sync_set_reset "reset"
always @(posedge clock)
begin
  if(reset) valids <= `SD 0;
  else if(wr1_en) 
    valids[wr1_idx] <= `SD 1'b1;
end

integer idx;
//synopsys sync_set_reset "reset"
always @(posedge clock)
begin
		if(reset) begin
			for(idx=0; idx<`ICACHE_LINES; idx=idx+1) begin
				data[idx]	<= `SD 0;
				tags[idx]	<= `SD 0;
			end
		end
  if(wr1_en) begin
    data[wr1_idx] <= `SD wr1_data;
    tags[wr1_idx] <= `SD wr1_tag;
  end
end

endmodule
