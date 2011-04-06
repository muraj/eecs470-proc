module lsq (clk, reset, 
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
						out_valid, rob_idx_out, pdest_idx_out, mem_value_out, rd_mem_out, wr_mem_out,
						// Outputs to MEM
						lsq2mem_command, lsq2mem_addr, lsq2mem_data
						);

// Input Definitions

  input clk, reset;
	input [`ROB_IDX*`SCALAR-1:0]	rob_idx_in;   // rob index assigned at dispatch
	input [`PRF_IDX*`SCALAR-1:0]	pdest_idx_in; // destination PRF index for loads
	input [`SCALAR-1:0]						rd_mem_in;    // loads
	input [`SCALAR-1:0]						wr_mem_in;		// stores
	input [32*`SCALAR-1:0]				ir_in; 				// IR
	input [64*`SCALAR-1:0]				npc_in; 	// NPC

	input [`SCALAR-1:0]					  up_req;				// address updates from EX stage
	input [`LSQ_IDX*`SCALAR-1:0]	lsq_idx_in;   // LSQ index to update
	input [64*`SCALAR-1:0]				addr_in;	    // result of EX stage
	input [64*`SCALAR-1:0]				regv_in; 			// data for stores

	input [3:0]	 mem2lsq_response; // 0 = can't accept, other = tag of transaction

	input dcache2lsq_valid;					// validates data
	input [3:0]  dcache2lsq_tag;		// tag of incoming data
	input [63:0] dcache2lsq_data; 	// incoming data from cache

	input [`ROB_IDX-1:0] rob_head;

// Output Definitions

	output reg full, full_almost;
	output reg [`LSQ_IDX*`SCALAR-1:0]	lsq_idx_out;	 // output assigned LSQ index at dispatch

	output [`SCALAR-1:0]					out_valid;		 // output valid signals
	output [`ROB_IDX*`SCALAR-1:0]	rob_idx_out;   // output rob index at commit
	output [`PRF_IDX*`SCALAR-1:0]	pdest_idx_out; // destination PRF index at commit
	output [64*`SCALAR-1:0]				mem_value_out; // data for load
	output [`SCALAR-1:0]					rd_mem_out;		 // loads
	output [`SCALAR-1:0]					wr_mem_out;		 // stores
	
	output [1:0]	lsq2mem_command;  // `BUS_NONE, `BUS_LOAD, `BUS_STORE
	output [63:0] lsq2mem_addr;		  // address to mem
	output [63:0] lsq2mem_data;			// data to mem


	wire [`SCALAR-1:0]	in_req;   // allocation requests at dispatch
	assign in_req[0] = (rd_mem_in[0] || wr_mem_in[0]) && !full;
	assign in_req[1] = (rd_mem_in[1] || wr_mem_in[1]) && !full_almost;
	
// Internal Data Storage
	reg [63:0] 				 data_addr [`LSQ_SZ-1:0];
	reg [63:0] 				 data_regv [`LSQ_SZ-1:0];
	reg [`LSQ_SZ-1:0]  wr_mem;
	reg [`LSQ_SZ-1:0]	 launched;
	reg [`LSQ_SZ-1:0]	 ready_launch;
	reg [`LSQ_SZ-1:0]	 ready_commit;

	reg [`PRF_IDX-1:0] pdest_idx [`LSQ_SZ-1:0];
	reg [`ROB_IDX-1:0] rob_idx   [`LSQ_SZ-1:0];
	reg [63:0] 				 npc 			 [`LSQ_SZ-1:0];
	reg [31:0] 				 ir  			 [`LSQ_SZ-1:0];
	
	reg [`LSQ_IDX-1:0]  lsq_map [`NUM_MEM_TAGS:1];


// H/T business
	reg [`LSQ_IDX-1:0] head, tail, next_head, next_tail;
	reg [`LSQ_IDX-1:0] tail_new;

	reg [`LSQ_IDX:0] iocount;
	wire [`LSQ_IDX:0] next_iocount;
	reg [1:0] incount, outcount;
	reg empty, empty_almost;

	wire [`LSQ_IDX-1:0] tail_p1, tail_p2, head_p1, head_p2, cur_size;
	wire next_full, next_full_almost, next_empty, next_empty_almost;
	
	wire [`SCALAR-1:0] commit;
	wire launch;

	reg [63:0] next_data_addr1, next_data_addr2, next_data_regv1, next_data_regv2;
	reg next_wr_mem1, next_wr_mem2, next_ready_launch1,	next_ready_launch2,	next_ready_commit1,	next_ready_commit2;
	reg [`PRF_IDX-1:0] next_pdest_idx1, next_pdest_idx2;
	reg [`ROB_IDX-1:0] next_rob_idx1, next_rob_idx2;
	reg [63:0] next_npc1, next_npc2;
	reg [31:0] next_ir1, next_ir2;

	// FIXME: get rid of it later
	wire flush;
	assign flush = 1'b0;
	
	// Memory launch decision
	// Currently both ld/st are only launched at the lsq head
	wire dcache_miss, dcache_hit, stall;

	assign launch = !empty && !launched[head] &&
 								  (wr_mem[head])? (rob_idx[head] == rob_head)&&ready_launch[head]: // for stores, need to check rob status
									 							  ready_launch[head]; // for loads, ready_launch is sufficient info

	assign lsq2mem_command = (launch)? ((wr_mem[head])? `BUS_STORE: `BUS_LOAD):
																		 `BUS_NONE;
	assign lsq2mem_addr = data_addr[head];
	assign lsq2mem_data = data_regv[head];

	assign dcache_miss = launch && !wr_mem[head] && !dcache2lsq_valid;
	assign dcache_hit = launch && !wr_mem[head] && dcache2lsq_valid && (dcache2lsq_tag=={4{1'b0}});
	assign stall = launch && ((dcache_miss && (mem2lsq_response==0)) || (dcache2lsq_valid && dcache2lsq_tag!={4{1'b0}})); // need to stall: either no tickets available at mem or cache is busy returning stuff

	// Committing decision
	assign commit[0] = !empty && 
										 (wr_mem[head])? launch: // for stores, launch == commit
										 								 ready_commit[head]; // for loads, launch happens before commit
	assign commit[1] = !empty_almost && commit[0] && 
										 (!wr_mem[head_p1])&&ready_commit[head_p1]; // only happens for loads that got forwarded

	// ===================================================
	// Duplicate cb functionality for things to be updated
	// ===================================================

	// combinational outputs
	assign out_valid = commit;
	assign mem_value_out = {data_regv[head_p1],data_regv[head]};
	assign rd_mem_out = {!wr_mem[head_p1],!wr_mem[head]};
	assign wr_mem_out = {wr_mem[head_p1],wr_mem[head]};

	assign pdest_idx_out = {pdest_idx[head_p1], pdest_idx[head]};
	assign rob_idx_out = {rob_idx[head_p1], rob_idx[head]};
	assign npc_out = {npc[head_p1], npc[head]};
	assign ir_out = {ir[head_p1], ir[head]};

	// purely combinational
	assign tail_p1 = tail + 1'd1;
	assign tail_p2 = tail + 2'd2;
	assign head_p1 = head + 1'd1;
	assign head_p2 = head + 2'd2;
	
	assign cur_size = (next_tail>=next_head)? (next_tail - next_head) : (next_tail + `LSQ_SZ - next_head);
	assign next_iocount = (flush)? cur_size : iocount + incount - outcount;
	assign next_full = next_iocount == `LSQ_SZ;
	assign next_full_almost = next_iocount == (`LSQ_SZ-1);
	assign next_empty = next_iocount == 0;
	assign next_empty_almost = next_iocount == 1;

	always @* begin
		// default cases for data
		next_data_addr1 = data_addr[tail];
		next_data_addr2 = data_addr[tail_p1];
		next_data_regv1 = data_regv[tail];
		next_data_regv2 = data_regv[tail_p1];
		next_ready_launch1 = ready_launch[tail];
		next_ready_launch2 = ready_launch[tail_p1];
		next_ready_commit1 = ready_commit[tail];
		next_ready_commit2 = ready_commit[tail_p1];
		next_wr_mem1 = wr_mem[tail];
		next_wr_mem2 = wr_mem[tail_p1];

		next_pdest_idx1 = pdest_idx[tail];
		next_pdest_idx2 = pdest_idx[tail_p1];
		next_rob_idx1 = rob_idx[tail];
		next_rob_idx2 = rob_idx[tail_p1];
		next_npc1 = npc[tail];
		next_npc2 = npc[tail_p1];
		next_ir1 = ir[tail];
		next_ir2 = ir[tail_p1];
		
		// other default cases
		lsq_idx_out = {tail_p1, tail};
		next_head = head;
		next_tail = tail;
		tail_new = tail;
		incount = in_req[0] + in_req[1];
		outcount = 2'd0;

		// deal with head and data out
		if (commit[0]) begin
			next_head = head_p1;
			outcount = 2'd1;
			if (commit[1]) begin
				next_head = head_p2;
				outcount = 2'd2;
			end
		end

		// deal with tail and data in (allocate)
		if (flush) begin
			next_tail = tail_new;
		end else begin
			if (incount == 2'd1) begin
					next_tail = tail_p1;
					lsq_idx_out = (in_req[0])? {tail_p1, tail}: {tail, tail_p1};

					next_data_addr1 = {64{1'b0}};
					next_data_regv1 = {64{1'b0}};
					next_ready_launch1 = 1'b0;
					next_ready_commit1 = 1'b0;
					next_wr_mem1 = (in_req[0])? wr_mem_in[0]: wr_mem_in[1];

					next_pdest_idx1 = (in_req[0])? pdest_idx_in[`SEL(`PRF_IDX,1)]: pdest_idx_in[`SEL(`PRF_IDX,2)];
					next_rob_idx1 = (in_req[0])? rob_idx_in[`SEL(`ROB_IDX,1)]: rob_idx_in[`SEL(`ROB_IDX,2)];
					next_npc1 = (in_req[0])? npc_in[`SEL(64,1)]: npc_in[`SEL(64,2)];
					next_ir1 = (in_req[0])? ir_in[`SEL(32,1)]: ir_in[`SEL(32,2)];

			end
			if (incount == 2'd2) begin
				next_tail = tail_p2;
				lsq_idx_out = {tail_p1, tail};
				
				next_data_addr1 = {64{1'b0}};
				next_data_regv1 = {64{1'b0}};
				next_ready_launch1 = 1'b0;
				next_ready_commit1 = 1'b0;
				next_wr_mem1 = wr_mem_in[0];

				next_pdest_idx1 = pdest_idx_in[`SEL(`PRF_IDX,1)];
				next_rob_idx1 = rob_idx_in[`SEL(`ROB_IDX,1)];
				next_npc1 = npc_in[`SEL(64,1)];
				next_ir1 = ir_in[`SEL(32,1)];

				next_data_addr2 = {64{1'b0}};
				next_data_regv2 = {64{1'b0}};
				next_ready_launch2 = 1'b0;
				next_ready_commit2 = 1'b0;
				next_wr_mem2 = wr_mem_in[1];

				next_pdest_idx2 = pdest_idx_in[`SEL(`PRF_IDX,2)];
				next_rob_idx2 = rob_idx_in[`SEL(`ROB_IDX,2)];
				next_npc2 = npc_in[`SEL(64,2)];
				next_ir2 = ir_in[`SEL(32,2)];
			end
		end

	end // always @*


	// ===================================================
	// Sequential Block
	// ===================================================
	always @(posedge clk) begin
		if (reset) begin
			head 					<= `SD {`LSQ_IDX{1'b0}};
			tail 					<= `SD {`LSQ_IDX{1'b0}};
			iocount 			<= `SD {`LSQ_IDX+1{1'b0}};
			full 					<= `SD 1'b0;
			full_almost 	<= `SD 1'b0;
			empty					<= `SD 1'b1;
			empty_almost	<= `SD 1'b0;

		end else begin

			// H/T business
			head 					<= `SD next_head;
			tail					<= `SD next_tail;
			iocount 			<= `SD next_iocount;
			full 					<= `SD next_full;
			full_almost 	<= `SD next_full_almost;
			empty					<= `SD next_empty;
			empty_almost	<= `SD next_empty_almost;
			
			// data allocation
			data_addr[tail]       <= `SD next_data_addr1;
			data_addr[tail_p1]    <= `SD next_data_addr2;
			data_regv[tail]       <= `SD next_data_regv1;
			data_regv[tail_p1]    <= `SD next_data_regv2;
			ready_launch[tail]    <= `SD next_ready_launch1;
		  ready_launch[tail_p1] <= `SD next_ready_launch2;
			ready_commit[tail]    <= `SD next_ready_commit1;
		  ready_commit[tail_p1] <= `SD next_ready_commit2;
			wr_mem[tail]      		<= `SD next_wr_mem1;
			wr_mem[tail_p1]       <= `SD next_wr_mem2;

			pdest_idx[tail]    		<= `SD next_pdest_idx1;
			pdest_idx[tail_p1]    <= `SD next_pdest_idx2;
			rob_idx[tail]      		<= `SD next_rob_idx1;
			rob_idx[tail_p1]      <= `SD next_rob_idx2;
			npc[tail]      				<= `SD next_npc1;
			npc[tail_p1]      	 	<= `SD next_npc2;
			ir[tail]      				<= `SD next_ir1;
			ir[tail_p1]       		<= `SD next_ir2;

			// data updates
			if (up_req[0]) begin
				data_addr[lsq_idx_in[`SEL(`LSQ_IDX,1)]] <= `SD addr_in[`SEL(64,1)];
				data_regv[lsq_idx_in[`SEL(`LSQ_IDX,1)]] <= `SD regv_in[`SEL(64,1)];
				ready_launch[lsq_idx_in[`SEL(`LSQ_IDX,1)]] <= `SD 1'b1;
				if (up_req[1]) begin
					data_addr[lsq_idx_in[`SEL(`LSQ_IDX,2)]] <= `SD addr_in[`SEL(64,2)];
					data_regv[lsq_idx_in[`SEL(`LSQ_IDX,2)]] <= `SD regv_in[`SEL(64,2)];
					ready_launch[lsq_idx_in[`SEL(`LSQ_IDX,2)]] <= `SD 1'b1;
				end
			end

			// memory launch status
			if (launch && !stall) begin
				launched[head] <= `SD 1'b1;
			end

			// ticket => lsq mapping
			if (dcache_miss) begin
				// Cache miss
				lsq_map[mem2lsq_response] <= `SD head;
			end else if (dcache_hit) begin
				// Cache hit
				data_regv[head] 	 <= `SD dcache2lsq_data;
				ready_commit[head] <= `SD 1'b1;
			end

			// Data from cache
			if (dcache2lsq_valid && (dcache2lsq_tag!={4{1'b0}})) begin
				data_regv[lsq_map[dcache2lsq_tag]] 	  <= `SD dcache2lsq_data;
				ready_commit[lsq_map[dcache2lsq_tag]] <= `SD 1'b1;
			end
		end
	end // always @(posedge clk)

  generate
  genvar i;
  for(i=0;i<`LSQ_SZ;i=i+1) begin : REG_RESET
      always @(posedge clk) begin
				if (reset) begin
            data_addr[i] 		<= `SD {64{1'b0}};
            data_regv[i] 		<= `SD {64{1'b0}};
						launched[i] 		<= `SD 1'b0;
            ready_launch[i] <= `SD 1'b0;
            ready_commit[i] <= `SD 1'b0;
						wr_mem[i] 	    <= `SD 1'b0;

            pdest_idx[i] 		<= `SD {`PRF_IDX{1'b0}};
            rob_idx[i] 			<= `SD {`ROB_IDX{1'b0}};
            npc[i] 					<= `SD {64{1'b0}};
            ir[i] 					<= `SD {32{1'b0}};
				end
      end
  end
	for(i=1;i<=`NUM_MEM_TAGS;i=i+1) begin : MAP_RESET
		always @(posedge clk) begin
			if (reset) begin
				lsq_map[i] <= `SD {`LSQ_IDX{1'b0}};
			end
		end
	end
  endgenerate

endmodule
