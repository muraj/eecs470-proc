/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench.v                                         //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module testbench;

  // Registers and wires used in the testbench
  reg        clock;
  reg        reset;
  reg [31:0] clock_count;
  reg [31:0] instr_count;
  integer    wb_fileno;

  wire [1:0]  proc2mem_command;
  wire [63:0] proc2mem_addr;
  wire [63:0] proc2mem_data;
  wire [3:0]  mem2proc_response;
  wire [63:0] mem2proc_data;
  wire [3:0]  mem2proc_tag;

  wire [3:0]            pipeline_completed_insts;
  wire [3:0]            pipeline_error_status;
  wire [`SCALAR*5-1:0]  pipeline_commit_wr_idx;
  wire [`SCALAR*64-1:0] pipeline_commit_wr_data;
  wire [`SCALAR-1:0]    pipeline_commit_wr_en;    //Whether the instruction wrote to a register
  wire [`SCALAR*64-1:0] pipeline_commit_NPC;
  wire [`SCALAR*32-1:0] pipeline_commit_IR;


  wire [`SCALAR*64-1:0] if_NPC_out;
  wire [`SCALAR*32-1:0] if_IR_out;
  wire [`SCALAR-1:0]    if_valid_inst_out;
  wire [`SCALAR*64-1:0] if_id_NPC;
  wire [`SCALAR*32-1:0] if_id_IR;
  wire [`SCALAR-1:0]    if_id_valid_inst;
  wire [`SCALAR*64-1:0] id_dp_NPC;
  wire [`SCALAR*32-1:0] id_dp_IR;
  wire [`SCALAR-1:0]    id_dp_valid_inst;

//DEBUG SIGNALS
`ifndef SYNTH
//*** RS DEBUG ***//
  integer rs_fileno, rs_idx;
  wire [31:0] rs1_IR[`RS_SZ-1:0];
  wire [63:0] rs1_npc[`RS_SZ-1:0];
  wire [`ROB_IDX:0] rs1_rob_idx[`RS_SZ-1:0];
  wire [`RS_SZ-1:0] rs1_rdy;
  wire [`RS_SZ-1:0] rs1_free;
`ifdef SUPERSCALAR
  wire [31:0] rs2_IR[`RS_SZ-1:0];
  wire [63:0] rs2_npc[`RS_SZ-1:0];
  wire [`ROB_IDX:0] rs2_rob_idx[`RS_SZ-1:0];
  wire [`RS_SZ-1:0] rs2_rdy;
  wire [`RS_SZ-1:0] rs2_free;
`endif  //SUPERSCALAR

generate
genvar rs_iter;
  for(rs_iter=0;rs_iter<`RS_SZ;rs_iter=rs_iter+1) begin : RS_DEBUG
    assign rs1_IR[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rs_IR_out;
    assign rs1_npc[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.npc_out;
    assign rs1_rob_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rob_idx_out;
    assign rs1_rdy[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rdy;
    assign rs1_free[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.entry_free;
    assign rs2_IR[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rs_IR_out;
    assign rs2_npc[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.npc_out;
    assign rs2_rob_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rob_idx_out;
    assign rs2_rdy[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rdy;
    assign rs2_free[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.entry_free;
  end
endgenerate
initial begin
  rs_fileno = $fopen("resstation.out");
  rs_idx=0;
end
always @(pipeline_error_status) begin
  if(pipeline_error_status != `NO_ERROR)
    $fclose(rs_fileno);
end
always @(posedge clock) begin
 if(~reset) begin
  $fdisplay(rs_fileno, "|=============================== Cycle: %10d ===============================|", clock_count);
  $fdisplay(rs_fileno, "inst_valid: %b rs1_sel: %b npc: %h IR: %h", pipeline_0.rs0.inst_valid, pipeline_0.rs0.rs1_sel, pipeline_0.rs0.npc, pipeline_0.rs0.rs_IR);
  $fdisplay(rs_fileno, "|                      RS0                  |                   RS1               |");
  $fdisplay(rs_fileno, "| IDX |   IR   |       NPC      | ROB | R/F |   IR   |       NPC      | ROB | R/F |");
  $fdisplay(rs_fileno, "|=================================================================================|");
  `define DISPLAY_RS(i) \
      $fdisplay(rs_fileno, "|%4d |%7h|%16h|  %2d | %b/%b |%7h|%16h|  %2d | %b/%b |", i, \
                rs1_IR[i], rs1_npc[i], rs1_rob_idx[i], rs1_rdy[i], rs1_free[i], \
                rs2_IR[i], rs2_npc[i], rs2_rob_idx[i], rs2_rdy[i], rs2_free[i]);
  `DISPLAY_RS(0) `DISPLAY_RS(1) `DISPLAY_RS(2)
  `DISPLAY_RS(3) `DISPLAY_RS(4) `DISPLAY_RS(5)
  `DISPLAY_RS(6) `DISPLAY_RS(7) `DISPLAY_RS(8)
  `DISPLAY_RS(9) `DISPLAY_RS(10) `DISPLAY_RS(11)
  `DISPLAY_RS(12) `DISPLAY_RS(13) `DISPLAY_RS(14)
  `DISPLAY_RS(15)
 end
end

//*** ROB DEBUG ***//
 integer rob_fileno, rob_idx;
 wire [31:0] rob_ir[`ROB_SZ-1:0];
 wire [63:0] rob_npc[`ROB_SZ-1:0];
 wire [`PRF_IDX-1:0] rob_pdest[`ROB_SZ-1:0];
 wire [4:0] rob_adest[`ROB_SZ-1:0];
 wire [63:0] cb_ba_pd[`ROB_SZ-1:0];
 wire [`ROB_SZ-1:0] cb_bt_pd;
 wire [`ROB_SZ-1:0] cb_isbranch;
 wire [`ROB_IDX-1:0] head = pipeline_0.rob0.head;
 wire [`ROB_IDX-1:0] tail = pipeline_0.rob0.tail; 
 initial begin                
  rob_fileno = $fopen("reorderbuf.out");
  rob_idx=0;                  
 end                          
always @(posedge clock) begin 
 if(~reset) begin
  $fdisplay(rob_fileno, "\n|=============================== Cycle: %10d ================================|", clock_count);
  $fdisplay(rob_fileno, "| H/T | IDX |    IR    |        NPC       | PDR | ADR | BRA/TKN |  Branch Address  |");
  $fdisplay(rob_fileno, "|==================================================================================|");
  `define DISPLAY_ROB(i) \
    $fdisplay(rob_fileno, "| %1s %1s | %3d | %h | %h | %3d | %3d |  %b / %b  | %h |",  \
              i === head ? "H" : " ",                         \
              i === tail ? "T" : " ", i,                      \
              rob_ir[i], rob_npc[i], rob_pdest[i], rob_adest[i],                    \
              cb_isbranch[i], cb_bt_pd[i], cb_ba_pd[i]);
  `DISPLAY_ROB(0)
  `DISPLAY_ROB(1)
  `DISPLAY_ROB(2)
  `DISPLAY_ROB(3)
  `DISPLAY_ROB(4)
  `DISPLAY_ROB(5)
  `DISPLAY_ROB(6)
  `DISPLAY_ROB(7)
 end
end
always @(pipeline_error_status) begin
  if(pipeline_error_status != `NO_ERROR)
    $fclose(rob_fileno);
end
generate
genvar rob_iter;
  for(rob_iter=0;rob_iter<`ROB_SZ;rob_iter=rob_iter+1) begin : ROB_DEBUG
  assign rob_ir[rob_iter] = pipeline_0.rob0.cb_ir.data[rob_iter];
  assign rob_npc    [rob_iter] = pipeline_0.rob0.cb_npc.data[rob_iter];
  assign rob_pdest  [rob_iter] = pipeline_0.rob0.cb_pdest.data[rob_iter];
  assign rob_adest  [rob_iter] = pipeline_0.rob0.cb_adest.data[rob_iter];
  assign cb_ba_pd   [rob_iter] = pipeline_0.rob0.cb_ba_pd.data[rob_iter];
  assign cb_bt_pd   [rob_iter] = pipeline_0.rob0.cb_bt_pd.data[rob_iter];
  assign cb_isbranch[rob_iter] = pipeline_0.rob0.cb_isbranch.data[rob_iter];
  end
endgenerate
`endif  //SYNTH


  // Strings to hold instruction opcode
  reg  [8*7:0] if_instr_str[`SCALAR-1:0];
  reg  [8*7:0] id_instr_str[`SCALAR-1:0];
  reg  [8*7:0] dp_instr_str[`SCALAR-1:0];
  reg  [8*7:0] co_instr_str[`SCALAR-1:0];

  // Instantiate the Pipeline
  oo_pipeline pipeline_0 (// Inputs
                       .clock             (clock),
                       .reset             (reset),
                       .mem2proc_response (mem2proc_response),
                       .mem2proc_data     (mem2proc_data),
                       .mem2proc_tag      (mem2proc_tag),

                        // Outputs
                       .proc2mem_command  (proc2mem_command),
                       .proc2mem_addr     (proc2mem_addr),
                       .proc2mem_data     (proc2mem_data),

                       .pipeline_completed_insts(pipeline_completed_insts),
                       .pipeline_error_status(pipeline_error_status),
                       .pipeline_commit_wr_data(pipeline_commit_wr_data),
                       .pipeline_commit_wr_idx(pipeline_commit_wr_idx),
                       .pipeline_commit_wr_en(pipeline_commit_wr_en),
                       .pipeline_commit_NPC(pipeline_commit_NPC),
                       .pipeline_commit_IR(pipeline_commit_IR),

                       .if_NPC_out(if_NPC_out),
                       .if_IR_out(if_IR_out),
                       .if_valid_inst_out(if_valid_inst_out),
                       .if_id_NPC(if_id_NPC),
                       .if_id_IR(if_id_IR),
                       .if_id_valid_inst(if_id_valid_inst),
                       .id_dp_NPC(id_dp_NPC),
                       .id_dp_IR(id_dp_IR),
                       .id_dp_valid_inst(id_dp_valid_inst)
                      );


  // Instantiate the Data Memory
  mem memory (// Inputs
            .clk               (clock),
            .proc2mem_command  (proc2mem_command),
            .proc2mem_addr     (proc2mem_addr),
            .proc2mem_data     (proc2mem_data),

             // Outputs

            .mem2proc_response (mem2proc_response),
            .mem2proc_data     (mem2proc_data),
            .mem2proc_tag      (mem2proc_tag)
           );

  // Generate System Clock
  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clock = ~clock;
  end

  // Task to display # of elapsed clock edges
  task show_clk_count;
        real cpi;

        begin
     cpi = (clock_count + 1.0) / instr_count;
     $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
        clock_count+1, instr_count, cpi);
           $display("@@  %4.2f ns total time to execute\n@@\n",
                    clock_count*`VIRTUAL_CLOCK_PERIOD);
        end
        
  endtask  // task show_clk_count 

  // Show contents of a range of Unified Memory, in both hex and decimal
  task show_mem_with_decimal;
   input [31:0] start_addr;
   input [31:0] end_addr;
   integer k;
   integer showing_data;
   begin
    $display("@@@");
    showing_data=0;
    for(k=start_addr;k<=end_addr; k=k+1)
      if (memory.unified_memory[k] != 0)
      begin
        $display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k], 
                                                 memory.unified_memory[k]);
        showing_data=1;
      end
      else if(showing_data!=0)
      begin
        $display("@@@");
        showing_data=0;
      end
    $display("@@@");
   end
  endtask  // task show_mem_with_decimal

  initial
  begin
    `ifdef DUMP
      $vcdplusdeltacycleon;
      $vcdpluson();
      $vcdplusmemon(memory.unified_memory);
    `endif  //DUMP
      
    clock = 1'b0;
    reset = 1'b0;

    // Pulse the reset signal
    $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
    reset = 1'b1;
    @(posedge clock);
    @(posedge clock);

    $readmemh("program.mem", memory.unified_memory);

    @(posedge clock);
    @(posedge clock);
    `SD;
    // This reset is at an odd time to avoid the pos & neg clock edges

    reset = 1'b0;
    $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);
    wb_fileno = $fopen("writeback.out");

//   $monitor("@@ cycle: %d  if_NPC_out: %h  if_IR_out: %h  if_id_NPC: %h  id_dp_NPC: %h  id_dp_IR: %h  imem_valid: %b  m2p_data: %h",
//             clock_count, if_NPC_out, if_IR_out, if_id_NPC, id_dp_NPC, id_dp_IR, pipeline_0.if_stage_0.Imem_valid, mem2proc_data);
    $monitor("@@ cycle: %0d  if_NPC_out: %h  id_dp_NPC: %h  if_IR_out: %h  if_valid: %b rs_stall: %b  completed_inst: %0d",
            clock_count, if_NPC_out, id_dp_NPC, if_IR_out, pipeline_0.if_stage_0.if_valid_inst_out, pipeline_0.rs0.rs_stall, pipeline_completed_insts);
  end


  // Count the number of posedges and number of instructions completed
  // till simulation ends
  always @(posedge clock or posedge reset)
  begin
    if(reset)
    begin
      clock_count <= `SD 0;
      instr_count <= `SD 0;
    end
    else
    begin
      clock_count <= `SD (clock_count + 1);
      instr_count <= `SD (instr_count + pipeline_completed_insts);
      if(clock_count > 20) begin
          $display("Debug quit");
          $fclose(wb_fileno);
          $finish;
      end
    end
  end  


  always @(negedge clock)
  begin
    if(reset)
      $display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
               $realtime);
    else
    begin
      if(pipeline_completed_insts>0) begin
        if(pipeline_commit_wr_en[0])
          $fdisplay(wb_fileno, "# SCALAR 1, IR=%s cycle=%0d\nPC=%x, REG[%d]=%x",
                    co_instr_str[0], clock_count,
                    pipeline_commit_NPC[`SEL(64, 1)]-4,
                    pipeline_commit_wr_idx[`SEL(5,1)],
                    pipeline_commit_wr_data[`SEL(64,1)]);
        else
          $fdisplay(wb_fileno, "# SCALAR 1, IR=%s cycle=%0d\nPC=%x, ---",
                    co_instr_str[0], clock_count,
                    pipeline_commit_NPC[`SEL(64, 1)]-4);
       `ifdef SUPERSCALAR
        if(pipeline_commit_wr_en[1])
          $fdisplay(wb_fileno, "# SCALAR 2, IR=%s cycle=%0d\nPC=%x, REG[%d]=%x",
                    co_instr_str[1], clock_count,
                    pipeline_commit_NPC[`SEL(64, 2)]-4,
                    pipeline_commit_wr_idx[`SEL(5,2)],
                    pipeline_commit_wr_data[`SEL(64,2)]);
        else
          $fdisplay(wb_fileno, "# SCALAR 2, IR=%s cycle=%0d\nPC=%x, ---",
                    co_instr_str[1], clock_count,
                    pipeline_commit_NPC[`SEL(64, 2)]-4);
       `endif //SUPERSCALAR

      end
      // deal with any halting conditions
      if(pipeline_error_status!=`NO_ERROR)
      begin
        $display("@@@ Unified Memory contents hex on left, decimal on right: ");
        show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
          // 8Bytes per line, 16kB total

        $display("@@  %t : System halted\n@@", $realtime);

        case(pipeline_error_status)
          `HALTED_ON_MEMORY_ERROR:  
              $display("@@@ System halted on memory error");
          `HALTED_ON_HALT:          
              $display("@@@ System halted on HALT instruction");
          `HALTED_ON_ILLEGAL:
              $display("@@@ System halted on illegal instruction");
          default: 
              $display("@@@ System halted on unknown error code %x",
                       pipeline_error_status);
        endcase
        $display("@@@\n@@");
        show_clk_count;
        $fclose(wb_fileno);
        #100 $finish;
      end

    end  // if(reset)
  end 

  // Translate IRs into strings for opcodes (for waveform viewer)
  always @* begin
    if_instr_str[0]  = get_instr_string(if_IR_out[`SEL(32, 1)], if_valid_inst_out[0]);
    id_instr_str[0]  = get_instr_string(if_id_IR[`SEL(32, 1)], if_id_valid_inst[0]);
    dp_instr_str[0]  = get_instr_string(id_dp_IR[`SEL(32, 1)], id_dp_valid_inst[0]);
    co_instr_str[0]  = get_instr_string(pipeline_commit_IR[`SEL(32, 1)], pipeline_commit_wr_en[0]);
  `ifdef SUPERSCALAR
    if_instr_str[1]  = get_instr_string(if_IR_out[`SEL(32, 2)], if_valid_inst_out[1]);
    id_instr_str[1]  = get_instr_string(if_id_IR[`SEL(32, 2)], if_id_valid_inst[1]);
    dp_instr_str[1]  = get_instr_string(id_dp_IR[`SEL(32, 2)], id_dp_valid_inst[1]);
    co_instr_str[1]  = get_instr_string(pipeline_commit_IR[`SEL(32, 2)], pipeline_commit_wr_en[1]);
  `endif  //SUPERSCALAR
  end

  function [8*7:0] get_instr_string;
    input [31:0] IR;
    input        instr_valid;
    begin
      if (!instr_valid)
        get_instr_string = "-";
      else if (IR==`NOOP_INST)
        get_instr_string = "nop";
      else
        case (IR[31:26])
          6'h00: get_instr_string = (IR == 32'h555) ? "halt" : "call_pal";
          6'h08: get_instr_string = "lda";
          6'h09: get_instr_string = "ldah";
          6'h0a: get_instr_string = "ldbu";
          6'h0b: get_instr_string = "ldqu";
          6'h0c: get_instr_string = "ldwu";
          6'h0d: get_instr_string = "stw";
          6'h0e: get_instr_string = "stb";
          6'h0f: get_instr_string = "stqu";
          6'h10: // INTA_GRP
            begin
              case (IR[11:5])
                7'h00: get_instr_string = "addl";
                7'h02: get_instr_string = "s4addl";
                7'h09: get_instr_string = "subl";
                7'h0b: get_instr_string = "s4subl";
                7'h0f: get_instr_string = "cmpbge";
                7'h12: get_instr_string = "s8addl";
                7'h1b: get_instr_string = "s8subl";
                7'h1d: get_instr_string = "cmpult";
                7'h20: get_instr_string = "addq";
                7'h22: get_instr_string = "s4addq";
                7'h29: get_instr_string = "subq";
                7'h2b: get_instr_string = "s4subq";
                7'h2d: get_instr_string = "cmpeq";
                7'h32: get_instr_string = "s8addq";
                7'h3b: get_instr_string = "s8subq";
                7'h3d: get_instr_string = "cmpule";
                7'h40: get_instr_string = "addlv";
                7'h49: get_instr_string = "sublv";
                7'h4d: get_instr_string = "cmplt";
                7'h60: get_instr_string = "addqv";
                7'h69: get_instr_string = "subqv";
                7'h6d: get_instr_string = "cmple";
                default: get_instr_string = "invalid";
              endcase
            end
          6'h11: // INTL_GRP
            begin
              case (IR[11:5])
                7'h00: get_instr_string = "and";
                7'h08: get_instr_string = "bic";
                7'h14: get_instr_string = "cmovlbs";
                7'h16: get_instr_string = "cmovlbc";
                7'h20: get_instr_string = "bis";
                7'h24: get_instr_string = "cmoveq";
                7'h26: get_instr_string = "cmovne";
                7'h28: get_instr_string = "ornot";
                7'h40: get_instr_string = "xor";
                7'h44: get_instr_string = "cmovlt";
                7'h46: get_instr_string = "cmovge";
                7'h48: get_instr_string = "eqv";
                7'h61: get_instr_string = "amask";
                7'h64: get_instr_string = "cmovle";
                7'h66: get_instr_string = "cmovgt";
                7'h6c: get_instr_string = "implver";
                default: get_instr_string = "invalid";
              endcase
            end
          6'h12: // INTS_GRP
            begin
              case(IR[11:5])
                7'h02: get_instr_string = "mskbl";
                7'h06: get_instr_string = "extbl";
                7'h0b: get_instr_string = "insbl";
                7'h12: get_instr_string = "mskwl";
                7'h16: get_instr_string = "extwl";
                7'h1b: get_instr_string = "inswl";
                7'h22: get_instr_string = "mskll";
                7'h26: get_instr_string = "extll";
                7'h2b: get_instr_string = "insll";
                7'h30: get_instr_string = "zap";
                7'h31: get_instr_string = "zapnot";
                7'h32: get_instr_string = "mskql";
                7'h34: get_instr_string = "srl";
                7'h36: get_instr_string = "extql";
                7'h39: get_instr_string = "sll";
                7'h3b: get_instr_string = "insql";
                7'h3c: get_instr_string = "sra";
                7'h52: get_instr_string = "mskwh";
                7'h57: get_instr_string = "inswh";
                7'h5a: get_instr_string = "extwh";
                7'h62: get_instr_string = "msklh";
                7'h67: get_instr_string = "inslh";
                7'h6a: get_instr_string = "extlh";
                7'h72: get_instr_string = "mskqh";
                7'h77: get_instr_string = "insqh";
                7'h7a: get_instr_string = "extqh";
                default: get_instr_string = "invalid";
              endcase
            end
          6'h13: // INTM_GRP
            begin
              case (IR[11:5])
                7'h01: get_instr_string = "mull";
                7'h20: get_instr_string = "mulq";
                7'h30: get_instr_string = "umulh";
                7'h40: get_instr_string = "mullv";
                7'h60: get_instr_string = "mulqv";
                default: get_instr_string = "invalid";
              endcase
            end
          6'h14: get_instr_string = "itfp"; // unimplemented
          6'h15: get_instr_string = "fltv"; // unimplemented
          6'h16: get_instr_string = "flti"; // unimplemented
          6'h17: get_instr_string = "fltl"; // unimplemented
          6'h1a: get_instr_string = "jsr";
          6'h1c: get_instr_string = "ftpi";
          6'h20: get_instr_string = "ldf";
          6'h21: get_instr_string = "ldg";
          6'h22: get_instr_string = "lds";
          6'h23: get_instr_string = "ldt";
          6'h24: get_instr_string = "stf";
          6'h25: get_instr_string = "stg";
          6'h26: get_instr_string = "sts";
          6'h27: get_instr_string = "stt";
          6'h28: get_instr_string = "ldl";
          6'h29: get_instr_string = "ldq";
          6'h2a: get_instr_string = "ldll";
          6'h2b: get_instr_string = "ldql";
          6'h2c: get_instr_string = "stl";
          6'h2d: get_instr_string = "stq";
          6'h2e: get_instr_string = "stlc";
          6'h2f: get_instr_string = "stqc";
          6'h30: get_instr_string = "br";
          6'h31: get_instr_string = "fbeq";
          6'h32: get_instr_string = "fblt";
          6'h33: get_instr_string = "fble";
          6'h34: get_instr_string = "bsr";
          6'h35: get_instr_string = "fbne";
          6'h36: get_instr_string = "fbge";
          6'h37: get_instr_string = "fbgt";
          6'h38: get_instr_string = "blbc";
          6'h39: get_instr_string = "beq";
          6'h3a: get_instr_string = "blt";
          6'h3b: get_instr_string = "ble";
          6'h3c: get_instr_string = "blbs";
          6'h3d: get_instr_string = "bne";
          6'h3e: get_instr_string = "bge";
          6'h3f: get_instr_string = "bgt";
          default: get_instr_string = "invalid";
        endcase
    end
  endfunction

endmodule  // module testbench

