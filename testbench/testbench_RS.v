/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_RS.v                                      //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps


module testbench;

 integer idx, limbo_inst, NPC;  //TEST VARS
  // Registers and wires used in the testbench
  reg  clk,  reset;
  reg  [`SCALAR-1:0]  inst_valid;      //  Instruction  ready
  reg  [`PRF_IDX-1:0] prega_idx[`SCALAR-1:0];
  reg  [`PRF_IDX-1:0] pregb_idx[`SCALAR-1:0];
  reg  [`PRF_IDX-1:0] pdest_idx[`SCALAR-1:0];
  reg  [`SCALAR-1:0]  prega_valid,  pregb_valid;
  reg  [4:0]          ALUop[`SCALAR-1:0];
  reg  [`SCALAR-1:0]  rd_mem,  wr_mem;
  reg  [31:0]         rs_IR[`SCALAR-1:0];
  reg  [`SCALAR-1:0]  cond_branch,  uncond_branch;
  reg  [63:0]         npc[`SCALAR-1:0];
  reg  [`SCALAR-1:0]  multfu_free,  exfu_free,  memfu_free,  cdb_valid;
  reg  [`SCALAR*`PRF_IDX-1:0]  cdb_tag;
  reg  [`ROB_IDX-1:0] rob_idx[`SCALAR-1:0];
  reg  [`RS_SZ-1:0]   entry_flush[`SCALAR-1:0];
 
  //OUTPUT
  wire  [`SCALAR-1:0]  rs_stall,  rs_rdy;
  wire  [`PRF_IDX-1:0] pdest_idx_out[`SCALAR-1:0];
  wire  [`PRF_IDX-1:0] prega_idx_out[`SCALAR-1:0];
  wire  [`PRF_IDX-1:0] pregb_idx_out[`SCALAR-1:0];
  wire  [4:0]          ALUop_out[`SCALAR-1:0];
  wire  [`SCALAR-1:0]  rd_mem_out,  wr_mem_out;
  wire  [31:0]  rs_IR_out[`SCALAR-1:0];
  wire  [63:0]  npc_out[`SCALAR-1:0];
  wire  [`ROB_IDX-1:0]  rob_idx_out[`SCALAR-1:0];
  wire  [`RS_IDX-1:0]  rs_idx_out[`SCALAR-1:0];
  wire  [`SCALAR-1:0]  en_out;

`ifdef SUPERSCALAR
  `define FLAT(VAL) {VAL[1], VAL[0]}
`else
  `define FLAT(VAL) VAL[0]
`endif

  SUPER_RS srs(clk, reset,
                //INPUTS
                inst_valid, `FLAT(prega_idx), `FLAT(pregb_idx), `FLAT(pdest_idx), prega_valid, pregb_valid, //RAT
                `FLAT(ALUop), rd_mem, wr_mem, `FLAT(rs_IR),  `FLAT(npc), cond_branch, uncond_branch,        //Issue Stage
                multfu_free, exfu_free, memfu_free, cdb_valid, cdb_tag, `FLAT(entry_flush),   //Pipeline communication
                `FLAT(rob_idx),                                                               //ROB
                0,                                                                            //LSQ

                //OUTPUT
                rs_stall,  rs_rdy,                                                     //Hazard detect
                `FLAT(pdest_idx_out), `FLAT(prega_idx_out), `FLAT(pregb_idx_out), `FLAT(ALUop_out), rd_mem_out,    //FU
                wr_mem_out, `FLAT(rs_IR_out), `FLAT(npc_out), `FLAT(rob_idx_out), en_out,                   //FU
                `FLAT(rs_idx_out),                                                             //ROB
          );

  // Generate System Clock
  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

  always @(posedge clk)
  begin
    if(inst_valid != 2'b00)
    begin
      if (limbo_inst < `SCALAR*`RS_SZ && rs_stall == 2'b11)
      begin // Not Full condition!
        $display("@@@ Fail! Time: %4.0f RS is supposed to be have an empty entry, but doesn't! rs_stall: %b @@@", $time, rs_stall);
        $finish;
      end
      limbo_inst = limbo_inst + (rs_stall[0] & inst_valid[0] ) + (rs_stall[1] & inst_valid[1]);
      if(limbo_inst > `SCALAR*`RS_SZ)
      begin   // Full condition!
        $display("@@@ Fail! Time: %4.0f RS is supposed to be full, but isn't! @@@", $time);
        $finish;
      end
    end
    if(multfu_free | exfu_free | memfu_free)
    begin
      if(limbo_inst <= 0 && | rs_rdy)
      begin // Empty test
        $display("@@@ Fail! Time: %4.0f RS entry is said to be ready, but no RS entry is allocated! @@@", $time);
        $display("@@@ [0] dest: %h opA: %h opB: %h ALUop: %h rd_mem: %h wr_mem: %h IR: %h NPC: %h ROB: %h",
                  pdest_idx_out[0], prega_idx_out[0], pregb_idx_out[0], ALUop_out[0], rd_mem_out[0], wr_mem_out[0], rs_IR_out[0],
                  npc_out[0], rob_idx_out[0]);
`ifdef SUPERSCALAR        
        $display("@@@ [0] dest: %h opA: %h opB: %h ALUop: %h rd_mem: %h wr_mem: %h IR: %h NPC: %h ROB: %h",
                  pdest_idx_out[1], prega_idx_out[1], pregb_idx_out[1], ALUop_out[1], rd_mem_out[1], wr_mem_out[1], rs_IR_out[1],
                  npc_out[1], rob_idx_out[1]);
`endif
        $finish;
      end
      else
        limbo_inst = limbo_inst - (rs_rdy[0] + rs_rdy[1]);
    end
  end

  // Task to insert an instruction 
  task insert_inst;
  input [`PRF_IDX-1:0] rega_idx, regb_idx, dest_idx;
  input rega_valid, regb_valid, rdmem_in, wrmem_in;
  input [4:0] ALUop_in;
  input which;
  begin
    NPC = NPC + 2;
    npc[which] = NPC;
    rs_IR[which] = NPC / 2; // whatever
    rob_idx[which] = rs_IR[which] + 1;

    inst_valid[which] = 1'b1;

    prega_idx[which] = rega_idx;
    pregb_idx[which] = regb_idx;
    pdest_idx[which] = dest_idx;
    prega_valid[which] = rega_valid;
    pregb_valid[which] = regb_valid;
    ALUop[which] = ALUop_in;
    rd_mem[which] = rdmem_in;
    wr_mem[which] = wrmem_in;
    cond_branch[which] = 1'b0;
    uncond_branch[which] = 1'b0;
		
	$display("Inserting Inst[%b]@%4.0fns: [%02d(%b), %02d(%b)] => %02d (ROB#: %02d, npc: 0x%h), ALUop: 0x%h, rdmem: %b, wrmem: %b",
				which, $time, rega_idx, rega_valid, regb_idx, regb_valid, dest_idx, rob_idx[which], npc[which], ALUop_in, rdmem_in, wrmem_in);

  end
  endtask

  task insert_ALUinst;
    input [`PRF_IDX-1:0] rega_idx, regb_idx, dest_idx;
    input rega_valid, regb_valid, mult;
    input which;
    insert_inst(rega_idx, regb_idx, dest_idx, rega_valid, regb_valid, 0, 0, mult ? `ALU_MULQ : `ALU_ADDQ, which);
  endtask

  task insert_MEMinst;
    input [`PRF_IDX-1:0] rega_idx, regb_idx, dest_idx;
    input rega_valid, regb_valid, rdmem_in, wrmem_in;
    input which;
    insert_inst(rega_idx, regb_idx, dest_idx, rega_valid, regb_valid, rdmem_in, wrmem_in, rdmem_in ? `LDQ_U_INST : `STQ_U_INST, which);
  endtask
	// Task to set CDB Tag/Valid
	task set_CDB;
		input [`PRF_IDX-1:0] tag;
		input valid;
        input scalar;
		begin
            if(scalar) begin
			cdb_tag[2*`PRF_IDX-1:`PRF_IDX] = tag;
			cdb_valid[1] = valid;
			$display("Setting CDB[%b]@%4.0fns: Register Tag = %02d Valid = %b", scalar, $time, cdb_tag[2*`PRF_IDX-1:`PRF_IDX], cdb_valid[scalar]);
            end
            else begin
			cdb_tag[`PRF_IDX-1:0] = tag;
			cdb_valid[0] = valid;
			$display("Setting CDB[%b]@%4.0fns: Register Tag = %02d Valid = %b", scalar, $time, cdb_tag[`PRF_IDX-1:0], cdb_valid[scalar]);
            end
		end
	endtask

	task CDB_fail;
		begin
			$display("@@@ Fail! CDB is broadcasting, but the valid bit has not been updated @ %4.0d", $time);
			$finish;
		end
	endtask

  // Task to display RS content of an Entry
  task show_entry_content;
  input integer which;
  begin
  `ifdef SYNTH
    $display("");
  `else
  `define DISPLAY_ENTRY(which, i) \
    if (which == 0) \
     $display("0.%02d |  0x%h/%b/%b |  %02d  |   %02d /  %b   |   %02d /  %b   |   %b  |   %b   | 0x%h | %02d   ", i, srs.rs0.entries[i].entry.ALUop_out, srs.rs0.entries[i].entry.rd_mem_out, srs.rs0.entries[i].entry.wr_mem_out, srs.rs0.entries[i].entry.pdest_idx_out, srs.rs0.entries[i].entry.prega_idx_out, srs.rs0.entries[i].entry.prega_rdy, srs.rs0.entries[i].entry.pregb_idx_out, srs.rs0.entries[i].entry.pregb_rdy, srs.rs0.entries[i].entry.entry_free, srs.rs0.entries[i].entry.ALU_rdy | srs.rs0.entries[i].entry.mem_rdy | srs.rs0.entries[i].entry.mult_rdy, srs.rs0.entries[i].entry.rs_IR_out, srs.rs0.entries[i].entry.rob_idx_out);   \
    else    \
     $display("1.%02d |  0x%h/%b/%b |  %02d  |   %02d /  %b   |   %02d /  %b   |   %b  |   %b   | 0x%h | %02d   ", i, srs.rs1.entries[i].entry.ALUop_out, srs.rs1.entries[i].entry.rd_mem_out, srs.rs1.entries[i].entry.wr_mem_out, srs.rs1.entries[i].entry.pdest_idx_out, srs.rs1.entries[i].entry.prega_idx_out, srs.rs1.entries[i].entry.prega_rdy, srs.rs1.entries[i].entry.pregb_idx_out, srs.rs1.entries[i].entry.pregb_rdy, srs.rs1.entries[i].entry.entry_free, srs.rs1.entries[i].entry.ALU_rdy | srs.rs1.entries[i].entry.mem_rdy | srs.rs1.entries[i].entry.mult_rdy, srs.rs1.entries[i].entry.rs_IR_out, srs.rs1.entries[i].entry.rob_idx_out);

    $display("============================================================================================ ");
    $display("Entry| ALU/RD/WR | Dest	| A Tag / Vld | B Tag / Vld | Free | Ready |     IR     | ROB#  ");
    $display("============================================================================================ ");
    `DISPLAY_ENTRY(which,15)
    `DISPLAY_ENTRY(which,14) 
    `DISPLAY_ENTRY(which,13) 
    `DISPLAY_ENTRY(which,12) 
    `DISPLAY_ENTRY(which,11) 
    `DISPLAY_ENTRY(which,10) 
    `DISPLAY_ENTRY(which,9)  
    `DISPLAY_ENTRY(which,8)  
    `DISPLAY_ENTRY(which,7)  
    `DISPLAY_ENTRY(which,6)  
    `DISPLAY_ENTRY(which,5)  
    `DISPLAY_ENTRY(which,4)  
    `DISPLAY_ENTRY(which,3)  
    `DISPLAY_ENTRY(which,2)  
    `DISPLAY_ENTRY(which,1)  
    `DISPLAY_ENTRY(which,0)  
    $display("============================================================================================\n\n "); 
  `endif
  end
  endtask

  task reset_all;
  integer i;
  begin
    for(i=0;i<`SCALAR;i=i+1) begin
        inst_valid[i] = 2'b00;
        prega_idx[i] = 0;
        pregb_idx[i] = 0;
        pdest_idx[i] = 0;
        prega_valid[i] = 0;
        pregb_valid[i] = 0;
        ALUop[i] = 0;
        rd_mem[i] = 0;
        wr_mem[i] = 0;
        rs_IR[i] = 0;
        cond_branch[i] = 0;
        uncond_branch[i] = 0;
        npc[i] = 0;
        rob_idx[i] = 0;
        entry_flush[i] = 0;
    end
    multfu_free = 0;
    exfu_free = 0;
    memfu_free = 0;
    cdb_valid = 0;
    cdb_tag = 0;
    limbo_inst = 0;
    NPC = 0;
  end
  endtask
  
  // Testbench
  initial
  begin
    reset = 1'b1;
    clk = 1'b0;
    reset_all();
    @(negedge clk);
    reset = 1'b0;
    // Initialize input signals
    @(negedge clk);
	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Insert one until full\n", $time);
    $display("=============================================================\n");

    for(idx=0;idx<`SCALAR*`RS_SZ;idx=idx+1)
    begin
      @(negedge clk);
      if(rs_stall != (idx < `RS_SZ ? 2'b00 : 2'b01)) begin
        $display("@@@ Fail! RS is full too early!");
        $finish;
      end
      insert_ALUinst(idx,idx+1,idx+2,0,0,0,0);
    end
    @(negedge clk);
    inst_valid = 2'b00;
    @(posedge clk);
    if(rs_stall != 2'b11)
    begin
      $display("@@@ Fail! ALU full test failed");
      $finish;
    end
    else
      $display("@@@ Success! ALU full test passed");

    show_entry_content(0);
    show_entry_content(1);
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Validate cdb on each instruction and test for empty\n", $time);
    $display("=============================================================\n");
    @(negedge clk);
    exfu_free=1'b1;               //Free an ALU entry every clock cycle
    set_CDB(5'b0, 1'b1, 1'b0);    //Set the first register for the first instruction
    @(negedge clk);
    for(idx=0;idx<`RS_SZ; idx=idx+1)
    begin
      set_CDB(idx+1, 1'b1, 1'b0); //Send the first operand (next iteration will get the second operand)
      @(posedge clk);
      if(~| rs_rdy) begin
        $display("@@@ Fail! rs_rdy not asserted when instruction should be ready");
        $display("@@@ Limbo: %0d  rs_stall: %h", limbo_inst, rs_stall);
        $finish;
      end
      if(~en_out[0]) begin
          $display("@@@ Fail!  Instruction not valid");
          $finish;
      end
      if(prega_idx_out[0] != idx || pregb_idx_out[0] != idx+1 || pdest_idx_out[0] != idx+2 ||
         ALUop_out[0] != `ALU_ADDQ || rd_mem_out[0] != 0 || wr_mem_out[0] != 0 || rs_IR_out[0] != idx+1 ||
         npc_out[0] != 2*(idx+1) || rob_idx_out[0] != (idx+2)%`ROB_SZ)
       begin
         $display("@@@ Fail! Instruction output does not match expected values!");
         $display("@@@ idx: %0d dest: %02d opA: %02d opB: %02d ALUop: %h rd_mem: %b wr_mem: %b IR: %h NPC: %h ROB: %02d",
                  idx, pdest_idx_out[0], prega_idx_out[0], pregb_idx_out[0], ALUop_out[0], rd_mem_out[0], wr_mem_out[0], rs_IR_out[0],
                  npc_out[0], rob_idx_out[0]);
         $finish;
       end
      @(negedge clk);
    end
    show_entry_content(0);
    show_entry_content(1);
    //Second RS
    `ifdef SUPERSCALAR
    for(idx=idx;idx<2*`RS_SZ; idx=idx+1)
    begin
      set_CDB(idx+1, 1'b1, 1'b0); //Send the first operand (next iteration will get the second operand)
      @(posedge clk);
      if(~| rs_rdy) begin
        $display("@@@ Fail! rs_rdy not asserted when instruction should be ready");
        $display("@@@ Limbo: %0d  rs_stall: %h", limbo_inst, rs_stall);
        $finish;
      end
      if(prega_idx_out[1] != idx || pregb_idx_out[1] != idx+1 || pdest_idx_out[1] != idx+2 ||
         ALUop_out[1] != 0 || rd_mem_out[1] != 0 || wr_mem_out[1] != 0 || rs_IR_out[1] != idx+1 ||
         npc_out[1] != 2*(idx+1) || rob_idx_out[1] != (idx+2) % `ROB_SZ)
       begin
         $display("@@@ Fail! Instruction output does not match expected values!");
         $display("@@@ idx: %0d dest: %02d opA: %02d opB: %02d ALUop: %h rd_mem: %b wr_mem: %b IR: 0x%h NPC: 0x%h ROB: %02d",
                  idx, pdest_idx_out[1], prega_idx_out[1], pregb_idx_out[1], ALUop_out[1], rd_mem_out[1], wr_mem_out[1], rs_IR_out[1],
                  npc_out[1], rob_idx_out[1]);
         $finish;
       end
      @(negedge clk);
    end
    `endif
    set_CDB(0, 1'b0, 1'b0); //Send the first operand (next iteration will get the second operand)
    show_entry_content(0);
    show_entry_content(1);
    //Refill 2*`RS_SZ again to test if completely empty
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Refill RS\n", $time);
    $display("=============================================================\n");
    for(idx=0;idx<`SCALAR*`RS_SZ;idx=idx+1)
    begin
      @(negedge clk);
      if(rs_stall != (idx < `RS_SZ ? 2'b00 : 2'b01)) begin
        $display("@@@ Fail! RS is full too early!");
        $finish;
      end
      insert_ALUinst(idx,idx+1,idx+2,0,0,0,0);
    end
    @(negedge clk);
    inst_valid = 2'b00;
    @(posedge clk);
    show_entry_content(0);
    show_entry_content(1);
    if(rs_stall != 2'b11)
    begin
      $display("@@@ Fail! ALU refill test failed");
      $finish;
    end
    else
      $display("@@@ Success! ALU refill test passed");
    exfu_free=1'b0; //Disable ALUs
    set_CDB(0,0,0); //Disable CDB

    reset_all();
    reset = 1'b1;
    @(negedge clk);
    @(posedge clk);
    reset = 1'b0;
    @(negedge clk);

    // Test case: Super scalar test
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Insert superscalar until full\n", $time);
    $display("=============================================================\n");
`ifndef SUPERSCALAR
    $display("Test not applicable for non-super scalar");
`else
    for(idx=0;idx<`RS_SZ;idx=idx+1)
    begin
      @(negedge clk);
      if(rs_stall != 2'b00) begin
        $display("@@@ Fail! RS is full too early!");
        $finish;
      end
      insert_ALUinst(idx,idx+1,idx+2,0,0,0,0);
      insert_ALUinst(`RS_SZ+idx,`RS_SZ+idx+1,`RS_SZ+idx+2,0,0,0,1);
    end
    @(negedge clk);
    inst_valid = 2'b00;
    @(posedge clk);
    if(rs_stall != 2'b11)
    begin
      $display("@@@ Fail! ALU full test failed");
      $finish;
    end
    else
      $display("@@@ Success! ALU full test passed");
`endif

    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Superscalar validate cdb on each instruction and test for empty\n", $time);
    $display("=============================================================\n");
`ifndef SUPERSCALAR
    $display("Test not applicable for non-super scalar");
`else
    @(negedge clk);
    exfu_free=2'b11;               //Free two ALU entries every clock cycle
    set_CDB(5'b0, 1'b1, 1'b0);    //Set the first register for the first instruction
    set_CDB(`RS_SZ, 1'b1, 1'b1);    //Set the first register for the first instruction
    @(negedge clk);
    for(idx=0;idx<`RS_SZ; idx=idx+1)
    begin
      set_CDB(idx+1, 1'b1, 1'b0); //Send the first operand (next iteration will get the second operand)
      set_CDB(`RS_SZ+idx+1, 1'b1, 1'b1); //Send the first operand (next iteration will get the second operand)
      @(posedge clk);
      if(~| rs_rdy) begin
        $display("@@@ Fail! rs_rdy not asserted when instruction should be ready");
        $display("@@@ Limbo: %0d  rs_stall: %h", limbo_inst, rs_stall);
        $finish;
      end
      if(~en_out[0]) begin
          $display("@@@ Fail!  Instruction not valid");
          $finish;
      end
      if(prega_idx_out[0] != idx || pregb_idx_out[0] != idx+1 || pdest_idx_out[0] != idx+2 ||
         ALUop_out[0] != `ALU_ADDQ || rd_mem_out[0] != 0 || wr_mem_out[0] != 0)
       begin
         $display("@@@ Fail! Instruction[0] output does not match expected values!");
         $display("@@@ idx: %0d dest: %02d opA: %02d opB: %02d ALUop: %h rd_mem: %b wr_mem: %b IR: %h NPC: %h ROB: %02d",
                  idx, pdest_idx_out[0], prega_idx_out[0], pregb_idx_out[0], ALUop_out[0], rd_mem_out[0], wr_mem_out[0], rs_IR_out[0],
                  npc_out[0], rob_idx_out[0]);
         $finish;
       end
      if(prega_idx_out[1] != `RS_SZ+idx || pregb_idx_out[1] != `RS_SZ+idx+1 || pdest_idx_out[1] != `RS_SZ+idx+2 ||
         ALUop_out[1] != `ALU_ADDQ || rd_mem_out[1] != 0 || wr_mem_out[1] != 0)
       begin
         $display("@@@ Fail! Instruction[1] output does not match expected values!");
         $display("@@@ idx: %0d dest: %02d opA: %02d opB: %02d ALUop: %h rd_mem: %b wr_mem: %b IR: %h NPC: %h ROB: %02d",
                  idx, pdest_idx_out[1], prega_idx_out[1], pregb_idx_out[1], ALUop_out[1], rd_mem_out[1], wr_mem_out[1], rs_IR_out[1],
                  npc_out[1], rob_idx_out[1]);
         $finish;
       end
      @(negedge clk);
    end
`endif
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Refill Superscalar\n", $time);
    $display("=============================================================\n");
`ifndef SUPERSCALAR
    $display("Test not applicable for non-super scalar");
`else
    for(idx=0;idx<`RS_SZ;idx=idx+1)
    begin
      @(negedge clk);
      if(rs_stall != 2'b00) begin
        $display("@@@ Fail! RS is full too early!");
        $finish;
      end
      insert_ALUinst(idx,idx+1,idx+2,0,0,0,0);
      insert_ALUinst(`RS_SZ+idx,`RS_SZ+idx+1,`RS_SZ+idx+2,0,0,0,1);
    end
    @(negedge clk);
    inst_valid = 2'b00;
    @(posedge clk);
    if(rs_stall != 2'b11)
    begin
      $display("@@@ Fail! ALU full test failed");
      $finish;
    end
    else
      $display("@@@ Success! ALU full test passed");
`endif
    
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Each FU is ready, but no instructions rdy\n", $time);
    $display("=============================================================\n");
    @(negedge clk);
    exfu_free = 2'b11;
    @(posedge clk);
    if(en_out != 2'b00) begin
      $display("@@@ Fail! Valid ALU instruction is out, but shouldn't be ready!");
      $finish;
    end
    @(negedge clk);
    memfu_free = 2'b11;
    @(posedge clk);
    if(en_out != 2'b00) begin
      $display("@@@ Fail! Valid MEM instruction is out, but shouldn't be ready!");
      $finish;
    end
    @(negedge clk);
    multfu_free = 2'b11;
    @(posedge clk);
    if(en_out != 2'b00) begin
      $display("@@@ Fail! Valid MULT instruction is out, but shouldn't be ready!");
      $finish;
    end
    if(rs_stall != 2'b11) begin //Must still be full
      $display("@@@ Fail! RS is no longer full!");
      $finish;
    end
    $display("@@@ Success! Passed FU is ready and no instructions rdy");

    // Test case #1.1: Insert new instruction 
/*   
    $display("=============================================================\n");
    $display("@@@ Test case #1.1: Insert ALU instruction\n");
    $display("=============================================================\n");
    

    insert_ALUinst(1,2,3,1,1,0);
    @(negedge clk);show_entry_content();
    insert_ALUinst(2,3,4,1,0,0);
    @(negedge clk);show_entry_content();
    insert_ALUinst(3,4,5,0,0,0);
    @(negedge clk);show_entry_content();
    insert_ALUinst(4,5,6,0,0,0);
    exfu_free=1'b1; 
    set_CDB(3,1,0); 
    @(negedge clk);show_entry_content();
    insert_ALUinst(5,6,7,0,0,0);
    exfu_free=1'b1; 
    set_CDB(4,1,0); 
    @(negedge clk);show_entry_content();
    rs_en = 1'b0;  // disable RS No more Inst
    exfu_free=1'b1; 
    set_CDB(5,1,0); 
    @(negedge clk);show_entry_content();
    exfu_free=1'b1; 
    set_CDB(6,1,0); 
    @(negedge clk);show_entry_content();
    exfu_free=1'b1; 
    set_CDB(7,1,0);
    @(negedge clk); show_entry_content();
    $display("@@@ Success!  Test #1.1 Passed!");

    reset_all();
    reset = 1'b1;
    @(negedge clk);
    reset = 1'b0;
    
    $display("=============================================================\n");
    $display("@@@ Test case #1.2: Insert MULT instruction\n");
    $display("=============================================================\n");
    
    insert_ALUinst(1,2,3,1,1,1);show_entry_content();
    @(negedge clk);
    insert_ALUinst(2,3,4,1,0,1);show_entry_content();
    @(negedge clk);
    insert_ALUinst(3,4,5,0,0,1);show_entry_content();
    @(negedge clk);
    insert_ALUinst(4,5,6,0,0,1);show_entry_content();
    mult_free=1'b1; 
    set_CDB(3,1,0); 
    @(negedge clk);show_entry_content();
    insert_ALUinst(5,6,7,0,0,1);
    mult_free=1'b1; 
    set_CDB(4,1,0); 
    @(negedge clk);show_entry_content();
    rs_en = 1'b0;  // disable RS No more Inst
    mult_free=1'b1; 
    set_CDB(5,1,0); 
    @(negedge clk);show_entry_content();
    mult_free=1'b1; 
    set_CDB(6,1,0); 
    @(negedge clk);show_entry_content();
    mult_free=1'b1; 
    set_CDB(7,1,0);
    @(negedge clk); show_entry_content();

    $display("@@@ Success!  Test #1.2 Passed!");

    reset_all();
    reset = 1'b1;
    @(negedge clk);
    reset = 1'b0;
    // Test case #1.3: Insert new instruction 
    
    $display("=============================================================\n");
    $display("@@@ Test case #1.3: Insert MEM instruction\n");
    $display("=============================================================\n");
    
    insert_MEMinst(1,2,3,1,1,1,0);
    @(negedge clk);show_entry_content();
    insert_MEMinst(2,3,4,1,0,1,0);
    @(negedge clk);show_entry_content();
    insert_MEMinst(3,4,5,0,0,1,0);
    @(negedge clk);show_entry_content();
    insert_MEMinst(4,5,6,0,0,1,0);
    mem_free=1'b1; 
    set_CDB(3,1,0); 
    @(negedge clk);show_entry_content();
    insert_MEMinst(5,6,7,0,0,1,0);
    mem_free=1'b1; 
    set_CDB(4,1,0); 
    @(negedge clk);show_entry_content();
    rs_en = 1'b0;  // disable RS No more Inst
    mem_free=1'b1; 
    set_CDB(5,1,0); 
    @(negedge clk);show_entry_content();
    mem_free=1'b1; 
    set_CDB(6,1,0); 
    @(negedge clk);show_entry_content();
    mem_free=1'b1; 
    set_CDB(7,1,0);
    @(negedge clk);  show_entry_content();

    $display("@@@ Success!  Test #1.3 Passed!");

    // Reset RS
    reset = 1'b1;      // Assert Reset
    clk = 1'b0;
    @(negedge clk);
    reset = 1'b0;      // Deassert Reset
    rs_en = 1'b1;  // Enable RS
    // Initialize input signals
    reset_all();

  
    // Test case #x.x: CDB Test
	@(negedge clk); 
	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Basic Internal CDB Test\n", $time);
    $display("=============================================================\n");
  `ifdef SYNTH
    $display("Test not applicable in synth mode");
  `else
	reset_all(); @(negedge clk); show_entry_content();

    insert_ALUinst( 1, 2, 3,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 2, 3, 4,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 3, 4, 5,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 4, 5, 6,0,0,1); @(negedge clk); show_entry_content();
    insert_ALUinst( 5, 6, 7,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 6, 7, 8,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 7, 8, 9,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst( 8, 9,10,0,0,1); @(negedge clk); show_entry_content();
    insert_ALUinst( 9,10,11,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst(10,11,12,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst(11,12,13,0,0,0); @(negedge clk); show_entry_content();
    insert_ALUinst(12,13,14,0,0,1); @(negedge clk); show_entry_content();
    insert_inst(13,14,15,0,0,0,1,0); @(negedge clk); show_entry_content();
    insert_inst(14,15,16,0,0,0,0,1); @(negedge clk); show_entry_content();
    insert_inst(15,16,17,0,0,0,1,0); @(negedge clk); show_entry_content();
    insert_inst(16,17,18,0,0,0,0,1); @(negedge clk); show_entry_content();

    set_CDB(2, 1, 0); @(negedge clk); show_entry_content();
		if(rs_0.entries[15].entry.pregb_rdy==1'b0 | rs_0.entries[14].entry.prega_rdy==1'b0) CDB_fail();
    set_CDB(2, 0, 0); @(negedge clk); show_entry_content();
		if(rs_0.entries[15].entry.pregb_rdy==1'b0 | rs_0.entries[14].entry.prega_rdy==1'b0) CDB_fail();
    set_CDB(3, 1, 0); @(negedge clk); show_entry_content();
		if(rs_0.entries[14].entry.pregb_rdy==1'b0 | rs_0.entries[13].entry.prega_rdy==1'b0) CDB_fail();
    set_CDB(4, 1, 0); @(negedge clk); show_entry_content();
		if(rs_0.entries[13].entry.pregb_rdy==1'b0 | rs_0.entries[12].entry.prega_rdy==1'b0) CDB_fail();
    set_CDB(5, 1, 0); @(negedge clk); show_entry_content();
		if(rs_0.entries[12].entry.pregb_rdy==1'b0 | rs_0.entries[11].entry.prega_rdy==1'b0) CDB_fail();
   
	$display("@@@ Success! Basic CDB test passed");
		
	@(negedge clk);
    `endif

	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case #5.1: FU becomes free, but no inst ready\n", $time);
    $display("=============================================================\n");

		// reset rs
		reset_all();
		@(negedge clk);
		reset = 1'b1;
		exfu_free = 1'b0;
		mult_free = 1'b0;
		@(negedge clk);
		reset = 1'b0;
		@(negedge clk);

		// begin test
    for(idx=0;idx<`RS_SZ; idx=idx+1)
    begin
		insert_ALUinst(5,9,21,0,0,0); @(negedge clk);
	end
	rs_en = 1'b0;
	exfu_free = 1'b1;
	@(negedge clk);
	@(negedge clk);
	mult_free = 1'b1;
	@(negedge clk);
	@(negedge clk);
	show_entry_content();
    
    @(posedge clk);
	if(rs_free)
    begin
      $display("@@@ Fail! Test case #5.1 failed");
      $finish;
    end

    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case #5.2: FU is free, ready instr come in\n", $time);
    $display("=============================================================\n");

		// reset rs
		reset_all();
		@(negedge clk);
		reset = 1'b1;
		exfu_free = 1'b0;
		mult_free = 1'b0;
		@(negedge clk);
		reset = 1'b0;
		@(negedge clk);

		// begin test
		mult_free = 1'b1;
		@(negedge clk);
		insert_ALUinst(6,2,14,1,1,1);	@(negedge clk);
		mult_free = 1'b0;
		exfu_free = 1'b1;
		@(negedge clk);
		insert_ALUinst(1,3,9,1,1,0);	@(negedge clk);
    
		show_entry_content();

    @(posedge clk);
	if(!rs_free)
    begin
      $display("@@@ Fail! Test case #5.2 failed");
      $finish;
    end
		

    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case #5.3: more than one instr's ready, FU/MEM becomes free\n", $time);
    $display("=============================================================\n");
`ifndef SYNTH
    $display("Test not applicable in synth mode");
`else
		// reset rs
		reset_all();
		@(negedge clk);
		reset = 1'b1;
		@(negedge clk);
		reset = 1'b0;
		@(negedge clk);

		// begin test
		@(negedge clk);
		insert_ALUinst(6,2,3,1,1,1);		@(negedge clk); show_entry_content();
        insert_MEMinst(1,2,3,1,1,1,0);	    @(negedge clk); show_entry_content();
        insert_MEMinst(2,1,4,1,0,0,1);	    @(negedge clk); show_entry_content();
		insert_ALUinst(3,1,2,1,0,0);		@(negedge clk); show_entry_content();
		rs_en = 1'b0;

		exfu_free = 1'b1; $display("ex is free now");
		set_CDB(1,1,0); 
		@(negedge clk);show_entry_content();
		// first alu instruction should be out
		if (!rs_0.entries[12].entry.entry_free)
        begin
          $display("@@@ Fail! Test case #5.3 failed");
          $finish;
        end

		insert_ALUinst(4,8,4,1,1,1); 		@(negedge clk);show_entry_content();

		mem_free = 1'b1; $display("mem is free now");
		insert_ALUinst(2,6,1,1,1,1); 		@(negedge clk);show_entry_content();
		if (!rs_0.entries[14].entry.entry_free)
        begin
          $display("@@@ Fail! Test case #5.3 failed");
          $finish;
        end
		rs_en = 1'b0;
		mult_free = 1'b1;$display("mult is free now");

		@(negedge clk);show_entry_content();
		if (!rs_0.entries[15].entry.entry_free)
        begin
          $display("@@@ Fail! Test case #5.3 failed");
          $finish;
        end

		@(negedge clk);show_entry_content();
		@(negedge clk);show_entry_content();
		@(negedge clk);show_entry_content();

		show_entry_content();
        @(posedge clk);
		if(!rs_free)
        begin
          $display("@@@ Fail! Test case #5.3 failed");
          $finish;
        end

`endif
/*
    $display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case #5.4: FU becomes free as new ready inst comes in\n", $time);
    $display("=============================================================\n");
		
		// reset rs
		reset_all();
		@(negedge clk);
		reset = 1'b1;
		@(negedge clk);
		reset = 1'b0;
		@(negedge clk);

		// begin test
		@(negedge clk);
		mult_free = 1'b1;
		insert_ALUinst(6,2,3,1,1,1);
		@(negedge clk);
		exfu_free = 1'b1;
		insert_ALUinst(3,1,2,1,0,0);
		@(negedge clk);

		show_entry_content();
    @(posedge clk);
	if(!rs_free)
    begin
      $display("@@@ Fail! Test case #5.4 failed");
      $finish;
    end

		// this should be a CDB test case
    $display("=============================================================\n");
    $display("@@@ Test case #5.5: As an inst comes in, FU becomes free, CDB makes it ready\n");
    $display("=============================================================\n");
		// reset rs
		reset_all();
		@(negedge clk);
		reset = 1'b1;
		@(negedge clk);
		reset = 1'b0;
		@(negedge clk);

		insert_ALUinst(6,2,3,0,1,1);
		set_CDB(6,1,0);
		mult_free = 1'b1;
        @(posedge clk); $display("rs_cdb_valid %b rs_cdb_tag %h next_prega_valid %b", rs_0.entries[15].entry.cdb_valid[0], rs_0.entries[15].entry.cdb_tag[`PRF_IDX-1:0], rs_0.entries[15].entry.next_prega_rdy);
        $display("prega_rdy %d, entry_en %d, prega_valid %d, prega_idx_out %d", rs_0.entries[15].entry.prega_rdy, rs_0.entries[15].entry.entry_en, rs_0.entries[15].entry.prega_valid, rs_0.entries[15].entry.prega_idx_out);
		@(negedge clk);show_entry_content();
        rs_en = 1'b0;
        set_CDB(0,0,0);
    @(posedge clk);
    if (ALUop_out != `ALU_MULQ || prega_idx_out != 6 || pregb_idx_out != 2 || pdest_idx_out != 3)
    begin
       $display("@@@ Fail! Instruction output does not match expected values!");
       $display("@@@ dest: %h opA: %h opB: %h ALUop: %h rd_mem: %h wr_mem: %h IR: %h NPC: %h ROB: %h",
                pdest_idx_out, prega_idx_out, pregb_idx_out, ALUop_out, rd_mem_out, wr_mem_out, rs_IR_out,
                npc_out, rob_idx_out);
       $finish;
    end
    else
      $display("@@@ Success! Test case pass!");
*/    
    $display("@@@ Success: All Testcases Passed!\n"); 
    $finish;
  end

endmodule  // module testbench

