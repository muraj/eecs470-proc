module br_file(clk, reset, ID_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, ROB_valid, paddress1, ptaken1, paddress2, ptaken2); //Branch Table
	input 	wire	clk,reset; 
	input		wire	[`SCALAR-1:0]	ROB_taken, ROB_br_en, ROB_valid;
	input		wire	[`SCALAR*64-1:0] ID_NPC, ROB_NPC, ROB_taken_address;
	output	wire	[63:0] paddress1, paddress2;
	output	wire	ptaken1, ptaken2;

	wire [`SCALAR*`BR_IDX-1:0] ID_pc_idx = ID_NPC[`SCALAR*`BR_IDX+1:2] ;
	wire [`SCALAR*`BR_IDX-1:0] ROB_pc_idx = ROB_NPC[`SCALAR*`BR_IDX+1:2] ;


	wire	[`BR_SZ-1:0] ID_sel1,ID_sel2;
	wire	[`BR_SZ-1:0] ROB_sel1,ROB_sel2;
	wire	[`BR_SZ-1:0] ptaken_all;
	wire	[`SCALAR*64-1:0] real_address [`BR_SZ-1:0];
	wire	[`SCALAR*64-1:0] predict_address [`BR_SZ-1:0];

	decoder_br br_dc1 (ID_pc_idx[`SEL(`BR_IDX,1)],ID_sel1); //ID_NPC to selecting entry decoder
	decoder_br br_dc2 (ID_pc_idx[`SEL(`BR_IDX,2)],ID_sel2); //ID_NPC to selecting entry decoder
	decoder_br ROB_dc1 (ROB_pc_idx[`SEL(`BR_IDX,1)],ROB_sel1); //ROB_NPC to selecting entry decoder
	decoder_br ROB_dc2 (ROB_pc_idx[`SEL(`BR_IDX,2)],ROB_sel2); //ROB_NPC to selecting entry decoder


	generate
  	genvar i;
  	for(i=0; i<`BR_SZ; i=i+1) begin : br_entries
    	br_entry entry0 ( .clk(clk), .reset(reset), .ROB_sel1(ROB_sel1[i]), .ROB_sel2(ROB_sel2[i]),.ROB_br_en(ROB_br_en),.ROB_taken(ROB_taken), .ptaken(ptaken_all[i]),.ROB_valid(ROB_valid)); 
  	end
	endgenerate

	generate
  	genvar j;
  	for(j=0; j<`BR_SZ; j=j+1) begin : BTB_entries
    	BTB_entry entry1 (.clk(clk), .reset(reset), .ROB_br_en(ROB_br_en), .ROB_sel1(ROB_sel1[j]), .ROB_sel2(ROB_sel2[j]), .real_address(real_address[j]), .predict_address(predict_address[j]),.ROB_valid(ROB_valid));
  	end
	endgenerate


	assign paddress1 = predict_address[ID_pc_idx[`SEL(`BR_IDX,1)]];
	assign ptaken1 = ptaken_all[ID_pc_idx[`SEL(`BR_IDX,1)]];
	assign paddress2 = predict_address[ID_pc_idx[`SEL(`BR_IDX,2)]];
	assign ptaken2 = ptaken_all[ID_pc_idx[`SEL(`BR_IDX,2)]];

endmodule



module br_entry(clk, reset, ROB_sel1, ROB_sel2, ROB_br_en, ROB_taken, ptaken, ROB_valid); 

  input   wire	clk, reset;
	input		wire	ROB_sel1, ROB_sel2;
	input		wire	[`SCALAR-1:0] ROB_br_en, ROB_taken, ROB_valid;
  output  reg		ptaken;
	
	
	reg	[1:0] current_count, next_count;
	
	always@*	begin

		if(ROB_sel1 && ROB_br_en[0])	begin
			if(ROB_taken[0]) begin
				next_count = current_count+1;
			end
			else	begin
				next_count = current_count-1;
			end
		end
		else if (ROB_sel2 && ROB_br_en[1]) begin
			if(ROB_taken[1]) begin
				next_count = current_count+1;
			end
			else	begin
			next_count = current_count-1;
			end
		end
    else begin
			next_count = current_count;
		end

		ptaken = (current_count[2] | current_count[1]); //predict taken when first upper bits are 1

	end



	always@(posedge clk)	begin
		if(reset) begin
			current_count <=`SD 2'b00;
		end
		else if (ROB_valid[0] || ROB_valid[1]) begin
			current_count <=`SD next_count;
		end
	end
endmodule

module BTB_entry(clk, reset, ROB_br_en, ROB_sel1, ROB_sel2, real_address, predict_address, ROB_valid);

	input   wire	clk, reset;
	input		wire	ROB_sel1, ROB_sel2;
	input		wire	[`SCALAR-1:0]		 ROB_br_en, ROB_valid;
	input		wire	[`SCALAR*64-1:0] real_address;
	output  reg		[`SCALAR*64-1:0] predict_address;

	reg	[`SCALAR*64-1:0] current_address, next_address;

	always@*	begin
		if(ROB_sel1 && ROB_br_en[0]) begin
			next_address[`SEL(64,1)] = real_address[`SEL(64,1)];
		end
		else if (ROB_sel2 && ROB_br_en[1]) begin
			next_address[`SEL(64,2)] = real_address[`SEL(64,2)];
		end
		else	begin
			next_address = current_address;
		end			
		
		predict_address = current_address;
	end

	always@(posedge clk)	begin
		if(reset) begin
			current_address <=`SD `SCALAR*64'b00;
		end
		else if (ROB_valid[0] || ROB_valid[1]) begin
			current_address <=`SD next_address;
		end
	end


endmodule

module decoder_br (
 binary_in   , // binary input
 decoder_out // bit out 
 );
 input [`BR_IDX-1:0] binary_in  ;
 output [`BR_SZ-1:0] decoder_out ; 
 wire [`BR_SZ-1:0] decoder_out ; 
 
assign decoder_out =  1 << binary_in;

endmodule	

  
