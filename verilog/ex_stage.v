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
module MEM_CONT (//Inputs from the Input Logic 
									LSQ_idx, rega_in, regb_in, disp_in, rd_in, wr_in, 
									pdest_idx_in, rs_IR_in, npc_in, rob_idx_in, EX_en_in,
								 //Inputs from LSQ
								 	LSQ_free, LSQ_rob_idx, LSQ_pdest_idx, LSQ_mem_value, 
									LSQ_done, LSQ_rd_mem, LSQ_wr_mem,
								 //Outputs to LSQ
								 	MEM_ADDR, MEM_rob_idx, MEM_pdest_idx, MEM_reg_value, 
									MEM_rd_mem, MEM_wr_mem,
								 //Outputs to EX/CDB registers
								 	MEM_valid_value, MEM_done, MEM_value, MEM_pdest_idx_out, 
									MEM_rob_idx_out, MEM_LSQ_free
									);
	// Inputs from the input logic in EX stage
	input [`LSQ_IDX-1:0]	
	input [63:0]					rega_in;
	input [63:0]					regb_in;
	input [63:0]					disp_in;
	input 								rd_in;
	input 								wr_in;
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0]					rs_IR_in;
	input [63:0]					npc_in;
	input [`ROB_IDX-1:0]	rob_idx_in;
	input 								EX_en_in;
	// Inputs from LSQ
	input									LSQ_free;
	input [`ROB_IDX-1:0]	LSQ_rob_idx;
	input [`PRF_IDX-1:0]	LSQ_pdest_idx;
	input [63:0]					LSQ_mem_value;
	input 								LSQ_done;
	input									LSQ_rd_mem;
	input									LSQ_wr_mem;
	// Outputs to LSQ
	output [63:0]					MEM_ADDR;
	output [`ROB_IDX-1:0]	MEM_rob_idx;
	output [`PRF_IDX-1:0]	MEM_pdest_idx;
	output [63:0]					MEM_reg_value;
	output								MEM_rd_mem;
	output								MEM_wr_mem;
	// Outputs to EX/CDB registers
	output								MEM_valid_value;
	output								MEM_done;
	output [63:0]					MEM_value;
	output [`PRF_IDX-1:0]	MEM_pdest_idx_out;
	output [`ROB_IDX-1:0]	MEM_rob_idx_out;
	output 								MEM_LSQ_free;

endmodule // MEM_CONT

// Multipliers
module MULT(clk, reset, mplier, mcand, start, product, done
						pdest_idx_in, rs_IR_in, npc_in, rob_idx_in, EX_en_in,
						pdest_idx_out, rs_IR_out, npc_out, rob_idx_out, EX_en_out
						);

  input clk, reset, start;
  input [63:0] mcand, mplier;
	
	input [`PRF_IDX-1:0] pdest_idx_in;
	input [31:0] rs_IR_in;
	input [63:0] npc_in;
	input [`ROB_IDX-1:0] rob_idx_in;
	input EX_en_in;

  output [63:0] product;
  output done;

	output reg [`PRF_IDX-1:0] pdest_idx_out;
	output reg [31:0] rs_IR_out;
	output reg [63:0] npc_out;
	output reg [`ROB_IDX-1:0] rob_idx_out;
	output reg EX_en_out;

  wire [63:0] mcand_out, mplier_out;
  wire [(7*64)-1:0] internal_products, internal_mcands, internal_mpliers;
	wire [(7*`PRF_IDX)-1:0] internal_pdest_idx;
	wire [(7*32)-1:0] internal_rs_IR;
  wire [(7*64)-1:0] internal_npc;
	wire [(7*`ROB_IDX)-1:0] internal_rob_idx;
	wire [6:0] internal_EX_en;
  wire [6:0] internal_dones;
  
  mult_stage mstage [7:0] 
    (.clk(clk),
     .reset(reset),
     .product_in({internal_products,64'h0}),
     .mplier_in({internal_mpliers,mplier}),
     .mcand_in({internal_mcands,mcand}),
     .start({internal_dones,start}),
     .product_out({product,internal_products}),
     .mplier_out({mplier_out,internal_mpliers}),
     .mcand_out({mcand_out,internal_mcands}),
     .done({done,internal_dones}),
		 .pdest_idx_in({internal_pdest_idx, pdest_idx_in}),
		 .rs_IR_in({internal_rs_IR, rs_IR_in}),
		 .npc_in({internal_npc, npc_in}),
		 .rob_idx_in({internal_rob_idx, rob_idx_in}),
		 .EX_en_in({internal_EX_en, EX_en_in}),
		 .pdest_idx_out({pdest_idx_out, internal_pdest_idx}),
		 .rs_IR_out({rs_IR_out, internal_rs_IR}),
		 .npc_out({npc_out, internal_npc}),
		 .rob_idx_out({rob_idx_out, internal_rob_idx}),
		 .EX_en_out({EX_en_out, internal_EX_en})
    );

endmodule // MULT

module mult_stage(clk, reset, stall, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done,
									pdest_idx_in, rs_IR_in, npc_in, rob_idx_in, EX_en_in,
									pdest_idx_out, rs_IR_out, npc_out, rob_idx_out, EX_en_out
									);

  input clk, reset, stall, start;
  input [63:0] product_in, mplier_in, mcand_in;

	input [`PRF_IDX-1:0] pdest_idx_in;
	input [31:0] rs_IR_in;
	input [63:0] npc_in;
	input [`ROB_IDX-1:0] rob_idx_in;
	input EX_en_in;

  output done;
  output [63:0] product_out, mplier_out, mcand_out;
	
	output reg [`PRF_IDX-1:0] pdest_idx_out;
	output reg [31:0] rs_IR_out;
	output reg [63:0] npc_out;
	output reg [`ROB_IDX-1:0] rob_idx_out;
	output reg EX_en_out;

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
	    prod_in_reg      	<= `SD 64'b0;
  	  partial_prod_reg 	<= `SD 64'b0;
    	mplier_out       	<= `SD 64'b0;
    	mcand_out        	<= `SD 64'b0;
			pdest_idx_out			<= `SD {`PRF_IDX{1'b0}};
			rs_IR_out					<= `SD 32'b0;
			npc_out						<= `SD 64'b0;
			rob_idx_out				<= `SD {`ROB_IDX{1'b0}};
			EX_en_out					<= `SD 1'b0;
		end
		else if(stall) begin	
	    prod_in_reg      	<= `SD prod_in_reg;
  	  partial_prod_reg 	<= `SD partial_prod_reg;
    	mplier_out       	<= `SD mplier_out;
    	mcand_out        	<= `SD mcand_out;
			pdest_idx_out			<= `SD pdest_idx_out;
			rs_IR_out					<= `SD rs_IR_out;
			npc_out						<= `SD npc_out;
			rob_idx_out				<= `SD rob_idx_out;
			EX_en_out					<= `SD EX_en_out;
		end
		else begin
   		prod_in_reg      	<= `SD product_in;
    	partial_prod_reg 	<= `SD partial_product;
    	mplier_out       	<= `SD next_mplier;
    	mcand_out        	<= `SD next_mcand;
			pdest_idx_out			<= `SD pdest_idx_in;
			rs_IR_out					<= `SD rs_IR_in;
			npc_out						<= `SD npc_in;
			rob_idx_out				<= `SD rob_idx_in;
			EX_en_out					<= `SD EX_en_in;
		end
  end

  always @(posedge clk)
  begin
    if(reset)	done <= `SD 1'b0;
    else if(stall) done <= `SD done;
    else done <= `SD start;
  end

endmodule // mult_stage

//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
module ALU (//Inputs
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
    
    if (a[63] == b[63]) 
      signed_lt = (a < b); // signs match: signed compare same as unsigned
    else
      signed_lt = a[63];   // signs differ: a is smaller if neg, larger if pos
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
      `ALU_SRA:    result = (opa >> opb[5:0]) | ({64{opa[63]}} << (64 -
                             opb[5:0])); // arithmetic from logical shift
      `ALU_MULQ:   result = opa * opb;   //TO BE REPLACED
      `ALU_CMPULT: result = { 63'd0, (opa < opb) };
      `ALU_CMPEQ:  result = { 63'd0, (opa == opb) };
      `ALU_CMPULE: result = { 63'd0, (opa <= opb) };
      `ALU_CMPLT:  result = { 63'd0, signed_lt(opa, opb) };
      `ALU_CMPLE:  result = { 63'd0, (signed_lt(opa, opb) || (opa == opb)) };
      default:     result = 64'hdeadbeefbaadbeef; // here only to force
                                                  // a combinational solution
                                                  // a casex would be better
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


// EX-CDB Interface
module EX_CDB_Interface (//Inputs
												ALU_result, BRcond_result, ALU_pdest_idx, ALU_rs_IR, ALU_npc, ALU_rob_idx, ALU_EX_en,	
												MULT_product, MULT_done, MULT_pdest_idx, MULT_rs_IR, MULT_npc, MULT_rob_idx, MULT_EX_en,
												MEM_valid_value, MEM_done, MEM_value, MEM_pdest_idx, MEM_rs_IR, MEM_npc, MEM_rob_idx, MEM_EX_en, MEM_LSQ_free,
												//Outputs
												cdb_tag_out, cdb_valid_out, cdb_value_out, 
												rob_idx_out, branch_NT_out, 
												ALU_free, MULT_free, MEM_free,
												ALU_stall, MULT_stall, 
												rs_IR_out, npc_out
												);
	input [64*`SCALAR-1:0]				ALU_result;
	input [`SCALAR-1:0] 					BRcond_result;
	input [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx;
	input [32*`SCALAR-1:0]				ALU_rs_IR;
	input [64*`SCALAR-1:0]				ALU_npc;
	input [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx;
	input [`SCALAR-1:0]						ALU_EX_en;
	input [64*`SCALAR-1:0]				MULT_product;
	input [`SCALAR-1:0]						MULT_done;
	input [`PRF_IDX*`SCALAR-1:0]	MULT_pdest_idx;
	input [32*`SCALAR-1:0]				MULT_rs_IR;
	input [64*`SCALAR-1:0]				MULT_npc;
	input [`ROB_IDX*`SCALAR-1:0]	MULT_rob_idx;
	input [`SCALAR-1:0]						MULT_EX_en;
	input [`SCALAR-1:0]						MEM_valid_value;
	input [`SCALAR-1:0]						MEM_done;
	input [64*`SCALAR-1:0]				MEM_value;
	input [`PRF_IDX*`SCALAR-1:0]	MEM_pdest_idx;
	input [32*`SCALAR-1:0]				MEM_rs_IR;
	input [64*`SCALAR-1:0]				MEM_npc;
	input [`ROB_IDX*`SCALAR-1:0]	MEM_rob_idx;
	input [`SCALAR-1:0]						MEM_EX_en;
	input [`SCALAR-1:0]						MEM_LSQ_free;


	output [`PRF_IDX*`SCALAR-1:0] cdb_tag_out;
	output [`SCALAR-1:0] 					cdb_valid_out;
	output [64*`SCALAR-1:0] 			cdb_value_out;
	output [`ROB_IDX*`SCALAR-1:0] rob_idx_out;
	output [`SCALAR-1:0] 					branch_NT_out;
	output [`SCALAR-1:0] 					ALU_free;
	output [`SCALAR-1:0] 					MULT_free;
	output [`SCALAR-1:0]					MEM_free;
	output [`SCALAR-1:0]					ALU_stall;
	output [`SCALAR-1:0]					MULT_stall;
	output [32*`SCALAR-1:0] 			rs_IR_out;
	output [64*`SCALAR-1:0] 			npc_out;




endmodule

module EX_input_logic (//Inputs
												pdest_idx, prega_value, pregb_value, ALUop, 
												rd_mem, wr_mem, rs_IR, npc, rob_idx, EX_en,
											 //Outputs
											 	ALU_opa_out, ALU_opb_out, ALU_func_out, BRcond_opa_out, BRcond_func_out, 
												ALU_pdest_idx_out, ALU_rs_IR_out, ALU_npc_out, ALU_rob_idx_out, ALU_EX_en_out,
											 	MULT_mplier_out, MULT_mcand_out, MULT_start_out,
												MULT_pdest_idx_out, MULT_rs_IR_out, MULT_npc_out, MULT_rob_idx_out, MULT_EX_en_out,
												MEM_rega_out, MEM_regb_out, MEM_disp_out, MEM_rd_out, MEM_wr_out,
												MEM_pdest_idx_out, MEM_rs_IR_out, MEM_npc_out, MEM_rob_idx_out, MEM_EX_en_out
											);

	input	[`PRF_IDX*`SCALAR-1:0] pdest_idx;
	input	[64*`SCALAR-1:0] prega_value;
	input	[64*`SCALAR-1:0] pregb_value;
	input	[5*`SCALAR-1:0] ALUop;
	input	[`SCALAR-1:0] rd_mem;
	input	[`SCALAR-1:0] wr_mem;
	input	[32*`SCALAR-1:0] rs_IR;
	input	[64*`SCALAR-1:0] npc;
	input	[`ROB_IDX*`SCALAR-1:0] rob_idx;
	input	[`SCALAR-1:0] EX_en;

	output [64*`SCALAR-1:0]				ALU_opa_out;
	output [64*`SCALAR-1:0]				ALU_opb_out;
	output [5*`SCALAR-1:0]				ALU_func_out;
	output [64*`SCALAR-1:0]				BRcond_opa_out;
	output [3*`SCALAR-1:0]				BRcond_func_out;
	output [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_out;
	output [32*`SCALAR-1:0]				ALU_rs_IR_out;
	output [64*`SCALAR-1:0]				ALU_npc_out;
	output [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_out;
	output [`SCALAR-1:0]					ALU_EX_en_out;
	output [64*`SCALAR-1:0]				MULT_mplier_out;
	output [64*`SCALAR-1:0]				MULT_mcand_out;
	output [`SCALAR-1:0]					MULT_start_out;
	output [`PRF_IDX*`SCALAR-1:0]	MULT_pdest_idx_out;
	output [32*`SCALAR-1:0]				MULT_rs_IR_out;
	output [64*`SCALAR-1:0]				MULT_npc_out;
	output [`ROB_IDX*`SCALAR-1:0]	MULT_rob_idx_out;
	output [`SCALAR-1:0]					MULT_EX_en_out;
	output [64*`SCALAR-1:0]				MEM_rega_out;
	output [64*`SCALAR-1:0]				MEM_regb_out;
	output [64*`SCALAR-1:0]				MEM_disp_out;
	output [`SCALAR-1:0]					MEM_rd_out;
	output [`SCALAR-1:0]					MEM_wr_out;
	output [`PRF_IDX*`SCALAR-1:0]	MEM_pdest_idx_out;
	output [32*`SCALAR-1:0]				MEM_rs_IR_out;
	output [64*`SCALAR-1:0]				MEM_npc_out;
	output [`ROB_IDX*`SCALAR-1:0]	MEM_rob_idx_out;
	output [`SCALAR-1:0]					MEM_EX_en_out;

// Outputs from the small decoder for ALU
	reg [2*`SCALAR-1:0] ALU_opa_select;
	reg [2*`SCALAR-1:0] ALU_opb_select;
	reg [64*`SCALAR-1:0] ALU_opa;
	reg [64*`SCALAR-1:0] ALU_opb;
	wire [64*`SCALAR-1:0] MULT_opa = ALU_opa;
	wire [64*`SCALAR-1:0] MULT_opb = ALU_opb;
// END OF Outputs from the small decoder for ALU

// Outputs from Setting up Possible Immediates
  wire [64*`SCALAR-1:0] mem_disp;
  wire [64*`SCALAR-1:0] br_disp;
  wire [64*`SCALAR-1:0] alu_imm;
// END OF Outputs from Setting up Possible Immediates

// Setting up Possible Immediates 
//   mem_disp: sign-extended 16-bit immediate for memory format
//   br_disp: sign-extended 21-bit immediate * 4 for branch displacement
//   alu_imm: zero-extended 8-bit immediate for ALU ops
	`ifdef SUPERSCALAR
  assign mem_disp	= { {48{rs_IR[47]}}, rs_IR[47:32], {48{rs_IR[15]}}, rs_IR[15:0]};
  assign br_disp	= { {41{rs_IR[52]}}, rs_IR[52:32], 2'b00, {41{rs_IR[20]}}, rs_IR[20:0], 2'b00};
  assign alu_imm	= { 56'b0, rs_IR[52:45], 56'b0, rs_IR[20:13]};
	`else
  assign mem_disp	= { {48{rs_IR[15]}}, rs_IR[15:0] };
  assign br_disp	= { {41{rs_IR[20]}}, rs_IR[20:0], 2'b00 };
  assign alu_imm	= { 56'b0, rs_IR[20:13] };
	`endif
// END OF Setting up Possible Immediates 

// Small Decoder for ALU operation
// Mostly a direct copy from id_stage.v
// ALU_opa/opb_select[SEL(2,1)] : opa/opb_select signals for the 1st instruction
// ALU_opa/opb_select[SEL(2,2)] : opa/opb_select signals for the 2nd instruction
// ALU_opa/opb[SEL(64,1)]  : opa/opb for the 1st instruction
// ALU_opa/opb[SEL(64,2)]  : opa/opb for the 2nd instruction
	always @*
	begin
		ALU_opa_select[SEL(2,1)] = 0;
		ALU_opb_select[SEL(2,1)] = 0;

		case({rs_IR[31:29], 3'b0})
			6'h10: 	
				begin
					ALU_opa_select[SEL(2,1)] = `ALU_OPA_IS_REGA;
					ALU_opb_select[SEL(2,1)] = rs_IR[12] ? `ALU_OPB_IS_ALU_IMM : `ALU_OPB_IS_REGB;
				end
			6'h18:
				case(rs_IR[31:26])
					`JSR_GRP:	
						begin
							ALU_opa_select[SEL(2,1)] = `ALU_OPA_IS_NOT3;
							ALU_opb_select[SEL(2,1)] = `ALU_OPB_IS_REGB;
						end
				endcase
			6'h08, 6'h20, 6'h28:	
				begin
					ALU_opa_select[SEL(2,1)] = `ALU_OPA_IS_MEM_DISP;
					ALU_opb_select[SEL(2,1)] = `ALU_OPB_IS_REGB;
				end
			6'h30, 6'h38: 
				begin
					ALU_opa_select[SEL(2,1)] = `ALU_OPA_IS_NPC;
					ALU_opb_select[SEL(2,1)] = `ALU_OPB_IS_BR_DISP;
				end
		endcase
	end
  
	always @*
  begin
    ALU_opb[SEL(64,1)] = 64'hbaadbeefdeadbeef;
    case (ALU_opa_select[1:0])
      `ALU_OPA_IS_REGA:     ALU_opa[SEL(64,1)] = prega_value;
      `ALU_OPA_IS_MEM_DISP: ALU_opa[SEL(64,1)] = mem_disp;
      `ALU_OPA_IS_NPC:      ALU_opa[SEL(64,1)] = npc;
      `ALU_OPA_IS_NOT3:     ALU_opa[SEL(64,1)] = ~64'h3;
    endcase
    case (ALU_opb_select[1:0])
      `ALU_OPB_IS_REGB:    ALU_opb[SEL(64,1)] = pregb_value;
      `ALU_OPB_IS_ALU_IMM: ALU_opb[SEL(64,1)] = alu_imm;
      `ALU_OPB_IS_BR_DISP: ALU_opb[SEL(64,1)] = br_disp;
    endcase 
  end

`ifdef SUPERSCALAR
	always @*
	begin
		ALU_opa_select[SEL(2,2)] = 0;
		ALU_opb_select[SEL(2,2)] = 0;

		case({rs_IR[63:61], 3'b0})
			6'h10: 	
				begin
					ALU_opa_select[SEL(2,2)] = `ALU_OPA_IS_REGA;
					ALU_opb_select[SEL(2,2)] = rs_IR[44] ? `ALU_OPB_IS_ALU_IMM : `ALU_OPB_IS_REGB;
				end
			6'h18:
				case(rs_IR[63:58])
					`JSR_GRP:	
						begin
							ALU_opa_select[SEL(2,2)] = `ALU_OPA_IS_NOT3;
							ALU_opb_select[SEL(2,2)] = `ALU_OPB_IS_REGB;
						end
				endcase
			6'h08, 6'h20, 6'h28:	
				begin
					ALU_opa_select[SEL(2,2)] = `ALU_OPA_IS_MEM_DISP;
					ALU_opb_select[SEL(2,2)] = `ALU_OPB_IS_REGB;
				end
			6'h30, 6'h38: 
				begin
					ALU_opa_select[SEL(2,2)] = `ALU_OPA_IS_NPC;
					ALU_opb_select[SEL(2,2)] = `ALU_OPB_IS_BR_DISP;
				end
		endcase
	end

	always @*
  begin
    ALU_opb[SEL(64,2)] = 64'hbaadbeefdeadbeef;
    case (ALU_opa_select[3:2])
      `ALU_OPA_IS_REGA:     ALU_opa[SEL(64,2)] = prega_value;
      `ALU_OPA_IS_MEM_DISP: ALU_opa[SEL(64,2)] = mem_disp;
      `ALU_OPA_IS_NPC:      ALU_opa[SEL(64,2)] = npc;
      `ALU_OPA_IS_NOT3:     ALU_opa[SEL(64,2)] = ~64'h3;
    endcase
    case (ALU_opb_select[3:2])
      `ALU_OPB_IS_REGB:    ALU_opb[SEL(64,2)] = pregb_value;
      `ALU_OPB_IS_ALU_IMM: ALU_opb[SEL(64,2)] = alu_imm;
      `ALU_OPB_IS_BR_DISP: ALU_opb[SEL(64,2)] = br_disp;
    endcase 
  end
`endif
// END OF  Small Decoder for ALU operation

endmodule


module ex_stage(clk, reset,
								// Inputs
								pdest_idx, prega_value, pregb_value, 
								ALUop, rd_mem, wr_mem,
								rs_IR, npc, rob_idx, EX_en,

								// Outputs
								cdb_tag_out, cdb_valid_out, cdb_value_out,	// to CDB
								rob_idx_out, branch_NT_out, 								// to ROB
								ALU_free, MULT_free, MEM_free,							// to RS
								rs_IR_out, npc_out													// for Debugging
               );

  input clk;  
  input reset;

// Outputs from the input pipeline registers (RS/EX)
	input	[`PRF_IDX*`SCALAR-1:0] pdest_idx;
	input	[64*`SCALAR-1:0] prega_value;
	input	[64*`SCALAR-1:0] pregb_value;
	input	[5*`SCALAR-1:0] ALUop;
	input	[`SCALAR-1:0] rd_mem;
	input	[`SCALAR-1:0] wr_mem;
	input	[32*`SCALAR-1:0] rs_IR;
	input	[64*`SCALAR-1:0] npc;
	input	[`ROB_IDX*`SCALAR-1:0] rob_idx;
	input	[`SCALAR-1:0] EX_en;
// END OF Outputs from the input pipeline registers (RS/EX)

// Outputs from the Output Logic
	output [`PRF_IDX*`SCALAR-1:0] cdb_tag_out;
	output [`SCALAR-1:0] cdb_valid_out;
	output [64*`SCALAR-1:0] cdb_value_out;
	output [`ROB_IDX*`SCALAR-1:0] rob_idx_out;
	output [`SCALAR-1:0] branch_NT_out;
	output [`SCALAR-1:0] ALU_free;
	output [`SCALAR-1:0] MULT_free;
	output [`SCALAR-1:0] MEM_free;
	output [32*`SCALAR-1:0] rs_IR_out;
	output [64*`SCALAR-1:0] npc_out;
// END OF Outputs from the Output Logic

// Stall Signals
	// For EX/CDB pipeline registers (come from EX_CDB_Interface)
	wire [`SCALAR-1:0] ALU_stall;
	wire [`SACLAR-1:0] MULT_stall;
// END OF Stall Signals

// Inputs to the functional units
	wire [64*`SCALAR-1:0]				ALU_opa_in;
	wire [64*`SCALAR-1:0]				ALU_opb_in;
	wire [5*`SCALAR-1:0]				ALU_func_in;
	wire [64*`SCALAR-1:0]				BRcond_opa_in;
	wire [3*`SCALAR-1:0]				BRcond_func_in;
	wire [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_in;
	wire [32*`SCALAR-1:0]				ALU_rs_IR_in;
	wire [64*`SCALAR-1:0]				ALU_npc_in;
	wire [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_in;
	wire [`SCALAR-1:0]					ALU_EX_en_in;
	wire [64*`SCALAR-1:0]				MULT_mplier_in;
	wire [64*`SCALAR-1:0]				MULT_mcand_in;
	wire [`SCALAR-1:0]					MULT_start_in;
	wire [`PRF_IDX*`SCALAR-1:0]	MULT_pdest_idx_in;
	wire [32*`SCALAR-1:0]				MULT_rs_IR_in;
	wire [64*`SCALAR-1:0]				MULT_npc_in;
	wire [`ROB_IDX*`SCALAR-1:0]	MULT_rob_idx_in;
	wire [`SCALAR-1:0]					MULT_EX_en_in;
	wire [64*`SCALAR-1:0]				MEM_rega_in;
	wire [64*`SCALAR-1:0]				MEM_regb_in;
	wire [64*`SCALAR-1:0]				MEM_disp_in;
	wire [`SCALAR-1:0]					MEM_rd_in;
	wire [`SCALAR-1:0]					MEM_wr_in;
	wire [`PRF_IDX*`SCALAR-1:0]	MEM_pdest_idx_in;
	wire [32*`SCALAR-1:0]				MEM_rs_IR_in;
	wire [64*`SCALAR-1:0]				MEM_npc_in;
	wire [`ROB_IDX*`SCALAR-1:0]	MEM_rob_idx_in;
	wire [`SCALAR-1:0]					MEM_EX_en_in;
// END OF Inputs to the functional units
	
// Outputs from the functional units
	wire [64*`SCALAR-1:0]				ALU_result;
	wire [`SCALAR-1:0] 					BRcond_result;
	wire [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx = ALU_pdest_idx_in;
	wire [32*`SCALAR-1:0]				ALU_rs_IR = ALU_rs_IR_in;
	wire [64*`SCALAR-1:0]				ALU_npc = ALU_npc_in;
	wire [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx = ALU_rob_idx_in;
	wire [`SCALAR-1:0]					ALU_EX_en = ALU_EX_en_in;
	wire [64*`SCALAR-1:0]				MULT_product;
	wire [`SCALAR-1:0]					MULT_done;
	wire [`PRF_IDX*`SCALAR-1:0]	MULT_pdest_idx;
	wire [32*`SCALAR-1:0]				MULT_rs_IR;
	wire [64*`SCALAR-1:0]				MULT_npc;
	wire [`ROB_IDX*`SCALAR-1:0]	MULT_rob_idx;
	wire [`SCALAR-1:0]					MULT_EX_en;
	wire [`SCALAR-1:0]					MEM_valid_value;
	wire [`SCALAR-1:0]					MEM_done;
	wire [64*`SCALAR-1:0]				MEM_value;
	wire [`PRF_IDX*`SCALAR-1:0]	MEM_pdest_idx;
	wire [32*`SCALAR-1:0]				MEM_rs_IR;
	wire [64*`SCALAR-1:0]				MEM_npc;
	wire [`ROB_IDX*`SCALAR-1:0]	MEM_rob_idx;
	wire [`SCALAR-1:0]					MEM_EX_en;
	wire [`SCALAR-1:0]					MEM_LSQ_free;
// END OF Outputs from the functional units

// Outputs from the EX/CDB registers
	reg [64*`SCALAR-1:0]				ALU_result_reg;
	reg [`SCALAR-1:0] 					BRcond_result_reg;
	reg [`PRF_IDX*`SCALAR-1:0]	ALU_pdest_idx_reg;
	reg [32*`SCALAR-1:0]				ALU_rs_IR_reg;
	reg [64*`SCALAR-1:0]				ALU_npc_reg;
	reg [`ROB_IDX*`SCALAR-1:0]	ALU_rob_idx_reg;
	reg [`SCALAR-1:0]						ALU_EX_en_reg;
	reg [64*`SCALAR-1:0]				MULT_product_reg;
	reg [`SCALAR-1:0]						MULT_done_reg;
	reg [`PRF_IDX*`SCALAR-1:0]	MULT_pdest_idx_reg;
	reg [32*`SCALAR-1:0]				MULT_rs_IR_reg;
	reg [64*`SCALAR-1:0]				MULT_npc_reg;
	reg [`ROB_IDX*`SCALAR-1:0]	MULT_rob_idx_reg;
	reg [`SCALAR-1:0]						MULT_EX_en_reg;
	reg [`SCALAR-1:0]						MEM_valid_value_reg;
	reg [`SCALAR-1:0]						MEM_done_reg;
	reg [64*`SCALAR-1:0]				MEM_value_reg;
	reg [`PRF_IDX*`SCALAR-1:0]	MEM_pdest_idx_reg;
	reg [32*`SCALAR-1:0]				MEM_rs_IR_reg;
	reg [64*`SCALAR-1:0]				MEM_npc_reg;
	reg [`ROB_IDX*`SCALAR-1:0]	MEM_rob_idx_reg;
	reg [`SCALAR-1:0]						MEM_EX_en_reg;
	reg [`SCALAR-1:0]						MEM_LSQ_free_reg;
// END OF Outputs from the EX/CDB registers

	EX_input_logic EX_input_logic0 (
																	.pdest_idx(pdest_idx), 
																	.prega_value(prega_value), 
																	.pregb_value(pregb_value), 
																	.ALUop(ALUop), 
																	.rd_mem(rd_mem), 
																	.wr_mem(wr_mem), 
																	.rs_IR(rs_IR), 
																	.npc(npc), 
																	.rob_idx(rob_idx), 
																	.EX_en(EX_en),
											 						.ALU_opa_out(ALU_opa_in), 
																	.ALU_opb_out(ALU_opb_in), 
																	.ALU_func_out(ALU_func_in), 
																	.BRcond_opa_out(BRcond_opa_in), 
																	.BRcond_func_out(BRcond_func_in), 
																	.ALU_pdest_idx_out(ALU_pdest_idx_in), 
																	.ALU_rs_IR_out(ALU_rs_IR_in), 
																	.ALU_npc_out(ALU_npc_in), 
																	.ALU_rob_idx_out(ALU_rob_idx_in), 
																	.ALU_EX_en_out(ALU_EX_en_in),
																 	.MULT_mplier_out(MULT_mplier_in), 
																	.MULT_mcand_out(MULT_mcand_in), 
																	.MULT_start_out(MULT_start_in),
																	.MULT_pdest_idx_out(MULT_pdest_idx_in), 
																	.MULT_rs_IR_out(MULT_rs_IR_in), 
																	.MULT_npc_out(MULT_npc_in), 
																	.MULT_rob_idx_out(MULT_rob_idx_in), 
																	.MULT_EX_en_out(MULT_EX_en_in),
																	.MEM_rega_out(MEM_rega_in), 
																	.MEM_regb_out(MEM_regb_in), 
																	.MEM_disp_out(MEM_disp_in), 
																	.MEM_rd_out(MEM_rd_in), 
																	.MEM_wr_out(MEM_wr_in),
																	.MEM_pdest_idx_out(MEM_pdest_idx_in), 
																	.MEM_rs_IR_out(MEM_rs_IR_in), 
																	.MEM_npc_out(MEM_npc_in), 
																	.MEM_rob_idx_out(MEM_rob_idx_in), 
																	.MEM_EX_en_out(MEM_EX_en_in)
																	);


// Functional units
	MEM_CONT MEM_CONT1 (
											.rega_in(MEM_rega_in[SEL(64,1)]), 
											.regb_in(MEM_regb_in[SEL(64,1)]), 
											.disp_in(MEM_disp_in[SEL(64,1)]), 
											.rd_in(MEM_rd_in[SEL(1,1)]), 
											.wr_in(MEM_wr_in[SEL(1,1)]), 
											.pdest_idx_in(MEM_pdest_idx_in[SEL(`PRF_IDX,1)]), 
											.rs_IR_in(MEM_rs_IR_in[SEL(32,1)]), 
											.npc_in(MEM_npc_in[SEL(64,1)]), 
											.rob_idx_in(MEM_rob_idx_in[SEL(`ROB_IDX,1)]), 
											.EX_en_in(MEM_EX_en_in[SEL(1,1)]),
								 			.LSQ_free(), 
											.LSQ_rob_idx(), 
											.LSQ_pdest_idx(), 
											.LSQ_mem_value(), 
											.LSQ_done(), 
											.LSQ_rd_mem(), 
											.LSQ_wr_mem(),
								 			.MEM_ADDR(), 
											.MEM_rob_idx(), 
											.MEM_pdest_idx(), 
											.MEM_reg_value(), 
											.MEM_rd_mem(), 
											.MEM_wr_mem(),
								 			.MEM_valid_value(MEM_valid_value[SEL(1,1)]), 
											.MEM_done(MEM_done[SEL(1,1)]), 
											.MEM_value(MEM_value[SEL(64,1)]), 
											.MEM_pdest_idx_out(MEM_pdest_idx[SEL(`PRF_IDX,1)]), 
											.MEM_rob_idx_out(MEM_rob_idx[SEL(`ROB_IDX,1)]), 
											.MEM_LSQ_free(MEM_LSQ_free[SEL(1,1)])
										);

  ALU ALU1 ( .opa(ALU_opa_in[SEL(64,1)]),
             .opb(ALU_opb_in[SEL(64,1)]),
             .func(ALU_func_in[SEL(5,1)]),
             .result(ALU_result[SEL(64, 1)])
            );

	BRcond BRcond1 (.opa(BRcond_opa_in[SEL(64,1)]),
									.func(BRcond_func_in[SEL(3,1)]),
									.cond(BRcond_result[SEL(1,1)])
									);

	MULT MULT1 (.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier_in[SEL(64,1)]),
							.mcand(MULT_mcand_in[SEL(64,1)]),
							.start(MULT_start_in[SEL(1,1)]),
							.product(MULT_product[SEL(64,1)]),
							.done(MULT_done[SEL(1,1)]),
							.pdest_idx_in(MULT_pdest_idx_in[SEL(`PRF_IDX,1)]),
							.rs_IR_in(MULT_rs_IR_in[SEL(32,1)]),
							.npc_in(MULT_npc_in[SEL(64,1)]),
							.rob_idx_in(MULT_rob_idx_in[SEL(`ROB_IDX,1)]),
							.EX_en_in(MULT_EX_en_in[SEL(1,1)]),
							.pdest_idx_out(MULT_pdest_idx[SEL(`PRF_IDX,1)]),
							.rs_IR_out(MULT_rs_IR[SEL(32,1)]),
							.npc_out(MULT_npc[SEL(64,1)]),
							.rob_idx_out(MULT_rob_idx[SEL(`ROB_IDX,1)]),
							.EX_en_out(MULT_EX_en[SEL(1,1)])
							);

`ifdef SUPERSCALAR
	MEM_CONT MEM_CONT2 (
											.rega_in(MEM_rega_in[SEL(64,2)]), 
											.regb_in(MEM_regb_in[SEL(64,2)]), 
											.disp_in(MEM_disp_in[SEL(64,2)]), 
											.rd_in(MEM_rd_in[SEL(1,2)]), 
											.wr_in(MEM_wr_in[SEL(1,2)]), 
											.pdest_idx_in(MEM_pdest_idx_in[SEL(`PRF_IDX,2)]), 
											.rs_IR_in(MEM_rs_IR_in[SEL(32,2)]), 
											.npc_in(MEM_npc_in[SEL(64,2)]), 
											.rob_idx_in(MEM_rob_idx_in[SEL(`ROB_IDX,2)]), 
											.EX_en_in(MEM_EX_en_in[SEL(1,2)]),
								 			.LSQ_free(), 
											.LSQ_rob_idx(), 
											.LSQ_pdest_idx(), 
											.LSQ_mem_value(), 
											.LSQ_done(), 
											.LSQ_rd_mem(), 
											.LSQ_wr_mem(),
								 			.MEM_ADDR(), 
											.MEM_rob_idx(), 
											.MEM_pdest_idx(), 
											.MEM_reg_value(), 
											.MEM_rd_mem(), 
											.MEM_wr_mem(),
								 			.MEM_valid_value(MEM_valid_value[SEL(1,2)]), 
											.MEM_done(MEM_done[SEL(1,2)]), 
											.MEM_value(MEM_value[SEL(64,2)]), 
											.MEM_pdest_idx_out(MEM_pdest_idx[SEL(`PRF_IDX,2)]), 
											.MEM_rob_idx_out(MEM_rob_idx[SEL(`ROB_IDX,2)]), 
											.MEM_LSQ_free(MEM_LSQ_free[SEL(1,2)])
										);

  ALU ALU2 ( .opa(ALU_opa_in[SEL(64, 2)]),
             .opb(ALU_opb_in[SEL(64, 2)]),
             .func(ALU_func_in[SEL(5,2)]),
             .result(ALU_result[SEL(64, 2)])
            );

	BRcond BRcond2 (.opa(BRcond_opa_in[SEL(64,2)]),
									.func(BRcond_func_in[SEL(3,2)]),
									.cond(BRcond_result[SEL(1,2)])
									);

	MULT MULT2 (.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier_in[SEL(64,2)]),
							.mcand(MULT_mcand_in[SEL(64,2)]),
							.start(MULT_start_in[SEL(1,2)]),
							.product(MULT_product[SEL(64,2)]),
							.done(MULT_done[SEL(1,2)]),
							.pdest_idx_in(MULT_pdest_idx_in[SEL(`PRF_IDX,2)]),
							.rs_IR_in(MULT_rs_IR_in[SEL(32,2)]),
							.npc_in(MULT_npc_in[SEL(64,2)]),
							.rob_idx_in(MULT_rob_idx_in[SEL(`ROB_IDX,2)]),
							.EX_en_in(MULT_EX_en_in[SEL(1,2)]),
							.pdest_idx_out(MULT_pdest_idx[SEL(`PRF_IDX,2)]),
							.rs_IR_out(MULT_rs_IR[SEL(32,2)]),
							.npc_out(MULT_npc[SEL(64,2)]),
							.rob_idx_out(MULT_rob_idx[SEL(`ROB_IDX,2)]),
							.EX_en_out(MULT_EX_en[SEL(1,2)])
							);
`endif
// END OF Functional units

// Output pipeline register (EX/CDB)
	always @(posedge clk)
	begin
		if(reset) begin
			ALU_result_reg			<= `SD {64*`SCALAR{1'b0}};
			BRcond_result_reg		<= `SD {`SCALAR{1'b0}};
			ALU_pdest_idx_reg		<= `SD {`PRF_IDX*`SCALAR{1'b0}};
			ALU_rs_IR_reg				<= `SD {32*`SCALAR{1'b0}};			
			ALU_npc_reg					<= `SD {64*`SCALAR{1'b0}};		
			ALU_rob_idx_reg			<= `SD {`ROB_IDX*`SCALAR{1'b0}};
			ALU_EX_en_reg				<= `SD {`SCALAR{1'b0}};				
			MULT_product_reg		<= `SD {64*`SCALAR{1'b0}};	
			MULT_done_reg				<= `SD {`SCALAR{1'b0}};	
			MULT_pdest_idx_reg	<= `SD {`PRF_IDX*`SCALAR{1'b0}};
			MULT_rs_IR_reg			<= `SD {32*`SCALAR{1'b0}};			
			MULT_npc_reg				<= `SD {64*`SCALAR{1'b0}};		
			MULT_rob_idx_reg		<= `SD {`ROB_IDX*`SCALAR{1'b0}};
			MULT_EX_en_reg			<= `SD {`SCALAR{1'b0}};				
			MEM_valid_value_reg	<= `SD {`SCALAR{1'b0}};				
			MEM_done_reg				<= `SD {`SCALAR{1'b0}};				
			MEM_value_reg				<= `SD {64*`SCALAR{1'b0}};	
			MEM_pdest_idx_reg		<= `SD {`PRF_IDX*`SCALAR{1'b0}};
			MEM_rs_IR_reg				<= `SD {32*`SCALAR{1'b0}};			
			MEM_npc_reg					<= `SD {64*`SCALAR{1'b0}};		
			MEM_rob_idx_reg			<= `SD {`ROB_IDX*`SCALAR{1'b0}};
			MEM_EX_en_reg				<= `SD {`SCALAR{1'b0}};				
			MEM_LSQ_free_reg		<= `SD {`SCALAR{1'b1}};				
		end
		`ifdef SUPERSCALAR
		else if({ALU_stall, MULT_stall} != 4'b0000) begin
			if(ALU_stall==2'b01) begin
				ALU_result_reg			<= `SD {ALU_result[SEL(64,2)], ALU_result_reg[SEL(64,1)]};
				BRcond_result_reg		<= `SD {BRcond_result[SEL(1,2)], BRcond_result_reg[SEL(1,1)]};
				ALU_pdest_idx_reg		<= `SD {ALU_pdest_idx[SEL(`PRF_IDX,2)], ALU_pdest_idx_reg[SEL(`PRF_IDX,1)]};
				ALU_rs_IR_reg				<= `SD {ALU_rs_IR[SEL(32,2)], ALU_rs_IR_reg[SEL(32,1)]};
				ALU_npc_reg					<= `SD {ALU_npc[SEL(64,2)], ALU_npc_reg[SEL(64,1)]};
				ALU_rob_idx_reg			<= `SD {ALU_rob_idx[SEL(`ROB_IDX,2)], ALU_rob_idx_reg[SEL(`ROB_IDX,1)]};
				ALU_EX_en_reg				<= `SD {ALU_EX_en[SEL(1,2)], ALU_EX_en_reg[SEL(1,1)]};
			end
			else if(ALU_stall==2'b10) begin
				ALU_result_reg			<= `SD {ALU_result_reg[SEL(64,2)], ALU_result[SEL(64,1)]};
				BRcond_result_reg		<= `SD {BRcond_result_reg[SEL(1,2)], BRcond_result[SEL(1,1)]};
				ALU_pdest_idx_reg		<= `SD {ALU_pdest_idx_reg[SEL(`PRF_IDX,2)], ALU_pdest_idx[SEL(`PRF_IDX,1)]};
				ALU_rs_IR_reg				<= `SD {ALU_rs_IR_reg[SEL(32,2)], ALU_rs_IR[SEL(32,1)]};
				ALU_npc_reg					<= `SD {ALU_npc_reg[SEL(64,2)], ALU_npc[SEL(64,1)]};
				ALU_rob_idx_reg			<= `SD {ALU_rob_idx_reg[SEL(`ROB_IDX,2)], ALU_rob_idx[SEL(`ROB_IDX,1)]};
				ALU_EX_en_reg				<= `SD {ALU_EX_en_reg[SEL(1,2)], ALU_EX_en[SEL(1,1)]};
			end
			else begin
				ALU_result_reg			<= `SD ALU_result;
				BRcond_result_reg		<= `SD BRcond_result;
				ALU_pdest_idx_reg		<= `SD ALU_pdest_idx;
				ALU_rs_IR_reg				<= `SD ALU_rs_IR;
				ALU_npc_reg					<= `SD ALU_npc;
				ALU_rob_idx_reg			<= `SD ALU_rob_idx;
				ALU_EX_en_reg				<= `SD ALU_EX_en;
			end
			if (MULT_stall==2'b01) begin
				MULT_product_reg		<= `SD {MULT_product[SEL(64,2)], MULT_product_reg[SEL(64,1)]};
				MULT_done_reg				<= `SD {MULT_done[SEL(1,2)], MULT_done_reg[SEL(1,1)]};
				MULT_pdest_idx_reg	<= `SD {MULT_pdest_idx[SEL(`PRF_IDX,2)], MULT_pdest_idx_reg[SEL(`PRF_IDX,1)]};
				MULT_rs_IR_reg			<= `SD {MULT_rs_IR[SEL(32,2)], MULT_rs_IR_reg[SEL(32,1)]};
				MULT_npc_reg				<= `SD {MULT_npc[SEL(64,2)], MULT_npc_reg[SEL(64,1)]};
				MULT_rob_idx_reg		<= `SD {MULT_rob_idx[SEL(`ROB_IDX,2)], MULT_rob_idx_reg[SEL(`ROB_IDX,1)]};
				MULT_EX_en_reg			<= `SD {MULT_EX_en[SEL(1,2)], MULT_EX_en_reg[SEL(1,1)]};
			end
			else if (MULT_stall==2'b10) begin
				MULT_product_reg		<= `SD {MULT_product_reg[SEL(64,2)], MULT_product[SEL(64,1)]};
				MULT_done_reg				<= `SD {MULT_done_reg[SEL(1,2)], MULT_done[SEL(1,1)]};
				MULT_pdest_idx_reg	<= `SD {MULT_pdest_idx_reg[SEL(`PRF_IDX,2)], MULT_pdest_idx[SEL(`PRF_IDX,1)]};
				MULT_rs_IR_reg			<= `SD {MULT_rs_IR_reg[SEL(32,2)], MULT_rs_IR[SEL(32,1)]};
				MULT_npc_reg				<= `SD {MULT_npc_reg[SEL(64,2)], MULT_npc[SEL(64,1)]};
				MULT_rob_idx_reg		<= `SD {MULT_rob_idx_reg[SEL(`ROB_IDX,2)], MULT_rob_idx[SEL(`ROB_IDX,1)]};
				MULT_EX_en_reg			<= `SD {MULT_EX_en_reg[SEL(1,2)], MULT_EX_en[SEL(1,1)]};
			end
			else begin
				MULT_product_reg		<= `SD MULT_product;
				MULT_done_reg				<= `SD MULT_done;
				MULT_pdest_idx_reg	<= `SD MULT_pdest_idx;
				MULT_rs_IR_reg			<= `SD MULT_rs_IR;
				MULT_npc_reg				<= `SD MULT_npc;
				MULT_rob_idx_reg		<= `SD MULT_rob_idx;
				MULT_EX_en_reg			<= `SD MULT_EX_en;
			end
			MEM_value_reg				<= `SD MEM_value;
			MEM_pdest_idx_reg		<= `SD MEM_pdest_idx;
			MEM_rs_IR_reg				<= `SD MEM_rs_IR;
			MEM_npc_reg					<= `SD MEM_npc;
			MEM_rob_idx_reg			<= `SD MEM_rob_idx;
			MEM_EX_en_reg				<= `SD MEM_EX_en;
			MEM_LSQ_free_reg		<= `SD MEM_LSQ_free;
		end
		`else
		else if({ALU_stall, MULT_stall} != 2'b00) begin
			if(ALU_stall) begin
				ALU_result_reg			<= `SD ALU_result_reg;
				BRcond_result_reg		<= `SD BRcond_result_reg;
				ALU_pdest_idx_reg		<= `SD ALU_pdest_idx_reg;
				ALU_rs_IR_reg				<= `SD ALU_rs_IR_reg;
				ALU_npc_reg					<= `SD ALU_npc_reg;
				ALU_rob_idx_reg			<= `SD ALU_rob_idx_reg;
				ALU_EX_en_reg				<= `SD ALU_EX_en_reg;
			end
			else begin
				ALU_result_reg			<= `SD ALU_result;
				BRcond_result_reg		<= `SD BRcond_result;
				ALU_pdest_idx_reg		<= `SD ALU_pdest_idx;
				ALU_rs_IR_reg				<= `SD ALU_rs_IR;
				ALU_npc_reg					<= `SD ALU_npc;
				ALU_rob_idx_reg			<= `SD ALU_rob_idx;
				ALU_EX_en_reg				<= `SD ALU_EX_en;
			end
			if (MULT_stall) begin
				MULT_product_reg		<= `SD MULT_product_reg;
				MULT_done_reg				<= `SD MULT_done_reg;
				MULT_pdest_idx_reg	<= `SD MULT_pdest_idx_reg;
				MULT_rs_IR_reg			<= `SD MULT_rs_IR_reg;
				MULT_npc_reg				<= `SD MULT_npc_reg;
				MULT_rob_idx_reg		<= `SD MULT_rob_idx_reg;
				MULT_EX_en_reg			<= `SD MULT_EX_en_reg;
			end
			else begin
				MULT_product_reg		<= `SD MULT_product;
				MULT_done_reg				<= `SD MULT_done;
				MULT_pdest_idx_reg	<= `SD MULT_pdest_idx;
				MULT_rs_IR_reg			<= `SD MULT_rs_IR;
				MULT_npc_reg				<= `SD MULT_npc;
				MULT_rob_idx_reg		<= `SD MULT_rob_idx;
				MULT_EX_en_reg			<= `SD MULT_EX_en;
			end
			MEM_value_reg				<= `SD MEM_value;
			MEM_pdest_idx_reg		<= `SD MEM_pdest_idx;
			MEM_rs_IR_reg				<= `SD MEM_rs_IR;
			MEM_npc_reg					<= `SD MEM_npc;
			MEM_rob_idx_reg			<= `SD MEM_rob_idx;
			MEM_EX_en_reg				<= `SD MEM_EX_en;
			MEM_LSQ_free_reg		<= `SD MEM_LSQ_free;
		end
		`endif
		else begin
			ALU_result_reg			<= `SD ALU_result;
			BRcond_result_reg		<= `SD BRcond_result;
			ALU_pdest_idx_reg		<= `SD ALU_pdest_idx;
			ALU_rs_IR_reg				<= `SD ALU_rs_IR;
			ALU_npc_reg					<= `SD ALU_npc;
			ALU_rob_idx_reg			<= `SD ALU_rob_idx;
			ALU_EX_en_reg				<= `SD ALU_EX_en;
			MULT_product_reg		<= `SD MULT_product;
			MULT_done_reg				<= `SD MULT_done;
			MULT_pdest_idx_reg	<= `SD MULT_pdest_idx;
			MULT_rs_IR_reg			<= `SD MULT_rs_IR;
			MULT_npc_reg				<= `SD MULT_npc;
			MULT_rob_idx_reg		<= `SD MULT_rob_idx;
			MULT_EX_en_reg			<= `SD MULT_EX_en;
			MEM_valid_value_reg	<= `SD MEM_valid_value;
			MEM_done_reg				<= `SD MEM_done;
			MEM_value_reg				<= `SD MEM_value;
			MEM_pdest_idx_reg		<= `SD MEM_pdest_idx;
			MEM_rs_IR_reg				<= `SD MEM_rs_IR;
			MEM_npc_reg					<= `SD MEM_npc;
			MEM_rob_idx_reg			<= `SD MEM_rob_idx;
			MEM_EX_en_reg				<= `SD MEM_EX_en;
			MEM_LSQ_free_reg		<= `SD MEM_LSQ_free;
		end
	end
// END OF Output pipeline register (EX/CDB)

// EX-CDB Interface
EX_CDB_Interface EX_CDB_Interface0	(//Inputs
																			.ALU_result(ALU_result_reg),
																			.BRcond_result(BRcond_result_reg),
																			.ALU_pdest_idx(ALU_pdest_idx_reg),
																			.ALU_rs_IR(ALU_rs_IR_reg),
																			.ALU_npc(ALU_npc_reg),
																			.ALU_rob_idx(ALU_rob_idx_reg),
																			.ALU_EX_en(ALU_EX_en_reg),
																			.MULT_product(MULT_product_reg),
																			.MULT_done(MULT_done_reg),
																			.MULT_pdest_idx(MULT_pdest_idx_reg),
																			.MULT_rs_IR(MULT_rs_IR_reg),
																			.MULT_npc(MULT_npc_reg),
																			.MULT_rob_idx(MULT_rob_idx_reg),
																			.MULT_EX_en(MULT_EX_en_reg),
																			.MEM_valid_value(MEM_valid_value_reg),
																			.MEM_done(MEM_done_reg),
																			.MEM_value(MEM_value_reg),
																			.MEM_pdest_idx(MEM_pdest_idx_reg),
																			.MEM_rs_IR(MEM_rs_IR_reg),
																			.MEM_npc(MEM_npc_reg),
																			.MEM_rob_idx(MEM_rob_idx_reg),
																			.MEM_EX_en(MEM_EX_en_reg),
																			.MEM_LSQ_free(MEM_LSQ_free_reg),

																		//Outputs
																			.cdb_tag_out(cdb_tag_out),
																			.cdb_valid_out(cdb_valid_out),
																			.cdb_value_out(cdb_value_out),
																			.rob_idx_out(rob_index_out),
																			.branch_NT_out(branch_NT_out),
																			.ALU_free(ALU_free),
																			.MULT_free(MULT_free),
																			.MEM_free(MEM_free),
																			.ALU_stall(ALU_stall),
																			.MULT_stall(MULT_stall),
																			.rs_IR_out(rs_IR_out),
																			.npc_out(npc_out)
																			);


endmodule // module ex_stage

