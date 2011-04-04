`timescale 1ns/100ps
//`define	DEBUG_EX	
`define NUM_CYCLES 1000

module testbench;

  integer count, limbo, idx; 
	integer FP;
	integer fgetsResult;
	integer sscanfResult;
	integer seed;
	reg [8*10:1] str;
	integer NPC, i, inst_ID, cdb_ID;
	integer full_cycle;
	integer fout1, fout2;
	real cycle;

  reg clk, reset;
	integer cache_fileno;

	// Between DMEM and Dcache
	wire [1:0]	mem_command;
	wire [63:0]	mem_addr, mem_wr_data;
	wire [3:0]	mem_response, mem_tag;
	wire [63:0]	mem_rd_data;

	// Between Dcachemem and Dcache
	wire												wr_en, rd_valid, en;
	wire [`DCACHE_IDX_BITS-1:0]	wr_idx, rd_idx;
	wire [`DCACHE_TAG_BITS-1:0]	wr_tag, rd_tag;
	wire [63:0]									wr_data, rd_data;

	// Output to Proc(LSQ)
	wire [63:0]	cache_data_out;
	wire				cache_valid_out;
	wire [3:0]	cache_tag_out;

	// Input to Dcache (from Proc(LSQ))
	reg [63:0]	cache_addr_in;
	reg [1:0]		cache_command_in;
	reg [63:0]	cache_data_in;

	mem mem0 ( // Inputs
             .clk(clk),
             .proc2mem_command(mem_command),
             .proc2mem_addr(mem_addr),
             .proc2mem_data(mem_wr_data),

             // Outputs
             .mem2proc_response(mem_response),
             .mem2proc_data(mem_rd_data),
             .mem2proc_tag(mem_tag)
       		   );

	dcachemem dcachemem0 (.clock(clk), .reset(reset), .en(en),
   	      	         		.wr1_en(wr_en), .wr1_tag(wr_tag), .wr1_idx(wr_idx), .wr1_data(wr_data),
    	  	            	.rd1_tag(rd_tag), .rd1_idx(rd_idx), .rd1_data(rd_data), .rd1_valid(rd_valid)
												);

	dcache dcache0 (.clock(clk), .reset(reset),
       		      	// inputs
          		    .Dmem2Dcache_response(mem_response), .Dmem2Dcache_tag(mem_tag), .Dmem2Dcache_data(mem_rd_data),							// From Dmem
       		    	  .proc2Dcache_addr(cache_addr_in), .proc2Dcache_command(cache_command_in), .proc2Dcache_data(cache_data_in),	// From Proc(LSQ)
         		    	.cachemem_data(rd_data), .cachemem_valid(rd_valid),  																												// From Dcachemem
           			  // outputs
     			        .Dcache2Dmem_command(mem_command), .Dcache2Dmem_addr(mem_addr), .Dcache2Dmem_data(mem_wr_data),								// To Dmem
          		    .Dcache2proc_data(cache_data_out), .Dcache2proc_valid(cache_valid_out), .Dcache2proc_tag(cache_tag_out), 			// To Proc(LSQ)
             			.rd_idx(rd_idx), .rd_tag(rd_tag), .wr_idx(wr_idx), .wr_tag(wr_tag), .wr_data(wr_data), .wr_en(wr_en), .en(en)	// To Dcachemem
        			    );

						
	always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

	always @(posedge clk or negedge clk)	
		cycle = cycle + 0.5;

	always @(posedge clk)
	begin
		full_cycle = full_cycle + 1;
		NPC = NPC + 4;
	end

	task reset_all;
	  begin
			i = 0; full_cycle = 0;	cycle = 0; NPC = 0;
			cache_addr_in = 0; cache_command_in = 0; cache_data_in = 0;
  	end
  endtask

	task show_cache_out;
		begin
			case ({dcache0.Dcache2proc_valid, (dcache0.Dcache2proc_tag!=4'b0)})
				2'b00:	if(cache_command_in == `BUS_LOAD) 
								$fdisplay (cache_fileno, "@@@ Output     at Cycle = %6.1f,    READ MISS!!    No Available Tickets. \n", cycle);
				2'b01: 	$fdisplay (cache_fileno, "@@@ Output     at Cycle = %6.1f,    READ MISS!!    Ticket_ID: %h \n", cycle, mem_response);
				2'b10:	$fdisplay (cache_fileno, "@@@ Output     at Cycle = %6.1f,    READ HIT!!    DATA: %16h \n", cycle, dcache0.Dcache2proc_data);
				2'b11:	$fdisplay (cache_fileno, "@@@ Output     at Cycle = %6.1f,    MISSED VALUE HAS COME!!    Ticket_ID: %h    DATA: %16h \n", cycle, dcache0.Dcache2proc_tag, dcache0.Dcache2proc_data);
			endcase
		end
	endtask

	task show_cache;
		begin
			`ifdef DCACHE_2WAY
				`define DISPLAY_ENTRY(i) $fdisplay(cache_fileno, "  %3h  |  %3h  |  %00000000000016h  |  %d / %d\n       |  %3h  |  %00000000000016h  |  %d / %d", i, dcachemem0.sets[i].sets.tags[0], dcachemem0.sets[i].sets.data[0], dcachemem0.sets[i].sets.valids[0], dcachemem0.sets[i].sets.recent[0], dcachemem0.sets[i].sets.tags[1], dcachemem0.sets[i].sets.data[1], dcachemem0.sets[i].sets.valids[1], dcachemem0.sets[i].sets.recent[1]);  
			`else
				`define DISPLAY_ENTRY(i) $fdisplay(cache_fileno, "  %3h  |  %3h  |  %00000000000016h  |  %d", i, dcachemem0.tags[i], dcachemem0.data[i], dcachemem0.valids[i]);  
			`endif

			`ifdef DCACHE_2WAY
				$fdisplay(cache_fileno, "=============[ CYCLE: %06.1f ]=====================", cycle);
				$fdisplay(cache_fileno, "  IDX  |  TAG  |        DATA        | VALID/RECENT ");
				$fdisplay(cache_fileno, "---------------------------------------------------");
				`DISPLAY_ENTRY(0)
				`DISPLAY_ENTRY(1)
				`DISPLAY_ENTRY(2)
				`DISPLAY_ENTRY(3)
				`DISPLAY_ENTRY(4)
				`DISPLAY_ENTRY(5)
				`DISPLAY_ENTRY(6)
				`DISPLAY_ENTRY(7)
				`DISPLAY_ENTRY(8)
				`DISPLAY_ENTRY(9)
				`DISPLAY_ENTRY(10)
				`DISPLAY_ENTRY(11)
				`DISPLAY_ENTRY(12)
				`DISPLAY_ENTRY(13)
				`DISPLAY_ENTRY(14)
				`DISPLAY_ENTRY(15)
				$fdisplay(cache_fileno, "===================================================\n\n");  

			`else
				$fdisplay(cache_fileno, "=============[ CYCLE: %06.1f ]==============", cycle);
				$fdisplay(cache_fileno, "  IDX  |  TAG  |        DATA        | VALID ");
				$fdisplay(cache_fileno, "--------------------------------------------");
				`DISPLAY_ENTRY(0)
				`DISPLAY_ENTRY(1)
				`DISPLAY_ENTRY(2)
				`DISPLAY_ENTRY(3)
				`DISPLAY_ENTRY(4)
				`DISPLAY_ENTRY(5)
				`DISPLAY_ENTRY(6)
				`DISPLAY_ENTRY(7)
				`DISPLAY_ENTRY(8)
				`DISPLAY_ENTRY(9)
				`DISPLAY_ENTRY(10)
				`DISPLAY_ENTRY(11)
				`DISPLAY_ENTRY(12)
				`DISPLAY_ENTRY(13)
				`DISPLAY_ENTRY(14)
				`DISPLAY_ENTRY(15)
				$fdisplay(cache_fileno, "============================================\n\n");
			`endif
		end
	endtask

	task inst_load;
		input [`DCACHE_IDX_BITS-1:0] idx;
		input [`DCACHE_TAG_BITS-1:0] tag;
		begin
			cache_addr_in 		= {48'b0, tag, idx, 3'b0};
			cache_command_in	= `BUS_LOAD;
			cache_data_in 		= 0;
			$fdisplay (cache_fileno, "@@@ LOAD ready at Cycle = %6.1f,    IDX: %3h,    TAG: %3h", cycle, idx, tag);
		end
	endtask

	task inst_store;
		input [`DCACHE_IDX_BITS-1:0] idx;
		input [`DCACHE_TAG_BITS-1:0] tag;
		input [63:0] data;
		begin
			cache_addr_in 		= {48'b0, tag, idx, 3'b0};
			cache_command_in	= `BUS_STORE;
			cache_data_in 		= data;
			$fdisplay (cache_fileno, "@@@ STORE ready at Cycle = %6.1f,    IDX: %3h,    TAG: %3h,    DATA: %16h", cycle, idx, tag, data);
		end
	endtask

	task inst_none;
		begin
			cache_addr_in 		= 0;
			cache_command_in	= `BUS_NONE;
			cache_data_in 		= 0;
		end
	endtask

	always @(posedge clk) show_cache_out();


initial begin

	cache_fileno = $fopen("./dcache.txt", "wb");


  $display("@@@ Testbench Started Here!! ===========================\n");
	clk = 1'b0;
	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;
	$display("@@@ Has been reset at Cycle %4d\n", full_cycle);

	@(posedge clk); 

	
	// Initialize
	@(posedge clk); `SD; `SD; show_cache(); inst_store(0,		5, 	64'haaaaaaaaaaaaaaaa);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(1,		6, 	64'hbbbbbbbbbbbbbbbb);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(2, 	7, 	64'hcccccccccccccccc);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(3, 	8, 	64'hdddddddddddddddd);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(4, 	9, 	64'heeeeeeeeeeeeeeee);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(5, 	0, 	64'hffffffffffffffff);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(6, 	1, 	64'h1111111111111111);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(7, 	2, 	64'h2222222222222222);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(8, 	3, 	64'h3333333333333333);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(9, 	4, 	64'h4444444444444444);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(10,	5, 	64'h5555555555555555);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(11,	6, 	64'h6666666666666666);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(12,	7, 	64'h7777777777777777);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(13,	8, 	64'h8888888888888888);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(14,	9, 	64'h9999999999999999);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(15,	10,	64'hdeadbeefdeadbeef);
	@(posedge clk); `SD; `SD; show_cache(); inst_none();
	// End of Initialization
	

	@(posedge clk); `SD; `SD; show_cache(); inst_store(0,		15, 	64'h0123456789abcdef);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(1,		16, 	64'habcdefabcdefabcd);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(2, 	17, 	64'hdeadbeefdeadbeef);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(3, 	18, 	64'h0000000000000001);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(4, 	19, 	64'h0000000000000002);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(5, 	10, 	64'h0000000000000003);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(6, 	11, 	64'h0000000000000004);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(7, 	12, 	64'h0000000000000005);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(8, 	13, 	64'h0000000000000006);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(9, 	14, 	64'h0000000000000007);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(10,	15, 	64'h0000000000000008);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(11,	16, 	64'h0000000000000009);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(12,	17, 	64'h000000000000000a);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(13,	18, 	64'h000000000000000b);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(14,	19, 	64'h000000000000000c);
	@(posedge clk); `SD; `SD; show_cache(); inst_store(15,	20,		64'h000000000000000d);
	@(posedge clk); `SD; `SD; show_cache(); inst_none();

	@(posedge clk); `SD; `SD; show_cache(); inst_load(2,	17); // READ HIT, DATA=64'hdeadbeefdeadbeef
	@(posedge clk); `SD; `SD; show_cache(); inst_load(2,	7);	 // READ MISS, DATA=64'hcccccccccccccccc should be returned later
	@(posedge clk); `SD; `SD; show_cache(); inst_store(2,	1,	64'h1212121212121212);
	@(posedge clk); `SD; `SD; show_cache(); inst_load(2,	17);
	@(posedge clk); `SD; `SD; show_cache(); inst_none();
	@(posedge clk); `SD; `SD; show_cache(); inst_store(2,	1,	64'h1234123412341234);




	@(posedge clk); `SD; `SD; show_cache(); inst_none();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	@(posedge clk); `SD; `SD; show_cache();
	$display("@@@ Testbench Finished at Cycle %4d ==================\n", full_cycle);

	$fclose(cache_fileno);
  $finish; 

		end
endmodule
