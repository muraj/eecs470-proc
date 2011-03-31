/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.v                                          //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline.                                //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module pipeline (// Inputs
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


                 // testing hooks (these must be exported so we can test
                 // the synthesized version) data is tested by looking at
                 // the final values in memory
                 if_NPC_out,
                 if_IR_out,
                 if_valid_inst_out,
                 if_id_NPC,
                 if_id_IR,
                 if_id_valid_inst,
                 id_ex_NPC,
                 id_ex_IR,
                 id_ex_valid_inst,
                 ex_mem_NPC,
                 ex_mem_IR,
                 ex_mem_valid_inst,
                 mem_wb_NPC,
                 mem_wb_IR,
                 mem_wb_valid_inst
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
  output [4:0]  pipeline_commit_wr_idx;
  output [63:0] pipeline_commit_wr_data;
  output        pipeline_commit_wr_en;
  output [63:0] pipeline_commit_NPC;

  output [63:0] if_NPC_out;
  output [31:0] if_IR_out;
  output        if_valid_inst_out;
  output [63:0] if_id_NPC;
  output [31:0] if_id_IR;
  output        if_id_valid_inst;
  output [63:0] id_ex_NPC;
  output [31:0] id_ex_IR;
  output        id_ex_valid_inst;
  output [63:0] ex_mem_NPC;
  output [31:0] ex_mem_IR;
  output        ex_mem_valid_inst;
  output [63:0] mem_wb_NPC;
  output [31:0] mem_wb_IR;
  output        mem_wb_valid_inst;

  // Pipeline register enables
  wire   if_id_enable, id_ex_enable, ex_mem_enable, mem_wb_enable;

  // Outputs from IF-Stage
  wire [63:0] if_NPC_out;
  wire [31:0] if_IR_out;
  wire        if_valid_inst_out;

  // Outputs from IF/ID Pipeline Register
  reg  [63:0] if_id_NPC;
  reg  [31:0] if_id_IR;
  reg         if_id_valid_inst;
   
  // Outputs from ID stage
  wire [63:0] id_rega_out;
  wire [63:0] id_regb_out;
  wire  [1:0] id_opa_select_out;
  wire  [1:0] id_opb_select_out;
  wire  [4:0] id_dest_reg_idx_out;
  wire  [4:0] id_alu_func_out;
  wire        id_rd_mem_out;
  wire        id_wr_mem_out;
  wire        id_ldl_mem_out;
  wire        id_stc_mem_out;
  wire        id_cond_branch_out;
  wire        id_uncond_branch_out;
  wire        id_halt_out;
  wire        id_cpuid_out;
  wire        id_illegal_out;
  wire        id_valid_inst_out;

  // Outputs from ID/EX Pipeline Register
  reg  [63:0] id_ex_NPC;
  reg  [31:0] id_ex_IR;
  reg  [63:0] id_ex_rega;
  reg  [63:0] id_ex_regb;
  reg   [1:0] id_ex_opa_select;
  reg   [1:0] id_ex_opb_select;
  reg   [4:0] id_ex_dest_reg_idx;
  reg   [4:0] id_ex_alu_func;
  reg         id_ex_rd_mem;
  reg         id_ex_wr_mem;
  reg         id_ex_cond_branch;
  reg         id_ex_uncond_branch;
  reg         id_ex_halt;
  reg         id_ex_illegal;
  reg         id_ex_valid_inst;
   
  // Outputs from EX-Stage
  wire [63:0] ex_alu_result_out;
  wire        ex_take_branch_out;

  // Outputs from EX/MEM Pipeline Register
  reg  [63:0] ex_mem_NPC;
  reg  [31:0] ex_mem_IR;
  reg   [4:0] ex_mem_dest_reg_idx;
  reg         ex_mem_rd_mem;
  reg         ex_mem_wr_mem;
  reg         ex_mem_halt;
  reg         ex_mem_illegal;
  reg         ex_mem_valid_inst;
  reg  [63:0] ex_mem_rega;
  reg  [63:0] ex_mem_alu_result;
  reg         ex_mem_take_branch;
  
  // Outputs from MEM-Stage
  wire [63:0] mem_result_out;
  wire        mem_stall_out;

  // Outputs from MEM/WB Pipeline Register
  reg  [63:0] mem_wb_NPC;
  reg  [31:0] mem_wb_IR;
  reg         mem_wb_halt;
  reg         mem_wb_illegal;
  reg         mem_wb_valid_inst;
  reg   [4:0] mem_wb_dest_reg_idx;
  reg  [63:0] mem_wb_result;
  reg         mem_wb_take_branch;

  // Outputs from WB-Stage  (These loop back to the register file in ID)
  wire [63:0] wb_reg_wr_data_out;
  wire  [4:0] wb_reg_wr_idx_out;
  wire        wb_reg_wr_en_out;

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

  assign pipeline_completed_insts = {3'b0, mem_wb_valid_inst};
  assign pipeline_error_status = 
    mem_wb_illegal ? `HALTED_ON_ILLEGAL
                   : mem_wb_halt ? `HALTED_ON_HALT
                                 : `NO_ERROR;

  assign pipeline_commit_wr_idx = wb_reg_wr_idx_out;
  assign pipeline_commit_wr_data = wb_reg_wr_data_out;
  assign pipeline_commit_wr_en = wb_reg_wr_en_out;
  assign pipeline_commit_NPC = mem_wb_NPC;

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
  if_stage if_stage_0 (// Inputs
                       .clock (clock),
                       .reset (reset),
                       .mem_wb_valid_inst(mem_wb_valid_inst),
                       .ex_mem_take_branch(ex_mem_take_branch),
                       .ex_mem_target_pc(ex_mem_alu_result),
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
  assign if_id_enable = 1'b1; // always enabled
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
                       .wb_reg_wr_en_out   (wb_reg_wr_en_out),
                       .wb_reg_wr_idx_out  (wb_reg_wr_idx_out),
                       .wb_reg_wr_data_out (wb_reg_wr_data_out),
                       
                       // Outputs
                       .id_ra_value_out(id_rega_out),
                       .id_rb_value_out(id_regb_out),
                       .id_opa_select_out(id_opa_select_out),
                       .id_opb_select_out(id_opb_select_out),
                       .id_dest_reg_idx_out(id_dest_reg_idx_out),
                       .id_alu_func_out(id_alu_func_out),
                       .id_rd_mem_out(id_rd_mem_out),
                       .id_wr_mem_out(id_wr_mem_out),
                       .id_ldl_mem_out(id_ldl_mem_out),
                       .id_stc_mem_out(id_stc_mem_out),
                       .id_cond_branch_out(id_cond_branch_out),
                       .id_uncond_branch_out(id_uncond_branch_out),
                       .id_halt_out(id_halt_out),
                       .id_cpuid_out(id_cpuid_out),
                       .id_illegal_out(id_illegal_out),
                       .id_valid_inst_out(id_valid_inst_out)
                      );

  // Note: Decode signals for load-lock/store-conditional and "get CPU ID"
  //  instructions (id_{ldl,stc}_mem_out, id_cpuid_out) are not connected
  //  to anything because the provided EX and MEM stages do not implement
  //  these instructions.  You will have to implement these instructions
  //  if you plan to do a multicore project.

  //////////////////////////////////////////////////
  //                                              //
  //            ID/EX Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign id_ex_enable = 1'b1; // always enabled
  always @(posedge clock)
  begin
    if (reset)
    begin
      id_ex_NPC           <= `SD 0;
      id_ex_IR            <= `SD `NOOP_INST;
      id_ex_rega          <= `SD 0;
      id_ex_regb          <= `SD 0;
      id_ex_opa_select    <= `SD 0;
      id_ex_opb_select    <= `SD 0;
      id_ex_dest_reg_idx  <= `SD `ZERO_REG;
      id_ex_alu_func      <= `SD 0;
      id_ex_rd_mem        <= `SD 0;
      id_ex_wr_mem        <= `SD 0;
      id_ex_cond_branch   <= `SD 0;
      id_ex_uncond_branch <= `SD 0;
      id_ex_halt          <= `SD 0;
      id_ex_illegal       <= `SD 0;
      id_ex_valid_inst    <= `SD 0;
    end // if (reset)
    else
    begin
      if (id_ex_enable)
      begin
        id_ex_NPC           <= `SD if_id_NPC;
        id_ex_IR            <= `SD if_id_IR;
        id_ex_rega          <= `SD id_rega_out;
        id_ex_regb          <= `SD id_regb_out;
        id_ex_opa_select    <= `SD id_opa_select_out;
        id_ex_opb_select    <= `SD id_opb_select_out;
        id_ex_dest_reg_idx  <= `SD id_dest_reg_idx_out;
        id_ex_alu_func      <= `SD id_alu_func_out;
        id_ex_rd_mem        <= `SD id_rd_mem_out;
        id_ex_wr_mem        <= `SD id_wr_mem_out;
        id_ex_cond_branch   <= `SD id_cond_branch_out;
        id_ex_uncond_branch <= `SD id_uncond_branch_out;
        id_ex_halt          <= `SD id_halt_out;
        id_ex_illegal       <= `SD id_illegal_out;
        id_ex_valid_inst    <= `SD id_valid_inst_out;
      end // if
    end // else: !if(reset)
  end // always


  //////////////////////////////////////////////////
  //                                              //
  //                  EX-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  ex_stage ex_stage_0 (// Inputs
                       .clock(clock),
                       .reset(reset),
                       .id_ex_NPC(id_ex_NPC), 
                       .id_ex_IR(id_ex_IR),
                       .id_ex_rega(id_ex_rega),
                       .id_ex_regb(id_ex_regb),
                       .id_ex_opa_select(id_ex_opa_select),
                       .id_ex_opb_select(id_ex_opb_select),
                       .id_ex_alu_func(id_ex_alu_func),
                       .id_ex_cond_branch(id_ex_cond_branch),
                       .id_ex_uncond_branch(id_ex_uncond_branch),
                       
                       // Outputs
                       .ex_alu_result_out(ex_alu_result_out),
                       .ex_take_branch_out(ex_take_branch_out)
                      );


  //////////////////////////////////////////////////
  //                                              //
  //           EX/MEM Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign ex_mem_enable = ~mem_stall_out;
  always @(posedge clock)
  begin
    if (reset)
    begin
      ex_mem_NPC          <= `SD 0;
      ex_mem_IR           <= `SD `NOOP_INST;
      ex_mem_dest_reg_idx <= `SD `ZERO_REG;
      ex_mem_rd_mem       <= `SD 0;
      ex_mem_wr_mem       <= `SD 0;
      ex_mem_halt         <= `SD 0;
      ex_mem_illegal      <= `SD 0;
      ex_mem_valid_inst   <= `SD 0;
      ex_mem_rega         <= `SD 0;
      ex_mem_alu_result   <= `SD 0;
      ex_mem_take_branch  <= `SD 0;
    end
    else
    begin
      if (ex_mem_enable)
      begin
        // these are forwarded directly from ID/EX latches
        ex_mem_NPC          <= `SD id_ex_NPC;
        ex_mem_IR           <= `SD id_ex_IR;
        ex_mem_dest_reg_idx <= `SD id_ex_dest_reg_idx;
        ex_mem_rd_mem       <= `SD id_ex_rd_mem;
        ex_mem_wr_mem       <= `SD id_ex_wr_mem;
        ex_mem_halt         <= `SD id_ex_halt;
        ex_mem_illegal      <= `SD id_ex_illegal;
        ex_mem_valid_inst   <= `SD id_ex_valid_inst;
        ex_mem_rega         <= `SD id_ex_rega;
        // these are results of EX stage
        ex_mem_alu_result   <= `SD ex_alu_result_out;
        ex_mem_take_branch  <= `SD ex_take_branch_out;
      end // if
    end // else: !if(reset)
  end // always

   
  //////////////////////////////////////////////////
  //                                              //
  //                 MEM-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  mem_stage mem_stage_0 (// Inputs
                         .clock(clock),
                         .reset(reset),
                         .ex_mem_rega(ex_mem_rega),
                         .ex_mem_alu_result(ex_mem_alu_result), 
                         .ex_mem_rd_mem(ex_mem_rd_mem),
                         .ex_mem_wr_mem(ex_mem_wr_mem),
                         .Dmem2proc_data(mem2proc_data),
                         .Dmem2proc_tag(mem2proc_tag),
                         .Dmem2proc_response(Dmem2proc_response),
                         
                         // Outputs
                         .mem_result_out(mem_result_out),
                         .mem_stall_out(mem_stall_out),
                         .proc2Dmem_command(proc2Dmem_command),
                         .proc2Dmem_addr(proc2Dmem_addr),
                         .proc2Dmem_data(proc2mem_data)
                        );

  wire [4:0] mem_dest_reg_idx_out = 
      mem_stall_out ? `ZERO_REG : ex_mem_dest_reg_idx;
  wire mem_valid_inst_out = ex_mem_valid_inst & ~mem_stall_out;

  //////////////////////////////////////////////////
  //                                              //
  //           MEM/WB Pipeline Register           //
  //                                              //
  //////////////////////////////////////////////////
  assign mem_wb_enable = 1'b1; // always enabled
  always @(posedge clock)
  begin
    if (reset)
    begin
      mem_wb_NPC          <= `SD 0;
      mem_wb_IR           <= `SD `NOOP_INST;
      mem_wb_halt         <= `SD 0;
      mem_wb_illegal      <= `SD 0;
      mem_wb_valid_inst   <= `SD 0;
      mem_wb_dest_reg_idx <= `SD `ZERO_REG;
      mem_wb_take_branch  <= `SD 0;
      mem_wb_result       <= `SD 0;
    end
    else
    begin
      if (mem_wb_enable)
      begin
        // these are forwarded directly from EX/MEM latches
        mem_wb_NPC          <= `SD ex_mem_NPC;
        mem_wb_IR           <= `SD ex_mem_IR;
        mem_wb_halt         <= `SD ex_mem_halt;
        mem_wb_illegal      <= `SD ex_mem_illegal;
        mem_wb_valid_inst   <= `SD mem_valid_inst_out;
        mem_wb_dest_reg_idx <= `SD mem_dest_reg_idx_out;
        mem_wb_take_branch  <= `SD ex_mem_take_branch;
        // these are results of MEM stage
        mem_wb_result       <= `SD mem_result_out;
      end // if
    end // else: !if(reset)
  end // always


  //////////////////////////////////////////////////
  //                                              //
  //                  WB-Stage                    //
  //                                              //
  //////////////////////////////////////////////////
  wb_stage wb_stage_0 (// Inputs
                       .clock(clock),
                       .reset(reset),
                       .mem_wb_NPC(mem_wb_NPC),
                       .mem_wb_result(mem_wb_result),
                       .mem_wb_dest_reg_idx(mem_wb_dest_reg_idx),
                       .mem_wb_take_branch(mem_wb_take_branch),
                       .mem_wb_valid_inst(mem_wb_valid_inst),

                       // Outputs
                       .reg_wr_data_out(wb_reg_wr_data_out),
                       .reg_wr_idx_out(wb_reg_wr_idx_out),
                       .reg_wr_en_out(wb_reg_wr_en_out)
                      );

endmodule  // module verisimple
