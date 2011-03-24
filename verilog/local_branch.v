module br_file(clk, reset, pc_idx, taken); //Branch Table
	input   wire clk, reset;
	input 	wire [`BR_IDX-1:0] pc_idx;
	output  wire taken;

	wire	[`BR_SZ-1:0] sel;
	wire	[`BR_SZ-1:0] taken_all;

decoder_br dc0 (pc_idx,sel); //PC to selecting entry decoder

generate
  genvar i;
  for(i=0; i<`BR_SZ; i=i+1) begin : entries
    br_entry entry ( .clk(clk), .reset(reset), .sel(sel[i]), .taken(taken_all[i])); 
  end
endgenerate


assign taken=taken_all[pc_idx];

endmodule



module br_entry(clk, reset, sel, taken); 

//synopsys template
//  parameter IDX_WIDTH = `HIS_IDX;
//  parameter REG_SZ  = 1<<IDX_WIDTH;
  input   wire clk, reset, sel;
  output  reg taken;

	reg	[1:0] current_count, next_count;
	
always@*
begin
next_count = current_count+1;

taken = (current_count[2] | current_count[1]); //taken when first upper bits are 1

end



always@(posedge clk)
	begin
		if(reset == 1'b1) begin
			current_count <=`SD 2'b00;
		end
		else if (sel == 1'b1) begin
			current_count <=`SD next_count;
		end
	end
endmodule

module decoder_br (
 binary_in   , // binary input
 decoder_out , // bit out 

 );
 input [`BR_IDX:0] binary_in  ;
 output [`BR_SZ:0] decoder_out ; 
 wire [`BR_SZ:0] decoder_out ; 
 
assign decoder_out =  1 << binary_in;

endmodule	

  
