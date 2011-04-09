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
  integer    branches_executed, branches_mispredicted;
  reg [31:0] wb_fileno, mem_fileno;

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

  wire [`SCALAR*64-1:0] dp_is_NPC;
  wire [`SCALAR*32-1:0] dp_is_IR;
  wire [`SCALAR-1:0]    dp_is_valid_inst;

  wire [`SCALAR*64-1:0] is_ex_NPC;
  wire [`SCALAR*32-1:0] is_ex_IR;
  wire [`SCALAR-1:0]    is_ex_valid_inst;

  wire [`SCALAR*64-1:0] ex_co_NPC;
  wire [`SCALAR*32-1:0] ex_co_IR;
  wire [`SCALAR-1:0]    ex_co_valid_inst;

  wire [`SCALAR*64-1:0] rob_retire_NPC;
  wire [`SCALAR*32-1:0] rob_retire_IR;
  wire [`SCALAR-1:0]    rob_retire_valid_inst;

//DEBUG SIGNALS
`ifndef SYNTH
//*** RS DEBUG ***//
  integer rs_fileno;
  wire [31:0] rs1_IR[`RS_SZ-1:0];
  wire [63:0] rs1_npc[`RS_SZ-1:0];
  wire [`ROB_IDX-1:0] rs1_rob_idx[`RS_SZ-1:0];
  wire [`LSQ_IDX-1:0] rs1_lsq_idx[`RS_SZ-1:0];
  wire [`RS_SZ-1:0] rs1_rdy;
  wire [`RS_SZ-1:0] rs1_free;
  wire [`PRF_IDX-1:0] rs1_prega_idx[`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] rs1_pregb_idx[`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] rs1_pdest_idx[`RS_SZ-1:0];
`ifdef SUPERSCALAR
  wire [31:0] rs2_IR[`RS_SZ-1:0];
  wire [63:0] rs2_npc[`RS_SZ-1:0];
  wire [`ROB_IDX-1:0] rs2_rob_idx[`RS_SZ-1:0];
  wire [`LSQ_IDX-1:0] rs2_lsq_idx[`RS_SZ-1:0];
  wire [`RS_SZ-1:0] rs2_rdy;
  wire [`RS_SZ-1:0] rs2_free;
  wire [`PRF_IDX-1:0] rs2_prega_idx[`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] rs2_pregb_idx[`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] rs2_pdest_idx[`RS_SZ-1:0];
`endif  //SUPERSCALAR

generate
genvar rs_iter;
  for(rs_iter=0;rs_iter<`RS_SZ;rs_iter=rs_iter+1) begin : RS_DEBUG
    assign rs1_IR[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rs_IR_out;
    assign rs1_npc[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.npc_out;
    assign rs1_rob_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rob_idx_out;
    assign rs1_lsq_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.lsq_idx_out;
    assign rs1_rdy[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.rdy;
    assign rs1_free[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.entry_free;
    assign rs1_prega_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.prega_idx_out;
    assign rs1_pregb_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.pregb_idx_out;
    assign rs1_pdest_idx[rs_iter] = pipeline_0.rs0.rs0.entries[rs_iter].entry.pdest_idx_out;
    assign rs2_IR[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rs_IR_out;
    assign rs2_npc[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.npc_out;
    assign rs2_rob_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rob_idx_out;
    assign rs2_lsq_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.lsq_idx_out;
    assign rs2_rdy[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.rdy;
    assign rs2_free[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.entry_free;
    assign rs2_prega_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.prega_idx_out;
    assign rs2_pregb_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.pregb_idx_out;
    assign rs2_pdest_idx[rs_iter] = pipeline_0.rs0.rs1.entries[rs_iter].entry.pdest_idx_out;
  end
endgenerate
initial begin
  rs_fileno = $fopen("resstation.out");
end
always @(posedge clock) begin
 if(~reset) begin
  $fdisplay(rs_fileno, "|============================================== Cycle: %10d ============================================================|", clock_count);
  $fdisplay(rs_fileno, "id_dp_valid_inst: %b stall_id: %b rs0.inst_valid: %b", pipeline_0.id_dp_valid_inst, pipeline_0.stall_id, pipeline_0.rs0.inst_valid);
  $fdisplay(rs_fileno, "|                               RS0                               |                              RS1                          |");
  $fdisplay(rs_fileno, "| IDX |   IR    |       NPC      | LSQ | ROB | RA | RB | RD | R/F |    IR   |       NPC      | LSQ | ROB | RA | RB | RD | R/F |");
  $fdisplay(rs_fileno, "|=============================================================================================================================|");
  `define DISPLAY_RS(i) \
      $fdisplay(rs_fileno, "|%4d |%9s|%16h| %03d | %03d | %02d | %02d | %02d | %b/%b |%9s|%16h| %03d | %03d | %02d | %02d | %02d | %b/%b |", i, \
                get_instr_string(rs1_IR[i], !rs1_free[i]), rs1_npc[i], rs1_lsq_idx[i], rs1_rob_idx[i], rs1_prega_idx[i], rs1_pregb_idx[i], rs1_pdest_idx[i], rs1_rdy[i], rs1_free[i], \
                `ifdef SUPERSCALAR  \
                get_instr_string(rs2_IR[i], !rs2_free[i]), rs2_npc[i], rs2_lsq_idx[i], rs2_rob_idx[i], rs2_prega_idx[i], rs2_pregb_idx[i], rs2_pdest_idx[i], rs2_rdy[i], rs2_free[i]  \
                `endif  \
                );
  `DISPLAY_RS(0) `DISPLAY_RS(1) `DISPLAY_RS(2)
  `DISPLAY_RS(3) `DISPLAY_RS(4) `DISPLAY_RS(5)
  `DISPLAY_RS(6) `DISPLAY_RS(7) `DISPLAY_RS(8)
  `DISPLAY_RS(9) `DISPLAY_RS(10) `DISPLAY_RS(11)
  `DISPLAY_RS(12) `DISPLAY_RS(13) `DISPLAY_RS(14)
  `DISPLAY_RS(15)
  if(pipeline_error_status != `NO_ERROR)
    #(`VERILOG_CLOCK_PERIOD)
    $fclose(rs_fileno);
 end
end

//*** ROB DEBUG ***//
 integer rob_fileno, rob_idx;
 wire [31:0] rob_ir[`ROB_SZ-1:0];
 wire [63:0] rob_npc[`ROB_SZ-1:0];
 wire [`PRF_IDX-1:0] rob_pdest[`ROB_SZ-1:0];
 wire [4:0] rob_adest[`ROB_SZ-1:0];
 wire [63:0] cb_ba_pd[`ROB_SZ-1:0];
 wire rob_rdy[`ROB_SZ-1:0];
 wire [`ROB_SZ-1:0] cb_bt_pd;
 wire [`ROB_SZ-1:0] cb_isbranch;
 wire [`ROB_IDX-1:0] head = pipeline_0.rob0.head;
 wire [`ROB_IDX-1:0] tail = pipeline_0.rob0.tail; 
 initial begin                
  rob_fileno = $fopen("reorderbuf.out");
 end                          
always @(posedge clock) begin 
 if(~reset) begin
  $fdisplay(rob_fileno, "\n|============================================= Cycle: %10d ================================================|", clock_count);
  $fdisplay(rob_fileno, "| H/T | IDX |     IR    |        NPC       | RDY | PDR | ADR | BRA/TKN/PTN |  Branch Addr PD  |  Branch Addr EX  |");
  $fdisplay(rob_fileno, "|================================================================================================================|");
  `define DISPLAY_ROB(i) \
    $fdisplay(rob_fileno, "| %1s %1s | %3d | %9s | %h |  %b  | %3d | %3d |  %b / %b / %b  | %16h | %16h |",  \
              i === head ? "H" : " ",                         \
              i === tail ? "T" : " ", i,                      \
              get_instr_string(rob_ir[i], 1'b1),              \
              rob_npc[i], rob_rdy[i], rob_pdest[i], rob_adest[i],  \
              cb_isbranch[i], pipeline_0.rob0.data_bt_ex[i], cb_bt_pd[i], cb_ba_pd[i], pipeline_0.rob0.data_ba_ex[i]);
   `DISPLAY_ROB(0)
   `DISPLAY_ROB(1)
   `DISPLAY_ROB(2)
   `DISPLAY_ROB(3)
   `DISPLAY_ROB(4)
   `DISPLAY_ROB(5)
   `DISPLAY_ROB(6)
   `DISPLAY_ROB(7)
   `DISPLAY_ROB(8)
   `DISPLAY_ROB(9)
   `DISPLAY_ROB(10)
   `DISPLAY_ROB(11)
   `DISPLAY_ROB(12)
   `DISPLAY_ROB(13)
   `DISPLAY_ROB(14)
   `DISPLAY_ROB(15)
   `DISPLAY_ROB(16)
   `DISPLAY_ROB(17)
   `DISPLAY_ROB(18)
   `DISPLAY_ROB(19)
   `DISPLAY_ROB(20)
   `DISPLAY_ROB(21)
   `DISPLAY_ROB(22)
   `DISPLAY_ROB(23)
   `DISPLAY_ROB(24)
   `DISPLAY_ROB(25)
   `DISPLAY_ROB(26)
   `DISPLAY_ROB(27)
   `DISPLAY_ROB(28)
   `DISPLAY_ROB(29)
   `DISPLAY_ROB(30)
   `DISPLAY_ROB(31)
 end
 if(pipeline_error_status != `NO_ERROR)
   #(`VERILOG_CLOCK_PERIOD)
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
  assign rob_rdy    [rob_iter] = pipeline_0.rob0.data_rdy[rob_iter];
  end
endgenerate

//*** RAT DEBUG ***//
wire [`PRF_IDX-1:0] rat_value[31:0];
wire [`PRF_IDX-1:0] rrat_value[31:0];
integer rat_fileno, rat_loop;
initial begin                
  rat_fileno = $fopen("rat.out");
end                          

generate
genvar rat_iter;
  for(rat_iter=0;rat_iter<`ROB_SZ;rat_iter=rat_iter+1) begin : RAT_DEBUG
    assign rat_value[rat_iter] = pipeline_0.rat0.file_rat.registers[rat_iter];
    assign rrat_value[rat_iter] = pipeline_0.rat0.file_rrat.registers[rat_iter];
  end
endgenerate
always @(posedge clock) begin 
 if(~reset) begin
  $fdisplay(rat_fileno, "\n|=============================================== Cycle: %10d =========================================|", clock_count);
  if(pipeline_0.rat0.flush)
    $fdisplay(rat_fileno, "****** FLUSH ******");
  $fdisplay(rat_fileno, "| IDX | RAT PRF | RRAT PRF | IDX | RAT PRF | RRAT PRF | IDX | RAT PRF | RRAT PRF | IDX | RAT PRF | RRAT PRF |");
  $fdisplay(rat_fileno, "|===========================================================================================================|");
  `define DISPLAY_RAT(i) \
    $fwrite(rat_fileno, "|%4d |%8d |%9d ", \
              i, rat_value[i], rrat_value[i]);
  `DISPLAY_RAT(0)  `DISPLAY_RAT(1)
  `DISPLAY_RAT(16) `DISPLAY_RAT(17) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(2)  `DISPLAY_RAT(3)
  `DISPLAY_RAT(18) `DISPLAY_RAT(19) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(4)  `DISPLAY_RAT(5)
  `DISPLAY_RAT(20) `DISPLAY_RAT(21) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(6)  `DISPLAY_RAT(7)
  `DISPLAY_RAT(22) `DISPLAY_RAT(23) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(8)  `DISPLAY_RAT(9)
  `DISPLAY_RAT(24) `DISPLAY_RAT(25) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(10) `DISPLAY_RAT(11)
  `DISPLAY_RAT(26) `DISPLAY_RAT(27) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(12) `DISPLAY_RAT(13)
  `DISPLAY_RAT(28) `DISPLAY_RAT(29) $fwrite(rat_fileno, "|\n");
  `DISPLAY_RAT(14) `DISPLAY_RAT(15)
  `DISPLAY_RAT(30) `DISPLAY_RAT(31) $fwrite(rat_fileno, "|\n");
  `define DISPLAY_NUMBER_LIST \
  for(rat_loop=0;rat_loop <= `PRF_SZ; rat_loop=rat_loop+4) begin \
    $fwrite(rat_fileno, "%3d|", `PRF_SZ - rat_loop);      \
  end \
  $fwrite(rat_fileno, "\n");
  $fdisplay(rat_fileno, "Free List:         %b", pipeline_0.rat0.fl);
  $fwrite(rat_fileno,   "               ");
  `DISPLAY_NUMBER_LIST
  $fdisplay(rat_fileno, "Retire Free List:  %b", pipeline_0.rat0.rfl);
  $fwrite(rat_fileno,   "               ");
  `DISPLAY_NUMBER_LIST
  $fdisplay(rat_fileno, "Valid List:        %b", pipeline_0.rat0.valid_list);
  $fwrite(rat_fileno,   "               ");
 end
  if(pipeline_error_status != `NO_ERROR)
    #(`VERILOG_CLOCK_PERIOD)
    $fclose(rat_fileno);
end

//*** REGISTER DEBUG ***//
integer reg_fileno, reg_iter;
initial begin
  reg_fileno = $fopen("register.out");
end
always @(negedge clock) begin
  if(~reset) begin
    $fdisplay(reg_fileno, "\n|=============================================== Cycle: %10d =========================================|", clock_count);
    if(pipeline_0.ex_cdb_valid_out[0])
      $fwrite(reg_fileno, "CDB1: %2d | %8h ", pipeline_0.ex_cdb_tag_out[`SEL(`PRF_IDX, 1)], pipeline_0.ex_cdb_value_out[`SEL(64, 1)]);
    else
      $fwrite(reg_fileno, "CDB1: -- | -------- ");
    if(pipeline_0.ex_cdb_valid_out[1])
      $fwrite(reg_fileno, "CDB2: %2d | %8h\n", pipeline_0.ex_cdb_tag_out[`SEL(`PRF_IDX, 2)], pipeline_0.ex_cdb_value_out[`SEL(64, 2)]);
    else
      $fwrite(reg_fileno, "CDB2: -- | -------- \n");
    for(reg_iter = 0; reg_iter < `PRF_SZ; reg_iter=reg_iter+1) begin : REG_ITER
      $fdisplay(reg_fileno, "%2d | %h", reg_iter, pipeline_0.PRF.registers[reg_iter]);
    end
  end
  if(pipeline_error_status != `NO_ERROR)
    #(`VERILOG_CLOCK_PERIOD)
    $fclose(reg_fileno);
end


//*** LSQ DEBUG ***//
integer lsq_fileno, lsq_iter;
initial begin
  lsq_fileno = $fopen("lsq.out");
end
always @(negedge clock) begin
  if(~reset) begin
    $fdisplay(lsq_fileno,"\n== Cycle: %5d ==========================================", clock_count);
    $fdisplay(lsq_fileno,"==========================================================");
		$fdisplay(lsq_fileno,"| F/A | E/A | LCH | CM | IN | UP | \$VAL | MEMRES | \$TAG |");
    $fdisplay(lsq_fileno,"----------------------------------------------------------");
		$fdisplay(lsq_fileno,"| %b/%b | %b/%b |  %b  | %b%b | %b%b | %b%b |   %b  |   %2d   |  %2d  |", 
						 pipeline_0.lsq0.full, pipeline_0.lsq0.full_almost, pipeline_0.lsq0.empty, pipeline_0.lsq0.empty_almost, pipeline_0.lsq0.launch, 
						 pipeline_0.lsq0.commit[1], pipeline_0.lsq0.commit[0], pipeline_0.lsq0.in_req[1], pipeline_0.lsq0.in_req[0],
						 pipeline_0.lsq0.up_req[1], pipeline_0.lsq0.up_req[0], pipeline_0.lsq0.dcache2lsq_valid, pipeline_0.lsq0.mem2lsq_response, pipeline_0.lsq0.dcache2lsq_tag);
    $fdisplay(lsq_fileno,"==========================================================\n");
		
		`define DISPLAY_LSQ_ENTRY(i) \
		$fdisplay(lsq_fileno,"| %1s %1s |  %2d |   %b  |   %b  |   %b  |   %b  |  %2d  | %16h | %16h |", \
						 i===pipeline_0.lsq0.head ? "H" : " ", i===pipeline_0.lsq0.tail ? "T" : " ", i, \
						 pipeline_0.lsq0.wr_mem[i], pipeline_0.lsq0.ready_launch[i], pipeline_0.lsq0.ready_commit[i], \
						 pipeline_0.lsq0.launched[i], pipeline_0.lsq0.rob_idx[i], pipeline_0.lsq0.data_addr[i], pipeline_0.lsq0.data_regv[i]);
		
		$fdisplay(lsq_fileno,"======================================================================================");
  	$fdisplay(lsq_fileno,"| H/T | IDX | STOR | RDYL | RDYC | SENT | ROB# |       ADDR       |        VAL       |");
  	$fdisplay(lsq_fileno,"|------------------------------------------------------------------------------------|");

		`DISPLAY_LSQ_ENTRY(0)
		`DISPLAY_LSQ_ENTRY(1)
		`DISPLAY_LSQ_ENTRY(2)
		`DISPLAY_LSQ_ENTRY(3)
		`DISPLAY_LSQ_ENTRY(4)
		`DISPLAY_LSQ_ENTRY(5)
		`DISPLAY_LSQ_ENTRY(6)
		`DISPLAY_LSQ_ENTRY(7)

		$fdisplay(lsq_fileno,"======================================================================================\n");
		$fdisplay(lsq_fileno,"====================================================");
		$fdisplay(lsq_fileno,"| TAG | 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 1| 2| 3| 4| 5|");
		$fdisplay(lsq_fileno,"| LSQ | %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d|", 
						 pipeline_0.lsq0.lsq_map[1], 
						 pipeline_0.lsq0.lsq_map[2], 
						 pipeline_0.lsq0.lsq_map[3], 
						 pipeline_0.lsq0.lsq_map[4], 
						 pipeline_0.lsq0.lsq_map[5], 
						 pipeline_0.lsq0.lsq_map[6], 
						 pipeline_0.lsq0.lsq_map[7], 
						 pipeline_0.lsq0.lsq_map[8], 
						 pipeline_0.lsq0.lsq_map[9], 
						 pipeline_0.lsq0.lsq_map[10],
						 pipeline_0.lsq0.lsq_map[11],
						 pipeline_0.lsq0.lsq_map[12],
						 pipeline_0.lsq0.lsq_map[13],
						 pipeline_0.lsq0.lsq_map[14],
						 pipeline_0.lsq0.lsq_map[15]
						 );
		$fdisplay(lsq_fileno,"====================================================\n");
  end
  if(pipeline_error_status != `NO_ERROR)
    $fclose(lsq_fileno);
end



//*** EX_STAGE DEBUG ***//
integer ex_fileno;
initial begin
  ex_fileno = $fopen("ex_stage.out");
  $fdisplay(ex_fileno, "Cycle | TAG | CDB Inst | CDB Value |      ALU     F/D |      MEM     F/D |     MULT0    F/D |     MULT1    F/D |     MULT2    F/D |     MULT3    F/D |     MULT4    F/D |     MULT5    F/D |     MULT6    F/D |     MULT7    F/D |");
end
always @(negedge clock) begin
//  TODO: Finish this
  if(~reset) begin
    `define DISPLAY_MUX(x,y) ((x) ? (y) : "-")
    `define DISPLAY_MULT1_STAGE(i) \
      $fwrite(ex_fileno, "%5d:%9s %1s %1s |", pipeline_0.ex_co_stage0.MULT1.mstage[i].npc_out, \
      get_instr_string(pipeline_0.ex_co_stage0.MULT1.mstage[i].IR_out, pipeline_0.ex_co_stage0.MULT1.mstage[i].done_reg), \
      `DISPLAY_MUX(!pipeline_0.ex_co_stage0.MULT1.mstage[i].stall, "F"), \
      `DISPLAY_MUX(pipeline_0.ex_co_stage0.MULT1.mstage[i].done_reg, "D"));
    `define DISPLAY_MULT2_STAGE(i) \
      $fwrite(ex_fileno, "%5d:%9s %1s %1s |", pipeline_0.ex_co_stage0.MULT2.mstage[i].npc_out, \
      get_instr_string(pipeline_0.ex_co_stage0.MULT2.mstage[i].IR_out, pipeline_0.ex_co_stage0.MULT2.mstage[i].done_reg), \
      `DISPLAY_MUX(!pipeline_0.ex_co_stage0.MULT2.mstage[i].stall, "F"), \
      `DISPLAY_MUX(pipeline_0.ex_co_stage0.MULT2.mstage[i].done_reg, "D"));
    $fwrite(ex_fileno, "%5d ", clock_count);
/*    if(pipeline_0.ex_co_stage0.cdb_valid[0])
      $fwrite(ex_fileno, "| %2d | %5d:%9s | %16h ");
    else
      $fwrite(ex_fileno, "| -- |   --:--     | ------------------");
    $fwrite(ex_fileno, "| %5d:%9s %1s %1s");
    $fwrite(ex_fileno, "| %5d:%9s %1s %1s");  */
    `DISPLAY_MULT1_STAGE(0)
    `DISPLAY_MULT1_STAGE(1)
    `DISPLAY_MULT1_STAGE(2)
    `DISPLAY_MULT1_STAGE(3)
    `DISPLAY_MULT1_STAGE(4)
    `DISPLAY_MULT1_STAGE(5)
    `DISPLAY_MULT1_STAGE(6)
    `DISPLAY_MULT1_STAGE(7)
/*    if(pipeline_0.ex_co_stage0.cdb_valid[1])
      $fwrite(ex_fileno, "| %2d | %5d:%9s | %16h ");
    else
      $fwrite(ex_fileno, "| -- |   --:--     | ------------------");
    $fwrite(ex_fileno, "| %5d:%9s %1s %1s");
    $fwrite(ex_fileno, "| %5d:%9s %1s %1s"); */
    `DISPLAY_MULT2_STAGE(0)
    `DISPLAY_MULT2_STAGE(1)
    `DISPLAY_MULT2_STAGE(2)
    `DISPLAY_MULT2_STAGE(3)
    `DISPLAY_MULT2_STAGE(4)
    `DISPLAY_MULT2_STAGE(5)
    `DISPLAY_MULT2_STAGE(6)
    `DISPLAY_MULT2_STAGE(7)
  end
  if(pipeline_error_status != `NO_ERROR)
    #(`VERILOG_CLOCK_PERIOD)
    $fclose(ex_fileno);
end

always @(posedge clock) begin
  if(reset) begin
    branches_executed <= `SD 0;
    branches_mispredicted <= `SD 0;
  end
  else begin
    if(rob_retire_valid_inst[0] && pipeline_0.rob_retire_isbranch[0]) begin
      branches_executed <= `SD branches_executed + 1;
      branches_mispredicted <= `SD branches_mispredicted + (pipeline_0.rob_mispredict);
    end
  `ifdef SUPERSCALAR
    if(rob_retire_valid_inst[1] && pipeline_0.rob_retire_isbranch[1]) begin
      branches_executed <= `SD branches_executed + 1;
      branches_mispredicted <= `SD branches_mispredicted + (pipeline_0.rob_mispredict);
    end
  `endif
  end
end



//*** PIPELINE DEBUG ***//
integer pipe_fileno;
initial begin
  pipe_fileno = $fopen("pipeline.out");
  $fdisplay(pipe_fileno, "Cycle:       IF      |      ID       |      DP       |      IS       |      EX       |      CO       |      RE       |            WB            | MEM  ADDR  |");
end
always @(negedge clock) begin
 if(~reset) begin
   `SD `SD    //Delay for mem.v to catch up
   $fwrite(pipe_fileno, "%5d:", clock_count);
   `define DISPLAY_STAGE(npc, ir, valid) \
    $fwrite(pipe_fileno, "%5d:%10s|", npc, get_instr_string(ir, valid));
   `DISPLAY_STAGE(if_NPC_out[`SEL(64,1)],if_IR_out[`SEL(32,1)], if_valid_inst_out[0])
   `DISPLAY_STAGE(if_id_NPC[`SEL(64,1)], if_id_IR[`SEL(32,1)], if_id_valid_inst[0])
   `DISPLAY_STAGE(id_dp_NPC[`SEL(64,1)], id_dp_IR[`SEL(32,1)], id_dp_valid_inst[0])
   `DISPLAY_STAGE(dp_is_NPC[`SEL(64,1)], dp_is_IR[`SEL(32,1)], dp_is_valid_inst[0])
   `DISPLAY_STAGE(is_ex_NPC[`SEL(64,1)], is_ex_IR[`SEL(32,1)], is_ex_valid_inst[0])
   `DISPLAY_STAGE(ex_co_NPC[`SEL(64,1)], ex_co_IR[`SEL(32,1)], ex_co_valid_inst[0])
   `DISPLAY_STAGE(rob_retire_NPC[`SEL(64,1)], rob_retire_IR[`SEL(32,1)], rob_retire_valid_inst[0])
   if(pipeline_commit_wr_en[0])
     $fwrite(pipe_fileno, " REG[%2d]=%16x |", pipeline_commit_wr_idx[`SEL(5,1)], pipeline_commit_wr_data[`SEL(64,1)]);
   else
     $fwrite(pipe_fileno, "                          |");
   if(proc2mem_command == `BUS_LOAD) begin
     $fwrite(pipe_fileno, "BUS_LOAD MEM[%0h]", proc2mem_addr);
     if(mem2proc_response != 0)
       $fwrite(pipe_fileno, " accepted %0d", mem2proc_response);
     else
       $fwrite(pipe_fileno, " rejected");
   end
   else if(proc2mem_command == `BUS_STORE) begin
     $fwrite(pipe_fileno, "BUS_STORE MEM[%0h] = %0h", proc2mem_addr, proc2mem_data);
     if(mem2proc_response != 0)
       $fwrite(pipe_fileno, " accepted %0d", mem2proc_response);
     else
       $fwrite(pipe_fileno, " rejected");
   end
   $fwrite(pipe_fileno, "\n      ");
   `DISPLAY_STAGE(if_NPC_out[`SEL(64,2)],if_IR_out[`SEL(32,2)], if_valid_inst_out[1])
   `DISPLAY_STAGE(if_id_NPC[`SEL(64,2)], if_id_IR[`SEL(32,2)], if_id_valid_inst[1])
   `DISPLAY_STAGE(id_dp_NPC[`SEL(64,2)], id_dp_IR[`SEL(32,2)], id_dp_valid_inst[1])
   `DISPLAY_STAGE(dp_is_NPC[`SEL(64,2)], dp_is_IR[`SEL(32,2)], dp_is_valid_inst[1])
   `DISPLAY_STAGE(is_ex_NPC[`SEL(64,2)], is_ex_IR[`SEL(32,2)], is_ex_valid_inst[1])
   `DISPLAY_STAGE(ex_co_NPC[`SEL(64,2)], ex_co_IR[`SEL(32,2)], ex_co_valid_inst[1])
   `DISPLAY_STAGE(rob_retire_NPC[`SEL(64,2)], rob_retire_IR[`SEL(32,2)], rob_retire_valid_inst[1])
   if(pipeline_commit_wr_en[1])
     $fwrite(pipe_fileno, " REG[%2d]=%16x |", pipeline_commit_wr_idx[`SEL(5,2)], pipeline_commit_wr_data[`SEL(64,2)]);
   else
     $fwrite(pipe_fileno, "                          |");
   if(mem2proc_tag != 0)
     $fwrite(pipe_fileno, "RETURN %d", mem2proc_tag);
   $fwrite(pipe_fileno, "\n");
 end
 if(pipeline_error_status != `NO_ERROR)
   #(`VERILOG_CLOCK_PERIOD)
   $fclose(pipe_fileno);
end
`endif  //SYNTH


  // Strings to hold instruction opcode
  reg  [8*8:0] if_instr_str[`SCALAR-1:0];
  reg  [8*8:0] id_instr_str[`SCALAR-1:0];
  reg  [8*8:0] dp_instr_str[`SCALAR-1:0];
  reg  [8*8:0] co_instr_str[`SCALAR-1:0];

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
                       .id_dp_valid_inst(id_dp_valid_inst),
                       .dp_is_NPC(dp_is_NPC),
                       .dp_is_IR(dp_is_IR),
                       .dp_is_valid_inst(dp_is_valid_inst),
                       .is_ex_NPC(is_ex_NPC),
                       .is_ex_IR(is_ex_IR),
                       .is_ex_valid_inst(is_ex_valid_inst),
                       .ex_co_NPC(ex_co_NPC),
                       .ex_co_IR(ex_co_IR),
                       .ex_co_valid_inst(ex_co_valid_inst),
                       .rob_retire_NPC(rob_retire_NPC),
                       .rob_retire_IR(rob_retire_IR),
                       .rob_retire_valid_inst(rob_retire_valid_inst)
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
    if(~reset) begin
      $write("%c@@ %10d mispredicts / %10d branches = %5.2f%% Branch Accuracy  %10d cycles / %10d instrs = %8.4f CPI",
        8'd13, branches_mispredicted, branches_executed, 100.0*(1.0 - (1.0*branches_mispredicted) / branches_executed), //Branches
        clock_count+1, instr_count, (clock_count+1.0) / instr_count);                                 //CPI
    end
  end

  // Task to display # of elapsed clock edges
  task show_clk_count;
        real cpi;
        real accuracy;
        begin
     cpi = (clock_count + 1.0) / (instr_count + (pipeline_error_status == `HALTED_ON_HALT));
     accuracy =  100.0*(1.0 - (1.0*branches_mispredicted) / branches_executed);
     $display("@@ %0d mispredicts / %0d branches = %0.2f%% Branch Accuracy",
        branches_mispredicted, branches_executed, accuracy); //Branches
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
   input integer fileno;
   integer k;
   integer showing_data;
   begin
    $fdisplay(fileno, "@@@");
    showing_data=0;
    for(k=start_addr;k<=end_addr; k=k+1)
      if (memory.unified_memory[k] != 0)
      begin
        $fdisplay(fileno, "@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k],
                                                 memory.unified_memory[k]);
        showing_data=1;
      end
      else if(showing_data!=0)
      begin
        $fdisplay(fileno, "@@@");
        showing_data=0;
      end
    $fdisplay(fileno,"@@@");
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
      `ifdef DEBUG_QUIT
      if(clock_count > `DEBUG_QUIT) begin
          $display("Debug quit");
          #(`VERILOG_CLOCK_PERIOD)
          $fclose(wb_fileno);
          $finish;
      end
      `endif //DEBUG_QUIT
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
        /*$fdisplay(wb_fileno, "# SCALAR 1, IR=%s %h Cycle=%0d rob_pdest_idx: %2d",
                  co_instr_str[0], pipeline_commit_IR[`SEL(32,1)], clock_count,
                  pipeline_0.rob_retire_pdest_idx[`SEL(`PRF_IDX,1)]);*/
        if(pipeline_commit_wr_en[0])
          $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
                    pipeline_commit_NPC[`SEL(64, 1)]-4,
                    pipeline_commit_wr_idx[`SEL(5,1)],
                    pipeline_commit_wr_data[`SEL(64,1)]);
        else
          $fdisplay(wb_fileno, "PC=%x, ---", pipeline_commit_NPC[`SEL(64,1)]-4);
      end
      `ifdef SUPERSCALAR
      if(pipeline_completed_insts>1) begin
        /*$fdisplay(wb_fileno, "# SCALAR 2, IR=%s %h Cycle=%0d rob_pdest_idx: %2d",
                  co_instr_str[1], pipeline_commit_IR[`SEL(32,2)], clock_count,
                  pipeline_0.rob_retire_pdest_idx[`SEL(`PRF_IDX,2)]);*/
        if(pipeline_commit_wr_en[1])
          $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
                    pipeline_commit_NPC[`SEL(64, 2)]-4,
                    pipeline_commit_wr_idx[`SEL(5,2)],
                    pipeline_commit_wr_data[`SEL(64,2)]);
        else
          $fdisplay(wb_fileno, "PC=%x, ---", pipeline_commit_NPC[`SEL(64,2)]-4);
      end
      `endif //SUPERSCALAR

      // deal with any halting conditions
      if(pipeline_error_status!=`NO_ERROR)
      begin
        mem_fileno = $fopen("memory.out");
        $fdisplay(mem_fileno, "@@@ Unified Memory contents hex on left, decimal on right: ");
        show_mem_with_decimal(0,`MEM_64BIT_LINES - 1, mem_fileno); 
        $fclose(mem_fileno);
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
        #(`VERILOG_CLOCK_PERIOD)
        $finish;
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

  function [8*8:0] get_instr_string;
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

