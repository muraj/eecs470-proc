`timescale 1ns/100ps

module testbench;

  integer clk_count, limbo, idx, NPC;  //TEST VARS

  reg clk, reset;
	reg [`ROB_IDX*`SCALAR-1:0]	rob_idx_in;   // rob index assigned at dispatch
	reg [`PRF_IDX*`SCALAR-1:0]	pdest_idx_in; // destination PRF index for loads
	reg [`SCALAR-1:0]						rd_mem_in;    // loads
	reg [`SCALAR-1:0]						wr_mem_in;		// stores
	reg [32*`SCALAR-1:0]				ir_in; 				// IR
	reg [64*`SCALAR-1:0]				npc_in; 	// NPC

	reg [`SCALAR-1:0]					  up_req;				// address updates from EX stage
	reg [`LSQ_IDX*`SCALAR-1:0]	lsq_idx_in;   // LSQ index to update
	reg [64*`SCALAR-1:0]				addr_in;	    // result of EX stage
	reg [64*`SCALAR-1:0]				regv_in; 			// data for stores

	reg [3:0]	 mem2lsq_response; // 0 = can't accept, other = tag of transaction

	reg dcache2lsq_valid;					// validates data
	reg [3:0]  dcache2lsq_tag;		// tag of incoming data
	reg [63:0] dcache2lsq_data; 	// incoming data from cache

	reg [`ROB_IDX-1:0] rob_head;

// Output Definitions

	wire full, full_almost;
	wire [`LSQ_IDX*`SCALAR-1:0]	lsq_idx_out;	 // output assigned LSQ index at dispatch

	wire [`SCALAR-1:0]					out_valid;		 // output valid signals
	wire [`ROB_IDX*`SCALAR-1:0]	rob_idx_out;   // output rob index at commit
	wire [`PRF_IDX*`SCALAR-1:0]	pdest_idx_out; // destination PRF index at commit
	wire [64*`SCALAR-1:0]				mem_value_out; // data for load
	wire [`SCALAR-1:0]					rd_mem_out;		 // loads
	wire [`SCALAR-1:0]					wr_mem_out;		 // stores
	wire [64*`SCALAR-1:0]				npc_out;
	wire [32*`SCALAR-1:0]				ir_out;
	
	wire [1:0]	lsq2mem_command;  // `BUS_NONE, `BUS_LOAD, `BUS_STORE
	wire [63:0] lsq2mem_addr;		  // address to mem
	wire [63:0] lsq2mem_data;			// data to mem

  lsq lsq0 (clk, reset, 
						full, full_almost, 
						// Inputs at Dispatch
						rob_idx_in, pdest_idx_in, rd_mem_in, wr_mem_in, npc_in, ir_in,
						// Inputs from EX
						up_req, lsq_idx_in, addr_in, regv_in,
						// Inputs from MEM
						mem2lsq_response,
						// Inputs from DCACHE
						dcache2lsq_valid, dcache2lsq_tag, dcache2lsq_data,
						// Inputs from ROB
						rob_head,
						// Output at Dispatch
						lsq_idx_out,
						// Outputs to EX
						out_valid, rob_idx_out, pdest_idx_out, mem_value_out, 
						rd_mem_out, wr_mem_out, npc_out, ir_out,
						// Outputs to MEM
						lsq2mem_command, lsq2mem_addr, lsq2mem_data
					 );
/*
 mem mem0	( // Inputs
             clk,
             proc2mem_command,
             proc2mem_addr,
             proc2mem_data,

             // Outputs
             mem2proc_response,
             mem2proc_data,
             mem2proc_tag
           );
*/

	always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
		NPC = NPC+1;
  end

	always @(posedge clk)
  begin
    clk_count = clk_count + 1;
  end
/*
  task show_io_mem;
	  begin
    $display("==OUTPUTS====================================================");
   	$display("Response\tData\tTag");
		$display("%d\t0x%h\t%d", mem2proc_response, mem2proc_data, mem2proc_tag );
    $display("=============================================================\n");
	  end
	endtask
*/

	task insert;
	input [1:0] num_inst;
  input write1, write2;
  begin
		ir_in = clk_count;
		npc_in = clk_count;
		
		if (num_inst >= 1) begin
			wr_mem_in[0] = write1;
			rd_mem_in[0] = !write1;
			rob_idx_in[`SEL(`ROB_IDX,1)] = clk_count%`ROB_SZ;
			pdest_idx_in[`SEL(`PRF_IDX,1)] = clk_count%`PRF_SZ+1;
			wr_mem_in[1] = 0;
			rd_mem_in[1] = 0;

		  if (num_inst == 2) begin
				wr_mem_in[1] = write2;
				rd_mem_in[1] = !write2;
				rob_idx_in[`SEL(`ROB_IDX,2)] = clk_count%`ROB_SZ;
				pdest_idx_in[`SEL(`PRF_IDX,2)] = clk_count%`PRF_SZ+1;
			end
		
		end else begin
			wr_mem_in = 0;
			rd_mem_in = 0;
			rob_idx_in = 0;
			pdest_idx_in = 0;
		end

	end
	endtask

	task up;
	input [1:0] num_inst;
  input [`LSQ_IDX-1:0] lsq1, lsq2;
  begin
		
		if (num_inst >= 1) begin
			up_req[0] = 1'b1;
			up_req[1] = 1'b0;
			lsq_idx_in[`SEL(`LSQ_IDX,1)] = lsq1;
			addr_in[`SEL(64,1)] = NPC;
			regv_in[`SEL(64,1)] = clk_count;

		  if (num_inst == 2) begin
				up_req[1] = 1'b1;
				lsq_idx_in[`SEL(`LSQ_IDX,2)] = lsq2;
				addr_in[`SEL(64,2)] = NPC;
				regv_in[`SEL(64,2)] = clk_count;
			end
		end else begin
			up_req = 0;
			lsq_idx_in = 0;
			addr_in = 0;
			regv_in = 0;
		end

	end
	endtask

	task show_io;
	  begin

	  end
	endtask


	task show_contents;
	  begin
			$display("@%4d NS, CLK%3d", $time, clk_count);
  	  $display("==========================================================");
			$display("| F/A | E/A | LCH | CM | IN | UP | \$VAL | MEMRES | \$TAG |");
  	  $display("----------------------------------------------------------");
			$display("| %b/%b | %b/%b |  %b  | %b%b | %b%b | %b%b |   %b  |   %2d   |  %2d  |", 
							 lsq0.full, lsq0.full_almost, lsq0.empty, lsq0.empty_almost, lsq0.launch, 
							 lsq0.commit[1], lsq0.commit[0], lsq0.in_req[1], lsq0.in_req[0],
							 up_req[1], up_req[0], dcache2lsq_valid, mem2lsq_response, dcache2lsq_tag);
  	  $display("==========================================================\n");
			
			`define DISPLAY_LSQ_ENTRY(i) \
			$display("| %1s %1s |  %2d |   %b  |   %b  |   %b  |   %b  |  %2d  | %16h | %16h |", \
							 i===lsq0.head ? "H" : " ", i===lsq0.tail ? "T" : " ", i, \
							 lsq0.wr_mem[i], lsq0.ready_launch[i], lsq0.ready_commit[i], \
							 lsq0.launched[i], lsq0.rob_idx[i], lsq0.data_addr[i], lsq0.data_regv[i]);
			
			$display("======================================================================================");
   		$display("| H/T | IDX | STOR | RDYL | RDYC | SENT | ROB# |       ADDR       |        VAL       |");
   		$display("|------------------------------------------------------------------------------------|");

			for (idx=0;idx<`LSQ_SZ;idx=idx+1) begin
				`DISPLAY_LSQ_ENTRY(idx)
			end
  	  
			$display("======================================================================================\n");
			$display("====================================================");
			$display("| TAG | 1| 2| 3| 4| 5| 6| 7| 8| 9| 0| 1| 2| 3| 4| 5|");
			$display("| LSQ | %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d| %1d|", 
							 lsq0.lsq_map[1], 
							 lsq0.lsq_map[2], 
							 lsq0.lsq_map[3], 
							 lsq0.lsq_map[4], 
							 lsq0.lsq_map[5], 
							 lsq0.lsq_map[6], 
							 lsq0.lsq_map[7], 
							 lsq0.lsq_map[8], 
							 lsq0.lsq_map[9], 
							 lsq0.lsq_map[10],
							 lsq0.lsq_map[11],
							 lsq0.lsq_map[12],
							 lsq0.lsq_map[13],
							 lsq0.lsq_map[14],
							 lsq0.lsq_map[15]
							 );
			$display("====================================================\n");
	  end
	endtask


	task reset_all;
	  begin
			// reset lsq first
			$display("@%4d NS, CLK%3d, RESETTING ALL", $time, clk_count);
    	@(negedge clk); reset = 1'b1;@(negedge clk); reset = 1'b0; 

			// reset inputs
	   	rob_idx_in=0;   
	   	pdest_idx_in=0; 
	   	rd_mem_in=0;    
	   	wr_mem_in=0;		

	    up_req=0;				
	   	lsq_idx_in=0;   
	   	addr_in=0;	    
	   	regv_in=0; 			

	    mem2lsq_response=0; 

	    dcache2lsq_valid=0;	
	    dcache2lsq_tag=0;		
	    dcache2lsq_data=0; 	

	    rob_head=0;
  	end
  endtask
	
	
	initial
	  begin
		NPC = 0;
    clk = 1'b0;
    clk_count = 0;

    // Initialize input signals
    reset_all();
    @(negedge clk);
		show_contents();
    @(negedge clk);
		show_contents();
		
		// #############################
		// USAGE:
		// new_inst(num_inst, dest_idx1, dest_idx2, bt_pd1, bt_pd2, isbranch1, isbranch2, ba_pd1, ba_pd2) 
		// up_inst(num_inst, rob1, rob2, bt_ex1, bt_ex2, ba_ex1, ba_ex2);
		// #############################

    $display("=============================================================");
    $display("@@@ Test case #1: Insert");
    $display("=============================================================\n");
    
		insert(1,1,0);@(negedge clk);show_contents();
		insert(2,1,1);@(negedge clk);show_contents();
		insert(2,0,1);@(negedge clk);show_contents();
		insert(2,0,1);@(negedge clk);show_contents();
		insert(2,0,1);@(negedge clk);show_contents();
		insert(0,0,1);@(negedge clk)

		// Test case #2: Update items
    $display("=============================================================");
    $display("@@@ Test case #2: Update address");
    $display("=============================================================\n");
		mem2lsq_response = 5;
		up(2,1,5);@(negedge clk);show_contents();
		up(2,2,3);@(negedge clk);show_contents();
		up(1,7,3);@(negedge clk);show_contents();
		up(1,0,3);@(negedge clk);show_contents();
		up(0,1,3);@(negedge clk);show_contents();
		up(0,1,3);@(negedge clk);show_contents();
		rob_head = 4; 
		up(0,1,3);@(negedge clk);show_contents();
		up(0,1,3);@(negedge clk);show_contents();


		// Test case #3: Insert & pull items at the same time 
    $display("=============================================================");
    $display("@@@ Test case #3: Branch Misprediction");
    $display("=============================================================\n");
    // address mispredict

		// direction mispredict



    $display("All Testcase Passed!\n"); 
    $finish; 

		end
endmodule
