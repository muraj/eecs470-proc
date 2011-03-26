
//                                                                     //
//   Modulename :  oo_pipeline.v                                       //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline.                                //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module oo_pipeline (// Inputs
                 clock,
                 reset,
                 mem2proc_response,
                 mem2proc_data,
                 mem2proc_tag,
                 
                 // Outputs
                 proc2mem_command,
                 proc2mem_addr,
                 proc2mem_data,

                 pipeline_completed_insts,
                 pipeline_error_status,
                 pipeline_commit_wr_data,
                 pipeline_commit_wr_idx,
                 pipeline_commit_wr_en,
                 pipeline_commit_NPC,
                 pipeline_commit_IR,


                 // testing hooks (these must be exported so we can test
                 // the synthesized version) data is tested by looking at
                 // the final values in memory
                 if_NPC_out,
                 if_IR_out,
                 if_valid_inst_out,
                 if_id_NPC,
                 if_id_IR,
                 if_id_valid_inst,
                 id_dp_NPC,
                 id_dp_IR,
                 id_dp_valid_inst,
								 ex_cdb_NPC, 
								 ex_cdb_IR, 
								 ex_cdb_valid_inst,
								 ex_cdb_ALU_NPC, 
								 ex_cdb_ALU_IR, 
								 ex_cdb_ALU_valid_inst,
								 ex_cdb_MULT_NPC, 
								 ex_cdb_MULT_IR, 
								 ex_cdb_MULT_valid_inst,
								 ex_cdb_MEM_NPC, 
								 ex_cdb_MEM_IR, 
								 ex_cdb_MEM_valid_inst
                );

  input         clock;             // System clock
  input         reset;             // System reset

  input  [3:0]  mem2proc_response; // Tag from memory about current request
  input  [63:0] mem2proc_data;     // Data coming back from memory
  input  [3:0]  mem2proc_tag;      // Tag from memory about current reply

  output [1:0]  proc2mem_command;  // command sent to memory
  output [63:0] proc2mem_addr;     // Address sent to memory
  output [63:0] proc2mem_data;     // Data sent to memory

  output [3:0]  pipeline_completed_insts;
  output [3:0]  pipeline_error_status;
  output [5*`SCALAR-1:0]  pipeline_commit_wr_idx;
  output [64*`SCALAR-1:0] pipeline_commit_wr_data;
  output [`SCALAR-1:0]    pipeline_commit_wr_en;
  output [64*`SCALAR-1:0] pipeline_commit_NPC;
  output [32*`SCALAR-1:0] pipeline_commit_IR;

  output [64*`SCALAR-1:0] if_NPC_out;
  output [32*`SCALAR-1:0] if_IR_out;
  output [`SCALAR-1:0]    if_valid_inst_out;
  output [64*`SCALAR-1:0] if_id_NPC;
  output [32*`SCALAR-1:0] if_id_IR;
  output [`SCALAR-1:0]    if_id_valid_inst;
  output [64*`SCALAR-1:0] id_dp_NPC;
  output [32*`SCALAR-1:0] id_dp_IR;
  output [`SCALAR-1:0]    id_dp_valid_inst;

  // Pipeline register enables
  wire   if_id_enable, id_dp_enable;

  // Outputs from IF-Stage
  wire [64*`SCALAR-1:0] if_NPC_out;
  wire [32*`SCALAR-1:0] if_IR_out;
  wire [`SCALAR-1:0]    if_valid_inst_out;

  // Outputs from IF/ID Pipeline Register
  reg  [64*`SCALAR-1:0] if_id_NPC;
  reg  [32*`SCALAR-1:0] if_id_IR;
  reg  [`SCALAR-1:0 ]   if_id_valid_inst;
   
  // Outputs from ID stage
  wire [5*`SCALAR-1:0]  id_dest_reg_idx_out;
  wire [5*`SCALAR-1:0]  id_alu_func_out;
  wire [5*`SCALAR-1:0]  id_rega_idx_out;
  wire [5*`SCALAR-1:0]  id_regb_idx_out;
  wire [`SCALAR-1:0]    id_rd_mem_out;
  wire [`SCALAR-1:0]    id_wr_mem_out;
  wire [`SCALAR-1:0]    id_cond_branch_out;
  wire [`SCALAR-1:0]    id_uncond_branch_out;
  wire [`SCALAR-1:0]    id_halt_out;
  wire [`SCALAR-1:0]    id_cpuid_out;
  wire [`SCALAR-1:0]    id_illegal_out;
  wire [`SCALAR-1:0]    id_valid_inst_out;

  // Outputs from ID/DISPATCH Pipeline Register
  reg  [64*`SCALAR-1:0] id_dp_NPC;
  reg  [32*`SCALAR-1:0] id_dp_IR;
  reg  [5*`SCALAR-1:0]  id_dp_rega_idx;
  reg  [5*`SCALAR-1:0]  id_dp_regb_idx;
  reg  [5*`SCALAR-1:0]  id_dp_dest_reg_idx;
  reg  [5*`SCALAR-1:0]  id_dp_alu_func;
  reg  [`SCALAR-1:0]    id_dp_rd_mem;
  reg  [`SCALAR-1:0]    id_dp_wr_mem;
  reg  [`SCALAR-1:0]    id_dp_cond_branch;
  reg  [`SCALAR-1:0]    id_dp_uncond_branch;
  reg  [`SCALAR-1:0]    id_dp_halt;
  reg  [`SCALAR-1:0]    id_dp_illegal;
  reg  [`SCALAR-1:0]    id_dp_valid_inst;

	// Outputs from DISPATCH stage
	wire	[`LSQ_IDX*`SCALAR-1:0]	dp_LSQ_idx;
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_pdest_idx;
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_prega_idx;
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_pregb_idx;
	wire	[64*`SCALAR-1:0] 				dp_prega_value;
	wire	[64*`SCALAR-1:0] 				dp_pregb_value;
	wire	[5*`SCALAR-1:0] 				dp_ALUop;
	wire	[`SCALAR-1:0] 					dp_rd_mem;
	wire	[`SCALAR-1:0] 					dp_wr_mem;
	wire	[32*`SCALAR-1:0] 				dp_rs_IR;
	wire	[64*`SCALAR-1:0] 				dp_npc;
	wire	[`ROB_IDX*`SCALAR-1:0] 	dp_rob_idx;
	wire	[`SCALAR-1:0] 					dp_en_out;

	// Outputs from DISPATCH/EX Pipeline Register
	reg [`LSQ_IDX*`SCALAR-1:0]	dp_ex_LSQ_idx;
	reg	[`PRF_IDX*`SCALAR-1:0]	dp_ex_pdest_idx;
	reg	[64*`SCALAR-1:0] 				dp_ex_prega_value;
	reg	[64*`SCALAR-1:0] 				dp_ex_pregb_value;
	reg	[5*`SCALAR-1:0] 				dp_ex_ALUop;
	reg	[`SCALAR-1:0] 					dp_ex_rd_mem;
	reg	[`SCALAR-1:0] 					dp_ex_wr_mem;
	reg	[32*`SCALAR-1:0] 				dp_ex_rs_IR;
	reg	[64*`SCALAR-1:0] 				dp_ex_npc;
	reg	[`ROB_IDX*`SCALAR-1:0] 	dp_ex_rob_idx;
	reg	[`SCALAR-1:0] 					dp_ex_EX_en;

		// only for DEBUGGING
	output [64*`SCALAR-1:0]				ex_cdb_NPC;
	output [32*`SCALAR-1:0]				ex_cdb_IR;
	output [`SCALAR-1:0]					ex_cdb_valid_inst;
	output [64*`SCALAR-1:0]				ex_cdb_ALU_NPC; 	
	output [32*`SCALAR-1:0]				ex_cdb_ALU_IR; 
	output [`SCALAR-1:0]					ex_cdb_ALU_valid_inst;
	output [64*`SCALAR-1:0]				ex_cdb_MULT_NPC; 		
	output [32*`SCALAR-1:0]				ex_cdb_MULT_IR; 		
	output [`SCALAR-1:0]					ex_cdb_MULT_valid_inst;
	output [64*`SCALAR-1:0]				ex_cdb_MEM_NPC; 			
	output [32*`SCALAR-1:0]				ex_cdb_MEM_IR; 		
	output [`SCALAR-1:0]					ex_cdb_MEM_valid_inst;

   
  // CDB FIXME
  wire [`SCALAR*`PRF_IDX-1:0] cdb_tag = 0;
  wire [`SCALAR*64-1:0]       cdb_data = 0;
  wire [`SCALAR-1:0]          cdb_valid = 0;

  // EX wires
	wire [`PRF_IDX*`SCALAR-1:0]	ex_cdb_tag_out;
	wire [`SCALAR-1:0] 					ex_cdb_valid_out;
	wire [64*`SCALAR-1:0] 			ex_cdb_value_out;
	wire [`SCALAR-1:0] 					ex_mem_value_valid_out;
	wire [`ROB_IDX*`SCALAR-1:0]	ex_rob_idx_out;
	wire [`SCALAR-1:0] 					ex_branch_NT_out;
	wire [`SCALAR-1:0]					ex_ALU_free;
	wire [`SCALAR-1:0]					ex_MULT_free;

  // RAT wires
  wire  [`SCALAR*`PRF_IDX-1:0] rat_prega_idx;
  wire  [`SCALAR*`PRF_IDX-1:0] rat_pregb_idx;
  wire  [`SCALAR*`PRF_IDX-1:0] rat_pdest_idx;

  // PRF
  wire  [`SCALAR-1:0]  prf_valid_prega;
  wire  [`SCALAR-1:0]  prf_valid_pregb;

  // Reservation Station wires
  wire  [`SCALAR-1:0]  rs_stall;

  // Memory interface/arbiter wires
  wire [63:0] proc2Dmem_addr, proc2Imem_addr;
  wire [1:0]  proc2Dmem_command, proc2Imem_command;
  wire [3:0]  Imem2proc_response, Dmem2proc_response;

  // Icache wires
  wire [63:0] cachemem_data;
  wire        cachemem_valid;
  wire  [6:0] Icache_rd_idx;
  wire [21:0] Icache_rd_tag;
  wire  [6:0] Icache_wr_idx;
  wire [21:0] Icache_wr_tag;
  wire        Icache_wr_en;
  wire [63:0] Icache_data_out, proc2Icache_addr;
  wire        Icache_valid_out;

	// Added declarations
  wire [`SCALAR-1:0] stall_id;
  wire rob_mispredict, bp_taken;
  wire [63:0] rob_target_pc, bp_pc;
  wire [`SCALAR-1:0] id_dp_isbranch;

  // For ROB
  wire [`SCALAR*`ROB_IDX-1:0] rob_idx_out;
  wire [`SCALAR*64-1:0]       rob_commit_npc_out;
  wire [`SCALAR*`ARF_IDX-1:0] rob_commit_dest_idx;
  wire [`SCALAR*`PRF_IDX-1:0] rob_commit_pdest_idx;
  wire [64*`SCALAR-1:0]       rob_commit_wr_data;
  wire [`SCALAR-1:0]          rob_valid_out;
  wire [64*`SCALAR-1:0]       rob_commit_NPC;
  wire [32*`SCALAR-1:0]       rob_commit_IR;

  // From the original version
  assign pipeline_completed_insts = rob_valid_out[0] + rob_valid_out[1];
  // FIXME
  assign pipeline_error_status = 
    id_dp_illegal ? `HALTED_ON_ILLEGAL
                   : (id_dp_halt ? `HALTED_ON_HALT
                                 : `NO_ERROR);

  assign pipeline_commit_wr_idx = rob_commit_pdest_idx;
  assign pipeline_commit_wr_data = rob_commit_wr_data;
  assign pipeline_commit_wr_en[0] = rob_commit_pdest_idx[`SEL(`PRF_IDX,1)] != `ZERO_REG;
  `ifdef SUPERSCALAR
  assign pipeline_commit_wr_en[1] = rob_commit_pdest_idx[`SEL(`PRF_IDX,2)] != `ZERO_REG;
  `endif
  assign pipeline_commit_NPC = rob_commit_npc_out;

  assign proc2Dmem_command = `BUS_NONE;     //FIXME

  assign proc2mem_command =
           (proc2Dmem_command==`BUS_NONE)?proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr =
           (proc2Dmem_command==`BUS_NONE)?proc2Imem_addr:proc2Dmem_addr;
  assign Dmem2proc_response = 
      (proc2Dmem_command==`BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response =
      (proc2Dmem_command==`BUS_NONE) ? mem2proc_response : 0;


  // Actual cache (data and tag RAMs)
  cachemem128x64 cachememory (// inputs
                              .clock(clock),
                              .reset(reset),
                              .wr1_en(Icache_wr_en),
                              .wr1_idx(Icache_wr_idx),
                              .wr1_tag(Icache_wr_tag),
                              .wr1_data(mem2proc_data),
                              
                              .rd1_idx(Icache_rd_idx),
                              .rd1_tag(Icache_rd_tag),

                              // outputs
                              .rd1_data(cachemem_data),
                              .rd1_valid(cachemem_valid)
                             );

  // Cache controller
  icache icache_0(// inputs 
                  .clock(clock),
                  .reset(reset),

                  .Imem2proc_response(Imem2proc_response),
                  .Imem2proc_data(mem2proc_data),
                  .Imem2proc_tag(mem2proc_tag),

                  .proc2Icache_addr(proc2Icache_addr),
                  .cachemem_data(cachemem_data),
                  .cachemem_valid(cachemem_valid),

                   // outputs
                  .proc2Imem_command(proc2Imem_command),
                  .proc2Imem_addr(proc2Imem_addr),

                  .Icache_data_out(Icache_data_out),
                  .Icache_valid_out(Icache_valid_out),
                  .current_index(Icache_rd_idx),
                  .current_tag(Icache_rd_tag),
                  .last_index(Icache_wr_idx),
                  .last_tag(Icache_wr_tag),
                  .data_write_enable(Icache_wr_en)
                 );


  //////////////////////////////////////////////////
  //                                              //
  //                  IF-Stage                    //
  //                                              //
  //////////////////////////////////////////////////

	// should be removed
	assign bp_taken = 0;
	assign bp_pc = 0;

  if_stage if_stage_0 (// Inputs
                       .clock (clock),
                       .reset (reset),
                       .stall (!if_id_enable),
                       .rob_mispredict(rob_mispredict),
                       .rob_target_pc(rob_target_pc),
                       .id_bp_taken(bp_taken),
                       .id_bp_pc(bp_pc),
                       .Imem2proc_data(Icache_data_out),
                       .Imem_valid(Icache_valid_out),
                       
                       // Outputs
                       .if_NPC_out(if_NPC_out), 
                       .if_IR_out(if_IR_out),
                       .proc2Imem_addr(proc2Icache_addr),
                       .if_valid_inst_out(if_valid_inst_out)
                      );


  //////////////////////////////////////////////////
  //                                              //
  //            IF/ID Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign if_id_enable = ~|stall_id;

  always @(posedge clock)
  begin
    if(reset)
    begin
      if_id_NPC        <= `SD 0;
      if_id_IR         <= `SD `NOOP_INST;
      if_id_valid_inst <= `SD `FALSE;
    end // if (reset)
    else if (if_id_enable)
      begin
        if_id_NPC        <= `SD if_NPC_out;
        if_id_IR         <= `SD if_IR_out;
        if_id_valid_inst <= `SD if_valid_inst_out;
      end // if (if_id_enable)
  end // always

   
  //////////////////////////////////////////////////
  //                                              //
  //                  ID-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  id_stage id_stage_0 (// Inputs
                       .clock     (clock),
                       .reset   (reset),
                       .if_id_IR   (if_id_IR),
                       .if_id_valid_inst(if_id_valid_inst),
                       
                       // Outputs
                       .id_ra_idx_out(id_rega_idx_out),
                       .id_rb_idx_out(id_regb_idx_out),
                       .id_dest_reg_idx_out(id_dest_reg_idx_out),
                       .id_alu_func_out(id_alu_func_out),
                       .id_rd_mem_out(id_rd_mem_out),
                       .id_wr_mem_out(id_wr_mem_out),
                       .id_cond_branch_out(id_cond_branch_out),
                       .id_uncond_branch_out(id_uncond_branch_out),
                       .id_halt_out(id_halt_out),
                       .id_illegal_out(id_illegal_out),
                       .id_valid_inst_out(id_valid_inst_out)
                      );

  //////////////////////////////////////////////////
  //                                              //
  //            ID/DP Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////

	// needs to be removed
	assign rob_full = 0;
	assign rob_full_almost = 0;



    // structural hazard
	assign stall_id[0] = &rs_stall | rob_full;
	`ifdef SUPERSCALAR
	assign stall_id[1] = ^rs_stall | rob_full_almost;
	`endif
    
  // isbranch generation
  assign id_dp_isbranch = id_dp_cond_branch | id_dp_uncond_branch;

  assign id_dp_enable = !stall_id;

  always @(posedge clock)
  begin
    if (reset)
    begin
      id_dp_NPC           <= `SD 0;
      id_dp_IR            <= `SD `NOOP_INST;
      id_dp_rega_idx      <= `SD {`ZERO_REG, `ZERO_REG};
      id_dp_regb_idx      <= `SD {`ZERO_REG, `ZERO_REG};
      id_dp_dest_reg_idx  <= `SD {`ZERO_REG, `ZERO_REG};
      id_dp_alu_func      <= `SD 0;
      id_dp_rd_mem        <= `SD 0;
      id_dp_wr_mem        <= `SD 0;
      id_dp_cond_branch   <= `SD 0;
      id_dp_uncond_branch <= `SD 0;
      id_dp_halt          <= `SD 0;
      id_dp_illegal       <= `SD 0;
      id_dp_valid_inst    <= `SD 0;
    end // if (reset)
    else
    begin
      if (id_dp_enable)
      begin
        id_dp_NPC           <= `SD if_id_NPC;
        id_dp_IR            <= `SD if_id_IR;
        id_dp_rega_idx      <= `SD id_rega_idx_out;
        id_dp_regb_idx      <= `SD id_regb_idx_out;
        id_dp_dest_reg_idx  <= `SD id_dest_reg_idx_out;
        id_dp_alu_func      <= `SD id_alu_func_out;
        id_dp_rd_mem        <= `SD id_rd_mem_out;
        id_dp_wr_mem        <= `SD id_wr_mem_out;
        id_dp_cond_branch   <= `SD id_cond_branch_out;
        id_dp_uncond_branch <= `SD id_uncond_branch_out;
        id_dp_halt          <= `SD id_halt_out;
        id_dp_illegal       <= `SD id_illegal_out;
        id_dp_valid_inst    <= `SD id_valid_inst_out;
      end else if (stall_id[1]) begin
			// need to move ir2 to ir1
        id_dp_NPC           [`SEL(64,1)] <= `SD id_dp_NPC					   [`SEL(64,2)];
        id_dp_IR            [`SEL(32,1)] <= `SD id_dp_IR					   [`SEL(32,2)];
        id_dp_rega_idx      [`SEL(5,1)]  <= `SD id_dp_rega_idx		   [`SEL(5,2)];
        id_dp_regb_idx      [`SEL(5,1)]  <= `SD id_dp_regb_idx       [`SEL(5,2)];
        id_dp_dest_reg_idx  [`SEL(5,1)]  <= `SD id_dp_dest_reg_idx   [`SEL(5,2)];
        id_dp_alu_func      [`SEL(5,1)]  <= `SD id_dp_alu_func		   [`SEL(5,2)];
        id_dp_rd_mem        [`SEL(1,1)]  <= `SD id_dp_rd_mem			   [`SEL(1,2)];
        id_dp_wr_mem        [`SEL(1,1)]  <= `SD id_dp_wr_mem  		   [`SEL(1,2)];
        id_dp_cond_branch   [`SEL(1,1)]  <= `SD id_dp_cond_branch    [`SEL(1,2)];
        id_dp_uncond_branch [`SEL(1,1)]  <= `SD id_dp_uncond_branch  [`SEL(1,2)];
        id_dp_halt          [`SEL(1,1)]  <= `SD id_dp_halt           [`SEL(1,2)];
        id_dp_illegal       [`SEL(1,1)]  <= `SD id_dp_illegal        [`SEL(1,2)];
        id_dp_valid_inst    [`SEL(1,1)]  <= `SD id_dp_valid_inst     [`SEL(1,2)];
			// mark ir2 as invalid
        id_dp_valid_inst    [`SEL(1,2)]  <= `SD 1'b0;  

			end
    end // else: !if(reset)
  end // always

  //////////////////////////////////////////////////
  //                                              //
  //                  DP-Stage                    //
  //                                              //
  //////////////////////////////////////////////////

  rat rat0 (.clk(clock), .reset(reset), .flush(rob_mispredict),
						// ARF inputs
						.rega_idx_in(id_dp_rega_idx), .regb_idx_in(id_dp_regb_idx), 
						.dest_idx_in(id_dp_dest_reg_idx), .retire_dest_idx_in(rob_commit_dest_idx),
						// PRF i/o
						.prega_idx_out(rat_prega_idx), .prega_valid_out(prf_valid_prega),
            .pregb_idx_out(rat_pregb_idx), .pregb_valid_out(prf_valid_pregb),
            //CDB input
            .cdb_en(cdb_valid), .cdb_tag(cdb_tag), //FIXME
						.pdest_idx_out(rat_pdest_idx), .retire_pdest_idx_in(rob_commit_pdest_idx),
						// enable signals for rat and rrat
						.issue(id_dp_valid_inst), .retire(rob_valid_out)
				 	 );

  rob rob0 (.clk(clock), .reset(reset),
						.full(rob_full), .full_almost(rob_full_almost),
						// Dispatch request
						.din1_req(id_dp_valid_inst[0]), .din2_req(id_dp_valid_inst[1]),
						// Update request
						.dup1_req(1'b0), .dup2_req(1'b0),
						.rob_idx_in1({`ROB_IDX{1'b0}}), .rob_idx_in2({`ROB_IDX{1'b0}}),//FIXME
						// Inputs @ dispatch
						.ir_in1(id_dp_IR[`SEL(32,1)]), .ir_in2(id_dp_IR[`SEL(32,2)]), 
            .npc_in1(id_dp_NPC[`SEL(64,1)]), .npc_in2(id_dp_NPC[`SEL(64,2)]),
            .pdest_in1(rat_pdest_idx[`SEL(`PRF_IDX,1)]), .pdest_in2(rat_pdest_idx[`SEL(`PRF_IDX,2)]), 
            .adest_in1(id_dp_dest_reg_idx[`SEL(5,1)]), .adest_in2(id_dp_dest_reg_idx[`SEL(5,2)]),
						// Branch @ dispatch
            .ba_pd_in1(64'b0), .ba_pd_in2(64'b0), //FIXME 
            .bt_pd_in1(1'b0), .bt_pd_in2(1'b0), //FIXME
            .isbranch_in1(id_dp_isbranch[0]), .isbranch_in2(id_dp_isbranch[1]),
						// Real branch results
						.ba_ex_in1(64'b0), .ba_ex_in2(64'b0), .bt_ex_in1(1'b0), .bt_ex_in2(1'b0),//FIXME
						// For retire
            .dout1_valid(rob_valid_out[0]), .dout2_valid(rob_valid_out[1]), 
						.rob_idx_out1(rob_idx_out[`SEL(`ROB_IDX,1)]), .rob_idx_out2(rob_idx_out[`SEL(`ROB_IDX,2)]),
						.ir_out1(rob_commit_IR[`SEL(32,1)]), .ir_out2(rob_commit_IR[`SEL(32,1)]), 
            .npc_out1(rob_commit_npc_out[`SEL(64,1)]), .npc_out2(rob_commit_npc_out[`SEL(64,2)]),
            .pdest_out1(rob_commit_pdest_idx[`SEL(`PRF_IDX,1)]), .pdest_out2(rob_commit_pdest_idx[`SEL(`PRF_IDX,2)]),
						.adest_out1(rob_commit_dest_idx[`SEL(`ARF_IDX,1)]), .adest_out2(rob_commit_dest_idx[`SEL(`ARF_IDX,1)]),
						// Branch Miss
						.branch_miss(rob_mispredict), .ba_out(rob_target_pc)
						);

  regfile #(.IDX_WIDTH(`PRF_IDX), .DATA_WIDTH(64), .ZERO_REGISTER(`ZERO_PRF))
  PRF(.rda_idx(dp_prega_idx), .rda_out(dp_prega_value),
      .rdb_idx(dp_pregb_idx), .rdb_out(dp_pregb_value),
      .reg_vals_out(),
      .wr_idx(cdb_tag), .wr_data(cdb_data),
      .wr_en(cdb_valid), .wr_clk(clock), .reset(reset),
      .copy(1'b0), .reg_vals_in({`PRF_SZ*64{1'b0}})
      );

  SUPER_RS rs0 (.clk(clock), .reset(reset),
                //INPUTS
                .inst_valid(id_dp_valid_inst), .prega_idx(rat_prega_idx), .pregb_idx(rat_pregb_idx), .pdest_idx(rat_pdest_idx), .prega_valid(prf_valid_prega), .pregb_valid(prf_valid_pregb), //RAT
                .ALUop(id_dp_alu_func), .rd_mem(id_dp_rd_mem), .wr_mem(id_dp_wr_mem), .rs_IR(id_dp_IR), . npc(id_dp_NPC), .cond_branch(id_dp_cond_branch), .uncond_branch(id_dp_uncond_branch),     //Issue Stage
                .multfu_free(ex_MULT_free), .exfu_free(ex_ALU_free), .memfu_free(2'b11), .cdb_valid(cdb_valid), .cdb_tag(cdb_tag), .entry_flush({`RS_SZ{0}}),   //Pipeline communication
//                .multfu_free(2'b0), .exfu_free(2'b0), .memfu_free(2'b11), .cdb_valid(cdb_valid), .cdb_tag(cdb_tag), .entry_flush({`RS_SZ{0}}),   //Pipeline communication - Disable ex_stage
                .rob_idx(rob_idx_out), //ROB

                //OUTPUT
                .rs_stall(rs_stall), .rs_rdy(), //Hazard detect
                .pdest_idx_out(dp_pdest_idx), .prega_idx_out(dp_prega_idx), .pregb_idx_out(dp_pregb_idx), 
								.ALUop_out(dp_ALUop), .rd_mem_out(dp_rd_mem), //FU
                .wr_mem_out(dp_wr_mem), .rs_IR_out(dp_rs_IR), .npc_out(dp_npc), 
								.rob_idx_out(dp_rob_idx), .en_out(dp_en_out), //FU
                .rs_idx_out() //ROB
         			 );

  //////////////////////////////////////////////////
  //                                              //
  //            DP/EX Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////

  always @(posedge clock)
  begin
    if (reset)
    begin
			dp_ex_LSQ_idx			<= `SD 0;
			dp_ex_pdest_idx		<= `SD {`SCALAR{`ZERO_REG}};
			dp_ex_prega_value	<= `SD 0;
			dp_ex_pregb_value	<= `SD 0;
			dp_ex_ALUop				<= `SD 0;
			dp_ex_rd_mem			<= `SD 0;
			dp_ex_wr_mem			<= `SD 0;
			dp_ex_rs_IR				<= `SD {`SCALAR{`NOOP_INST}};
			dp_ex_npc					<= `SD 0;
			dp_ex_rob_idx			<= `SD 0;
			dp_ex_EX_en				<= `SD 0;
    end // if (reset)
    else begin
			dp_ex_LSQ_idx			<= `SD 0;	// FIXME
			dp_ex_pdest_idx		<= `SD dp_pdest_idx;
			dp_ex_prega_value	<= `SD dp_prega_value;
			dp_ex_pregb_value	<= `SD dp_pregb_value;
			dp_ex_ALUop				<= `SD dp_ALUop;
			dp_ex_rd_mem			<= `SD dp_rd_mem;
			dp_ex_wr_mem			<= `SD dp_wr_mem;
			dp_ex_rs_IR				<= `SD dp_rs_IR;
			dp_ex_npc					<= `SD dp_npc;
			dp_ex_rob_idx			<= `SD dp_rob_idx;
			dp_ex_EX_en				<= `SD dp_en_out;
    end // else: !if(reset)
  end // always

  //////////////////////////////////////////////////
  //                                              //
  //                  EX-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
ex_stage ex_stage0 (.clk(clock), .reset(reset),
										// Inputs
										.LSQ_idx(dp_ex_LSQ_idx), .pdest_idx(dp_ex_pdest_idx), 
										.prega_value(dp_ex_prega_value), .pregb_value(dp_ex_pregb_value),  
										.ALUop(dp_ex_ALUop), .rd_mem(dp_ex_rd_mem), .wr_mem(dp_ex_wr_mem), 
										.rs_IR(dp_ex_rs_IR), .npc(dp_ex_npc), .rob_idx(dp_ex_rob_idx), .EX_en(dp_ex_EX_en), 
		
										// Inputs (from LSQ)
										.LSQ_rob_idx(0), .LSQ_pdest_idx(0), .LSQ_mem_value(0), .LSQ_done(0), .LSQ_rd_mem(0), .LSQ_wr_mem(0), 
		
										// Outputs
										.cdb_tag_out(ex_cdb_tag_out), .cdb_valid_out(ex_cdb_valid_out), .cdb_value_out(ex_cdb_value_out),				 	// to CDB
										.mem_value_valid_out(ex_mem_value_valid_out), .rob_idx_out(ex_rob_idx_out), .branch_NT_out(ex_branch_NT_out), 	// to ROB
										.ALU_free(ex_ALU_free), .MULT_free(ex_MULT_free),  																// to RS
		
										// Outputs (to LSQ)
										.EX_LSQ_idx(), .EX_MEM_ADDR(), .EX_MEM_reg_value(),

										.ex_cdb_NPC(ex_cdb_NPC), .ex_cdb_IR(ex_cdb_IR), .ex_cdb_valid_inst(ex_cdb_valid_inst),
										.ex_cdb_ALU_NPC(ex_cdb_ALU_NPC), .ex_cdb_ALU_IR(ex_cdb_ALU_IR), .ex_cdb_ALU_valid_inst(ex_cdb_ALU_valid_inst),
										.ex_cdb_MULT_NPC(ex_cdb_MULT_NPC), .ex_cdb_MULT_IR(ex_cdb_MULT_IR), .ex_cdb_MULT_valid_inst(ex_cdb_MULT_valid_inst),
										.ex_cdb_MEM_NPC(ex_cdb_MEM_NPC), .ex_cdb_MEM_IR(ex_cdb_MEM_IR), .ex_cdb_MEM_valid_inst(ex_cdb_MEM_valid_inst)
		               );
/*
// Should connect the below signals to EX-Stage

// Inputs from the LSQ
	input [`ROB_IDX*`SCALAR-1:0]	LSQ_rob_idx;
	input [`PRF_IDX*`SCALAR-1:0]	LSQ_pdest_idx;
	input [64*`SCALAR-1:0]				LSQ_mem_value;
	input [`SCALAR-1:0]						LSQ_done;
	input [`SCALAR-1:0]						LSQ_rd_mem;
	input [`SCALAR-1:0]						LSQ_wr_mem;

// Outputs to the LSQ
	output [`LSQ_IDX*`SCALAR-1:0]	EX_LSQ_idx;
	output [64*`SCALAR-1:0]				EX_MEM_ADDR;
	output [64*`SCALAR-1:0]				EX_MEM_reg_value;

*/

endmodule  // module verisimple

