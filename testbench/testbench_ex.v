`timescale 1ns/100ps

// testbench works with length

module testbench;

  integer count, limbo, idx, NPC;  //TEST VARS

  reg clk, reset;

// Inputs to EX_STAGE
	reg [`LSQ_IDX*`SCALAR-1:0]	LSQ_idx_in;
	reg	[`PRF_IDX*`SCALAR-1:0]	pdest_idx_in;
	reg	[64*`SCALAR-1:0] 				prega_value_in;
	reg	[64*`SCALAR-1:0] 				pregb_value_in;
	reg	[5*`SCALAR-1:0] 				ALUop_in;
	reg	[`SCALAR-1:0] 					rd_mem_in;
	reg	[`SCALAR-1:0] 					wr_mem_in;
	reg	[32*`SCALAR-1:0] 				rs_IR_in;
	reg	[64*`SCALAR-1:0] 				npc_in;
	reg	[`ROB_IDX*`SCALAR-1:0] 	rob_idx_in;
	reg	[`SCALAR-1:0] 					EX_en_in;

// Inputs to LSQ (WARNING: It's a fake LSQ. It just splits out everything as it is)
	reg [`ROB_IDX*`SCALAR-1:0]	LSQ_rob_idx_in;
	reg [`PRF_IDX*`SCALAR-1:0]	LSQ_pdest_idx_in;
	reg [64*`SCALAR-1:0]				LSQ_mem_value_in;
	reg [`SCALAR-1:0]						LSQ_done_in;
	reg [`SCALAR-1:0]						LSQ_rd_mem_in;
	reg [`SCALAR-1:0]						LSQ_wr_mem_in;

// Outputs from EX_STAGE
	wire [`PRF_IDX*`SCALAR-1:0]	EX_cdb_tag;
	wire [`SCALAR-1:0] 					EX_cdb_valid;
	wire [64*`SCALAR-1:0] 			EX_cdb_value;
	wire [`ROB_IDX*`SCALAR-1:0]	EX_rob_idx;
	wire [`SCALAR-1:0] 					EX_branch_NT;
	wire [`SCALAR-1:0] 					EX_ALU_free;
	wire [`SCALAR-1:0] 					EX_MULT_free;

// Connection between EX_STAGE and LSQ
	wire [`ROB_IDX*`SCALAR-1:0]	LSQ_EX_rob_idx;
	wire [`PRF_IDX*`SCALAR-1:0]	LSQ_EX_pdest_idx;
	wire [64*`SCALAR-1:0]				LSQ_EX_mem_value;
	wire [`SCALAR-1:0]					LSQ_EX_done, LSQ_EX_rd_mem, LSQ_EX_wr_mem;
	wire [`LSQ_IDX*`SCALAR-1:0]	EX_LSQ_idx;
	wire [64*`SCALAR-1:0]				EX_LSQ_ADDR;
	wire [64*`SCALAR-1:0]				EX_LSQ_reg_value;


	LSQ LSQ0 (.clk(clk), .reset(reset),
						//Inputs
						.LSQ_idx_in(EX_LSQ_idx), .ADDR_in(EX_LSQ_ADDR), .reg_value_in(EX_LSQ_reg_value),

						//Inputs (to control the outputs manuall)
						.rob_idx_in(LSQ_rob_idx_in), .pdest_idx_in(LSQ_pdest_idx_in), 
						.mem_value_in(LSQ_mem_value_in), .done_in(LSQ_done_in), 
						.rd_mem_in(LSQ_rd_mem_in), .wr_mem_in(LSQ_wr_mem_in),

						//Outputs
						.rob_idx_out(LSQ_EX_rob_idx), .pdest_idx_out(LSQ_EX_pdest_idx), .mem_value_out(LSQ_EX_mem_value), 
						.done_out(LSQ_EX_done), .rd_mem_out(LSQ_EX_rd_mem), .wr_mem_out(LSQ_EX_wr_mem)
						);

	ex_stage ex_stage0 (.clk(clk), .reset(reset),

											.LSQ_idx(LSQ_idx_in), .pdest_idx(pdest_idx_in), 
											.prega_value(prega_value_in), .pregb_value(pregb_value_in), 
											.ALUop(ALUop_in), .rd_mem(rd_mem_in), .wr_mem(wr_mem_in),
											.rs_IR(rs_IR_in), .npc(npc_in), .rob_idx(rob_idx_in), .EX_en(EX_en_in),

											.LSQ_rob_idx(LSQ_EX_rob_idx), .LSQ_pdest_idx(LSQ_EX_pdest_idx), .LSQ_mem_value(LSQ_EX_mem_value), 
											.LSQ_done(LSQ_EX_done), .LSQ_rd_mem(LSQ_EX_rd_mem), .LSQ_wr_mem(LSQ_EX_wr_mem),

											.cdb_tag_out(EX_cdb_tag), .cdb_valid_out(EX_cdb_valid), .cdb_value_out(EX_cdb_value),	
											.rob_idx_out(EX_rob_idx), .branch_NT_out(EX_branch_NT), 							
											.ALU_free(EX_ALU_free), .MULT_free(EX_MULT_free), 										

											.EX_LSQ_idx(EX_LSQ_idx), .EX_MEM_ADDR(EX_LSQ_ADDR), .EX_MEM_reg_value(EX_LSQ_reg_value)
					            );
						
	always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

	task reset_all;
	  begin
			LSQ_idx_in = 0; pdest_idx_in = 0; prega_value_in = 0; pregb_value_in = 0;
			ALUop_in = 0; rd_mem_in = 0; wr_mem_in = 0; rs_IR_in = 0; npc_in = 0;
			rob_idx_in = 0; EX_en_in = 0;
			LSQ_rob_idx_in = 0; LSQ_pdest_idx_in = 0; LSQ_mem_value_in = 0; LSQ_done_in = 0; LSQ_rd_mem_in = 0; LSQ_wr_mem_in = 0;
  	end
  endtask

	task show_input;
		begin
	    $display("==< INPUTS >=======================================================================================================================");
			$display("Way | LSQ_idx | pdest |     prega_value    |     pregb_value    | ALUop | rd/wr |    rs_IR   |        npc         | rob_idx | EX_en");
 	    $display("-----------------------------------------------------------------------------------------------------------------------------------");
  	  $display(" 1  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", ex_stage0.LSQ_idx[`SEL(`LSQ_IDX,1)], ex_stage0.pdest_idx[`SEL(`PRF_IDX,1)], ex_stage0.prega_value[`SEL(64,1)], ex_stage0.pregb_value[`SEL(64,1)], ex_stage0.ALUop[`SEL(5,1)], ex_stage0.rd_mem[`SEL(1,1)], ex_stage0.wr_mem[`SEL(1,1)], ex_stage0.rs_IR[`SEL(32,1)], ex_stage0.npc[`SEL(64,1)], ex_stage0.rob_idx[`SEL(`ROB_IDX,1)], ex_stage0.EX_en[`SEL(1,1)]);
  	  $display(" 2  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", ex_stage0.LSQ_idx[`SEL(`LSQ_IDX,2)], ex_stage0.pdest_idx[`SEL(`PRF_IDX,2)], ex_stage0.prega_value[`SEL(64,2)], ex_stage0.pregb_value[`SEL(64,2)], ex_stage0.ALUop[`SEL(5,2)], ex_stage0.rd_mem[`SEL(1,2)], ex_stage0.wr_mem[`SEL(1,2)], ex_stage0.rs_IR[`SEL(32,2)], ex_stage0.npc[`SEL(64,2)], ex_stage0.rob_idx[`SEL(`ROB_IDX,2)], ex_stage0.EX_en[`SEL(1,2)]);
 	    $display("===================================================================================================================================\n");
		end
	endtask

	task show_fu_output;
		begin
	    $display("==< FU OUTPUTS >================================================================================================================================================================");
  	  $display("    ||                               ALU                              ||                             MULT                     ||                        MEM                     ");
      $display("Way ||       result       | BRresult | pdest | rob_idx | done | fr/st ||        result       | pdest | rob_idx | done | fr/st ||      value (valid)     | pdest | rob_idx | done");
      $display("--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
  	  $display(" 1  || 0x%16h |     %1d    |  %2d   |   %2d    |  %1d   | %1d / %1d || 0x%16h  |  %2d   |   %2d    |   %1d  | %1d / %1d || 0x%16h (%1d) |  %2d   |   %2d    |  %1d ", ex_stage0.ALU_result[`SEL(64,1)], ex_stage0.BRcond_result[`SEL(1,1)], ex_stage0.ALU_pdest_idx[`SEL(`PRF_IDX,1)], ex_stage0.ALU_rob_idx[`SEL(`ROB_IDX,1)], ex_stage0.ALU_EX_en[`SEL(1,1)], ex_stage0.ALU_free[`SEL(1,1)], ex_stage0.ALU_stall[`SEL(1,1)], ex_stage0.MULT_product[`SEL(64,1)], ex_stage0.MULT_pdest_idx[`SEL(`PRF_IDX,1)], ex_stage0.MULT_rob_idx[`SEL(`ROB_IDX,1)], ex_stage0.MULT_done[`SEL(1,1)], ex_stage0.MULT_free[`SEL(1,1)], ex_stage0.MULT_stall[`SEL(1,1)], ex_stage0.MEM_value[`SEL(64,1)], ex_stage0.MEM_valid_value[`SEL(1,1)], ex_stage0.MEM_pdest_idx[`SEL(`PRF_IDX,1)], ex_stage0.MEM_rob_idx[`SEL(`ROB_IDX,1)], ex_stage0.MEM_done[`SEL(1,1)]);
   		$display(" 2  || 0x%16h |     %1d    |  %2d   |   %2d    |  %1d   | %1d / %1d || 0x%16h  |  %2d   |   %2d    |   %1d  | %1d / %1d || 0x%16h (%1d) |  %2d   |   %2d    |  %1d ", ex_stage0.ALU_result[`SEL(64,2)], ex_stage0.BRcond_result[`SEL(1,2)], ex_stage0.ALU_pdest_idx[`SEL(`PRF_IDX,2)], ex_stage0.ALU_rob_idx[`SEL(`ROB_IDX,2)], ex_stage0.ALU_EX_en[`SEL(1,2)], ex_stage0.ALU_free[`SEL(1,2)], ex_stage0.ALU_stall[`SEL(1,2)], ex_stage0.MULT_product[`SEL(64,2)], ex_stage0.MULT_pdest_idx[`SEL(`PRF_IDX,2)], ex_stage0.MULT_rob_idx[`SEL(`ROB_IDX,2)], ex_stage0.MULT_done[`SEL(1,2)], ex_stage0.MULT_free[`SEL(1,2)], ex_stage0.MULT_stall[`SEL(1,2)], ex_stage0.MEM_value[`SEL(64,2)], ex_stage0.MEM_valid_value[`SEL(1,2)], ex_stage0.MEM_pdest_idx[`SEL(`PRF_IDX,2)], ex_stage0.MEM_rob_idx[`SEL(`ROB_IDX,2)], ex_stage0.MEM_done[`SEL(1,2)]);
 	    $display("================================================================================================================================================================================\n");
		end
	endtask

	task show_cdb_output;
		begin
	    $display("==< CDB OUTPUTS >=====================================================================");
     	$display("Way | cdb_tag | cdb_valid |      cdb_value     | mem_value_valid | rob_idx | branch_NT");
      $display("--------------------------------------------------------------------------------------");
   		$display(" 1  |   %2d    |      %1d    | 0x%16h |        %1d        |   %2d    |     %1d", ex_stage0.cdb_tag_out[`SEL(`PRF_IDX,1)], ex_stage0.cdb_valid_out[`SEL(1,1)], ex_stage0.cdb_value_out[`SEL(64,1)], ex_stage0.mem_value_valid_out[`SEL(1,1)], ex_stage0.rob_idx_out[`SEL(`ROB_IDX,1)], ex_stage0.branch_NT_out[`SEL(1,1)]);
   		$display(" 2  |   %2d    |      %1d    | 0x%16h |        %1d        |   %2d    |     %1d", ex_stage0.cdb_tag_out[`SEL(`PRF_IDX,2)], ex_stage0.cdb_valid_out[`SEL(1,2)], ex_stage0.cdb_value_out[`SEL(64,2)], ex_stage0.mem_value_valid_out[`SEL(1,2)], ex_stage0.rob_idx_out[`SEL(`ROB_IDX,2)], ex_stage0.branch_NT_out[`SEL(1,2)]);
 	    $display("======================================================================================\n");
		end
	endtask





initial begin
	clk = 1'b0;
	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;

	show_fu_output();

	@(posedge clk); show_input(); show_fu_output();

	@(negedge clk); show_cdb_output();


    $finish; 

		end
endmodule
/*
  always @(posedge clk) //simulating 
  begin
     #2;
    count = count + din1_en+din2_en - dout1_req - dout2_req;
    count = (count >= `CB_WIDTH) ?  `CB_WIDTH : (count <= 0) ? 0 : count;  
		if((count < `CB_WIDTH) && full)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be full, but isn't! count: %d int_count: %d @@@", $time, count, cb0.iocount);
				$finish;
			end
		else if((count > 0) && cb0.empty)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be empty, but isn't! count: %d int_count: %d@@@", $time, count, cb0.iocount);
				$finish;
			end 
	end
*/
/*
  task show_io;
	  begin
		
    $display("==OUTPUTS====================================================");
   	$display("RDY1\tRDY2\tROB1\tROB2\tVAL1\tVAL2\tMISS\tBA");
		$display("%b\t%b\t%0d\t%0d\t%b\t%b\t%b\t%0d", din1_rdy, din2_rdy, rob_idx_out1, rob_idx_out2, dout1_valid, dout2_valid, branch_miss, ba_out);
    $display("=============================================================\n");

	  end
	endtask


	task show_contents;
	  begin
		$display("==============================================================");
    $display("ROB Contents");
		$display("==============================================================");

    $display("Counter : %d",rob0.iocount);
		$display("Full  / Almost : %0d,%0d",rob0.full, rob0.full_almost);
		$display("Empty / Almost : %0d,%0d\n",rob0.empty, rob0.empty_almost);
    $display("Head : %d",rob0.head);
		$display("Tail : %d\n",rob0.tail);
    
		$display("         |  RDY\tBTEX\tBAEX\tNPC\tPDEST\tBTPD\tBAPD");
		$display("==============================================================");
    $display("Entry  0 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[0], rob0.data_bt_ex[0], rob0.data_ba_ex[0], rob0.cb_npc.data[0], rob0.cb_pdest.data[0], rob0.cb_bt_pd.data[0], rob0.cb_ba_pd.data[0]);
    $display("Entry  1 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[1], rob0.data_bt_ex[1], rob0.data_ba_ex[1], rob0.cb_npc.data[1], rob0.cb_pdest.data[1], rob0.cb_bt_pd.data[1], rob0.cb_ba_pd.data[1]);
    $display("Entry  2 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[2], rob0.data_bt_ex[2], rob0.data_ba_ex[2], rob0.cb_npc.data[2], rob0.cb_pdest.data[2], rob0.cb_bt_pd.data[2], rob0.cb_ba_pd.data[2]);
    $display("Entry  3 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[3], rob0.data_bt_ex[3], rob0.data_ba_ex[3], rob0.cb_npc.data[3], rob0.cb_pdest.data[3], rob0.cb_bt_pd.data[3], rob0.cb_ba_pd.data[3]);
    $display("Entry  4 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[4], rob0.data_bt_ex[4], rob0.data_ba_ex[4], rob0.cb_npc.data[4], rob0.cb_pdest.data[4], rob0.cb_bt_pd.data[4], rob0.cb_ba_pd.data[4]);
    $display("Entry  5 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[5], rob0.data_bt_ex[5], rob0.data_ba_ex[5], rob0.cb_npc.data[5], rob0.cb_pdest.data[5], rob0.cb_bt_pd.data[5], rob0.cb_ba_pd.data[5]);
    $display("Entry  6 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[6], rob0.data_bt_ex[6], rob0.data_ba_ex[6], rob0.cb_npc.data[6], rob0.cb_pdest.data[6], rob0.cb_bt_pd.data[6], rob0.cb_ba_pd.data[6]);
    $display("Entry  7 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[7], rob0.data_bt_ex[7], rob0.data_ba_ex[7], rob0.cb_npc.data[7], rob0.cb_pdest.data[7], rob0.cb_bt_pd.data[7], rob0.cb_ba_pd.data[7]);
	  $display("Entry  8 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[8], rob0.data_bt_ex[8], rob0.data_ba_ex[8], rob0.cb_npc.data[8], rob0.cb_pdest.data[8], rob0.cb_bt_pd.data[8], rob0.cb_ba_pd.data[8]);
    $display("Entry  9 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[9], rob0.data_bt_ex[9], rob0.data_ba_ex[9], rob0.cb_npc.data[9], rob0.cb_pdest.data[9], rob0.cb_bt_pd.data[9], rob0.cb_ba_pd.data[9]);
    $display("Entry 10 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[10], rob0.data_bt_ex[10], rob0.data_ba_ex[10], rob0.cb_npc.data[10], rob0.cb_pdest.data[10], rob0.cb_bt_pd.data[10], rob0.cb_ba_pd.data[10]);
    $display("Entry 11 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[11], rob0.data_bt_ex[11], rob0.data_ba_ex[11], rob0.cb_npc.data[11], rob0.cb_pdest.data[11], rob0.cb_bt_pd.data[11], rob0.cb_ba_pd.data[11]);
    $display("Entry 12 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[12], rob0.data_bt_ex[12], rob0.data_ba_ex[12], rob0.cb_npc.data[12], rob0.cb_pdest.data[12], rob0.cb_bt_pd.data[12], rob0.cb_ba_pd.data[12]);
    $display("Entry 13 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[13], rob0.data_bt_ex[13], rob0.data_ba_ex[13], rob0.cb_npc.data[13], rob0.cb_pdest.data[13], rob0.cb_bt_pd.data[13], rob0.cb_ba_pd.data[13]);
    $display("Entry 14 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[14], rob0.data_bt_ex[14], rob0.data_ba_ex[14], rob0.cb_npc.data[14], rob0.cb_pdest.data[14], rob0.cb_bt_pd.data[14], rob0.cb_ba_pd.data[14]);
    $display("Entry 15 |  %b\t%b\t%0d\t%0d\t%0d\t%b\t%0d",rob0.data_rdy[15], rob0.data_bt_ex[15], rob0.data_ba_ex[15], rob0.cb_npc.data[15], rob0.cb_pdest.data[15], rob0.cb_bt_pd.data[15], rob0.cb_ba_pd.data[15]);

		$display("==============================================================\n");
	  end
	endtask

	task reset_all;
	  begin
			count = 0;
			NPC = 0;
			reset = 0; din1_req = 0; din2_req = 0; dup1_req = 0; dup2_req = 0;
	    ir_in1 = 0; ir_in2 = 0;
	    npc_in1 = 0; npc_in2 = 0;
	    pdest_in1 = 0; pdest_in2 = 0;
	    bt_pd_in1 = 0; bt_pd_in2 = 0;
	    ba_pd_in1 = 0; ba_pd_in2 = 0;
	    bt_ex_in1 = 0; bt_ex_in2 = 0;
	    ba_ex_in1 = 0; ba_ex_in2 = 0;
	    rob_idx_in1 = 0; rob_idx_in2 = 0;
  	end
  endtask



  // Task to allocate an instruction 
  task new_inst;
	input [1:0] num_inst;
  input [`PRF_IDX-1:0] dest_idx1, dest_idx2;
	input bt_pd1, bt_pd2, isbranch1, isbranch2;
	input [63:0] ba_pd1, ba_pd2; 
  begin

    if (num_inst >= 1) begin
			din1_req = 1;
			din2_req = 0;
			
			NPC = NPC + 1;
			npc_in1 = NPC;  // arbitrary
			ir_in1 = NPC/2; // arbitrary
			pdest_in1 = dest_idx1;
			bt_pd_in1 = bt_pd1;
			ba_pd_in1 = ba_pd1; 
			isbranch_in1 = isbranch1;
			$display("Allocating Inst @%4.0fns: PRF=%0d, ISBR=%b, BT:%b, BA:%0d",	$time, dest_idx1, isbranch1, bt_pd1, ba_pd1);

			if (num_inst == 2) begin
				din2_req = 1;
				
				NPC = NPC + 1;
				npc_in2 = NPC;  // arbitrary
				ir_in2 = NPC/2; // arbitrary
				pdest_in2 = dest_idx2;
				bt_pd_in2 = bt_pd2;
				ba_pd_in2 = ba_pd2; 
				isbranch_in2 = isbranch2;
				$display("Allocating Inst @%4.0fns: PRF=%0d, ISBR=%b, BT:%b, BA:%0d",	$time, dest_idx2, isbranch2, bt_pd2, ba_pd2);
			end

		end else begin
			din1_req = 0;
			din2_req = 0;
		end
		
  end
  endtask

  // Task to update an instruction 
  task up_inst;
	input [1:0] num_inst;
	input [`ROB_IDX-1:0] rob1, rob2;
	input bt_ex1, bt_ex2;
	input [63:0] ba_ex1, ba_ex2; 
  begin

		rob_idx_in1 = rob1;
		rob_idx_in2 = rob2;

    if (num_inst >= 1) begin
			dup1_req = 1;
			dup2_req = 0;
			
			bt_ex_in1 = bt_ex1;
			ba_ex_in1 = ba_ex1;
			$display("Updating ROB #%0d @%4.0fns: BT=%b, BA=%0d",	rob1, $time, bt_ex1, ba_ex1);

			if (num_inst == 2) begin
				dup2_req = 1;
				
				bt_ex_in1 = bt_ex1;
				ba_ex_in1 = ba_ex1;
				$display("Updating ROB #%0d @%4.0fns: BT=%b, BA=%0d",	rob2, $time, bt_ex2, ba_ex2);
			end

		end else begin
			dup1_req = 0;
			dup2_req = 0;
		end
		
  end
  endtask
*/
/*	initial
	  begin
    clk = 1'b0;
    // Reset ROB
    reset = 1'b1;@(negedge clk); reset = 1'b0; 

    // Initialize input signals
    reset_all();
  
    @(negedge clk);
		
		// #############################
		// USAGE:
		// new_inst(num_inst, dest_idx1, dest_idx2, bt_pd1, bt_pd2, isbranch1, isbranch2, ba_pd1, ba_pd2) 
		// up_inst(num_inst, rob1, rob2, bt_ex1, bt_ex2, ba_ex1, ba_ex2);
		// #############################

    $display("=============================================================");
    $display("@@@ Test case #1: Insert & Remove one at a time");
    $display("=============================================================\n");
    
    $display("============[        INSERT       ]==========================\n");
		// insert one at a time
		new_inst(2,2,3,0,0,0,0,0,0);
    @(negedge clk);show_contents();show_io();
		new_inst(2,2,3,1,0,0,0,0,0);
    @(negedge clk);show_contents();show_io();
		new_inst(1,5,3,0,0,0,0,0,0);
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
    @(negedge clk);show_contents();show_io();
		new_inst(0,5,3,0,0,0,0,0,0);
    @(negedge clk);show_contents();show_io();

    $display("============[        REMOVE       ]==========================\n");
		up_inst(2,0,1,0,0,0,0);
    @(negedge clk);show_contents();show_io();
		up_inst(1,4,0,0,0,0,0);
    @(negedge clk);show_contents();show_io();
		up_inst(0,4,0,0,0,0,0);


		// Test case #2: Pull items
    $display("=============================================================");
    $display("@@@ Test case #2: Insert and remove two at a time");
    $display("=============================================================\n");



		// Test case #3: Insert & pull items at the same time 
    $display("=============================================================");
    $display("@@@ Test case #3: Branch Misprediction");
    $display("=============================================================\n");
    // address mispredict

		// direction mispredict



    $display("All Testcase Passed!\n"); 
*/
