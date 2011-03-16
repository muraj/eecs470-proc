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
module MULT(clk, reset, mplier, mcand, start, product, done);

  input clk, reset, start;
  input [63:0] mcand, mplier;

  output [63:0] product;
  output done;

  wire [63:0] mcand_out, mplier_out;
  wire [(7*64)-1:0] internal_products, internal_mcands, internal_mpliers;
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
     .done({done,internal_dones})
    );

endmodule // MULT

module mult_stage(clk, reset, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done);

  input clk, reset, start;
  input [63:0] product_in, mplier_in, mcand_in;

  output done;
  output [63:0] product_out, mplier_out, mcand_out;

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
    prod_in_reg      <= #1 product_in;
    partial_prod_reg <= #1 partial_product;
    mplier_out       <= #1 next_mplier;
    mcand_out        <= #1 next_mcand;
  end

  always @(posedge clk)
  begin
    if(reset)
      done <= #1 1'b0;
    else
      done <= #1 start;
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
								cdb_tag_out, cdb_valid_out, cdb_value_out,
								rob_idx_out, branch_NT, branch_target_ADDR
								
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
	output reg	[`SCALAR-1:0] branch_NT;
	output reg	[64*`SCALAR-1:0] branch_target_ADDR;

	reg	[`PRF_IDX*`SCALAR-1:0] next_cdb_tag_out;
	reg	[`SCALAR-1:0] next_cdb_valid_out;
	reg	[64*`SCALAR-1:0] next_cdb_value_out;
	reg	[`ROB_IDX*`SCALAR-1:0] next_rob_idx_out;
	reg	[`SCALAR-1:0] next_branch_NT;
	reg	[64*`SCALAR-1:0] next_branch_target_ADDR;

	reg [2*`SCALAR-1:0] ALU_opa_select;
	reg [2*`SCALAR-1:0] ALU_opb_select;
	reg [64*`SCALAR-1:0] ALU_opa;
	reg [64*`SCALAR-1:0] ALU_opb;
	wire [64*`SCALAR-1:0] MULT_opa = ALU_opa;
	wire [64*`SCALAR-1:0] MULT_opb = ALU_opb;

   // set up possible immediates:
   //   mem_disp: sign-extended 16-bit immediate for memory format
   //   br_disp: sign-extended 21-bit immediate * 4 for branch displacement
   //   alu_imm: zero-extended 8-bit immediate for ALU ops
  wire [64*`SCALAR-1:0] mem_disp;
  wire [64*`SCALAR-1:0] br_disp;
  wire [64*`SCALAR-1:0] alu_imm;

	`ifdef SUPERSCALAR
  assign mem_disp	= { {48{rs_IR[47]}}, rs_IR[47:32], {48{rs_IR[15]}}, rs_IR[15:0]};
  assign br_disp	= { {41{rs_IR[52]}}, rs_IR[52:32], 2'b00, {41{rs_IR[20]}}, rs_IR[20:0], 2'b00};
  assign alu_imm	= { 56'b0, rs_IR[52:45], 56'b0, rs_IR[20:13]};
	`else
  assign mem_disp	= { {48{rs_IR[15]}}, rs_IR[15:0] };
  assign br_disp	= { {41{rs_IR[20]}}, rs_IR[20:0], 2'b00 };
  assign alu_imm	= { 56'b0, rs_IR[20:13] };
	`endif


 // `define SEL(WIDTH, WHICH) WIDTH*(WHICH)-1:WIDTH*(WHICH - 1) // defined in sys_def.vh


	// All combinational logics go here
	always @*
	begin
		ALU_opa_select[1:0] = 0;
		ALU_opb_select[1:0] = 0;

		case({rs_IR[31:29], 3'b0})
			6'h10: 	
				begin
					ALU_opa_select[1:0] = `ALU_OPA_IS_REGA;
					ALU_opb_select[1:0] = rs_IR[12] ? `ALU_OPB_IS_ALU_IMM : `ALU_OPB_IS_REGB;
				end
			6'h18:
				case(rs_IR[31:26])
					`JSR_GRP:	
						begin
							ALU_opa_select[1:0] = `ALU_OPA_IS_NOT3;
							ALU_opb_select[1:0] = `ALU_OPB_IS_REGB;
						end
				endcase
			6'h08, 6'h20, 6'h28:	
				begin
					ALU_opa_select[1:0] = `ALU_OPA_IS_MEM_DISP;
					ALU_opb_select[1:0] = `ALU_OPB_IS_REGB;
				end
			6'h30, 6'h38: 
				begin
					ALU_opa_select[1:0] = `ALU_OPA_IS_NPC;
					ALU_opb_select[1:0] = `ALU_OPB_IS_BR_DISP;
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
		ALU_opa_select[3:2] = 0;
		ALU_opb_select[3:2] = 0;

		case({rs_IR[63:61], 3'b0})
			6'h10: 	
				begin
					ALU_opa_select[3:2] = `ALU_OPA_IS_REGA;
					ALU_opb_select[3:2] = rs_IR[44] ? `ALU_OPB_IS_ALU_IMM : `ALU_OPB_IS_REGB;
				end
			6'h18:
				case(rs_IR[63:58])
					`JSR_GRP:	
						begin
							ALU_opa_select[3:2] = `ALU_OPA_IS_NOT3;
							ALU_opb_select[3:2] = `ALU_OPB_IS_REGB;
						end
				endcase
			6'h08, 6'h20, 6'h28:	
				begin
					ALU_opa_select[3:2] = `ALU_OPA_IS_MEM_DISP;
					ALU_opb_select[3:2] = `ALU_OPB_IS_REGB;
				end
			6'h30, 6'h38: 
				begin
					ALU_opa_select[3:2] = `ALU_OPA_IS_NPC;
					ALU_opb_select[3:2] = `ALU_OPB_IS_BR_DISP;
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

	// All sequential elements go here
	always @(posedge clk)
	begin
		if(reset) begin
			cdb_tag_out					<= `SD {`PRE_IDX*`SCALAR{1'b0}};
			cdb_valid_out				<= `SD {`SCALAR{1'b0}};
			cdb_value_out				<= `SD {64*`SCALAR{1'b0}};
			rob_idx_out					<= `SD {`ROB_IDX*`SCALAR{1'b0}};
			branch_NT						<= `SD {`SCALAR{1'b0}};
			branch_target_ADDR	<= `SD {64*`SCALAR{1'b0}};
		end
		else begin
			cdb_tag_out					<= `SD next_cdb_tag_out;
			cdb_valid_out				<= `SD next_cdb_valid_out;
			cdb_value_out				<= `SD next_cdb_value_out;
			rob_idx_out					<= `SD next_rob_idx_out;
			branch_NT						<= `SD next_branch_NT;
			branch_target_ADDR	<= `SD next_branch_target_ADDR;
		end
	end



   //
   // instantiate the Functional Units 
   //
	MEM_CONT MEM_CONT0 ();

  ALU ALU0 (// Inputs
             .opa(ALU_opa[SEL(64, 1)]),
             .opb(ALU_opb[SEL(64, 1)]),
             .func(ALU_func),

             // Output
             .result(ALU_result[SEL(64, 1)])
            );

	BRcond BRcond0 (// Inputs
							.opa(BRcond_opa),
							.func(BRcond_func),

							// Outputs
							.cond(BRcond_result)
							);

	MULT MULT0 (// Inputs
							.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier),
							.mcand(MULT_mcand),
							.start(MULT_start),
							.product(MULT_product),
							.done(MULT_done)
							);

`ifdef SUPERSCALAR
  ALU ALU1 (// Inputs
             .opa(ALU_opa[SEL(64, 2)]),
             .opb(ALU_opb[SEL(64, 2)]),
             .func(ALU_func),

             // Output
             .result(ALU_result[SEL(64, 2)])
            );

	BRcond BRcond1 (// Inputs
							.opa(BRcond_opa),
							.func(BRcond_func),

							// Outputs
							.cond(BRcond_result)
							);

	MULT MULT1 (// Inputs
							.clk(clk),
							.reset(reset),
							.mplier(MULT_mplier),
							.mcand(MULT_mcand),
							.start(MULT_start),
							.product(MULT_product),
							.done(MULT_done)
							);
`endif


endmodule // module ex_stage

