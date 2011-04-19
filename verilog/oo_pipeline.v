
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
                 dp_is_NPC,
                 dp_is_IR,
                 dp_is_valid_inst,
                 is_ex_NPC,
                 is_ex_IR,
                 is_ex_valid_inst,
								 ex_co_NPC, 
								 ex_co_IR, 
								 ex_co_valid_inst,
								 rob_retire_NPC, 
								 rob_retire_IR, 
								 rob_retire_valid_inst
                );

  input         clock;             // System clock
  input         reset;             // System reset

  input  [`NUM_MEM_TAG_BITS-1:0]  mem2proc_response; // Tag from memory about current request
  input  [63:0] mem2proc_data;     // Data coming back from memory
  input  [`NUM_MEM_TAG_BITS-1:0]  mem2proc_tag;      // Tag from memory about current reply

  output [1:0]  proc2mem_command;  // command sent to memory
  output [63:0] proc2mem_addr;     // Address sent to memory
  output [63:0] proc2mem_data;     // Data sent to memory

  output reg [3:0]  pipeline_completed_insts;
  output [3:0]  pipeline_error_status;
  output [5*`SCALAR-1:0]  pipeline_commit_wr_idx;
  output [64*`SCALAR-1:0] pipeline_commit_wr_data;
  output [`SCALAR-1:0]    pipeline_commit_wr_en;
  output [64*`SCALAR-1:0] pipeline_commit_NPC;
  output [32*`SCALAR-1:0] pipeline_commit_IR;
  wire   [64*`PRF_SZ-1:0] prf_regs;
  wire   [63:0] prf_regs_out [`PRF_SZ-1:0];
  generate
  genvar prf_reg_idx;
  for(prf_reg_idx=0; prf_reg_idx < `PRF_SZ; prf_reg_idx = prf_reg_idx + 1) begin : WB_REG_2D
    assign prf_regs_out[prf_reg_idx] = prf_regs[`SEL(64,prf_reg_idx+1)];
  end
  endgenerate

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
  reg  [`SCALAR*64-1:0] if_id_ba;
  reg  [`SCALAR-1:0]    if_id_bt;
   
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
  reg  [`SCALAR*64-1:0] id_dp_ba;
  reg  [`SCALAR-1:0]    id_dp_bt;

	// Outputs from DISPATCH stage
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_pdest_idx;
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_prega_idx;
	wire	[`PRF_IDX*`SCALAR-1:0]	dp_pregb_idx;
	wire	[64*`SCALAR-1:0] 				dp_prega_value;
	wire	[64*`SCALAR-1:0] 				dp_pregb_value;
	wire	[5*`SCALAR-1:0] 				dp_ALUop;
	wire	[`SCALAR-1:0] 					dp_rd_mem;
	wire	[`SCALAR-1:0] 					dp_wr_mem;
	output wire	[32*`SCALAR-1:0]	dp_is_IR;
	output wire	[64*`SCALAR-1:0] 	dp_is_NPC;
	wire	[`ROB_IDX*`SCALAR-1:0] 	dp_rob_idx;
  wire  [`LSQ_IDX*`SCALAR-1:0]  dp_lsq_idx;
	output wire	[`SCALAR-1:0] 		dp_is_valid_inst;

	// Outputs from DISPATCH/EX Pipeline Register
	reg	[`PRF_IDX*`SCALAR-1:0]	is_ex_pdest_idx;
	reg	[64*`SCALAR-1:0] 				is_ex_prega_value;
	reg	[64*`SCALAR-1:0] 				is_ex_pregb_value;
	reg	[5*`SCALAR-1:0] 				is_ex_ALUop;
	reg	[`SCALAR-1:0] 					is_ex_rd_mem;
	reg	[`SCALAR-1:0] 					is_ex_wr_mem;
	output reg	[32*`SCALAR-1:0] 				is_ex_IR;
	output reg	[64*`SCALAR-1:0] 				is_ex_NPC;
	output reg	[`SCALAR-1:0] 	is_ex_valid_inst;
	reg	[`ROB_IDX*`SCALAR-1:0] 	is_ex_rob_idx;
	reg	[`LSQ_IDX*`SCALAR-1:0] 	is_ex_lsq_idx;

		// only for DEBUGGING
	output [64*`SCALAR-1:0]				ex_co_NPC;
	output [32*`SCALAR-1:0]				ex_co_IR;
	output [`SCALAR-1:0]					ex_co_valid_inst;
   
  // EX wires
	wire [`PRF_IDX*`SCALAR-1:0]	ex_cdb_tag_out;
	wire [`SCALAR-1:0] 					ex_cdb_valid_out;
	wire [64*`SCALAR-1:0] 			ex_cdb_value_out;
	wire [64*`SCALAR-1:0] 			ex_cdb_branch_target_addr_out;
	wire [`SCALAR-1:0] 					ex_mem_value_valid_out;
	wire [`ROB_IDX*`SCALAR-1:0]	ex_rob_idx_out;
	wire [`SCALAR-1:0] 					ex_branch_NT_out;
	wire [`SCALAR-1:0]					ex_ALU_free;
	wire [`SCALAR-1:0]					ex_MULT_free;
	wire [`LSQ_IDX*`SCALAR-1:0] ex_lsq_idx_out;
	wire [64*`SCALAR-1:0]       ex_addr_out;
	wire [64*`SCALAR-1:0]   	  ex_regv_out;
	wire [`SCALAR-1:0]					ex_lsq_req;

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
  wire [`NUM_MEM_TAG_BITS-1:0]  Imem2proc_response, Dmem2proc_response;

  // Icache wires
  wire [63:0] cachemem_data;
  wire        cachemem_valid;
  wire  [`ICACHE_IDX_BITS-1:0] Icache_rd_idx;
  wire [`ICACHE_TAG_BITS-1:0] Icache_rd_tag;
  wire  [`ICACHE_IDX_BITS-1:0] Icache_wr_idx;
  wire [`ICACHE_TAG_BITS-1:0] Icache_wr_tag;
  wire        Icache_wr_en;
  wire [63:0] Icache_data_out, proc2Icache_addr;
  wire        Icache_valid_out;

	// Added declarations
  wire [`SCALAR-1:0] stall_id;
  wire rob_mispredict;
  wire [`SCALAR-1:0] bp_taken;
  wire [`SCALAR*64-1:0] bp_pc;
  wire [`SCALAR-1:0] id_dp_isbranch;

  // ROB Wires
  output wire [`SCALAR-1:0]    rob_retire_valid_inst;
  output wire [64*`SCALAR-1:0] rob_retire_NPC;
  output wire [32*`SCALAR-1:0] rob_retire_IR;
	wire rob_full, rob_full_almost;
  wire [`SCALAR*`ROB_IDX-1:0]  rob_idx_out;
  wire [`SCALAR*`ARF_IDX-1:0]  rob_retire_dest_idx;
  wire [`SCALAR*`PRF_IDX-1:0]  rob_retire_pdest_idx;
  wire [`SCALAR*64-1:0]				 rob_ba_out;
  wire [`SCALAR-1:0] 					 rob_bt_out;
  wire [`SCALAR-1:0] 					 rob_retire_isbranch;
	wire [`ROB_IDX-1:0] 				 rob_head;
  wire [63:0] 								 rob_target_pc;
  wire [`SCALAR-1:0]				 rob_illegal_out;
	
	// LSQ Wires
	wire [`SCALAR-1:0]					lsq_out_valid;
	wire [`ROB_IDX*`SCALAR-1:0]	lsq_rob_idx_out;
	wire [`PRF_IDX*`SCALAR-1:0]	lsq_pdest_idx_out;
	wire [64*`SCALAR-1:0]				lsq_mem_value_out;
	wire [`SCALAR-1:0]					lsq_rd_mem_out;
	wire [`SCALAR-1:0]					lsq_wr_mem_out;
	wire [`LSQ_IDX*`SCALAR-1:0] lsq_idx_out;
	wire [1:0]  lsq2dcache_command;
	wire [63:0] lsq2dcache_addr;
	wire [63:0] lsq2dcache_data;
	wire [32*`SCALAR-1:0] lsq_ir_out;
	wire [64*`SCALAR-1:0] lsq_npc_out;
	wire lsq_full, lsq_full_almost;

	// Dcache Wires
	wire [`DCACHE_TAG_BITS-1:0] dcachemem_rd_tag, dcachemem_wr_tag;
	wire [`DCACHE_IDX_BITS-1:0] dcachemem_rd_idx, dcachemem_wr_idx;
	wire [63:0] dcachemem_rd_data, dcachemem_wr_data;
	wire dcachemem_en;
	wire dcachemem_wr_en;
	wire dcachemem_rd_valid;
	wire [`NUM_MEM_TAG_BITS-1:0]	dcache2lsq_tag;
	wire [63:0]	dcache2lsq_data;
	wire [`NUM_MEM_TAG_BITS-1:0]	Dmem2proc_tag;
	wire [63:0]	Dmem2proc_data;
	wire				dcache2lsq_valid;
	wire dcache2lsq_st_received;


	always @* begin
		pipeline_completed_insts = 0;
		case (rob_illegal_out)
			2'b00:	pipeline_completed_insts = rob_retire_valid_inst[0] + rob_retire_valid_inst[1];	
			2'b01:	pipeline_completed_insts = 0 ; //rob_retire_valid_inst[0];
			2'b11:	pipeline_completed_insts = 0 ; //rob_retire_valid_inst[0];
			2'b10:	pipeline_completed_insts = rob_retire_valid_inst[0]; //+ rob_retire_valid_inst[1];
			default: pipeline_completed_insts = 0;
		endcase
	end

	wire [1:0] valid_halt;
	assign valid_halt = {(rob_retire_valid_inst[1] & (pipeline_commit_IR[`SEL(32,2)] == 32'h555)), (rob_retire_valid_inst[0] & (pipeline_commit_IR[`SEL(32,1)] == 32'h555))};
	assign pipeline_error_status =
											(valid_halt[0]) ? `HALTED_ON_HALT :
											(rob_retire_valid_inst[0] & rob_illegal_out[0]) ? `HALTED_ON_ILLEGAL :
											(valid_halt[1]) ? `HALTED_ON_HALT :
											(rob_retire_valid_inst[1] & rob_illegal_out[1]) ? `HALTED_ON_ILLEGAL : `NO_ERROR;

  assign pipeline_commit_wr_idx = rob_retire_dest_idx;
  assign pipeline_commit_IR = rob_retire_IR;
  assign pipeline_commit_wr_data[`SEL(64,1)] = prf_regs_out[rob_retire_pdest_idx[`SEL(`PRF_IDX,1)]];
  assign pipeline_commit_wr_en[0] = rob_retire_valid_inst[0] && (rob_retire_pdest_idx[`SEL(`PRF_IDX,1)] != `ZERO_PRF);
  `ifdef SUPERSCALAR
  assign pipeline_commit_wr_en[1] = rob_retire_valid_inst[1] && (rob_retire_pdest_idx[`SEL(`PRF_IDX,2)] != `ZERO_PRF);
  assign pipeline_commit_wr_data[`SEL(64,2)] = prf_regs_out[rob_retire_pdest_idx[`SEL(`PRF_IDX,2)]];
  `endif
  assign pipeline_commit_NPC = rob_retire_NPC;


  assign proc2mem_command		= (proc2Dmem_command==`BUS_NONE) ? proc2Imem_command:proc2Dmem_command;
  assign proc2mem_addr			= (proc2Dmem_command==`BUS_NONE) ? proc2Imem_addr:proc2Dmem_addr;
  assign Dmem2proc_response	= (proc2Dmem_command==`BUS_NONE) ? 0 : mem2proc_response;
  assign Imem2proc_response	= (proc2Dmem_command==`BUS_NONE) ? mem2proc_response : 0;


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

                  .stall_icache(proc2Dmem_command != `BUS_NONE),

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

  branch_predictor bp0(.clk (clock),
                       .reset(reset),
                       //** IF_STAGE **//
                       .IF_NPC(if_NPC_out),
                       .paddress(bp_pc),
                       .ptaken(bp_taken),
                       //**  ROB  **//
                       .ROB_br_en(rob_retire_isbranch & rob_retire_valid_inst),
                       .ROB_taken(rob_bt_out),
                       .ROB_taken_address(rob_ba_out),
                       .ROB_NPC(rob_retire_NPC));

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

  //synopsys sync_set_reset "reset"
  always @(posedge clock)
  begin
    if(reset | rob_mispredict)
    begin
      if_id_NPC        <= `SD 0;
      if_id_IR         <= `SD `NOOP_INST;
      if_id_valid_inst <= `SD `FALSE;
      if_id_ba         <= `SD 0;
      if_id_bt         <= `SD 0;
    end // if (reset)
    else if (if_id_enable)
      begin
        if_id_NPC        <= `SD if_NPC_out;
        if_id_IR         <= `SD if_IR_out;
        if_id_valid_inst <= `SD if_valid_inst_out;
        if_id_ba         <= `SD bp_pc;
        if_id_bt         <= `SD bp_taken;
      end // if (if_id_enable)
  end // always

   
  //////////////////////////////////////////////////
  //                                              //
  //                  ID-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  id_stage id_stage_0 (// Inputs
                       .clock     (clock),
                       .reset   (reset), // Not used for anything
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

    // structural hazard
	assign stall_id[0] = (&rs_stall) | rob_full | (lsq_full & |((id_dp_rd_mem|id_dp_wr_mem)&id_dp_valid_inst));
	`ifdef SUPERSCALAR
	assign stall_id[1] = stall_id[0] | (|rs_stall) | rob_full_almost | (lsq_full_almost && (id_dp_rd_mem[1]&id_dp_valid_inst[1] | id_dp_wr_mem[1]&id_dp_valid_inst[1]));
	`endif
    
  // isbranch generation
  assign id_dp_isbranch = id_dp_cond_branch | id_dp_uncond_branch;

  assign id_dp_enable = stall_id == 0;

  //synopsys sync_set_reset "reset"
  always @(posedge clock)
  begin
    if (reset | rob_mispredict)
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
      id_dp_bt            <= `SD 0;
      id_dp_ba            <= `SD 0;
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
        id_dp_bt            <= `SD if_id_bt;
        id_dp_ba            <= `SD if_id_ba;
      `ifdef SUPERSCALAR
      end else if (stall_id == 2'b10) begin //Almost full case
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
        id_dp_bt            [`SEL(1,1)]  <= `SD id_dp_bt             [`SEL(1,2)];
        id_dp_ba            [`SEL(64,1)] <= `SD id_dp_ba             [`SEL(64,2)];
			// mark ir2 as invalid
        id_dp_valid_inst    [`SEL(1,2)]  <= `SD 1'b0;  
		   // mark ir2 as legal (this is because we use illegal | valid to command issue)
  		  id_dp_illegal		 [`SEL(1,2)]  <= `SD 1'b0;
        `endif //SUPERSCALAR
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
						.dest_idx_in(id_dp_dest_reg_idx), .retire_dest_idx_in(rob_retire_dest_idx),
						// PRF i/o
						.prega_idx_out(rat_prega_idx), .prega_valid_out(prf_valid_prega),
            .pregb_idx_out(rat_pregb_idx), .pregb_valid_out(prf_valid_pregb),
            //CDB input
            .cdb_en(ex_cdb_valid_out), .cdb_tag(ex_cdb_tag_out),
						.pdest_idx_out(rat_pdest_idx), .retire_pdest_idx_in(rob_retire_pdest_idx),
						// enable signals for rat and rrat
						.issue(id_dp_valid_inst & ~stall_id), .retire(rob_retire_valid_inst)
				 	 );

  rob rob0 (.clk(clock), .reset(reset),
						.full(rob_full), .full_almost(rob_full_almost),
						// Dispatch request
						.din1_req((id_dp_valid_inst[0] | id_dp_illegal[0]) & !stall_id[0]), .din2_req((id_dp_valid_inst[1] | id_dp_illegal[1]) & !stall_id[1]),
						// Update request
						.dup1_req(ex_cdb_valid_out[0]), .dup2_req(ex_cdb_valid_out[1]),
						.rob_idx_in1(ex_rob_idx_out[`SEL(`ROB_IDX,1)]), .rob_idx_in2(ex_rob_idx_out[`SEL(`ROB_IDX,2)]),
						// Inputs @ dispatch
						.ir_in1(id_dp_IR[`SEL(32,1)]), .ir_in2(id_dp_IR[`SEL(32,2)]), 
            .npc_in1(id_dp_NPC[`SEL(64,1)]), .npc_in2(id_dp_NPC[`SEL(64,2)]),
            .pdest_in1(rat_pdest_idx[`SEL(`PRF_IDX,1)]), .pdest_in2(rat_pdest_idx[`SEL(`PRF_IDX,2)]), 
            .adest_in1(id_dp_dest_reg_idx[`SEL(5,1)]), .adest_in2(id_dp_dest_reg_idx[`SEL(5,2)]),
				.illegal_in(id_dp_illegal),
						// Outputs @ dispatch
						.rob_idx_out1(rob_idx_out[`SEL(`ROB_IDX,1)]), .rob_idx_out2(rob_idx_out[`SEL(`ROB_IDX,2)]),
						// Branch @ dispatch
            .ba_pd_in1(id_dp_ba[`SEL(64,1)]), .ba_pd_in2(id_dp_ba[`SEL(64,2)]), //FIXME 
            .bt_pd_in1(id_dp_bt[0]), .bt_pd_in2(id_dp_bt[1]), //FIXME
            .isbranch_in1(id_dp_isbranch[0]), .isbranch_in2(id_dp_isbranch[1]),
						// Real branch results                                                              //vv-- What the crap yejoong? >:P
						.ba_ex_in1(ex_cdb_branch_target_addr_out[`SEL(64,1)]), .ba_ex_in2(ex_cdb_branch_target_addr_out[`SEL(64,2)]), .bt_ex_in1(ex_branch_NT_out[0]), .bt_ex_in2(ex_branch_NT_out[1]),
						// For retire
            .dout1_valid(rob_retire_valid_inst[0]), .dout2_valid(rob_retire_valid_inst[1]), 
						.ir_out1(rob_retire_IR[`SEL(32,1)]), .ir_out2(rob_retire_IR[`SEL(32,2)]), 
            .npc_out1(rob_retire_NPC[`SEL(64,1)]), .npc_out2(rob_retire_NPC[`SEL(64,2)]),
            .pdest_out1(rob_retire_pdest_idx[`SEL(`PRF_IDX,1)]), .pdest_out2(rob_retire_pdest_idx[`SEL(`PRF_IDX,2)]),
						.adest_out1(rob_retire_dest_idx[`SEL(`ARF_IDX,1)]), .adest_out2(rob_retire_dest_idx[`SEL(`ARF_IDX,2)]),
						.illegal_out(rob_illegal_out),
						// Branch Miss
						.branch_miss(rob_mispredict), .correct_target(rob_target_pc),
						// for updating branch predictor
						.isbranch_out(rob_retire_isbranch), .bt_out(rob_bt_out), .ba_out(rob_ba_out),
						// for lsq
						.head(rob_head)
						);

  regfile #(.IDX_WIDTH(`PRF_IDX), .DATA_WIDTH(64), .ZERO_REGISTER(`ZERO_PRF))
  PRF(.rda_idx(dp_prega_idx), .rda_out(dp_prega_value),
      .rdb_idx(dp_pregb_idx), .rdb_out(dp_pregb_value),
      .reg_vals_out(prf_regs),
      .wr_idx(ex_cdb_tag_out), .wr_data(ex_cdb_value_out),
      .wr_en(ex_cdb_valid_out), .clock(clock)
      );

  SUPER_RS rs0 (.clk(clock), .reset(reset | rob_mispredict),
                //INPUTS
                .inst_valid((id_dp_valid_inst & ~stall_id)), .prega_idx(rat_prega_idx), .pregb_idx(rat_pregb_idx), .pdest_idx(rat_pdest_idx), .prega_valid(prf_valid_prega), .pregb_valid(prf_valid_pregb), //RAT
                .ALUop(id_dp_alu_func), .rd_mem(id_dp_rd_mem), .wr_mem(id_dp_wr_mem), .rs_IR(id_dp_IR), . npc(id_dp_NPC), .cond_branch(id_dp_cond_branch), .uncond_branch(id_dp_uncond_branch),     //Issue Stage
                .multfu_free(ex_MULT_free), .exfu_free(ex_ALU_free), .memfu_free(2'b11), .cdb_valid(ex_cdb_valid_out), .cdb_tag(ex_cdb_tag_out), .entry_flush({`SCALAR*`RS_SZ{1'b0}}),   //Pipeline communication
//                .multfu_free(2'b0), .exfu_free(2'b0), .memfu_free(2'b11), .cdb_valid(cdb_valid), .cdb_tag(cdb_tag), .entry_flush({`RS_SZ{0}}),   //Pipeline communication - Disable ex_stage
                .rob_idx(rob_idx_out), //ROB
                .lsq_idx(lsq_idx_out), //LSQ

                //OUTPUT
                .rs_stall(rs_stall), .rs_rdy(), //Hazard detect
                .pdest_idx_out(dp_pdest_idx), .prega_idx_out(dp_prega_idx), .pregb_idx_out(dp_pregb_idx), 
								.ALUop_out(dp_ALUop), .rd_mem_out(dp_rd_mem), //FU
                .wr_mem_out(dp_wr_mem), .rs_IR_out(dp_is_IR), .npc_out(dp_is_NPC), 
								.rob_idx_out(dp_rob_idx), .en_out(dp_is_valid_inst), //FU
                .lsq_idx_out(dp_lsq_idx)
         			 );

  //////////////////////////////////////////////////
  //                                              //
  //            IS/EX Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////

  //Write forwarding for IS/EX stage
  wire [63:0] prega_value[`SCALAR-1:0];
  wire [63:0] pregb_value[`SCALAR-1:0];
  assign prega_value[0] = (dp_prega_idx[`SEL(`PRF_IDX,1)] == `ZERO_PRF) ? 0 : ((ex_cdb_valid_out[0] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 1)] == dp_prega_idx[`SEL(`PRF_IDX,1)])) ? ex_cdb_value_out[`SEL(64,1)] : 
                          `ifdef SUPERSCALAR
                          (ex_cdb_valid_out[1] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 2)] == dp_prega_idx[`SEL(`PRF_IDX,1)])) ? ex_cdb_value_out[`SEL(64,2)] :
                          `endif
                          dp_prega_value[`SEL(64,1)]);
  assign prega_value[1] = (dp_prega_idx[`SEL(`PRF_IDX,2)] == `ZERO_PRF) ? 0 : ((ex_cdb_valid_out[0] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 1)] == dp_prega_idx[`SEL(`PRF_IDX,2)])) ? ex_cdb_value_out[`SEL(64,1)] : 
                          `ifdef SUPERSCALAR
                          (ex_cdb_valid_out[1] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 2)] == dp_prega_idx[`SEL(`PRF_IDX,2)])) ? ex_cdb_value_out[`SEL(64,2)] :
                          `endif
                          dp_prega_value[`SEL(64,2)]);
  assign pregb_value[0] = (dp_pregb_idx[`SEL(`PRF_IDX,1)] == `ZERO_PRF) ? 0 : ((ex_cdb_valid_out[0] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 1)] == dp_pregb_idx[`SEL(`PRF_IDX,1)])) ? ex_cdb_value_out[`SEL(64,1)] : 
                          `ifdef SUPERSCALAR
                          (ex_cdb_valid_out[1] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 2)] == dp_pregb_idx[`SEL(`PRF_IDX,1)])) ? ex_cdb_value_out[`SEL(64,2)] :
                          `endif
                          dp_pregb_value[`SEL(64,1)]);
  assign pregb_value[1] = (dp_pregb_idx[`SEL(`PRF_IDX,2)] == `ZERO_PRF) ? 0 : ((ex_cdb_valid_out[0] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 1)] == dp_pregb_idx[`SEL(`PRF_IDX,2)])) ? ex_cdb_value_out[`SEL(64,1)] : 
                          `ifdef SUPERSCALAR
                          (ex_cdb_valid_out[1] && (ex_cdb_tag_out[`SEL(`PRF_IDX, 2)] == dp_pregb_idx[`SEL(`PRF_IDX,2)])) ? ex_cdb_value_out[`SEL(64,2)] :
                          `endif
                          dp_pregb_value[`SEL(64,2)]);

  //synopsys sync_set_reset "reset"
  always @(posedge clock)
  begin
    if (reset | rob_mispredict)
    begin
			is_ex_lsq_idx			<= `SD 0;
			is_ex_pdest_idx		<= `SD {`SCALAR{`ZERO_REG}};
			is_ex_prega_value	<= `SD 0;
			is_ex_pregb_value	<= `SD 0;
			is_ex_ALUop				<= `SD 0;
			is_ex_rd_mem			<= `SD 0;
			is_ex_wr_mem			<= `SD 0;
			is_ex_IR				  <= `SD {`SCALAR{`NOOP_INST}};
			is_ex_NPC					<= `SD 0;
			is_ex_rob_idx			<= `SD 0;
			is_ex_lsq_idx			<= `SD 0;
			is_ex_valid_inst	<= `SD 0;
    end // if (reset)
    else begin
			is_ex_pdest_idx		<= `SD dp_pdest_idx;
			is_ex_prega_value	<= `SD {prega_value[1], prega_value[0]};
			is_ex_pregb_value	<= `SD {pregb_value[1], pregb_value[0]};
			is_ex_ALUop				<= `SD dp_ALUop;
			is_ex_rd_mem			<= `SD dp_rd_mem;
			is_ex_wr_mem			<= `SD dp_wr_mem;
			is_ex_IR				  <= `SD dp_is_IR;
			is_ex_NPC					<= `SD dp_is_NPC;
			is_ex_rob_idx			<= `SD dp_rob_idx;
      is_ex_lsq_idx     <= `SD dp_lsq_idx;
			is_ex_valid_inst	<= `SD dp_is_valid_inst;
    end // else: !if(reset)
  end // always

  //////////////////////////////////////////////////
  //                                              //
  //                  EX-Stage                    //
  //                                              //
  //////////////////////////////////////////////////

assign ex_co_valid_inst = ex_cdb_valid_out;	// These signals are redundant. Remove one of them.

ex_co_stage ex_co_stage0 (.clk(clock), .reset(reset | rob_mispredict),
													// Inputs
													.LSQ_idx(is_ex_lsq_idx), .pdest_idx(is_ex_pdest_idx), 
													.prega_value(is_ex_prega_value), .pregb_value(is_ex_pregb_value), 
													.ALUop(is_ex_ALUop), .rd_mem(is_ex_rd_mem), .wr_mem(is_ex_wr_mem),
													.IR(is_ex_IR), .npc(is_ex_NPC), .rob_idx(is_ex_rob_idx), .EX_en(is_ex_valid_inst),

													// Inputs (from LSQ)
													.LSQ_rob_idx(lsq_rob_idx_out), .LSQ_pdest_idx(lsq_pdest_idx_out), .LSQ_mem_value(lsq_mem_value_out), .LSQ_done(lsq_out_valid), .LSQ_rd_mem(lsq_rd_mem_out), .LSQ_wr_mem(lsq_wr_mem_out),
													.LSQ_IR(lsq_ir_out), .LSQ_npc(lsq_npc_out),

													// Outputs
													.cdb_tag(ex_cdb_tag_out), .cdb_valid(ex_cdb_valid_out), .cdb_value(ex_cdb_value_out), 
													.cdb_MEM_result_valid(ex_mem_value_valid_out), 	  // to CDB
													.cdb_rob_idx(ex_rob_idx_out), .cdb_BR_result(ex_branch_NT_out), 
													.cdb_npc(ex_co_NPC), .cdb_IR(ex_co_IR),					  // to CDB
													.cdb_branch_target_addr(ex_cdb_branch_target_addr_out),				// to ROB
													.ALU_free(ex_ALU_free), .MULT_free(ex_MULT_free), // to RS

													// Outputs (to LSQ)

													.EX_LSQ_idx(ex_lsq_idx_out), .EX_MEM_ADDR(ex_addr_out), .EX_MEM_reg_value(ex_regv_out), .EX_MEM_valid(ex_lsq_req));


  //////////////////////////////////////////////////
  //                                              //
  //                LSQ & DCACHE                  //
  //                                              //
  //////////////////////////////////////////////////


  lsq lsq0 (.clk(clock), .reset(reset | rob_mispredict), 
						.full(lsq_full), .full_almost(lsq_full_almost),
						// Inputs at Dispatch
						.rob_idx_in(rob_idx_out), .pdest_idx_in(rat_pdest_idx), .rd_mem_in(id_dp_rd_mem & id_dp_valid_inst & ~stall_id), .wr_mem_in(id_dp_wr_mem & id_dp_valid_inst & ~stall_id),
						.npc_in(id_dp_NPC), .ir_in(id_dp_IR), 
						// Inputs from EX
						.up_req(ex_lsq_req), .lsq_idx_in(ex_lsq_idx_out), .addr_in(ex_addr_out), .regv_in(ex_regv_out),
						// Inputs from MEM
						.mem2lsq_response(Dmem2proc_response),
						// Inputs from DCACHE
						.dcache2lsq_valid(dcache2lsq_valid), .dcache2lsq_tag(dcache2lsq_tag), .dcache2lsq_data(dcache2lsq_data), .dcache2lsq_st_received(dcache2lsq_st_received),
						// Inputs from ROB
						.rob_head(rob_head),
						// Output at Dispatch
						.lsq_idx_out(lsq_idx_out),
						// Outputs to EX
						.out_valid(lsq_out_valid), .rob_idx_out(lsq_rob_idx_out), .pdest_idx_out(lsq_pdest_idx_out), .mem_value_out(lsq_mem_value_out), .rd_mem_out(lsq_rd_mem_out), .wr_mem_out(lsq_wr_mem_out),
						.ir_out(lsq_ir_out), .npc_out(lsq_npc_out),
						// Outputs to DCACHE
						.lsq2mem_command(lsq2dcache_command), .lsq2mem_addr(lsq2dcache_addr), .lsq2mem_data(lsq2dcache_data)
					 );


	dcachemem dcachemem0 (.clock(clock), .reset(reset), .en(dcachemem_en),
   	      	         		.wr1_en(dcachemem_wr_en), .wr1_tag(dcachemem_wr_tag), .wr1_idx(dcachemem_wr_idx), .wr1_data(dcachemem_wr_data),
    	  	            	.rd1_tag(dcachemem_rd_tag), .rd1_idx(dcachemem_rd_idx), .rd1_data(dcachemem_rd_data), .rd1_valid(dcachemem_rd_valid)
												);

	dcache dcache0 (.clock(clock), .reset(reset | rob_mispredict),
       		      	// inputs
          		    .Dmem2Dcache_response(Dmem2proc_response), .Dmem2Dcache_tag(mem2proc_tag), .Dmem2Dcache_data(mem2proc_data),	// From Dmem
       		    	  .proc2Dcache_addr(lsq2dcache_addr), .proc2Dcache_command(lsq2dcache_command), .proc2Dcache_data(lsq2dcache_data),	// From Proc(LSQ)
         		    	.cachemem_data(dcachemem_rd_data), .cachemem_valid(dcachemem_rd_valid), // From Dcachemem
           			  // outputs
     			        .Dcache2Dmem_command(proc2Dmem_command), .Dcache2Dmem_addr(proc2Dmem_addr), .Dcache2Dmem_data(proc2mem_data),	// To Dmem
          		    .Dcache2proc_data(dcache2lsq_data), .Dcache2proc_valid(dcache2lsq_valid), .Dcache2proc_tag(dcache2lsq_tag), 		// To Proc(LSQ)
      						.Dcache2proc_st_received(dcache2lsq_st_received),
             			.rd_idx(dcachemem_rd_idx), .rd_tag(dcachemem_rd_tag), .wr_idx(dcachemem_wr_idx), .wr_tag(dcachemem_wr_tag), .wr_data(dcachemem_wr_data), .wr_en(dcachemem_wr_en), .en(dcachemem_en)	// To Dcachemem
        			    );


endmodule  // module oo_pipeline


