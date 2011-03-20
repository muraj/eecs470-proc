`timescale 1ns/100ps

// testbench works with length

module testbench;

  integer count, limbo, idx; 
	integer NPC, NUM_CYCLES, i;
	integer full_cycle;
	real cycle;
	reg [63:0] 	temp64;
	reg [31:0] 	temp32;
	reg					temp;
	reg	[3:0]		free;

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

	reg [`LSQ_IDX*`SCALAR-1:0]	LSQ_idx_reg;
	reg	[`PRF_IDX*`SCALAR-1:0]	pdest_idx_reg;
	reg	[64*`SCALAR-1:0] 				prega_value_reg;
	reg	[64*`SCALAR-1:0] 				pregb_value_reg;
	reg	[5*`SCALAR-1:0] 				ALUop_reg;
	reg	[`SCALAR-1:0] 					rd_mem_reg;
	reg	[`SCALAR-1:0] 					wr_mem_reg;
	reg	[32*`SCALAR-1:0] 				rs_IR_reg;
	reg	[64*`SCALAR-1:0] 				npc_reg;
	reg	[`ROB_IDX*`SCALAR-1:0] 	rob_idx_reg;
	reg	[`SCALAR-1:0] 					EX_en_reg;

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

											.LSQ_idx(LSQ_idx_reg), .pdest_idx(pdest_idx_reg), 
											.prega_value(prega_value_reg), .pregb_value(pregb_value_reg), 
											.ALUop(ALUop_reg), .rd_mem(rd_mem_reg), .wr_mem(wr_mem_reg),
											.rs_IR(rs_IR_reg), .npc(npc_reg), .rob_idx(rob_idx_reg), .EX_en(EX_en_reg),

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

	always @(posedge clk) begin
		if(reset) begin
			LSQ_idx_reg			<= `SD 0;
			pdest_idx_reg		<= `SD 0;
			prega_value_reg	<= `SD 0;
			pregb_value_reg	<= `SD 0;
			ALUop_reg				<= `SD 0;
			rd_mem_reg			<= `SD 0;
			wr_mem_reg			<= `SD 0;
			rs_IR_reg				<= `SD 0;
			npc_reg					<= `SD 0;
			rob_idx_reg			<= `SD 0;
			EX_en_reg				<= `SD 0;
		end
		else begin
			LSQ_idx_reg			<= `SD LSQ_idx_in;
			pdest_idx_reg		<= `SD pdest_idx_in;
			prega_value_reg	<= `SD prega_value_in;
			pregb_value_reg	<= `SD pregb_value_in;
			ALUop_reg				<= `SD ALUop_in;
			rd_mem_reg			<= `SD rd_mem_in;
			wr_mem_reg			<= `SD wr_mem_in;
			rs_IR_reg				<= `SD rs_IR_in;
			npc_reg					<= `SD npc_in;
			rob_idx_reg			<= `SD rob_idx_in;
			EX_en_reg				<= `SD EX_en_in;
		end
	end


	always @(posedge clk or negedge clk)	
		cycle = cycle + 0.5;

	always @(posedge clk)
	begin
		full_cycle = full_cycle + 1;
		NPC = NPC + 8;
	end

	task reset_all;
	  begin
			i = 0; full_cycle = 0;	cycle = 0; NPC = 0;
			LSQ_idx_in = 0; pdest_idx_in = 0; prega_value_in = 0; pregb_value_in = 0;
			ALUop_in = 0; rd_mem_in = 0; wr_mem_in = 0; rs_IR_in = 0; npc_in = 0;
			rob_idx_in = 0; EX_en_in = 0;
			LSQ_rob_idx_in = 0; LSQ_pdest_idx_in = 0; LSQ_mem_value_in = 0; LSQ_done_in = 0; LSQ_rd_mem_in = 0; LSQ_wr_mem_in = 0;
  	end
  endtask

	task show_inst;
		begin
	    $display("Cycle: %4.1f ==< NEW INSTRUCTION >======================================================================================================", cycle);
			$display("Way     | LSQ_idx | pdest |     prega_value    |     pregb_value    | ALUop | rd/wr |    rs_IR   |        npc         | rob_idx | EX_en");
 	    $display("----------------------------------------------------------------------------------------------------------------------------------------");
			if(EX_en_in[0]==1'b0) 									$display(" 1 NOOP |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,1)], pdest_idx_in[`SEL(`PRF_IDX,1)], prega_value_in[`SEL(64,1)], pregb_value_in[`SEL(64,1)], ALUop_in[`SEL(5,1)], rd_mem_in[`SEL(1,1)], wr_mem_in[`SEL(1,1)], rs_IR_in[`SEL(32,1)], npc_in[`SEL(64,1)], rob_idx_in[`SEL(`ROB_IDX,1)], EX_en_in[`SEL(1,1)]);
			else if(rd_mem_in[0] | wr_mem_in[0])		$display(" 1 MEM  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,1)], pdest_idx_in[`SEL(`PRF_IDX,1)], prega_value_in[`SEL(64,1)], pregb_value_in[`SEL(64,1)], ALUop_in[`SEL(5,1)], rd_mem_in[`SEL(1,1)], wr_mem_in[`SEL(1,1)], rs_IR_in[`SEL(32,1)], npc_in[`SEL(64,1)], rob_idx_in[`SEL(`ROB_IDX,1)], EX_en_in[`SEL(1,1)]);
			else if(ALUop_in[`SEL(5,1)]==5'b01011)	$display(" 1 MULT |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,1)], pdest_idx_in[`SEL(`PRF_IDX,1)], prega_value_in[`SEL(64,1)], pregb_value_in[`SEL(64,1)], ALUop_in[`SEL(5,1)], rd_mem_in[`SEL(1,1)], wr_mem_in[`SEL(1,1)], rs_IR_in[`SEL(32,1)], npc_in[`SEL(64,1)], rob_idx_in[`SEL(`ROB_IDX,1)], EX_en_in[`SEL(1,1)]);
			else 																		$display(" 1 ALU  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,1)], pdest_idx_in[`SEL(`PRF_IDX,1)], prega_value_in[`SEL(64,1)], pregb_value_in[`SEL(64,1)], ALUop_in[`SEL(5,1)], rd_mem_in[`SEL(1,1)], wr_mem_in[`SEL(1,1)], rs_IR_in[`SEL(32,1)], npc_in[`SEL(64,1)], rob_idx_in[`SEL(`ROB_IDX,1)], EX_en_in[`SEL(1,1)]);
			if(EX_en_in[1]==1'b0) 									$display(" 2 NOOP |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,2)], pdest_idx_in[`SEL(`PRF_IDX,2)], prega_value_in[`SEL(64,2)], pregb_value_in[`SEL(64,2)], ALUop_in[`SEL(5,2)], rd_mem_in[`SEL(1,2)], wr_mem_in[`SEL(1,2)], rs_IR_in[`SEL(32,2)], npc_in[`SEL(64,2)], rob_idx_in[`SEL(`ROB_IDX,2)], EX_en_in[`SEL(1,2)]);
			else if(rd_mem_in[1] | wr_mem_in[1]) 		$display(" 2 MEM  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,2)], pdest_idx_in[`SEL(`PRF_IDX,2)], prega_value_in[`SEL(64,2)], pregb_value_in[`SEL(64,2)], ALUop_in[`SEL(5,2)], rd_mem_in[`SEL(1,2)], wr_mem_in[`SEL(1,2)], rs_IR_in[`SEL(32,2)], npc_in[`SEL(64,2)], rob_idx_in[`SEL(`ROB_IDX,2)], EX_en_in[`SEL(1,2)]);
			else if(ALUop_in[`SEL(5,2)]==5'b01011)	$display(" 2 MULT |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,2)], pdest_idx_in[`SEL(`PRF_IDX,2)], prega_value_in[`SEL(64,2)], pregb_value_in[`SEL(64,2)], ALUop_in[`SEL(5,2)], rd_mem_in[`SEL(1,2)], wr_mem_in[`SEL(1,2)], rs_IR_in[`SEL(32,2)], npc_in[`SEL(64,2)], rob_idx_in[`SEL(`ROB_IDX,2)], EX_en_in[`SEL(1,2)]);
			else 																		$display(" 2 ALU  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", LSQ_idx_in[`SEL(`LSQ_IDX,2)], pdest_idx_in[`SEL(`PRF_IDX,2)], prega_value_in[`SEL(64,2)], pregb_value_in[`SEL(64,2)], ALUop_in[`SEL(5,2)], rd_mem_in[`SEL(1,2)], wr_mem_in[`SEL(1,2)], rs_IR_in[`SEL(32,2)], npc_in[`SEL(64,2)], rob_idx_in[`SEL(`ROB_IDX,2)], EX_en_in[`SEL(1,2)]);
 	    $display("========================================================================================================================================\n");
		end
	endtask

	task show_input;
		begin
	    $display("Cycle: %4.1f ==< INPUTS >===========================================================================================================", cycle);
			$display("Way | LSQ_idx | pdest |     prega_value    |     pregb_value    | ALUop | rd/wr |    rs_IR   |        npc         | rob_idx | EX_en");
 	    $display("-----------------------------------------------------------------------------------------------------------------------------------");
  	  $display(" 1  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", ex_stage0.LSQ_idx[`SEL(`LSQ_IDX,1)], ex_stage0.pdest_idx[`SEL(`PRF_IDX,1)], ex_stage0.prega_value[`SEL(64,1)], ex_stage0.pregb_value[`SEL(64,1)], ex_stage0.ALUop[`SEL(5,1)], ex_stage0.rd_mem[`SEL(1,1)], ex_stage0.wr_mem[`SEL(1,1)], ex_stage0.rs_IR[`SEL(32,1)], ex_stage0.npc[`SEL(64,1)], ex_stage0.rob_idx[`SEL(`ROB_IDX,1)], ex_stage0.EX_en[`SEL(1,1)]);
  	  $display(" 2  |   %2d    |  %2d   | 0x%16h | 0x%16h | 0x%2h  | %1d / %1d | 0x%8h | 0x%16h |   %2d    |   %1d", ex_stage0.LSQ_idx[`SEL(`LSQ_IDX,2)], ex_stage0.pdest_idx[`SEL(`PRF_IDX,2)], ex_stage0.prega_value[`SEL(64,2)], ex_stage0.pregb_value[`SEL(64,2)], ex_stage0.ALUop[`SEL(5,2)], ex_stage0.rd_mem[`SEL(1,2)], ex_stage0.wr_mem[`SEL(1,2)], ex_stage0.rs_IR[`SEL(32,2)], ex_stage0.npc[`SEL(64,2)], ex_stage0.rob_idx[`SEL(`ROB_IDX,2)], ex_stage0.EX_en[`SEL(1,2)]);
 	    $display("===================================================================================================================================\n");
		end
	endtask

	task show_fu_output;
		begin
	    $display("Cycle: %4.1f ==< FU OUTPUTS >====================================================================================================================================================", cycle);
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
	    $display("Cycle: %4.1f ==< CDB OUTPUTS >=========================================================", cycle);
     	$display("Way | cdb_tag | cdb_valid |      cdb_value     | mem_value_valid | rob_idx | branch_NT");
      $display("--------------------------------------------------------------------------------------");
   		$display(" 1  |   %2d    |      %1d    | 0x%16h |        %1d        |   %2d    |     %1d", ex_stage0.cdb_tag_out[`SEL(`PRF_IDX,1)], ex_stage0.cdb_valid_out[`SEL(1,1)], ex_stage0.cdb_value_out[`SEL(64,1)], ex_stage0.mem_value_valid_out[`SEL(1,1)], ex_stage0.rob_idx_out[`SEL(`ROB_IDX,1)], ex_stage0.branch_NT_out[`SEL(1,1)]);
   		$display(" 2  |   %2d    |      %1d    | 0x%16h |        %1d        |   %2d    |     %1d", ex_stage0.cdb_tag_out[`SEL(`PRF_IDX,2)], ex_stage0.cdb_valid_out[`SEL(1,2)], ex_stage0.cdb_value_out[`SEL(64,2)], ex_stage0.mem_value_valid_out[`SEL(1,2)], ex_stage0.rob_idx_out[`SEL(`ROB_IDX,2)], ex_stage0.branch_NT_out[`SEL(1,2)]);
 	    $display("======================================================================================\n");
		end
	endtask

	task make_NOOP;	
		input integer way;
		begin
			if(way == 1) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,1)] = 0; 
				pdest_idx_in[`SEL(`PRF_IDX,1)] = 0; 
				prega_value_in[`SEL(64,1)] = 0;
				pregb_value_in[`SEL(64,1)] = 0;
				ALUop_in[`SEL(5,1)] = 0;
				rd_mem_in[`SEL(1,1)] = 1'b0; 
				wr_mem_in[`SEL(1,1)] = 1'b0;
				rs_IR_in[`SEL(32,1)] = 0;
				npc_in[`SEL(64,1)] = 0;
				rob_idx_in[`SEL(`ROB_IDX,1)] = 0;
				EX_en_in[`SEL(1,1)] = 1'b0;
			end
			else if(way == 2) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,2)] = 0; 
				pdest_idx_in[`SEL(`PRF_IDX,2)] = 0; 
				prega_value_in[`SEL(64,2)] = 0;
				pregb_value_in[`SEL(64,2)] = 0;
				ALUop_in[`SEL(5,2)] = 0;
				rd_mem_in[`SEL(1,2)] = 1'b0; 
				wr_mem_in[`SEL(1,2)] = 1'b0;
				rs_IR_in[`SEL(32,2)] = 0;
				npc_in[`SEL(64,2)] = 0;
				rob_idx_in[`SEL(`ROB_IDX,2)] = 0;
				EX_en_in[`SEL(1,2)] = 1'b0;
			end
			else if(way==3) begin
				LSQ_idx_in = 0;
				pdest_idx_in = 0;
				prega_value_in = 0;
				pregb_value_in = 0;
				ALUop_in = 0;
				rd_mem_in = 0;
				wr_mem_in = 0;
				rs_IR_in = 0;
				npc_in = 0;
				rob_idx_in = 0;
				EX_en_in = 0;
			end
		end
	endtask

	task make_MEM_inst;	
		input integer way;
		begin
			if(way == 1) begin
				temp32 = {$random} % 32;
				LSQ_idx_in[`SEL(`LSQ_IDX,1)] = temp32[`LSQ_IDX-1:0];
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,1)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,1)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,1)] = temp64;
				ALUop_in[`SEL(5,1)] = 5'b0;
				rd_mem_in[`SEL(1,1)] = 1'b1; 
				wr_mem_in[`SEL(1,1)] = 1'b0;
				rs_IR_in[31:21] = 11'b001_00000000;
				rs_IR_in[20:16] = 21'b0;
				temp32 = {$random} % 100;
				rs_IR_in[15:0] = temp32[15:0];
				npc_in[`SEL(64,1)] = NPC;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,1)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,1)] = 1'b1;
			end
			else if(way == 2) begin
				temp32 = {$random} % 32;
				LSQ_idx_in[`SEL(`LSQ_IDX,1)] = temp32[`LSQ_IDX-1:0];
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,2)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,2)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,2)] = temp64;
				ALUop_in[`SEL(5,2)] = 5'b0;
				rd_mem_in[`SEL(1,2)] = 1'b0; 
				wr_mem_in[`SEL(1,2)] = 1'b1;
				rs_IR_in[63:53] = 11'b001_00000000;
				rs_IR_in[52:48] = 21'b0;
				temp32 = {$random} % 100;
				rs_IR_in[47:32] = temp32[15:0];
				npc_in[`SEL(64,2)] = NPC + 4;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,2)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,2)] = 1'b1;
			end
		end
	endtask

	task make_MULT_inst;	
		input integer way;
		begin
			if(way == 1) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,1)] = 0;
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,1)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,1)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,1)] = temp64;
				ALUop_in[`SEL(5,1)] = 5'b01011;
				rd_mem_in[`SEL(1,1)] = 1'b0; 
				wr_mem_in[`SEL(1,1)] = 1'b0;
				rs_IR_in[31:21] = 11'b010_00000000;
				rs_IR_in[20:0] = 21'b0;
				npc_in[`SEL(64,1)] = NPC;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,1)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,1)] = 1'b1;
			end
			else if(way == 2) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,2)] = 0;
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,2)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,2)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,2)] = temp64;
				ALUop_in[`SEL(5,2)] = 5'b01011;
				rd_mem_in[`SEL(1,2)] = 1'b0; 
				wr_mem_in[`SEL(1,2)] = 1'b0;
				rs_IR_in[63:53] = 11'b010_00000000;
				rs_IR_in[52:32] = 21'b0;
				npc_in[`SEL(64,2)] = NPC + 4;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,2)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,2)] = 1'b1;
			end
		end
	endtask

	task make_ALU_inst;	
		input integer way;
		begin
			if(way == 1) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,1)] = 0;
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,1)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,1)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,1)] = temp64;
				temp32 = {$random} % 16;
				ALUop_in[4] = 1'b0;
				ALUop_in[3:0] = temp32[3:0];
				while(ALUop_in[3:0]==4'b1011) begin
					temp32 = {$random} % 16;
					ALUop_in[3:0] = temp32[3:0];
				end
				rd_mem_in[`SEL(1,1)] = 1'b0; 
				wr_mem_in[`SEL(1,1)] = 1'b0;
				rs_IR_in[31:21] = 11'b010_00000000;
				temp32 = {$random} % 100;
				rs_IR_in[20:13] = temp32[7:0];
				temp = {$random} % 2;
				rs_IR_in[12] = temp;
				rs_IR_in[11:0] = 12'b0;
				npc_in[`SEL(64,1)] = NPC;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,1)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,1)] = 1'b1;
			end
			else if(way == 2) begin
				LSQ_idx_in[`SEL(`LSQ_IDX,2)] = 0;
				temp32 = {$random} % 32;
				pdest_idx_in[`SEL(`PRF_IDX,2)] = temp32[`PRF_IDX-1:0];
				temp64 = {$random} % 100;
				prega_value_in[`SEL(64,2)] = temp64;
				temp64 = {$random} % 100;
				pregb_value_in[`SEL(64,2)] = temp64;
				temp32 = {$random} % 16;
				ALUop_in[9] = 1'b0;
				ALUop_in[8:5] = temp32[3:0];
				while(ALUop_in[8:5]==4'b1011) begin
					temp32 = {$random} % 16;
					ALUop_in[8:5] = temp32[3:0];
				end
				rd_mem_in[`SEL(1,2)] = 1'b0; 
				wr_mem_in[`SEL(1,2)] = 1'b0;
				rs_IR_in[63:53] = 11'b010_00000000;
				temp32 = {$random} % 100;
				rs_IR_in[52:45] = temp32[7:0];
				temp = {$random} % 2;
				rs_IR_in[44] = temp;
				rs_IR_in[43:32] = 12'b0;
				npc_in[`SEL(64,2)] = NPC + 4;
				temp32 = {$random} % 32;
				rob_idx_in[`SEL(`ROB_IDX,2)] = temp32[`ROB_IDX-1:0];
				EX_en_in[`SEL(1,2)] = 1'b1;
			end
		end
	endtask

// Always use make_inst() at negedge clk
	task make_inst;
		begin
			#(`VERILOG_CLOCK_PERIOD/4.0);
			free={EX_ALU_free, EX_MULT_free};
			if(free==4'b0000) make_NOOP(3);
			else begin
				case (free)
					4'b1000, 4'b0100: begin
															make_ALU_inst(1); make_NOOP(2);
														end
					4'b0010, 4'b0001: begin
															make_MULT_inst(1); make_NOOP(2);
														end
					4'b1100: 	begin
											make_ALU_inst(1); make_ALU_inst(2);
										end
					4'b0011: 	begin
											make_MULT_inst(1); make_MULT_inst(2);
										end
					default	: begin
											temp32 = {$random} % 2;
											if(temp32[0] == 1'b0) make_ALU_inst(1);
											else make_MULT_inst(1);
											temp32 = {$random} % 2;
											if(temp32[0] == 1'b0) make_ALU_inst(2);
											else make_MULT_inst(2);
										end
				endcase
			end
			show_inst();
		end
	endtask

initial begin

  $display("@@@ Testbench Started Here!! ======================================================================================================\n");
	clk = 1'b0;
	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;
	$display("@@@ Has been reset at Cycle %4d\n", full_cycle);

	@(posedge clk); 

	@(negedge clk); 

	@(negedge clk); make_inst();

	NUM_CYCLES = 10;
	while(i<NUM_CYCLES) begin
		@(posedge clk); show_fu_output();
		@(negedge clk); show_cdb_output(); make_inst();
		i=i+1;
	end

	@(posedge clk);
	@(negedge clk);

  $finish; 

		end
endmodule
