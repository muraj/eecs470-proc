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
module MEM_CONT ();
// Make it!
endmodule // MEM_CONT

// Multipliers
module MULT(clk, reset, mplier, mcand, start, product, done
						rs_IR_in, npc_in, rob_idx_in, EX_en_in,
						rs_IR_out, npc_out, rob_idx_out, EX_en_out
						);

  input clk, reset, start;
  input [63:0] mcand, mplier;
	
	input [31:0] rs_IR_in;
	input [63:0] npc_in;
	input [`ROB_IDX-1:0] rob_idx_in;
	input EX_en_in;

  output [63:0] product;
  output done;

	output reg [31:0] rs_IR_out;
	output reg [63:0] npc_out;
	output reg [`ROB_IDX-1:0] rob_idx_out;
	output reg EX_en_out;

  wire [63:0] mcand_out, mplier_out;
  wire [(7*64)-1:0] internal_products, internal_mcands, internal_mpliers;
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
		 .rs_IR_in({internal_rs_IR, rs_IR_in}),
		 .npc_in({internal_npc, npc_in}),
		 .rob_idx_in({internal_rob_idx, rob_idx_in}),
		 .EX_en_in({internal_EX_en, EX_en_in}),
		 .rs_IR_out({rs_IR_out, internal_rs_IR}),
		 .npc_out({npc_out, internal_npc}),
		 .rob_idx_out({rob_idx_out, internal_rob_idx}),
		 .EX_en_out({EX_en_out, internal_EX_en})
    );

endmodule // MULT

module mult_stage(clk, reset, stall, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done,
									rs_IR_in, npc_in, rob_idx_in, EX_en_in,
									rs_IR_out, npc_out, rob_idx_out, EX_en_out
									);

  input clk, reset, stall, start;
  input [63:0] product_in, mplier_in, mcand_in;

	input [31:0] rs_IR_in;
	input [63:0] npc_in;
	input [`ROB_IDX-1:0] rob_idx_in;
	input EX_en_in;

  output done;
  output [63:0] product_out, mplier_out, mcand_out;
	
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

module ex_stage(clk, reset,
								// Inputs
								pdest_idx, prega_value, pregb_value, 
								ALUop, rd_mem, wr_mem,
								rs_IR, npc, rob_idx, EX_en,

								// Outputs
								cdb_tag_out, cdb_valid_out, cdb_value_out,	// to CDB
								rob_idx_out, branch_NT_out, isBranch_out,		// to ROB
								stall,																			// to the pipeline register (in front of ex_stage)
								ALU_free, MULT_free, MEM_free								// to RS
               );

  input clk;  
  input reset;

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

	output reg	[`PRF_IDX*`SCALAR-1:0] cdb_tag_out;
	output reg	[`SCALAR-1:0] cdb_valid_out;
	output reg	[64*`SCALAR-1:0] cdb_value_out;
	output reg	[`ROB_IDX*`SCALAR-1:0] rob_idx_out;
	output reg	[`SCALAR-1:0] branch_NT_out;
	output reg	[`SCALAR-1:0] isBranch_out;
	output reg	[`SCALAR-1:0] ALU_free;
	output reg	[`SCALAR-1:0] MULT_free;
	output reg	MEM_free;
	output reg	stall;

	reg	[`PRF_IDX*`SCALAR-1:0] next_cdb_tag_out;
	reg	[`SCALAR-1:0] next_cdb_valid_out;
	reg	[64*`SCALAR-1:0] next_cdb_value_out;
	reg	[`ROB_IDX*`SCALAR-1:0] next_rob_idx_out;
	reg	[`SCALAR-1:0] next_branch_NT_out;
	reg	[`SCALAR-1:0] next_isBranch_out;
	reg	[`SCALAR-1:0] next_ALU_free;
	reg	[`SCALAR-1:0] next_MULT_free;
	reg	next_MEM_free;
	reg	next_stall;

// Outputs from the small decoder for ALU
	reg [2*`SCALAR-1:0] ALU_opa_select;
	reg [2*`SCALAR-1:0] ALU_opb_select;
	reg [64*`SCALAR-1:0] ALU_opa;
	reg [64*`SCALAR-1:0] ALU_opb;
	wire [64*`SCALAR-1:0] MULT_opa = ALU_opa;
	wire [64*`SCALAR-1:0] MULT_opb = ALU_opb;
// END OF Outputs from the small decoder for ALU

// Outputs from the input logic
// BRCond is a part of ALU
	reg [64*`SCALAR-1:0] ALU_opa_in;
	reg [64*`SCALAR-1:0] ALU_opb_in;
	reg [5*`SCALAR-1:0] ALU_func_in;
	reg [64*`SCALAR-1:0] BRcond_opa_in;
	reg [3*`SCALAR-1:0] BRcond_func_in;
	reg [32*`SCALAR-1:0] ALU_rs_
	reg [64*`SCALAR-1:0] MULT_mplier_in;
	reg [64*`SCALAR-1:0] MULT_mcand_in;
	reg [`SCALAR-1:0] MULT_start_in;

// Outputs from Setting up Possible Immediates
  wire [64*`SCALAR-1:0] mem_disp;
  wire [64*`SCALAR-1:0] br_disp;
  wire [64*`SCALAR-1:0] alu_imm;
// END OF Outputs from Setting up Possible Immediates

// Outputs from the small decoder for Branch Instructions
	reg [`SCALAR-1:0] cond_branch, uncond_branch;
	wire [`SCALAR-1:0] isBranch = cond_branch | uncond_branch;
// END OF Outputs from the small decoder for Branch Instructions

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

// Small Decoder for Branch Instructions
	always @*
	begin
		cond_branch[0] = `FALSE;
		uncond_branch[0] = `FALSE;

		case ({rs_IR[31:29], 3'b0})
			6'h18:
				case (rs_IR[31:26])
					`JSR_GRP:	uncond_branch[0] = `TRUE;
				endcase
			6'h30, 6'h38:
				case (rs_IR[31:26])
					`BR_INST, `BSR_INST: uncond_branch[0] = `TRUE;
          `FBEQ_INST, `FBLT_INST, `FBLE_INST, `FBNE_INST, `FBGE_INST, `FBGT_INST: // FP conditionals not implemented
					default: cond_branch[0] = `TRUE;
				endcase
		endcase
	end

	`ifdef SUPERSCALAR
	always @*
	begin
		cond_branch[1] = `FALSE;
		uncond_branch[1] = `FALSE;

		case ({rs_IR[63:61], 3'b0})
			6'h18:
				case (rs_IR[63:58])
					`JSR_GRP:	uncond_branch[1] = `TRUE;
				endcase
			6'h30, 6'h38:
				case (rs_IR[63:58])
					`BR_INST, `BSR_INST: uncond_branch[1] = `TRUE;
          `FBEQ_INST, `FBLT_INST, `FBLE_INST, `FBNE_INST, `FBGE_INST, `FBGT_INST: // FP conditionals not implemented
					default: cond_branch[1] = `TRUE;
				endcase
		endcase
	end
	`endif
// END OF Small Decoder for Branch Instructions

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

	// All sequential elements go here
	always @(posedge clk)
	begin
		if(reset) begin
			cdb_tag_out			<= `SD {`PRE_IDX*`SCALAR{1'b0}};
			cdb_valid_out		<= `SD {`SCALAR{1'b0}};
			cdb_value_out		<= `SD {64*`SCALAR{1'b0}};
			rob_idx_out			<= `SD {`ROB_IDX*`SCALAR{1'b0}};
			branch_NT_out		<= `SD {`SCALAR{1'b0}};
			isBranch_out		<= `SD {`SCALAR{1'b0}};
			ALU_free				<= `SD {`SCALAR{1'b0}};
			MULT_free				<= `SD {`SCALAR{1'b0}};
			MEM_free				<= `SD 1'b0;
			stall						<= `SD 1'b0;
		end
		else begin
			cdb_tag_out			<= `SD next_cdb_tag_out;
			cdb_valid_out		<= `SD next_cdb_valid_out;
			cdb_value_out		<= `SD next_cdb_value_out;
			rob_idx_out			<= `SD next_rob_idx_out;
			branch_NT_out		<= `SD next_branch_NT_out;
			isBranch_out		<= `SD next_isBranch_out;
			ALU_free				<= `SD next_ALU_free;
			MULT_free				<= `SD next_MULT_free;
			MEM_free				<= `SD next_MEM_free;
			stall						<= `SD next_stall;
		end
	end



   //
   // instantiate the Functional Units 
   //
	MEM_CONT MEM_CONT0 ();

  ALU ALU1 (// Inputs
             .opa(ALU_opa_in[SEL(64, 1)]),
             .opb(ALU_opb_in[SEL(64, 1)]),
             .func(ALU_func_in),

             // Output
             .result(ALU_result[SEL(64, 1)])
            );

	BRcond BRcond1 (// Inputs
							.opa(BRcond_opa_in),
							.func(BRcond_func_in),

							// Outputs
							.cond(BRcond_result)
							);

	MULT MULT1 (// Inputs
							.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier_in),
							.mcand(MULT_mcand_in),
							.start(MULT_start_in),
							.product(MULT_product),
							.done(MULT_done),
							.rs_IR_in(),
							.npc_in(),
							.rob_idx_in(),
							.EX_en_in(),
							.rs_IR_out(),
							.npc_out(),
							.rob_idx_out(),
							.EX_en_out()
							);

`ifdef SUPERSCALAR
  ALU ALU2 (// Inputs
             .opa(ALU_opa_in[SEL(64, 2)]),
             .opb(ALU_opb_in[SEL(64, 2)]),
             .func(ALU_func_in),

             // Output
             .result(ALU_result[SEL(64, 2)])
            );

	BRcond BRcond2 (// Inputs
							.opa(BRcond_opa_in),
							.func(BRcond_func_in),

							// Outputs
							.cond(BRcond_result)
							);

	MULT MULT2 (// Inputs
							.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier_in),
							.mcand(MULT_mcand_in),
							.start(MULT_start_in),
							.product(MULT_product),
							.done(MULT_done),
							.rs_IR_in(),
							.npc_in(),
							.rob_idx_in(),
							.EX_en_in(),
							.rs_IR_out(),
							.npc_out(),
							.rob_idx_out(),
							.EX_en_out()
							);
`endif


endmodule // module ex_stage

