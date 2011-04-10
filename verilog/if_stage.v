/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  if_stage.v                                          //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       // 
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module if_stage(// Inputs
                clock,
                reset,
								stall,
                rob_mispredict,
								rob_target_pc,
								id_bp_taken,
								id_bp_pc,
                Imem2proc_data,
                Imem_valid,
                    
                // Outputs
                if_NPC_out,        // PC+4 of fetched instructions
                if_IR_out,         // fetched instruction out
                proc2Imem_addr,
                if_valid_inst_out  // when low, instruction is garbage
               );

  input         clock;              // system clock
  input         reset;              // system reset
  input					stall;
  input         rob_mispredict; 		// branch mispredict signal
  input  [63:0] rob_target_pc; 		  // target pc: use if rob_mispredict is TRUE
  input  [`SCALAR-1:0]       id_bp_taken; 				// branch prediction result
  input  [`SCALAR*64-1:0] id_bp_pc;			 		  // use if predicted branch is taken
  input  [63:0] Imem2proc_data;     // Data coming back from instruction-memory
  input         Imem_valid;

  output [63:0] proc2Imem_addr;     	// Address sent to Instruction memory
  output [64*`SCALAR-1:0] if_NPC_out; // PC of instruction after fetched (PC+8).
  output [32*`SCALAR-1:0] if_IR_out;  // fetched instruction
  output [`SCALAR-1:0]    if_valid_inst_out;

  reg    [63:0] PC_reg;               // PC we are currently fetching

  wire   [63:0] PC_plus_4;
  wire   [63:0] PC_plus_8;
  wire   [63:0] next_PC;
  wire          PC_enable;
   
  assign proc2Imem_addr = {PC_reg[63:3], 3'b0};

    // output two instructions at a time
  assign if_IR_out[`SEL(32,1)] = PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];
  assign if_IR_out[`SEL(32,2)] = PC_reg[2] ? `NOOP_INST : Imem2proc_data[63:32];

    // default next PC value
  assign PC_plus_4 = PC_reg + 4;
  assign PC_plus_8 = PC_reg + 8;

    // Next PC is rob_target_pc if we mispredicted branch
		// Otherwise we use the result of branch predictor
		// The default is PC+8
    // (halting is handled with the enable PC_enable;
  assign next_PC = (rob_mispredict)? rob_target_pc :      // Branch mispredict?
                   (id_bp_taken[0])? id_bp_pc[`SEL(64,1)] :              // Branch predicted taken
                   `ifdef SUPERSCALAR
                   ((!PC_reg[2]) & id_bp_taken[1])? id_bp_pc[`SEL(64,2)] :              // Branch predicted taken
                   `endif
                   (PC_reg[2])? PC_plus_4 : PC_plus_8;    // Branch to misaligned address

    // The take-branch signal must override stalling (otherwise it may be lost)
 // assign PC_enable = (Imem_valid & !stall) || rob_mispredict || |id_bp_taken;
 //  assign PC_enable = (Imem_valid & !stall) || rob_mispredict || (|id_bp_taken & !stall);
 		assign PC_enable = rob_mispredict | (Imem_valid & !stall);

    // Pass PC+4 and PC+8 down pipeline w/instruction
  assign if_NPC_out[`SEL(64,1)] = PC_plus_4;
  assign if_NPC_out[`SEL(64,2)] = PC_plus_8;

  assign if_valid_inst_out[`SEL(1,1)] = !rob_mispredict && Imem_valid;
  assign if_valid_inst_out[`SEL(1,2)] = !rob_mispredict && Imem_valid && !PC_reg[2] && !id_bp_taken[0];

//  assign next_ready_for_valid = (ready_for_valid | mem_wb_valid_inst) & 
//                                !if_valid_inst_out;

  // This register holds the PC value
  always @(posedge clock)
  begin
    if(reset)
      PC_reg <= `SD 0;       // initial PC value is 0
    else if(PC_enable)
      PC_reg <= `SD next_PC; // transition to next PC
  end  // always


/*
    // This FF controls the stall signal that artificially forces
    // fetch to stall until the previous instruction has completed
  always @(posedge clock)
  begin
    if (reset)
      ready_for_valid <= `SD 1;  // must start with something
    else
      ready_for_valid <= `SD next_ready_for_valid;
  end
  
*/

endmodule  // module if_stage
