module branch_predictor(clk, reset, IF_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, paddress, ptaken); //Branch Table
 //synopsys template
  parameter PRED_BITS =   `PRED_BITS;
	parameter PRED_IDX   =  `PRED_IDX;
	parameter	PRED_SZ    =  1 << PRED_IDX;

	input 	wire	clk, reset; 
	input		wire	[`SCALAR-1:0]    ROB_taken, ROB_br_en;
	input		wire	[`SCALAR*64-1:0] IF_NPC;
	input   wire  [`SCALAR*64-1:0] ROB_NPC, ROB_taken_address;
	output	wire	[`SCALAR*64-1:0] paddress;
	output	wire	[`SCALAR-1:0]    ptaken;

	reg    [PRED_BITS-1:0] predictor[PRED_SZ-1:0];
	reg    [63:0] 				 BTB_addr	[PRED_SZ-1:0];
  reg    [63:0]          BTB_npc  [PRED_SZ-1:0];

	wire [PRED_IDX-1:0] IF_TAG[`SCALAR-1:0];
	assign IF_TAG[0] = IF_NPC[PRED_IDX+1:2];
`ifdef SUPERSCALAR
	assign IF_TAG[1] = IF_NPC[PRED_IDX+64+1:64+2];
`endif
	wire [PRED_IDX-1:0] ROB_TAG[`SCALAR-1:0];
	assign ROB_TAG[0] = ROB_NPC[PRED_IDX+1:2];
`ifdef SUPERSCALAR
  wire [PRED_IDX-1:0] ROB_TAG_DEBUG = ROB_NPC[PRED_IDX+64+1:64+2];
	assign ROB_TAG[1] = ROB_NPC[PRED_IDX+64+1:64+2];
`endif

	wire [PRED_BITS-1:0] pred_result1 = predictor[IF_TAG[0]];
	assign ptaken[0] = pred_result1[PRED_BITS-1] && (BTB_npc[IF_TAG[0]] == IF_NPC[`SEL(64,1)]);			//Trick to get taken/not-taken.
	assign paddress[`SEL(64,1)] = BTB_addr[IF_TAG[0]];
`ifdef SUPERSCALAR
	wire [PRED_BITS-1:0] pred_result2 = predictor[IF_TAG[1]];
	assign ptaken[1] = pred_result2[PRED_BITS-1] && (BTB_npc[IF_TAG[1]] == IF_NPC[`SEL(64,2)]);			//Trick to get taken/not-taken.
	assign paddress[`SEL(64,2)] = BTB_addr[IF_TAG[1]];
`endif

//*** Update logic ***//
  wire [`SCALAR-1:0] predictor_plus_one;
  wire [`SCALAR-1:0] predictor_minus_one;
  wire [PRED_BITS-1:0] next_predictor[`SCALAR-1:0];

  assign predictor_plus_one[0] = (~& predictor[ROB_TAG[0]]) ? 1'b1 : 1'b0;
  assign predictor_minus_one[0] = (| predictor[ROB_TAG[0]]) ? -1'b1 : 1'b0;
  assign next_predictor[0] = predictor[ROB_TAG[0]] + (ROB_taken[0] ? predictor_plus_one : predictor_minus_one);
`ifdef  SUPERSCALAR   //We're assuming we'll never branch to ourself, otherwise we need some additional checks...
  assign predictor_plus_one[1] = (~& predictor[ROB_TAG[1]]) ? 1'b1 : 1'b0;
  assign predictor_minus_one[1] = (| predictor[ROB_TAG[1]]) ? -1'b1 : 1'b0;
  assign next_predictor[1] = predictor[ROB_TAG[1]] + (ROB_taken[1] ? predictor_plus_one : predictor_minus_one);
 `endif

	generate
	genvar i;
	for(i=0;i<`BR_SZ;i=i+1) begin : BR_PRED_RESET
		always @(posedge clk) begin
			if(reset) begin
				predictor[i] <= `SD 0;
				BTB_addr[i]  <= `SD 0;
        BTB_npc[i]   <= `SD 0;
			end
		end
	end
	endgenerate

	always @(posedge clk) begin
		if(ROB_br_en[0]) begin
			predictor[ROB_TAG[0]] <= `SD next_predictor[0];
      if((next_predictor[0] >> (PRED_BITS-1)) & ~(predictor[ROB_TAG[0]] >> (PRED_BITS-1))) begin  //Now considered taken, cache the result
  			BTB_addr[ROB_TAG[0]] <= `SD ROB_taken_address[`SEL(64,1)];
        BTB_npc [ROB_TAG[0]] <= `SD ROB_NPC[`SEL(64,1)];
      end
	  end
`ifdef SUPERSCALAR
    if(ROB_br_en[1]) begin
			predictor[ROB_TAG[1]] <= `SD next_predictor[1];
      if((next_predictor[1] >> (PRED_BITS-1))& ~(predictor[ROB_TAG[1]] >> (PRED_BITS-1))) begin  //Now considered taken, cache the result
  			BTB_addr[ROB_TAG[1]] <= `SD ROB_taken_address[`SEL(64,2)];
        BTB_npc [ROB_TAG[1]] <= `SD ROB_NPC[`SEL(64,2)];
      end
    end
`endif
	end
endmodule
