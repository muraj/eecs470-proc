module br_file(clk, reset, ID_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, paddress, ptaken); //Branch Table
 //synopsys template
  parameter PRED_BITS =   `PRED_BITS;
	parameter PRED_IDX   =  `PRED_IDX;
	parameter	PRED_SZ    =  1 << PRED_IDX;

	input 	wire	clk, reset; 
	input		wire	ROB_taken, ROB_br_en;
	input		wire	[`SCALAR*64-1:0] ID_NPC;
	input   wire  [63:0]           ROB_NPC, ROB_taken_address;
	output	wire	[`SCALAR*64-1:0] paddress;
	output	wire	[`SCALAR-1:0] ptaken;

	reg    [PRED_BITS-1:0] predictor	[PRED_SZ-1:0];
	reg    [63:0] 					    BTB	[PRED_SZ-1:0];

	wire [PRED_IDX-1:0] ID_TAG[`SCALAR-1:0];
	ID_TAG[0] = ID_NPC[PRED_IDX+3:3];
`ifdef SUPERSCALAR
	ID_TAG[1] = ID_NPC[PRED_IDX+64+3:64+3];
`endif
	wire [PRED_IDX-1:0] ROB_TAG = ROB_NPC[PRED_IDX+3:3];

	wire [PRED_IDX-1:0] pred_result1 = predictor[ID_TAG[0]];
	assign ptaken[0] = pred_result1[PRED_IDX-1];			//Trick to get taken/not-taken.
	assign paddress[`SEL(64,1)] = BTB[ID_TAG[0]];
`ifdef SUPERSCALAR
	wire [PRED_IDX-1:0] pred_result2 = predictor[ID_TAG[1]];
	assign ptaken[1] = pred_result2[PRED_IDX-1];			//Trick to get taken/not-taken.
	assign paddress[`SEL(64,2)] = BTB[ID_TAG[1]];
`endif

	generate
	genvar i;
	for(i=0;i<`BR_SZ;i=i+1) begin : BR_PRED_RESET
		always @(posedge clk) begin
			if(reset) begin
				predicator[i] <= `SD 0;
				BTB[i] <= `SD 0;
			end
		end
	end
	endgenerate


	always @(posedge clk) begin
		if(ROB_br_en) begin
			predictor[ROB_TAG] <= `SD predictor[ROB_TAG] + (ROB_taken ? 1'b1 : -1'b1);
			BTB[ROB_TAG] <= `SD ROB_taken ? ROB_taken_address : ROB_NPC;
	  end
	end
endmodule
