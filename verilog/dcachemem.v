//////////////////////////////////////////////////
// Data Cache Memory
//////////////////////////////////////////////////

module dcachemem (clock, reset, en,
                  wr1_en, wr1_tag, wr1_idx, wr1_data,
                  rd1_tag, rd1_idx, rd1_data, rd1_valid);

input clock, reset, en, wr1_en;
input [`DCACHE_IDX_BITS-1:0] wr1_idx, rd1_idx;
input [`DCACHE_TAG_BITS-1:0] wr1_tag, rd1_tag;
input [63:0] wr1_data;

output [63:0] rd1_data;
output rd1_valid;

`ifdef DCACHE_2WAY
	reg		[`DCACHE_SETS-1:0]	set_access;
	wire	[`DCACHE_SETS-1:0]	set_rd_valid;
	wire	[63:0]							set_rd_data	[`DCACHE_SETS-1:0];

	`ifdef DCACHE_VICTIM
		wire [63:0]	evicted_data [`DCACHE_SETS-1:0];
		wire [`DCACHE_TAG_BITS-1:0] evicted_tag [`DCACHE_SETS-1:0];
		wire [`DCACHE_SETS-1:0] evicted_valid;
	`endif

	reg wr_en;
	reg [`DCACHE_TAG_BITS-1:0] wr_tag;
	reg [63:0] wr_data;

	generate
		genvar i;
		for(i=0; i<`DCACHE_SETS; i=i+1) begin : sets
			dcachemem_set sets (.clock(clock), .reset(reset), .access(set_access[i]),
													.wr_en(wr_en), .wr_tag(wr_tag), .wr_data(wr_data),
													.rd_tag(rd1_tag), .rd_data(set_rd_data[i]), .rd_valid(set_rd_valid[i])
													`ifdef DCACHE_VICTIM
														, .evicted_data(evicted_data[i]), .evicted_tag(evicted_tag[i]), .evicted_valid(evicted_valid[i])
													`endif
													);
		end
	endgenerate

	`ifdef DCACHE_VICTIM

	reg [63:0] rd1_data;
	reg rd1_valid;

	wire victim_rd_valid;
	wire [`DCACHE_TAG_BITS-1:0] victim_rd_tag;
	wire [`DCACHE_IDX_BITS-1:0] victim_rd_idx;
	wire [63:0] victim_rd_data;
	reg victim_wr_en;
	reg [`DCACHE_TAG_BITS-1:0] victim_wr_tag;
	reg [`DCACHE_IDX_BITS-1:0] victim_wr_idx;
	reg [63:0] victim_wr_data;

	dcachemem_victim victims (.clock(clock), .reset(reset), .en(en),
														.wr_en(victim_wr_en), .wr_tag(victim_wr_tag), .wr_idx(victim_wr_idx), .wr_data(victim_wr_data),
														.rd_tag(victim_rd_tag), .rd_idx(victim_rd_idx), .rd_data(victim_rd_data), .rd_valid(victim_rd_valid));

	assign victim_rd_tag = (en && !wr1_en) ? rd1_tag : 0;
	assign victim_rd_idx = (en && !wr1_en) ? rd1_idx : 0;

	wire [`DCACHE_IDX_BITS-1:0] evicted_idx;

	pe #(.OUT_WIDTH(`DCACHE_IDX_BITS)) pe0 (.gnt(evicted_valid), .enc(evicted_idx));

		always @* begin
			set_access = 0; wr_en = 0; wr_tag = 0; wr_data = 0; rd1_data = 0; rd1_valid = 0;
			victim_wr_en = 0; victim_wr_tag = 0; victim_wr_idx = 0; victim_wr_data = 0;
			if(en) begin

				if(wr1_en) begin // WRITE
					set_access[wr1_idx] = 1'b1;
					wr_en = 1'b1;
					wr_tag = wr1_tag;
					wr_data = wr1_data;
				end
				else begin // READ
					if(victim_rd_valid) begin
						rd1_data = victim_rd_data;
						rd1_valid = victim_rd_valid;
						set_access[rd1_idx] = 1'b1;
						wr_en = 1'b1;
						wr_tag = rd1_tag;
						wr_data = victim_rd_data;
					end
					else begin
						set_access[rd1_idx] = 1'b1;
						rd1_data = set_rd_data[rd1_idx];
						rd1_valid = set_rd_valid[rd1_idx];
					end
				end
			end

				if(|evicted_valid) begin
					victim_wr_en = 1'b1;
					victim_wr_tag = evicted_tag[evicted_idx];
					victim_wr_idx = evicted_idx;
					victim_wr_data = evicted_data[evicted_idx]; 
				end


		end
	`else 

		always @* begin
			set_access = 0; wr_en = 0;
			if(en) begin
				if(wr1_en) 	begin
					set_access[wr1_idx] = 1'b1;
					wr_en = 1'b1;
					wr_tag = wr1_tag;
					wr_data = wr1_data;
				end
				else				set_access[rd1_idx] = 1'b1;
			end
		end

		assign rd1_data 	= set_rd_data[rd1_idx];
		assign rd1_valid 	= set_rd_valid[rd1_idx];
	`endif

`else
	reg [63:0]									data		[`DCACHE_SETS-1:0];
	reg [`DCACHE_TAG_BITS-1:0]	tags		[`DCACHE_SETS-1:0];
	reg [`DCACHE_SETS-1:0]			valids;
	
	assign rd1_data		= data[rd1_idx];
	assign rd1_valid	= valids[rd1_idx]&&(tags[rd1_idx] == rd1_tag);

    //synopsys sync_set_reset "reset"
	always @(posedge clock)
	begin
	  if(reset) valids <= `SD 0;
	  else if(wr1_en)
	    valids[wr1_idx] <= `SD 1;
	end

	integer idx;
	
    //synopsys sync_set_reset "reset"
	always @(posedge clock)
	begin
		if(reset) begin
			for(idx=0; idx<`DCACHE_SETS; idx=idx+1) begin
				data[idx]	<= `SD 0;
				tags[idx]	<= `SD 0;
			end
		end
	  else if(wr1_en) begin
	    data[wr1_idx] <= `SD wr1_data;
	    tags[wr1_idx] <= `SD wr1_tag;
	  end
	end
`endif
endmodule

module dcachemem_set (clock, reset, access,
											wr_en, wr_tag, wr_data, 
											rd_tag, rd_data, rd_valid
											`ifdef DCACHE_VICTIM
											, evicted_data, evicted_tag, evicted_valid
											`endif
											);

	input clock, reset, access, wr_en;
	input [`DCACHE_TAG_BITS-1:0] wr_tag, rd_tag;
	input [63:0] wr_data;

	output [63:0] rd_data; 
	output rd_valid;

	reg	[63:0]									data		[1:0];
	reg [`DCACHE_TAG_BITS-1:0]	tags		[1:0];
	reg	[1:0]										valids, recent;
	reg													rd_miss, rd_way, wr_way;

`ifdef DCACHE_VICTIM
	output [63:0] evicted_data;
	output [`DCACHE_TAG_BITS-1:0] evicted_tag;
	output evicted_valid;
	assign evicted_data		= (access & wr_en) ? data[wr_way] : 0;
	assign evicted_tag		= (access & wr_en) ? tags[wr_way] : 0;
	assign evicted_valid	= (access & wr_en) ? valids[wr_way] : 0;
`endif

	always @* begin
		rd_miss	= 0;
		rd_way	= 0;
		wr_way	= 0;
		if(access) begin
			if(wr_en) begin
				if			(wr_tag == tags[1])	wr_way = 1'b1;
				else if	(wr_tag == tags[0])	wr_way = 1'b0;
				else if (recent == 2'b01)		wr_way = 1'b1;
				else if (recent == 2'b10)		wr_way = 1'b0;
				else		wr_way = 1'b0;
			end
			else begin
				if			((rd_tag == tags[1]) && valids[1]) rd_way = 1'b1;
				else if	((rd_tag == tags[0]) && valids[0]) rd_way = 1'b0;
				else		rd_miss = 1'b1;
			end
		end
	end

    //synopsys sync_set_reset "reset"
	always @(posedge clock) begin
		if(reset) begin
			recent	<= `SD 0;
			valids	<= `SD 0;
			tags[0]	<= `SD 0;
			tags[1]	<= `SD 0;
			data[0]	<= `SD 0;
			data[1]	<= `SD 0;
		end // if (reset)
		else if(access) begin
			if(wr_en) begin // if WRITE
				if(wr_way == 1'b1) begin 
					data[1]		<= `SD wr_data;
					tags[1]		<= `SD wr_tag;
					recent		<= `SD 2'b10;
					valids[1]	<= `SD 1'b1;
				end
				else if (wr_way == 1'b0) begin
					data[0]		<= `SD wr_data;
					tags[0]		<= `SD wr_tag;
					recent		<= `SD 2'b01;
					valids[0]	<= `SD 1'b1;
				end
			end // if(wr_en)
			else if (!rd_miss) begin // if READ HIT
				if			(rd_way==1'b1) recent <= `SD 2'b10;
				else if	(rd_way==1'b0) recent <= `SD 2'b01;
			end // else
		end // else if (access)
	end // always @

	assign rd_data	= (rd_way) ? data[1] : data[0];
	assign rd_valid	= (!rd_miss) ? ((rd_way) ? valids[1] : valids[0]) : 1'b0;

endmodule


`ifdef DCACHE_VICTIM
module dcachemem_victim (clock, reset, en, 
											wr_en, wr_tag, wr_idx, wr_data, 
											rd_tag, rd_idx, rd_data, rd_valid
											);

	input clock, reset, en, wr_en;
	input [`DCACHE_IDX_BITS-1:0] wr_idx, rd_idx;
	input [`DCACHE_TAG_BITS-1:0] wr_tag, rd_tag;
	input [63:0] wr_data;

	output [63:0] rd_data; 
	output rd_valid;

	reg	[63:0]									data		[1:0];
	reg [`DCACHE_TAG_BITS-1:0]	tags		[1:0];
	reg [`DCACHE_IDX_BITS-1:0]	index		[1:0];
	reg	[1:0]										valids, recent;
	reg													rd_miss, rd_way, wr_way;


	always @* begin
		rd_miss	= 0;
		rd_way	= 0;
		wr_way	= 0;
			if(en) begin
				if(wr_en) begin
					if			((wr_idx == index[1]) && (wr_tag == tags[1]))	wr_way = 1'b1;
					else if	((wr_idx == index[0]) && (wr_tag == tags[0]))	wr_way = 1'b0;
					else if (recent == 2'b01)		wr_way = 1'b1;
					else if (recent == 2'b10)		wr_way = 1'b0;
					else		wr_way = 1'b0;
				end
				else begin
					if			((rd_idx == index[1]) && (rd_tag == tags[1]) && valids[1]) rd_way = 1'b1;
					else if	((rd_idx == index[0]) && (rd_tag == tags[0]) && valids[0]) rd_way = 1'b0;
					else		rd_miss = 1'b1;
				end
			end
	end

    //synopsys sync_set_reset "reset"
	always @(posedge clock) begin
		if(reset) begin
			recent	<= `SD 0;
			valids	<= `SD 0;
			index[0]	<= `SD 0;
			index[1]	<= `SD 0;
			tags[0]	<= `SD 0;
			tags[1]	<= `SD 0;
			data[0]	<= `SD 0;
			data[1]	<= `SD 0;
		end // if (reset)
		else begin
			if(en) begin
				if(wr_en) begin // if WRITE
					if(wr_way == 1'b1) begin 
						data[1]		<= `SD wr_data;
						tags[1]		<= `SD wr_tag;
						index[1]	<= `SD wr_idx;
						recent		<= `SD 2'b10;
						valids[1]	<= `SD 1'b1;
					end
					else if (wr_way == 1'b0) begin
						data[0]		<= `SD wr_data;
						tags[0]		<= `SD wr_tag;
						index[0]	<= `SD wr_idx;
						recent		<= `SD 2'b01;
						valids[0]	<= `SD 1'b1;
					end
				end // if(wr_en)
				else if (!rd_miss) begin // if READ HIT
					if			(rd_way==1'b1) recent <= `SD 2'b10;
					else if	(rd_way==1'b0) recent <= `SD 2'b01;
				end // else
			end // else if (en)
		end
	end // always @

	assign rd_data	= (rd_way) ? data[1] : data[0];
	assign rd_valid	= (!rd_miss) ? ((rd_way) ? valids[1] : valids[0]) : 1'b0;

endmodule
`endif
