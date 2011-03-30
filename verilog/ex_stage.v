//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  ex_stage.v                                           //
//                                                                      //
//  Description :  instruction execute (EX) stage of the pipeline;      //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the ALU, compute the result,// 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline.                       // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

// Memory-Controller
// Have to make a fake LSQ inside the testbench. (Remove this line after all things are done)
module MEM_CONT ( clk, reset,
									//Inputs from the Input Logic 
									LSQ_idx, prega_in, pregb_in, rd_in, wr_in, 
									pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in, next_gnt,
								 //Inputs from LSQ
								 	LSQ_rob_idx, LSQ_pdest_idx, LSQ_mem_value, 
									LSQ_done, LSQ_rd_mem, LSQ_wr_mem,
								 //Outputs to LSQ
								 	MEM_LSQ_idx, MEM_ADDR, MEM_reg_value, 
								 //Outputs to EX/CO registers
								 	result_reg, result_valid_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
									done, done_reg, gnt_reg
									);

	input									clk, reset;
	// Inputs from the input logic in EX stage
	input [`LSQ_IDX-1:0]	LSQ_idx;	
	input [63:0]					prega_in, pregb_in;
	input 								rd_in, wr_in, EX_en_in, next_gnt;
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0]					IR_in;
	input [63:0]					npc_in;
	input [`ROB_IDX-1:0]	rob_idx_in;
	// Inputs from LSQ
	input [`ROB_IDX-1:0]	LSQ_rob_idx;
	input [`PRF_IDX-1:0]	LSQ_pdest_idx;
	input [63:0]					LSQ_mem_value;
	input 								LSQ_done, LSQ_rd_mem, LSQ_wr_mem;
	// Outputs to LSQ
	output [`LSQ_IDX-1:0]	MEM_LSQ_idx;
	output [63:0]					MEM_ADDR, MEM_reg_value;
	// Outputs to EX/CO registers
	output reg [63:0]					result_reg;
	output reg [`PRF_IDX-1:0]	pdest_idx_reg;
	output reg [31:0]					IR_reg;
	output reg [63:0]					npc_reg;
	output reg [`ROB_IDX-1:0]	rob_idx_reg;
	output reg								result_valid_reg, done_reg, gnt_reg;
	output										done;

	assign done = LSQ_done;

	wire [63:0]	mem_disp 	= { {48{IR_in[15]}}, IR_in[15:0]};
	assign	MEM_LSQ_IDX		= LSQ_idx;
	assign	MEM_ADDR 			= mem_disp + pregb_in;
	assign	MEM_reg_value = prega_in;

	always @(posedge clk) begin
		if(reset)	gnt_reg	<= `SD 0;
		else			gnt_reg	<= `SD next_gnt; 
	end

	always @(posedge clk) begin
		if(reset) begin
			result_reg				<= `SD 0;
			result_valid_reg	<= `SD 0;
			pdest_idx_reg			<= `SD `ZERO_PRF;
			IR_reg						<= `SD `NOOP_INST;
			npc_reg						<= `SD 0;
			rob_idx_reg				<= `SD 0;
			done_reg					<= `SD 0;
		end
		else begin
			result_reg				<= `SD LSQ_mem_value;
			result_valid_reg	<= `SD LSQ_done & LSQ_rd_mem;
			pdest_idx_reg			<= `SD LSQ_pdest_idx;
			IR_reg						<= `SD 0; // FIXME
			npc_reg						<= `SD 0; // FIXME
			rob_idx_reg				<= `SD LSQ_rob_idx;
			done_reg					<= `SD LSQ_done;
		end
	end

endmodule // MEM_CONT

// Multiplier
module MULT(clk, reset, 
						// Inputs
						prega_value, pregb_value, pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in,
						next_gnt, stall,
						// Outputs
						result_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
						done, done_reg, gnt_reg
						);
	//synopsys template
	parameter STAGES=8;

  input 								clk, reset, stall, next_gnt;
  input [63:0] 				 	prega_value, pregb_value;	
	
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0] 					IR_in;
	input [63:0] 					npc_in;
	input [`ROB_IDX-1:0] 	rob_idx_in;
	input 								EX_en_in;

	output reg [63:0]					result_reg;
	output reg [`PRF_IDX-1:0]	pdest_idx_reg;
	output reg [31:0] 				IR_reg;
	output reg [63:0] 				npc_reg;
	output reg [`ROB_IDX-1:0] rob_idx_reg;
	output reg								done_reg, gnt_reg;
	output										done;

	wire [63:0]												mcand_out, mplier_out;
  wire [((STAGES-1)*64)-1:0] 				internal_products, internal_mcands, internal_mpliers;
	wire [((STAGES-1)*`PRF_IDX)-1:0]	internal_pdest_idx;
	wire [((STAGES-1)*32)-1:0] 				internal_IR;
  wire [((STAGES-1)*64)-1:0] 				internal_npc;
	wire [((STAGES-1)*`ROB_IDX)-1:0]	internal_rob_idx;
	wire [STAGES-2:0] 								internal_dones;

	wire [63:0]					result_out, npc_out;
	wire [`PRF_IDX-1:0]	pdest_idx_out;
	wire [31:0]					IR_out;
	wire [`ROB_IDX-1:0]	rob_idx_out;

	// decoder for MULT
	reg	[63:0]	mcand_in, mplier_in;
	always @* begin
		mcand_in = prega_value;
		case(IR_in[31:29])
			3'b010	: mplier_in = IR_in[12] ? {56'b0, IR_in[20:13]} : pregb_value;
			default	: mplier_in = 64'hbaadbeefdeadbeef;
		endcase
	end

	always @(posedge clk) begin
		if(reset)	gnt_reg	<= `SD 0;
		else			gnt_reg	<= `SD next_gnt; 
	end

	always @(posedge clk) begin
		if(reset) begin
			result_reg		<= `SD 0;
			pdest_idx_reg	<= `SD `ZERO_PRF;
			IR_reg				<= `SD `NOOP_INST;
			npc_reg				<= `SD 0;
			rob_idx_reg		<= `SD 0;
			done_reg			<= `SD 0;
		end
		else if (!stall) begin
			result_reg		<= `SD result_out;
			pdest_idx_reg	<= `SD pdest_idx_out;
			IR_reg				<= `SD IR_out;
			npc_reg				<= `SD npc_out;
			rob_idx_reg		<= `SD rob_idx_out;
			done_reg			<= `SD done;
		end
	end

  mult_stage mstage [STAGES-1:0] 
    (.clk(clk),
     .reset(reset),
		 .stall(stall),
     .product_in({internal_products,64'h0}),
     .mplier_in({internal_mpliers,mplier_in}),
     .mcand_in({internal_mcands,mcand_in}),
     .start({internal_dones,EX_en_in}),
     .product_out({result_out,internal_products}),
     .mplier_out({mplier_out,internal_mpliers}),
     .mcand_out({mcand_out,internal_mcands}),
     .done({done,internal_dones}),
		 .pdest_idx_in({internal_pdest_idx, pdest_idx_in}),
		 .IR_in({internal_IR, IR_in}),
		 .npc_in({internal_npc, npc_in}),
		 .rob_idx_in({internal_rob_idx, rob_idx_in}),
		 .pdest_idx_out({pdest_idx_out, internal_pdest_idx}),
		 .IR_out({IR_out, internal_IR}),
		 .npc_out({npc_out, internal_npc}),
		 .rob_idx_out({rob_idx_out, internal_rob_idx})
    );

endmodule // MULT

module mult_stage(clk, reset, stall, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done,
									pdest_idx_in, IR_in, npc_in, rob_idx_in,
									pdest_idx_out, IR_out, npc_out, rob_idx_out
									);

  input 								clk, reset, stall, start;
  input [63:0] 					product_in, mplier_in, mcand_in;

	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0] 					IR_in;
	input [63:0] 					npc_in;
	input [`ROB_IDX-1:0] 	rob_idx_in;

  output 								done;
  output [63:0] 				product_out, mplier_out, mcand_out;
	
	output reg [`PRF_IDX-1:0]	pdest_idx_out;
	output reg [31:0] 				IR_out;
	output reg [63:0] 				npc_out;
	output reg [`ROB_IDX-1:0]	rob_idx_out;

  reg  [63:0] prod_in_reg, partial_prod_reg;
  wire [63:0] partial_product, next_mplier, next_mcand;

  reg [63:0] mplier_out, mcand_out;
  reg done;
  
  assign product_out = prod_in_reg + partial_prod_reg;
  assign partial_product = mplier_in[7:0] * mcand_in;
  assign next_mplier = {8'b0,mplier_in[63:8]};
  assign next_mcand = {mcand_in[55:0],8'b0};

  always @(posedge clk)
  begin
		if(reset) begin
	    prod_in_reg      	<= `SD 0;
  	  partial_prod_reg 	<= `SD 0;
    	mplier_out       	<= `SD 0;
    	mcand_out        	<= `SD 0;
			pdest_idx_out			<= `SD `ZERO_PRF;
			IR_out						<= `SD `NOOP_INST;
			npc_out						<= `SD 0;
			rob_idx_out				<= `SD 0;
		end
		else if(!stall) begin
   		prod_in_reg      	<= `SD product_in;
    	partial_prod_reg 	<= `SD partial_product;
    	mplier_out       	<= `SD next_mplier;
    	mcand_out        	<= `SD next_mcand;
			pdest_idx_out			<= `SD pdest_idx_in;
			IR_out						<= `SD IR_in;
			npc_out						<= `SD npc_in;
			rob_idx_out				<= `SD rob_idx_in;
		end
  end

  always @(posedge clk)
  begin
    if(reset)	done <= `SD 1'b0;
    else if(stall) done <= `SD done;
    else done <= `SD start;
  end

endmodule // mult_stage

module ALU (clk, reset,
						// Inputs
						prega_in, pregb_in, ALUop, pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in, 
						next_gnt, stall,	// from EX_ps
						// Outputs
						result_reg, BR_result_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
						done, done_reg, gnt_reg			// to EX_ps
						);

  input 								clk, reset;
	
	input [63:0]	        prega_in, pregb_in;
	input [4:0] 					ALUop;
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0] 					IR_in;
	input [63:0] 					npc_in;
	input [`ROB_IDX-1:0] 	rob_idx_in;
	input 								EX_en_in, next_gnt, stall;

	output reg [63:0]					result_reg;
	output reg								BR_result_reg;
	output reg [`PRF_IDX-1:0]	pdest_idx_reg;
	output reg [31:0] 				IR_reg;
	output reg [63:0] 				npc_reg;
	output reg [`ROB_IDX-1:0] rob_idx_reg;
	output reg								done, done_reg, gnt_reg;

  wire [63:0]	alu_result_out;
  wire 				br_result_out;
  reg [63:0] 	opa, opb;
  reg 				isBranch;
	reg					uncondBranch;
	reg [63:0]	result;
	reg					BR_result;

  ALU_leaf	ALU_leaf0	(.opa(opa), .opb(opb), .func(ALUop), .result(alu_result_out));
  BRcond 		BRcond0		(.opa(prega_in), .func(IR_in[28:26]), .cond(br_result_out));

  always @* begin //Small mux for reading the correct reg values
		done			= EX_en_in;
		result		= (isBranch & !uncondBranch & !br_result_out) ? npc_in : alu_result_out;
		BR_result	= isBranch ? br_result_out : 1'b0;
    isBranch	= 1'b0;
		uncondBranch = 1'b0;
    case (IR_in[31:29])
      3'b010: begin
  				     	opa = prega_in;
       					opb = IR_in[12] ? {56'b0, IR_in[20:13]} : pregb_in;
      				end
      3'b011: begin
        				opa = ~64'h3;
        				opb = pregb_in;
        				isBranch = 1'b1;
								uncondBranch = 1'b1;
      				end
			3'b001, 3'b100, 3'b101:	begin	// for 'lda' instruction
																opa = {{48{IR_in[15]}}, IR_in[15:0]};
																opb = pregb_in;
															end
      3'b111, 3'b110: begin
        								opa = npc_in;
        								opb = {{41{IR_in[20]}}, IR_in[20:0], 2'b00};
        								isBranch = 1'b1;
												uncondBranch = (IR_in[31:26] == `BR_INST) | (IR_in[31:26] == `BSR_INST);
      								end
      default: 	begin  //Should never see this
        					opa = 64'hbaadbeefdeadbeef;
        					opb = 64'hbaadbeefdeadbeef;
      					end
    endcase
  end

	always @(posedge clk) begin
		if(reset)	gnt_reg	<= `SD 0;
		else			gnt_reg	<= `SD next_gnt; 
	end
			
	always @(posedge clk) begin
		if(reset) begin
			result_reg			<= `SD 0;
			BR_result_reg		<= `SD 0;
			pdest_idx_reg		<= `SD `ZERO_PRF;
			IR_reg					<= `SD `NOOP_INST;
			npc_reg					<= `SD 0;
			rob_idx_reg			<= `SD 0;
			done_reg				<= `SD 0;
		end 
		else if (!stall) begin
			result_reg			<= `SD result;
			BR_result_reg		<= `SD BR_result;
			pdest_idx_reg		<= `SD pdest_idx_in;
			IR_reg					<= `SD IR_in;
			npc_reg					<= `SD npc_in;
			rob_idx_reg			<= `SD rob_idx_in;
			done_reg				<= `SD EX_en_in;
		end
	end

endmodule

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module ALU_leaf (//Inputs
           opa,
           opb,
           func,
           
           // Output
           result
          );

  input  [63:0] opa;
  input  [63:0] opb;
  input   [4:0] func;
  output [63:0] result;

  reg    [63:0] result;

    // This function computes a signed less-than operation
  function signed_lt;
    input [63:0] a, b;
    
    if (a[63] == b[63])	signed_lt = (a < b); // signs match: signed compare same as unsigned
    else 								signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
  endfunction

  always @*
  begin
    case (func)
      `ALU_ADDQ:   result = opa + opb;
      `ALU_SUBQ:   result = opa - opb;
      `ALU_AND:    result = opa & opb;
      `ALU_BIC:    result = opa & ~opb;
      `ALU_BIS:    result = opa | opb;
      `ALU_ORNOT:  result = opa | ~opb;
      `ALU_XOR:    result = opa ^ opb;
      `ALU_EQV:    result = opa ^ ~opb;
      `ALU_SRL:    result = opa >> opb[5:0];
      `ALU_SLL:    result = opa << opb[5:0];
      `ALU_SRA:    result = (opa >> opb[5:0]) | ({64{opa[63]}} << (64 - opb[5:0])); // arithmetic from logical shift
      `ALU_CMPULT: result = { 63'd0, (opa < opb) };
      `ALU_CMPEQ:  result = { 63'd0, (opa == opb) };
      `ALU_CMPULE: result = { 63'd0, (opa <= opb) };
      `ALU_CMPLT:  result = { 63'd0, signed_lt(opa, opb) };
      `ALU_CMPLE:  result = { 63'd0, (signed_lt(opa, opb) || (opa == opb)) };
      default:     result = 64'hdeadbeefbaadbeef; 
    endcase
  end
endmodule // ALU

//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module BRcond(// Inputs
              opa,        // Value to check against condition
              func,       // Specifies which condition to check
              // Output
              cond        // 0/1 condition result (False/True)
             );

  input   [2:0] func;
  input  [63:0] opa;
  output        cond;
  
  reg           cond;

  always @*
  begin
    case (func[1:0]) // 'full-case'  All cases covered, no need for a default
      2'b00: cond = (opa[0] == 0);  // LBC: (lsb(opa) == 0) ?
      2'b01: cond = (opa == 0);     // EQ: (opa == 0) ?
      2'b10: cond = (opa[63] == 1); // LT: (signed(opa) < 0) : check sign bit
      2'b11: cond = (opa[63] == 1) || (opa == 0); // LE: (signed(opa) <= 0)
    endcase
  
     // negate cond if func[2] is set
    if (func[2])
      cond = ~cond;
  end
endmodule // BRcond

// EX_ps
module EX_ps (// Inputs
							ALU_done, MULT_done, MEM_done, ALU_done_reg, MULT_done_reg, MEM_done_reg,
							ALU_gnt_reg, MULT_gnt_reg, MEM_gnt_reg,
							// Outputs
							ALU_next_gnt_reg, MULT_next_gnt_reg, MEM_next_gnt_reg,
							ALU_stall, MULT_stall, ALU_free, MULT_free
							);
	input [`SCALAR-1:0]	ALU_done, ALU_done_reg, ALU_gnt_reg;
	input [`SCALAR-1:0]	MULT_done, MULT_done_reg, MULT_gnt_reg;
	input [`SCALAR-1:0]	MEM_done, MEM_done_reg, MEM_gnt_reg;

	output [`SCALAR-1:0]	ALU_next_gnt_reg, MULT_next_gnt_reg, MEM_next_gnt_reg;
	output [`SCALAR-1:0]	ALU_stall, MULT_stall;
	output [`SCALAR-1:0]	ALU_free, MULT_free;

	// Truth Table
	//	done	gnt	done_reg	gnt_reg	|	stall	next_gnt_reg	free
	//		0		0			0					0			|		0				0						1
	//		0		0			0					1			|		illegal
	//		0		0			1					0			|		1				0						0
	//		0		0			1					1			|		0				0						1
	//		0		1			0					0			|		illegal
	//		0		1			0					1			|		illegal
	//		0		1			1					0			|		1				1						1
	//		0		1			1					1			|		illegal
	//		1		0			0					0			|		0				0						0
	//		1		0			0					1			|		illegal
	//		1		0			1					0			|		1				0						0	
	//		1		0			1					1			|		0				0						0
	//		1		1			0					0			|		0				1						1
	//		1		1			0					1			|		illegal
	//		1		1			1					0			|		1				1						0	
	//		1		1			1					1			|		0				1						1

	`ifdef SUPERSCALAR
	wire [5:0]	done 					= {MEM_done[0], MEM_done[1], MULT_done[0], MULT_done[1], ALU_done[0], ALU_done[1]};
	wire [5:0]	done_reg			= {MEM_done_reg[0], MEM_done_reg[1], MULT_done_reg[0], MULT_done_reg[1], ALU_done_reg[0], ALU_done_reg[1]}; 
	wire [5:0]	gnt_reg				= {MEM_gnt_reg[0], MEM_gnt_reg[1], MULT_gnt_reg[0], MULT_gnt_reg[1], ALU_gnt_reg[0], ALU_gnt_reg[1]}; 
	wire [5:0]	ps_req				= done | (done_reg & ~gnt_reg);
	wire [1:0]	temp_ps1, temp_ps2;
	wire [5:0]	gnt_ps1, gnt_ps2;
	wire [5:0]	gnt = gnt_ps1 | gnt_ps2;
	wire [5:0]	stall					= done_reg & (~gnt_reg); 
	wire [5:0]	next_gnt_reg	= ((done ^ done_reg) & gnt & (~gnt_reg)) | (done & gnt & done_reg);
	wire [5:0]	free					= ((((~done) & (~gnt)) | (done & gnt)) & (((~done_reg) & (~gnt_reg)) | (done_reg & gnt_reg))) | ((~done) & gnt & done_reg & (~gnt_reg));
	ps #(.NUM_BITS(8)) ps1 (.req({2'b00, ps_req}), .en(1'b1), .gnt({temp_ps1, gnt_ps1}), .req_up());
	ps #(.NUM_BITS(8)) ps2 (.req({2'b00, ps_req ^ gnt_ps1}), .en(1'b1), .gnt({temp_ps2, gnt_ps2}), .req_up());
	assign ALU_next_gnt_reg 	= {next_gnt_reg[0], next_gnt_reg[1]};
	assign MULT_next_gnt_reg	= {next_gnt_reg[2], next_gnt_reg[3]};
	assign MEM_next_gnt_reg		= {next_gnt_reg[4], next_gnt_reg[5]};
	assign ALU_stall					= {stall[0], stall[1]};
	assign MULT_stall					= {stall[2], stall[3]};
	assign ALU_free						= {free[0], free[1]};
	assign MULT_free					= {free[2], free[3]};
	`else
	wire [2:0]	done 					= {MEM_done, MULT_done, ALU_done};
	wire [2:0]	done_reg			= {MEM_done_reg, MULT_done_reg, ALU_done_reg}; 
	wire [2:0]	gnt_reg				= {MEM_gnt_reg, MULT_gnt_reg, ALU_gnt_reg}; 
	wire [2:0]	ps_req				= done | (done_reg & ~gnt_reg);
	wire 				temp_ps1;
	wire [2:0]	gnt;
	wire [2:0]	stall					= done_reg & (~gnt_reg); 
	wire [2:0]	next_gnt_reg	= ((done ^ done_reg) & gnt & (~gnt_reg)) | (done & gnt & done_reg);
	wire [2:0]	free					= ((((~done) & (~gnt)) | (done & gnt)) & (((~done_reg) & (~gnt_reg)) | (done_reg & gnt_reg))) | ((~done) & gnt & done_reg & (~gnt_reg));
	ps #(.NUM_BITS(4)) ps1 (.req({1'b0, ps_req}), .en(1'b1), .gnt({temp_ps1, gnt}), .req_up());
	assign ALU_next_gnt_reg 	= next_gnt_reg[0];
	assign MULT_next_gnt_reg	= next_gnt_reg[1];
	assign MEM_next_gnt_reg		= next_gnt_reg[2];
	assign ALU_stall					= stall[0];
	assign MULT_stall					= stall[1];
	assign ALU_free						= free[0];
	assign MULT_free					= free[1];
	`endif

endmodule

// EX-CO Interface
module EX_CO_Mux (	//Inputs
										ALU_result, ALU_BR_result, ALU_pdest_idx, ALU_IR, ALU_npc, ALU_rob_idx, ALU_gnt,	
										MULT_result, MULT_pdest_idx, MULT_IR, MULT_npc, MULT_rob_idx, MULT_gnt,
										MEM_result, MEM_result_valid, MEM_pdest_idx, MEM_IR, MEM_npc, MEM_rob_idx, MEM_gnt,
										//Outputs
										cdb_tag, cdb_valid, cdb_value, cdb_MEM_result_valid, 
										cdb_rob_idx, cdb_BR_result,
										//for DEBUGGING
										cdb_npc, cdb_IR 
										);
	input [64*`SCALAR-1:0]				ALU_result, MULT_result, MEM_result;
	input [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx, MULT_pdest_idx, MEM_pdest_idx;
	input [32*`SCALAR-1:0]				ALU_IR, MULT_IR, MEM_IR;
	input [64*`SCALAR-1:0]				ALU_npc, MULT_npc, MEM_npc;
	input [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx, MULT_rob_idx, MEM_rob_idx;
	input [`SCALAR-1:0]						ALU_gnt, MULT_gnt, MEM_gnt;
	input [`SCALAR-1:0] 					ALU_BR_result;
	input [`SCALAR-1:0]						MEM_result_valid;

	output [`PRF_IDX*`SCALAR-1:0] cdb_tag;
	output [`SCALAR-1:0] 					cdb_valid;
	output [64*`SCALAR-1:0] 			cdb_value;
	output [`SCALAR-1:0] 					cdb_MEM_result_valid;
	output [`ROB_IDX*`SCALAR-1:0] cdb_rob_idx;
	output [`SCALAR-1:0] 					cdb_BR_result;
	// for DEBUGGING
	output [64*`SCALAR-1:0]				cdb_npc;
	output [32*`SCALAR-1:0]				cdb_IR;

	`ifdef SUPERSCALAR
		wire [63:0] 				result 		[7:0];
		wire [`PRF_IDX-1:0]	pdest_idx	[7:0];
		wire [31:0] 				IR 				[7:0];
		wire [63:0] 				npc 			[7:0];
		wire [`ROB_IDX-1:0]	rob_idx 	[7:0];
			assign result[7]		= 64'b0; 														assign result[6] 		= 64'b0;
			assign result[5]		= ALU_result[`SEL(64,2)];						assign result[4] 		= ALU_result[`SEL(64,1)];
			assign result[3]		= MULT_result[`SEL(64,2)];					assign result[2] 		= MULT_result[`SEL(64,1)];
			assign result[1]		= MEM_result[`SEL(64,2)];						assign result[0]		= MEM_result[`SEL(64,1)];
			assign pdest_idx[7]	= `ZERO_PRF;												assign pdest_idx[6]	= `ZERO_PRF;
			assign pdest_idx[5]	= ALU_pdest_idx[`SEL(`PRF_IDX,2)];	assign pdest_idx[4]	= ALU_pdest_idx[`SEL(`PRF_IDX,1)];
			assign pdest_idx[3]	= MULT_pdest_idx[`SEL(`PRF_IDX,2)];	assign pdest_idx[2]	= MULT_pdest_idx[`SEL(`PRF_IDX,1)];
			assign pdest_idx[1]	= MEM_pdest_idx[`SEL(`PRF_IDX,2)];	assign pdest_idx[0]	= MEM_pdest_idx[`SEL(`PRF_IDX,1)];
			assign IR[7]				= `NOOP_INST; 											assign IR[6] 				= `NOOP_INST;
			assign IR[5]				= ALU_IR[`SEL(32,2)];								assign IR[4]				= ALU_IR[`SEL(32,1)];
			assign IR[3]				= MULT_IR[`SEL(32,2)];							assign IR[2]				= MULT_IR[`SEL(32,1)];
			assign IR[1]				= MEM_IR[`SEL(32,2)];								assign IR[0]				= MEM_IR[`SEL(32,1)];
			assign npc[7]				= 64'b0; 														assign npc[6] 			= 64'b0;
			assign npc[5]				= ALU_npc[`SEL(64,2)];							assign npc[4]				= ALU_npc[`SEL(64,1)];
			assign npc[3]				= MULT_npc[`SEL(64,2)];							assign npc[2]				= MULT_npc[`SEL(64,1)];
			assign npc[1]				= MEM_npc[`SEL(64,2)];							assign npc[0]				= MEM_npc[`SEL(64,1)];
			assign rob_idx[7]		= {`ROB_IDX{1'b0}};									assign rob_idx[6]		= {`ROB_IDX{1'b0}};
			assign rob_idx[5] 	= ALU_rob_idx[`SEL(`ROB_IDX,2)];		assign rob_idx[4] 	= ALU_rob_idx[`SEL(`ROB_IDX,1)];
			assign rob_idx[3] 	= MULT_rob_idx[`SEL(`ROB_IDX,2)];		assign rob_idx[2] 	= MULT_rob_idx[`SEL(`ROB_IDX,1)];
			assign rob_idx[1] 	= MEM_rob_idx[`SEL(`ROB_IDX,2)];		assign rob_idx[0] 	= MEM_rob_idx[`SEL(`ROB_IDX,1)];
		wire [7:0]	result_valid_MEM				= {5'b0, MEM_result_valid, 1'b0};
		wire [7:0]	BR_result								= {1'b0, ALU_BR_result, 5'b0};

		wire [5:0] 	granted = {ALU_gnt, MULT_gnt, MEM_gnt};
		wire [1:0]	temp;
		wire [5:0]	granted_cdb1;
		wire [5:0] 	granted_cdb2 = granted ^ granted_cdb1;
		wire [2:0]	cdb1_idx, cdb2_idx;
		ps #(.NUM_BITS(8)) ps1 (.req({2'b00, granted}), .en(1'b1), .gnt({temp, granted_cdb1}), .req_up());
		pe #(.OUT_WIDTH(3)) pe1 (.gnt({2'b00, granted_cdb1}), .enc(cdb1_idx));
		pe #(.OUT_WIDTH(3)) pe2 (.gnt({2'b00, granted_cdb2}), .enc(cdb2_idx));
		assign cdb_tag 							= {pdest_idx[cdb2_idx], pdest_idx[cdb1_idx]};
		assign cdb_valid 						=	{ |cdb2_idx, |cdb1_idx};
		assign cdb_value						= {result[cdb2_idx], result[cdb1_idx]}; 
		assign cdb_rob_idx					=	{rob_idx[cdb2_idx], rob_idx[cdb1_idx]};
		assign cdb_MEM_result_valid	= {result_valid_MEM[cdb2_idx], result_valid_MEM[cdb1_idx]};
		assign cdb_BR_result				= {BR_result[cdb2_idx], BR_result[cdb1_idx]};
		//for debugging
		assign cdb_npc							= {npc[cdb2_idx], npc[cdb1_idx]};
		assign cdb_IR								= {IR[cdb2_idx], IR[cdb1_idx]};
	`else
		wire [63:0]					result		[3:0];
		wire [`PRF_IDX-1:0]	pdest_idx	[3:0];
		wire [31:0] 				IR 				[3:0];
		wire [63:0] 				npc 			[3:0];
		wire [`ROB_IDX-1:0]	rob_idx 	[3:0];
			assign result[3] 		= 64'b0;						assign result[2] 		= ALU_result;
			assign result[1] 		= MULT_result;			assign result[0] 		= MEM_result;
			assign pdest_idx[3]	= `ZERO_PRFi;				assign pdest_idx[2]	= ALU_pdest_idx;
			assign pdest_idx[1]	= MULT_pdest_idx;		assign pdest_idx[0]	= MEM_pdest_idx;
			assign IR[3]				= `NOOP_INST;				assign IR[2] 				= ALU_IR; 
			assign IR[1] 				= MULT_IR; 					assign IR[0] 				= MEM_IR;
			assign npc[3] 			= 64'b0; 						assign npc[2] 			= ALU_npc; 
			assign npc[1] 			= MULT_npc; 				assign npc[0] 			= MEM_npc;
			assign rob_idx[3] 	= {`ROB_IDX{1'b0}};	assign rob_idx[2] 	= ALU_rob_idx; 
			assign rob_idx[1] 	= MULT_rob_idx;			assign rob_idx[0] 	= MEM_rob_idx;
		wire [3:0]	result_valid_MEM				= {2'b0, MEM_result_valid, 1'b0};
		wire [3:0]	BR_result								= {ALU_BR_result, 3'b0};
		wire [2:0] 	granted = {ALU_gnt, MULT_gnt, MEM_gnt};
		wire 				temp;
		wire [2:0]	granted_cdb;
		wire [1:0]	cdb_idx;
		ps #(.NUM_BITS(4)) ps1 (.req({1'b0, granted}), .en(1'b1), .gnt({temp, granted_cdb}), .req_up());
		pe #(.OUT_WIDTH(2)) pe1 (.gnt({1'b0, granted_cdb}), .enc(cdb_idx));
		assign cdb_tag 							= pdest_idx[cdb_idx];
		assign cdb_valid 						=	|cdb_idx;
		assign cdb_value						= result[cdb_idx];
		assign cdb_rob_idx					=	rob_idx[cdb_idx];
		assign cdb_MEM_result_valid	= result_valid_MEM[cdb_idx];
		assign cdb_BR_result				= BR_result[cdb_idx];
		//for debugging
		assign cdb_npc							= npc[cdb_idx];
		assign cdb_IR								= IR[cdb_idx];
	`endif

endmodule

module EX_input_logic (//Inputs
												clk, reset, ALU_free_in, MULT_free_in,
												LSQ_idx, pdest_idx, prega_value, pregb_value, ALUop, 
												rd_mem, wr_mem, IR, npc, rob_idx, EX_en,
											 //Outputs
												ALU_prega_out, ALU_pregb_out, ALU_func_out, 
												ALU_pdest_idx_out, ALU_IR_out, ALU_npc_out, ALU_rob_idx_out, ALU_EX_en_out,
												MULT_prega_out, MULT_pregb_out, 
												MULT_pdest_idx_out, MULT_IR_out, MULT_npc_out, MULT_rob_idx_out, MULT_EX_en_out,
												MEM_LSQ_idx_out, MEM_prega_out, MEM_pregb_out, 
												MEM_rd_out, MEM_wr_out, MEM_pdest_idx_out, MEM_IR_out, MEM_npc_out, MEM_rob_idx_out, MEM_EX_en_out
											);

	input													clk, reset;
	input	[`SCALAR-1:0] 					ALU_free_in, MULT_free_in;
	input [`LSQ_IDX*`SCALAR-1:0]	LSQ_idx;
	input	[`PRF_IDX*`SCALAR-1:0] 	pdest_idx;
	input	[64*`SCALAR-1:0] 				prega_value;
	input	[64*`SCALAR-1:0] 				pregb_value;
	input	[5*`SCALAR-1:0] 				ALUop;
	input	[`SCALAR-1:0] 					rd_mem;
	input	[`SCALAR-1:0] 					wr_mem;
	input	[32*`SCALAR-1:0] 				IR;
	input	[64*`SCALAR-1:0] 				npc;
	input	[`ROB_IDX*`SCALAR-1:0] 	rob_idx;
	input	[`SCALAR-1:0] 					EX_en;

	output reg [64*`SCALAR-1:0]				ALU_prega_out, ALU_pregb_out, MULT_prega_out, MULT_pregb_out, MEM_prega_out, MEM_pregb_out;
	output reg [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_out, MULT_pdest_idx_out, MEM_pdest_idx_out;
	output reg [32*`SCALAR-1:0]				ALU_IR_out, MULT_IR_out, MEM_IR_out;
	output reg [64*`SCALAR-1:0]				ALU_npc_out, MULT_npc_out, MEM_npc_out;
	output reg [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_out, MULT_rob_idx_out, MEM_rob_idx_out;
	output reg [`SCALAR-1:0]					ALU_EX_en_out, MULT_EX_en_out, MEM_EX_en_out;
	output reg [5*`SCALAR-1:0]				ALU_func_out;
	output reg [`LSQ_IDX*`SCALAR-1:0]	MEM_LSQ_idx_out;
	output reg [`SCALAR-1:0]					MEM_rd_out, MEM_wr_out;

	reg [`SCALAR-1:0]							ALU_free, MULT_free;
	wire [`SCALAR-1:0]						MEM_inst = rd_mem | wr_mem;

	always @(posedge clk) begin
		if(reset) begin
			ALU_free	<= `SD {`SCALAR{1'b1}};
			MULT_free	<= `SD {`SCALAR{1'b1}};
		end
		else begin
			ALU_free	<= `SD ALU_free_in;
			MULT_free	<= `SD MULT_free_in;
		end
	end

	// Determine the instruction type
	reg	[2*`SCALAR-1:0]	inst_type;
	always @* begin
		inst_type = {`SCALAR{`EX_NOOP}};
			if(MEM_inst[`SEL(1,1)])	inst_type[`SEL(2,1)] = `EX_MEM;
			else if(ALUop[`SEL(5,1)] == `ALU_MULQ)	inst_type[`SEL(2,1)] = `EX_MULT;
			else if(EX_en[`SEL(1,1)]) inst_type[`SEL(2,1)] = `EX_ALU;
		`ifdef SUPERSCALAR
			if(MEM_inst[`SEL(1,2)])	inst_type[`SEL(2,2)] = `EX_MEM;
			else if(ALUop[`SEL(5,2)] == `ALU_MULQ)	inst_type[`SEL(2,2)] = `EX_MULT;
			else if(EX_en[`SEL(1,2)]) inst_type[`SEL(2,2)] = `EX_ALU;
		`endif
	end


	// Determine which instruction goes to which functional unit
	reg [3*`SCALAR-1:0]					select1, select2;
	`ifdef SUPERSCALAR
	always @* begin
		case (inst_type)
			{`EX_NOOP, `EX_NOOP}:	begin // inst2=NOOP,  inst1=NOOP
															select2 = 6'b000000; select1 = 6'b000000; end
			{`EX_NOOP, `EX_MEM}	:	begin // inst2=NOOP,  inst1=MEM
															select2 = 6'b000000; select1 = 6'b010000; end
			{`EX_NOOP, `EX_MULT}:	begin // inst2=NOOP,  inst1=MULT
															select2 = 6'b000000; select1 = (MULT_free[0]) ? 6'b000100 : 6'b001000; end
			{`EX_NOOP, `EX_ALU}	:	begin // inst2=NOOP,  inst1=ALU
															select2 = 6'b000000; select1 = (ALU_free[0]) ? 6'b000001 : 6'b000010; end
			{`EX_MEM, `EX_NOOP}	:	begin // inst2=MEM,  inst1=NOOP
															select2 = 6'b010000; select1 = 6'b000000; end
			{`EX_MEM, `EX_MEM}	:	begin // inst2=MEM,  inst1=MEM
															select2 = 6'b100000; select1 = 6'b010000; end
			{`EX_MEM, `EX_MULT}	:	begin // inst2=MEM,  inst1=MULT
															select2 = 6'b010000; select1 = (MULT_free[0]) ? 6'b000100 : 6'b001000; end
			{`EX_MEM, `EX_ALU}	:	begin // inst2=MEM,  inst1=ALU
															select2 = 6'b010000; select1 = (ALU_free[0]) ? 6'b000001 : 6'b000010; end
			{`EX_MULT, `EX_NOOP}:	begin // inst2=MULT, inst1=NOOP
															select2 = (MULT_free[0]) ? 6'b000100 : 6'b001000; select1 = 6'b000000; end
			{`EX_MULT, `EX_MEM}	:	begin // inst2=MULT, inst1=MEM
															select2 = (MULT_free[0]) ? 6'b000100 : 6'b001000; select1 = 6'b010000; end
			{`EX_MULT, `EX_MULT}:	begin // inst2=MULT, inst1=MULT
															select2 = 6'b001000; select1 = 6'b000100; end
			{`EX_MULT, `EX_ALU}	:	begin // inst2=MULT, inst1=ALU
															select2 = (MULT_free[0]) ? 6'b000100 : 6'b001000; select1 = (ALU_free[0]) ? 6'b000001 : 6'b000010; end
			{`EX_ALU, `EX_NOOP}	:	begin // inst2=ALU,  inst1=NOOP
															select2 = (ALU_free[0]) ? 6'b000001 : 6'b000010; select1 = 6'b000000; end
			{`EX_ALU, `EX_MEM}	:	begin // inst2=ALU,  inst1=MEM
															select2 = (ALU_free[0]) ? 6'b000001 : 6'b000010; select1 = 6'b010000; end
			{`EX_ALU, `EX_MULT}	:	begin // inst2=ALU,  inst1=MULT
															select2 = (ALU_free[0]) ? 6'b000001 : 6'b000010; select1 = (MULT_free[0]) ? 6'b000100 : 6'b001000; end
			{`EX_ALU, `EX_ALU}	:	begin // inst2=ALU,  inst1=ALU
															select2 = 6'b000010; select1 = 6'b000001; end
		endcase
	end
	`else
	always @* begin
		case (inst_type)
			`EX_NOOP:	select1 = 3'b000; // inst1=NOOP
			`EX_MEM	:	select1 = 3'b100; // inst1=MEM
			`EX_MULT:	select1 = 3'b010; // inst1=MULT
			`EX_ALU	:	select1 = 3'b001; // inst1=ALU
		endcase
	end
	`endif

	// Map the incoming signals to the designated functional unit
	always @* begin
		ALU_prega_out = 0; ALU_pregb_out = 0; ALU_func_out = 0;
		ALU_pdest_idx_out = {`SCALAR{`ZERO_PRF}}; ALU_IR_out = {`SCALAR{`NOOP_INST}};
		ALU_npc_out = 0; ALU_rob_idx_out = 0; ALU_EX_en_out = 0;
		MULT_prega_out = 0; MULT_pregb_out = 0;
		MULT_pdest_idx_out = {`SCALAR{`ZERO_PRF}}; MULT_IR_out = {`SCALAR{`NOOP_INST}};
		MULT_npc_out = 0; MULT_rob_idx_out = 0; MULT_EX_en_out = 0;
		MEM_LSQ_idx_out = 0; MEM_prega_out = 0; MEM_pregb_out = 0; MEM_rd_out = 0; MEM_wr_out = 0;
		MEM_pdest_idx_out = {`SCALAR{`ZERO_PRF}}; MEM_IR_out = {`SCALAR{`NOOP_INST}};
		MEM_npc_out = 0; MEM_rob_idx_out = 0; MEM_EX_en_out = 0;

		`ifdef SUPERSCALAR
		case (select1)
			6'b100000	: begin
										MEM_LSQ_idx_out[`SEL(`LSQ_IDX,2)]		= LSQ_idx[`SEL(`LSQ_IDX,1)]; 
										MEM_prega_out[`SEL(64,2)]						= prega_value[`SEL(64,1)]; 
										MEM_pregb_out[`SEL(64,2)]						= pregb_value[`SEL(64,1)];
										MEM_rd_out[`SEL(1,2)]								= rd_mem[`SEL(1,1)];
										MEM_wr_out[`SEL(1,2)]								= wr_mem[`SEL(1,1)];
										MEM_pdest_idx_out[`SEL(`PRF_IDX,2)]	= pdest_idx[`SEL(`PRF_IDX,1)];
										MEM_IR_out[`SEL(32,2)]							= IR[`SEL(32,1)];
										MEM_npc_out[`SEL(64,2)]							= npc[`SEL(64,1)];
										MEM_rob_idx_out[`SEL(`ROB_IDX,2)]		= rob_idx[`SEL(`ROB_IDX,1)];
										MEM_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,1)];
									end
			6'b010000	: begin
										MEM_LSQ_idx_out[`SEL(`LSQ_IDX,1)]		= LSQ_idx[`SEL(`LSQ_IDX,1)]; 
										MEM_prega_out[`SEL(64,1)]						= prega_value[`SEL(64,1)]; 
										MEM_pregb_out[`SEL(64,1)]						= pregb_value[`SEL(64,1)];
										MEM_rd_out[`SEL(1,1)]								= rd_mem[`SEL(1,1)];
										MEM_wr_out[`SEL(1,1)]								= wr_mem[`SEL(1,1)];
										MEM_pdest_idx_out[`SEL(`PRF_IDX,1)]	= pdest_idx[`SEL(`PRF_IDX,1)];
										MEM_IR_out[`SEL(32,1)]							= IR[`SEL(32,1)];
										MEM_npc_out[`SEL(64,1)]							= npc[`SEL(64,1)];
										MEM_rob_idx_out[`SEL(`ROB_IDX,1)]		= rob_idx[`SEL(`ROB_IDX,1)];
										MEM_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,1)];
									end
			6'b001000	: begin
										MULT_prega_out[`SEL(64,2)]					= prega_value[`SEL(64,1)]; 
										MULT_pregb_out[`SEL(64,2)]					= pregb_value[`SEL(64,1)];
										MULT_pdest_idx_out[`SEL(`PRF_IDX,2)]= pdest_idx[`SEL(`PRF_IDX,1)];
										MULT_IR_out[`SEL(32,2)]							= IR[`SEL(32,1)];
										MULT_npc_out[`SEL(64,2)]						= npc[`SEL(64,1)];
										MULT_rob_idx_out[`SEL(`ROB_IDX,2)]	= rob_idx[`SEL(`ROB_IDX,1)];
										MULT_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,1)];
									end
			6'b000100	: begin
										MULT_prega_out[`SEL(64,1)]					= prega_value[`SEL(64,1)]; 
										MULT_pregb_out[`SEL(64,1)]					= pregb_value[`SEL(64,1)];
										MULT_pdest_idx_out[`SEL(`PRF_IDX,1)]= pdest_idx[`SEL(`PRF_IDX,1)];
										MULT_IR_out[`SEL(32,1)]							= IR[`SEL(32,1)];
										MULT_npc_out[`SEL(64,1)]						= npc[`SEL(64,1)];
										MULT_rob_idx_out[`SEL(`ROB_IDX,1)]	= rob_idx[`SEL(`ROB_IDX,1)];
										MULT_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,1)];
									end
			6'b000010	: begin
										ALU_prega_out[`SEL(64,2)]						= prega_value[`SEL(64,1)];
										ALU_pregb_out[`SEL(64,2)]						= pregb_value[`SEL(64,1)];
										ALU_func_out[`SEL(5,2)]							= ALUop[`SEL(5,1)]; 
										ALU_pdest_idx_out[`SEL(`PRF_IDX,2)]	= pdest_idx[`SEL(`PRF_IDX,1)];
										ALU_IR_out[`SEL(32,2)]							= IR[`SEL(32,1)];
										ALU_npc_out[`SEL(64,2)]							= npc[`SEL(64,1)];
										ALU_rob_idx_out[`SEL(`ROB_IDX,2)]		= rob_idx[`SEL(`ROB_IDX,1)];
										ALU_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,1)];
									end
			6'b000001	: begin
										ALU_prega_out[`SEL(64,1)]						= prega_value[`SEL(64,1)];
										ALU_pregb_out[`SEL(64,1)]						= pregb_value[`SEL(64,1)];
										ALU_func_out[`SEL(5,1)]							= ALUop[`SEL(5,1)]; 
										ALU_pdest_idx_out[`SEL(`PRF_IDX,1)]	= pdest_idx[`SEL(`PRF_IDX,1)];
										ALU_IR_out[`SEL(32,1)]							= IR[`SEL(32,1)];
										ALU_npc_out[`SEL(64,1)]							= npc[`SEL(64,1)];
										ALU_rob_idx_out[`SEL(`ROB_IDX,1)]		= rob_idx[`SEL(`ROB_IDX,1)];
										ALU_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,1)];
									end
		endcase

		if(select2 != select1) begin
			case (select2)
				6'b100000	: begin
											MEM_LSQ_idx_out[`SEL(`LSQ_IDX,2)]		= LSQ_idx[`SEL(`LSQ_IDX,2)]; 
											MEM_prega_out[`SEL(64,2)]						= prega_value[`SEL(64,2)]; 
											MEM_pregb_out[`SEL(64,2)]						= pregb_value[`SEL(64,2)];
											MEM_rd_out[`SEL(1,2)]								= rd_mem[`SEL(1,2)];
											MEM_wr_out[`SEL(1,2)]								= wr_mem[`SEL(1,2)];
											MEM_pdest_idx_out[`SEL(`PRF_IDX,2)]	= pdest_idx[`SEL(`PRF_IDX,2)];
											MEM_IR_out[`SEL(32,2)]							= IR[`SEL(32,2)];
											MEM_npc_out[`SEL(64,2)]							= npc[`SEL(64,2)];
											MEM_rob_idx_out[`SEL(`ROB_IDX,2)]		= rob_idx[`SEL(`ROB_IDX,2)];
											MEM_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,2)];
										end
				6'b010000	: begin
											MEM_LSQ_idx_out[`SEL(`LSQ_IDX,1)]		= LSQ_idx[`SEL(`LSQ_IDX,2)]; 
											MEM_prega_out[`SEL(64,1)]						= prega_value[`SEL(64,2)]; 
											MEM_pregb_out[`SEL(64,1)]						= pregb_value[`SEL(64,2)];
											MEM_rd_out[`SEL(1,1)]								= rd_mem[`SEL(1,2)];
											MEM_wr_out[`SEL(1,1)]								= wr_mem[`SEL(1,2)];
											MEM_pdest_idx_out[`SEL(`PRF_IDX,1)]	= pdest_idx[`SEL(`PRF_IDX,2)];
											MEM_IR_out[`SEL(32,1)]							= IR[`SEL(32,2)];
											MEM_npc_out[`SEL(64,1)]							= npc[`SEL(64,2)];
											MEM_rob_idx_out[`SEL(`ROB_IDX,1)]		= rob_idx[`SEL(`ROB_IDX,2)];
											MEM_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,2)];
										end
				6'b001000	: begin
											MULT_prega_out[`SEL(64,2)]					= prega_value[`SEL(64,2)]; 
											MULT_pregb_out[`SEL(64,2)]					= pregb_value[`SEL(64,2)];
											MULT_pdest_idx_out[`SEL(`PRF_IDX,2)]= pdest_idx[`SEL(`PRF_IDX,2)];
											MULT_IR_out[`SEL(32,2)]							= IR[`SEL(32,2)];
											MULT_npc_out[`SEL(64,2)]						= npc[`SEL(64,2)];
											MULT_rob_idx_out[`SEL(`ROB_IDX,2)]	= rob_idx[`SEL(`ROB_IDX,2)];
											MULT_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,2)];
										end
				6'b000100	: begin
											MULT_prega_out[`SEL(64,1)]					= prega_value[`SEL(64,2)]; 
											MULT_pregb_out[`SEL(64,1)]					= pregb_value[`SEL(64,2)];
											MULT_pdest_idx_out[`SEL(`PRF_IDX,1)]= pdest_idx[`SEL(`PRF_IDX,2)];
											MULT_IR_out[`SEL(32,1)]							= IR[`SEL(32,2)];
											MULT_npc_out[`SEL(64,1)]						= npc[`SEL(64,2)];
											MULT_rob_idx_out[`SEL(`ROB_IDX,1)]	= rob_idx[`SEL(`ROB_IDX,2)];
											MULT_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,2)];
										end
				6'b000010	: begin
											ALU_prega_out[`SEL(64,2)]						= prega_value[`SEL(64,2)];
											ALU_pregb_out[`SEL(64,2)]						= pregb_value[`SEL(64,2)];
											ALU_func_out[`SEL(5,2)]							= ALUop[`SEL(5,2)]; 
											ALU_pdest_idx_out[`SEL(`PRF_IDX,2)]	= pdest_idx[`SEL(`PRF_IDX,2)];
											ALU_IR_out[`SEL(32,2)]							= IR[`SEL(32,2)];
											ALU_npc_out[`SEL(64,2)]							= npc[`SEL(64,2)];
											ALU_rob_idx_out[`SEL(`ROB_IDX,2)]		= rob_idx[`SEL(`ROB_IDX,2)];
											ALU_EX_en_out[`SEL(1,2)]						= EX_en[`SEL(1,2)];
										end
				6'b000001	: begin
											ALU_prega_out[`SEL(64,1)]						= prega_value[`SEL(64,2)];
											ALU_pregb_out[`SEL(64,1)]						= pregb_value[`SEL(64,2)];
											ALU_func_out[`SEL(5,1)]							= ALUop[`SEL(5,2)]; 
											ALU_pdest_idx_out[`SEL(`PRF_IDX,1)]	= pdest_idx[`SEL(`PRF_IDX,2)];
											ALU_IR_out[`SEL(32,1)]							= IR[`SEL(32,2)];
											ALU_npc_out[`SEL(64,1)]							= npc[`SEL(64,2)];
											ALU_rob_idx_out[`SEL(`ROB_IDX,1)]		= rob_idx[`SEL(`ROB_IDX,2)];
											ALU_EX_en_out[`SEL(1,1)]						= EX_en[`SEL(1,2)];
										end
			endcase
		end	// if(select2 != select1)
		`else
		case (select1)
			3'b100	: begin
										MEM_LSQ_idx_out		= LSQ_idx; 
										MEM_prega_out			= prega_value; 
										MEM_pregb_out			= pregb_value;
										MEM_rd_out				= rd_mem;
										MEM_wr_out				= wr_mem;
										MEM_pdest_idx_out	= pdest_idx;
										MEM_IR_out				= IR;
										MEM_npc_out				= npc;
										MEM_rob_idx_out		= rob_idx;
										MEM_EX_en_out			= EX_en;
									end
			3'b010	: begin
										MULT_prega_out		= prega_value; 
										MULT_pregb_out		= pregb_value;
										MULT_pdest_idx_out= pdest_idx;
										MULT_IR_out				= IR;
										MULT_npc_out			= npc;
										MULT_rob_idx_out	= rob_idx;
										MULT_EX_en_out		= EX_en;
									end
			3'b001	: begin
										ALU_prega_out			= prega_value;
										ALU_pregb_out			= pregb_value;
										ALU_func_out			= ALUop; 
										ALU_pdest_idx_out	= pdest_idx;
										ALU_IR_out				= IR;
										ALU_npc_out				= npc;
										ALU_rob_idx_out		= rob_idx;
										ALU_EX_en_out			= EX_en;
									end
		endcase
		`endif
	end // always @* 

endmodule


module ex_co_stage(clk, reset,
									// Inputs
									LSQ_idx, pdest_idx, prega_value, pregb_value, 
									ALUop, rd_mem, wr_mem,
									IR, npc, rob_idx, EX_en,

									// Inputs (from LSQ)
									LSQ_rob_idx, LSQ_pdest_idx, LSQ_mem_value, LSQ_done, LSQ_rd_mem, LSQ_wr_mem,

									// Outputs
									cdb_tag, cdb_valid, cdb_value, cdb_MEM_result_valid, 	// to CDB
									cdb_rob_idx, cdb_BR_result, cdb_npc, cdb_IR,					// to CDB
									ALU_free, MULT_free, 																	// to RS

									// Outputs (to LSQ)
									EX_LSQ_idx, EX_MEM_ADDR, EX_MEM_reg_value,

									// Outputs (to PRF)
									ALU_result_out, ALU_pdest_idx_out, ALU_done_reg,
									MULT_result_out, MULT_pdest_idx_out, MULT_done_reg,
									MEM_result_out, MEM_pdest_idx_out, MEM_result_valid_out
               );

  input clk;  
  input reset;

// Inputs from the input pipeline registers (IS/EX)
	input [`LSQ_IDX*`SCALAR-1:0]	LSQ_idx;
	input	[`PRF_IDX*`SCALAR-1:0]	pdest_idx;
	input	[64*`SCALAR-1:0] 				prega_value, pregb_value;
	input	[5*`SCALAR-1:0] 				ALUop;
	input	[`SCALAR-1:0] 					rd_mem, wr_mem;
	input	[32*`SCALAR-1:0] 				IR;
	input	[64*`SCALAR-1:0] 				npc;
	input	[`ROB_IDX*`SCALAR-1:0] 	rob_idx;
	input	[`SCALAR-1:0] 					EX_en;
// END OF Inputs from the input pipeline registers (RS/EX)

// Inputs from the LSQ
	input [`ROB_IDX*`SCALAR-1:0]	LSQ_rob_idx;
	input [`PRF_IDX*`SCALAR-1:0]	LSQ_pdest_idx;
	input [64*`SCALAR-1:0]				LSQ_mem_value;
	input [`SCALAR-1:0]						LSQ_done;
	input [`SCALAR-1:0]						LSQ_rd_mem, LSQ_wr_mem;
// END OF Inputs from the LSQ

// Outputs to the LSQ
	output [`LSQ_IDX*`SCALAR-1:0]	EX_LSQ_idx;
	output [64*`SCALAR-1:0]				EX_MEM_ADDR;
	output [64*`SCALAR-1:0]				EX_MEM_reg_value;
// END OF Outputs to the LSQ

// Outputs to the CDB Interface 
	output [`PRF_IDX*`SCALAR-1:0]	cdb_tag;
	output [`SCALAR-1:0] 					cdb_valid, cdb_MEM_result_valid, cdb_BR_result;
	output [64*`SCALAR-1:0] 			cdb_value;
	output [`ROB_IDX*`SCALAR-1:0]	cdb_rob_idx;
	output [64*`SCALAR-1:0]				cdb_npc;
	output [32*`SCALAR-1:0]				cdb_IR;
// END OF Outputs to the Output Logic

// Outputs to PRF
	output [`SCALAR-1:0]					ALU_done_reg, MULT_done_reg, MEM_result_valid_out;
	output [64*`SCALAR-1:0]				ALU_result_out, MULT_result_out, MEM_result_out;
	output [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_out, MULT_pdest_idx_out, MEM_pdest_idx_out;
// END OF Outputs to PRF

	output 	[`SCALAR-1:0]					ALU_free, MULT_free;
	wire 		[`SCALAR-1:0]					ALU_stall, MULT_stall;

// Inputs to the functional units
	wire [64*`SCALAR-1:0]				ALU_prega_in, ALU_pregb_in, MULT_prega_in, MULT_pregb_in, MEM_prega_in, MEM_pregb_in;
	wire [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_in, MULT_pdest_idx_in, MEM_pdest_idx_in;
	wire [32*`SCALAR-1:0]				ALU_IR_in, MULT_IR_in, MEM_IR_in;
	wire [64*`SCALAR-1:0]				ALU_npc_in, MULT_npc_in, MEM_npc_in;
	wire [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_in, MULT_rob_idx_in, MEM_rob_idx_in;
	wire [`SCALAR-1:0]					ALU_EX_en_in, MULT_EX_en_in, MEM_EX_en_in;
	wire [5*`SCALAR-1:0]				ALU_func_in;
	wire [`LSQ_IDX*`SCALAR-1:0]	MEM_LSQ_idx_in;
	wire [`SCALAR-1:0]					MEM_rd_in, MEM_wr_in;
// END OF Inputs to the functional units
	
// Wires EX_ps
	wire 		[`SCALAR-1:0]					ALU_done, ALU_done_reg, ALU_gnt_reg, ALU_next_gnt;
	wire 		[`SCALAR-1:0]					MULT_done, MULT_done_reg, MULT_gnt_reg, MULT_next_gnt;
	wire 		[`SCALAR-1:0]					MEM_done, MEM_done_reg, MEM_gnt_reg, MEM_next_gnt;
// END OF Wires for EX_ps

// Outputs from the functional units (from EX/CO registers)
	wire [64*`SCALAR-1:0]				ALU_result_out, MULT_result_out, MEM_result_out;
	wire [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_out, MULT_pdest_idx_out, MEM_pdest_idx_out;
	wire [32*`SCALAR-1:0]				ALU_IR_out, MULT_IR_out, MEM_IR_out;
	wire [64*`SCALAR-1:0]				ALU_npc_out, MULT_npc_out, MEM_npc_out;
	wire [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_out, MULT_rob_idx_out, MEM_rob_idx_out;
	wire [`SCALAR-1:0] 					ALU_BR_result_out;
	wire [`SCALAR-1:0] 					MEM_result_valid_out;
// END OF Outputs from the functional units (from EX/CO registers)

	EX_input_logic EX_input_logic0 (.clk(clk), .reset(reset), 
																	//Inputs
																	.ALU_free_in(ALU_free), .MULT_free_in(MULT_free), 
																	.LSQ_idx(LSQ_idx), .pdest_idx(pdest_idx), 
																	.prega_value(prega_value), .pregb_value(pregb_value), 
																	.ALUop(ALUop),  
																	.rd_mem(rd_mem), .wr_mem(wr_mem), 
																	.IR(IR), .npc(npc), 
																	.rob_idx(rob_idx), .EX_en(EX_en), 
																	// to ALUs
																	.ALU_prega_out(ALU_prega_in), .ALU_pregb_out(ALU_pregb_in), .ALU_func_out(ALU_func_in),  
																	.ALU_pdest_idx_out(ALU_pdest_idx_in), .ALU_IR_out(ALU_IR_in), 
																	.ALU_npc_out(ALU_npc_in), .ALU_rob_idx_out(ALU_rob_idx_in), 
																	.ALU_EX_en_out(ALU_EX_en_in), 
																	// to MULTs
																	.MULT_prega_out(MULT_prega_in), .MULT_pregb_out(MULT_pregb_in),  
																	.MULT_pdest_idx_out(MULT_pdest_idx_in), .MULT_IR_out(MULT_IR_in), 
																	.MULT_npc_out(MULT_npc_in), .MULT_rob_idx_out(MULT_rob_idx_in), 
																	.MULT_EX_en_out(MULT_EX_en_in),
																	// to MEM_CONTs
																	.MEM_LSQ_idx_out(MEM_LSQ_idx_in), .MEM_prega_out(MEM_prega_in), .MEM_pregb_out(MEM_pregb_in),  
																	.MEM_rd_out(MEM_rd_in), .MEM_wr_out(MEM_wr_in), 
																	.MEM_pdest_idx_out(MEM_pdest_idx_in), .MEM_IR_out(MEM_IR_in), 
																	.MEM_npc_out(MEM_npc_in), .MEM_rob_idx_out(MEM_rob_idx_in), 
																	.MEM_EX_en_out(MEM_EX_en_in)
																);

// Functional units
	ALU ALU1	(.clk(clk), .reset(reset),
						// Inputs
						.prega_in(ALU_prega_in[`SEL(64,1)]), .pregb_in(ALU_pregb_in[`SEL(64,1)]), .ALUop(ALU_func_in[`SEL(5,1)]), 
						.pdest_idx_in(ALU_pdest_idx_in[`SEL(`PRF_IDX,1)]), .IR_in(ALU_IR_in[`SEL(32,1)]), 
						.npc_in(ALU_npc_in[`SEL(64,1)]), .rob_idx_in(ALU_rob_idx_in[`SEL(`ROB_IDX,1)]), 
						.EX_en_in(ALU_EX_en_in[`SEL(1,1)]), 
						.next_gnt(ALU_next_gnt[`SEL(1,1)]), .stall(ALU_stall[`SEL(1,1)]),
						// Outputs
						.result_reg(ALU_result_out[`SEL(64,1)]), .BR_result_reg(ALU_BR_result_out[`SEL(1,1)]), 
						.pdest_idx_reg(ALU_pdest_idx_out[`SEL(`PRF_IDX,1)]), .IR_reg(ALU_IR_out[`SEL(32,1)]), 
						.npc_reg(ALU_npc_out[`SEL(64,1)]), .rob_idx_reg(ALU_rob_idx_out[`SEL(`ROB_IDX,1)]),
						.done(ALU_done[`SEL(1,1)]), .done_reg(ALU_done_reg[`SEL(1,1)]), .gnt_reg(ALU_gnt_reg[`SEL(1,1)])
						);


	MULT	MULT1	(.clk(clk), .reset(reset), 
							// Inputs
							.prega_value(MULT_prega_in[`SEL(64,1)]), .pregb_value(MULT_pregb_in[`SEL(64,1)]), 
							.pdest_idx_in(MULT_pdest_idx_in[`SEL(`PRF_IDX,1)]), .IR_in(MULT_IR_in[`SEL(32,1)]), 
							.npc_in(MULT_npc_in[`SEL(64,1)]), .rob_idx_in(MULT_rob_idx_in[`SEL(`ROB_IDX,1)]), 
							.EX_en_in(MULT_EX_en_in[`SEL(1,1)]),
							.next_gnt(MULT_next_gnt[`SEL(1,1)]), .stall(MULT_stall[`SEL(1,1)]),
							// Outputs
							.result_reg(MULT_result_out[`SEL(64,1)]), 
							.pdest_idx_reg(MULT_pdest_idx_out[`SEL(`PRF_IDX,1)]), .IR_reg(MULT_IR_out[`SEL(32,1)]), 
							.npc_reg(MULT_npc_out[`SEL(64,1)]), .rob_idx_reg(MULT_rob_idx_out[`SEL(`ROB_IDX,1)]),
							.done(MULT_done[`SEL(1,1)]), .done_reg(MULT_done_reg[`SEL(1,1)]), .gnt_reg(MULT_gnt_reg[`SEL(1,1)])
						);

	MEM_CONT MEM_CONT1	( .clk(clk), .reset(reset),
												//Inputs from the Input Logic 
												.LSQ_idx(MEM_LSQ_idx_in[`SEL(`LSQ_IDX,1)]), 
												.prega_in(MEM_prega_in[`SEL(64,1)]), .pregb_in(MEM_pregb_in[`SEL(64,1)]), 
												.rd_in(MEM_rd_in[`SEL(1,1)]), .wr_in(MEM_wr_in[`SEL(1,1)]), 
												.pdest_idx_in(MEM_pdest_idx_in[`SEL(`PRF_IDX,1)]), .IR_in(MEM_IR_in[`SEL(32,1)]), 
												.npc_in(MEM_npc_in[`SEL(64,1)]), .rob_idx_in(MEM_rob_idx_in[`SEL(`ROB_IDX,1)]), 
												.EX_en_in(MEM_EX_en_in[`SEL(1,1)]), .next_gnt(MEM_next_gnt[`SEL(1,1)]),
								 				//Inputs from LSQ
								 				.LSQ_rob_idx(LSQ_rob_idx[`SEL(`ROB_IDX,1)]), 
												.LSQ_pdest_idx(LSQ_pdest_idx[`SEL(`PRF_IDX,1)]), .LSQ_mem_value(LSQ_mem_value[`SEL(64,1)]), 
												.LSQ_done(LSQ_done[`SEL(1,1)]), .LSQ_rd_mem(LSQ_rd_mem[`SEL(1,1)]), .LSQ_wr_mem(LSQ_wr_mem[`SEL(1,1)]),
								 				//Outputs to LSQ
								 				.MEM_LSQ_idx(EX_LSQ_idx[`SEL(`LSQ_IDX,1)]), .MEM_ADDR(EX_MEM_ADDR[`SEL(64,1)]), .MEM_reg_value(EX_MEM_reg_value[`SEL(64,1)]), 
								 				//Outputs to EX/CO registers
								 				.result_reg(MEM_result_out[`SEL(64,1)]), .result_valid_reg(MEM_result_valid_out[`SEL(1,1)]), 
												.pdest_idx_reg(MEM_pdest_idx_out[`SEL(`PRF_IDX,1)]), .IR_reg(MEM_IR_out[`SEL(32,1)]), 
												.npc_reg(MEM_npc_out[`SEL(64,1)]), .rob_idx_reg(MEM_rob_idx_out[`SEL(`ROB_IDX,1)]),
												.done(MEM_done[`SEL(1,1)]), .done_reg(MEM_done_reg[`SEL(1,1)]), .gnt_reg(MEM_gnt_reg[`SEL(1,1)])
												);

`ifdef SUPERSCALAR
	ALU ALU2	(.clk(clk), .reset(reset),
						// Inputs
						.prega_in(ALU_prega_in[`SEL(64,2)]), .pregb_in(ALU_pregb_in[`SEL(64,2)]), .ALUop(ALU_func_in[`SEL(5,2)]), 
						.pdest_idx_in(ALU_pdest_idx_in[`SEL(`PRF_IDX,2)]), .IR_in(ALU_IR_in[`SEL(32,2)]), 
						.npc_in(ALU_npc_in[`SEL(64,2)]), .rob_idx_in(ALU_rob_idx_in[`SEL(`ROB_IDX,2)]), 
						.EX_en_in(ALU_EX_en_in[`SEL(1,2)]), 
						.next_gnt(ALU_next_gnt[`SEL(1,2)]), .stall(ALU_stall[`SEL(1,2)]),
						// Outputs
						.result_reg(ALU_result_out[`SEL(64,2)]), .BR_result_reg(ALU_BR_result_out[`SEL(1,2)]), 
						.pdest_idx_reg(ALU_pdest_idx_out[`SEL(`PRF_IDX,2)]), .IR_reg(ALU_IR_out[`SEL(32,2)]), 
						.npc_reg(ALU_npc_out[`SEL(64,2)]), .rob_idx_reg(ALU_rob_idx_out[`SEL(`ROB_IDX,2)]),
						.done(ALU_done[`SEL(1,2)]), .done_reg(ALU_done_reg[`SEL(1,2)]), .gnt_reg(ALU_gnt_reg[`SEL(1,2)])
						);


	MULT	MULT2	(.clk(clk), .reset(reset), 
							// Inputs
							.prega_value(MULT_prega_in[`SEL(64,2)]), .pregb_value(MULT_pregb_in[`SEL(64,2)]), 
							.pdest_idx_in(MULT_pdest_idx_in[`SEL(`PRF_IDX,2)]), .IR_in(MULT_IR_in[`SEL(32,2)]), 
							.npc_in(MULT_npc_in[`SEL(64,2)]), .rob_idx_in(MULT_rob_idx_in[`SEL(`ROB_IDX,2)]), 
							.EX_en_in(MULT_EX_en_in[`SEL(1,2)]),
							.next_gnt(MULT_next_gnt[`SEL(1,2)]), .stall(MULT_stall[`SEL(1,2)]),
							// Outputs
							.result_reg(MULT_result_out[`SEL(64,2)]), 
							.pdest_idx_reg(MULT_pdest_idx_out[`SEL(`PRF_IDX,2)]), .IR_reg(MULT_IR_out[`SEL(32,2)]), 
							.npc_reg(MULT_npc_out[`SEL(64,2)]), .rob_idx_reg(MULT_rob_idx_out[`SEL(`ROB_IDX,2)]),
							.done(MULT_done[`SEL(1,2)]), .done_reg(MULT_done_reg[`SEL(1,2)]), .gnt_reg(MULT_gnt_reg[`SEL(1,2)])
						);

	MEM_CONT MEM_CONT2	( .clk(clk), .reset(reset),
												//Inputs from the Input Logic 
												.LSQ_idx(MEM_LSQ_idx_in[`SEL(`LSQ_IDX,2)]), 
												.prega_in(MEM_prega_in[`SEL(64,2)]), .pregb_in(MEM_pregb_in[`SEL(64,2)]), 
												.rd_in(MEM_rd_in[`SEL(1,2)]), .wr_in(MEM_wr_in[`SEL(1,2)]), 
												.pdest_idx_in(MEM_pdest_idx_in[`SEL(`PRF_IDX,2)]), .IR_in(MEM_IR_in[`SEL(32,2)]), 
												.npc_in(MEM_npc_in[`SEL(64,2)]), .rob_idx_in(MEM_rob_idx_in[`SEL(`ROB_IDX,2)]), 
												.EX_en_in(MEM_EX_en_in[`SEL(1,2)]), .next_gnt(MEM_next_gnt[`SEL(1,2)]),
								 				//Inputs from LSQ
								 				.LSQ_rob_idx(LSQ_rob_idx[`SEL(`ROB_IDX,2)]), 
												.LSQ_pdest_idx(LSQ_pdest_idx[`SEL(`PRF_IDX,2)]), .LSQ_mem_value(LSQ_mem_value[`SEL(64,2)]), 
												.LSQ_done(LSQ_done[`SEL(1,2)]), .LSQ_rd_mem(LSQ_rd_mem[`SEL(1,2)]), .LSQ_wr_mem(LSQ_wr_mem[`SEL(1,2)]),
								 				//Outputs to LSQ
								 				.MEM_LSQ_idx(EX_LSQ_idx[`SEL(`LSQ_IDX,2)]), .MEM_ADDR(EX_MEM_ADDR[`SEL(64,2)]), .MEM_reg_value(EX_MEM_reg_value[`SEL(64,2)]), 
								 				//Outputs to EX/CO registers
								 				.result_reg(MEM_result_out[`SEL(64,2)]), .result_valid_reg(MEM_result_valid_out[`SEL(1,2)]), 
												.pdest_idx_reg(MEM_pdest_idx_out[`SEL(`PRF_IDX,2)]), .IR_reg(MEM_IR_out[`SEL(32,2)]), 
												.npc_reg(MEM_npc_out[`SEL(64,2)]), .rob_idx_reg(MEM_rob_idx_out[`SEL(`ROB_IDX,2)]),
												.done(MEM_done[`SEL(1,2)]), .done_reg(MEM_done_reg[`SEL(1,2)]), .gnt_reg(MEM_gnt_reg[`SEL(1,2)])
												);
`endif
// END OF Functional units

	EX_ps EX_ps0 (// Inputs
								.ALU_done(ALU_done), .MULT_done(MULT_done), .MEM_done(MEM_done), 
								.ALU_done_reg(ALU_done_reg), .MULT_done_reg(MULT_done_reg), .MEM_done_reg(MEM_done_reg),
								.ALU_gnt_reg(ALU_gnt_reg), .MULT_gnt_reg(MULT_gnt_reg), .MEM_gnt_reg(MEM_gnt_reg),
								// Outputs
								.ALU_next_gnt_reg(ALU_next_gnt), .MULT_next_gnt_reg(MULT_next_gnt), .MEM_next_gnt_reg(MEM_next_gnt),
								.ALU_stall(ALU_stall), .MULT_stall(MULT_stall), 
								.ALU_free(ALU_free), .MULT_free(MULT_free)
								);

// EX-CO Interface
	EX_CO_Mux	EX_CO_Mux0 (	//Inputs
													.ALU_result(ALU_result_out), .ALU_BR_result(ALU_BR_result_out), 
													.ALU_pdest_idx(ALU_pdest_idx_out), .ALU_IR(ALU_IR_out), 
													.ALU_npc(ALU_npc_out), .ALU_rob_idx(ALU_rob_idx_out), 
													.ALU_gnt(ALU_gnt_reg),	
													.MULT_result(MULT_result_out), 
													.MULT_pdest_idx(MULT_pdest_idx_out), .MULT_IR(MULT_IR_out), 
													.MULT_npc(MULT_npc_out), .MULT_rob_idx(MULT_rob_idx_out), 
													.MULT_gnt(MULT_gnt_reg),
													.MEM_result(MEM_result_out), .MEM_result_valid(MEM_result_valid_out), 
													.MEM_pdest_idx(MEM_pdest_idx_out), .MEM_IR(MEM_IR_out), 
													.MEM_npc(MEM_npc_out), .MEM_rob_idx(MEM_rob_idx_out), 
													.MEM_gnt(MEM_gnt_reg),
													// Outputs
													.cdb_tag(cdb_tag), 
													.cdb_valid(cdb_valid), 
													.cdb_value(cdb_value), 
													.cdb_MEM_result_valid(cdb_MEM_result_valid), 
													.cdb_rob_idx(cdb_rob_idx), 
													.cdb_BR_result(cdb_BR_result),
													.cdb_npc(cdb_npc), 
													.cdb_IR(cdb_IR) 
													);

endmodule // module ex_stage

