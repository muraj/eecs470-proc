
module ALU (clk, reset,
						// Inputs
						prega_in, pregb_in, ALUop, pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in, 
						next_gnt, stall,	// from EX_ps
						// Outputs
						result_reg, BR_result_reg, BR_target_addr_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
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
	output reg								BR_target_addr_reg;
	output reg [`PRF_IDX-1:0]	pdest_idx_reg;
	output reg [31:0] 				IR_reg;
	output reg [63:0] 				npc_reg;
	output reg [`ROB_IDX-1:0] rob_idx_reg;
	output reg								done, done_reg, gnt_reg;

  wire [63:0]	alu_result_out;
  wire 				BR_result_out;
  reg [63:0] 	opa, opb;
  reg 				isBranch;
//	reg					uncondBranch;
	reg [63:0]	result;
	reg					BR_result;
	reg [63:0]	BR_target_addr;

  ALU_leaf	ALU_leaf0	(.opa(opa), .opb(opb), .func(ALUop), .result(alu_result_out));
  BRcond 		BRcond0		(.opa(prega_in), .func(IR_in[28:26]), .cond(BR_result_out));

  always @* begin //Small mux for reading the correct reg values
		done			= EX_en_in;
//		result		= (isBranch & !uncondBranch & !BR_result_out) ? npc_in : alu_result_out;
		result		= isBranch ? npc_in : alu_result_out;
		BR_result	= isBranch ? BR_result_out : 1'b0;
    isBranch	= 1'b0;
//		uncondBranch = 1'b0;
		BR_target_addr = 0;

    case (IR_in[31:29])
      3'b010: begin // 6'h10 (opa=REGA, opb=ALU_IMM or REGB, dest=REGC, ALUop=various)
  				     	opa = prega_in;
       					opb = IR_in[12] ? {56'b0, IR_in[20:13]} : pregb_in;
      				end
      3'b011: begin	// 6'h18 Uncond Branches (opa=NOT3, opb=REGB, dest=REGA, ALUop=AND)
        				opa = ~64'h3;
        				opb = pregb_in;
        				isBranch = 1'b1;
//								uncondBranch = 1'b1;
								BR_target_addr = alu_result_out;	// BR target addr comes from ALU
      				end
			3'b001, 3'b100, 3'b101:	begin	// 6'h08, 6'h20, 6'h28, for 'lda' instruction (opa=MEM_DISP, opb=REGB, dest=REGA, ALUop=ADD)
																opa = {{48{IR_in[15]}}, IR_in[15:0]};
																opb = pregb_in;
															end
      3'b111, 3'b110: begin // 6'h38, 6'h30 Branches (Uncond or Cond) (opa=NPC, opb=BR_DISP, dest=REGA, ALUop=ADD)
        								opa = npc_in;
        								opb = {{41{IR_in[20]}}, IR_in[20:0], 2'b00};
        								isBranch = 1'b1;
//												uncondBranch = (IR_in[31:26] == `BR_INST) | (IR_in[31:26] == `BSR_INST);
												BR_target_addr = alu_result_out;	// BR target addr comes from ALU
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
			result_reg					<= `SD 0;
			BR_result_reg				<= `SD 0;
			BR_target_addr_reg	<= `SD 0;
			pdest_idx_reg				<= `SD `ZERO_PRF;
			IR_reg							<= `SD `NOOP_INST;
			npc_reg							<= `SD 0;
			rob_idx_reg					<= `SD 0;
			done_reg						<= `SD 0;
		end 
		else if (!stall) begin
			result_reg					<= `SD result;
			BR_result_reg				<= `SD BR_result;
			BR_target_addr_reg	<= `SD BR_target_addr;
			pdest_idx_reg				<= `SD pdest_idx_in;
			IR_reg							<= `SD IR_in;
			npc_reg							<= `SD npc_in;
			rob_idx_reg					<= `SD rob_idx_in;
			done_reg						<= `SD EX_en_in;
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
