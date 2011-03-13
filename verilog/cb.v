module cb (clk, reset, move_tail, tail_offset, din1_en, din2_en, dout1_req, dout2_req, 
			din1, din2, dout1, dout2, full, full_almost);

	//synopsys template
	parameter CB_IDX = 4;
	parameter CB_LENGTH = 1'b1<<CB_IDX;
	parameter CB_WIDTH = 8;

  input clk, reset, move_tail, din1_en, din2_en, dout1_req, dout2_req;
	input [CB_IDX-1:0] tail_offset;
	input [CB_WIDTH-1:0] din1, din2;
	output full, full_almost;
	output reg [CB_WIDTH-1:0] dout1, dout2;

	// internal regs
	reg [CB_IDX-1:0] head, tail;
	reg [CB_WIDTH-1:0] data [CB_LENGTH-1:0];
	reg [CB_WIDTH-1:0] next_data1, next_data2;
	reg [CB_IDX-1:0] next_head, next_tail;
	
	// purely combinational
	wire [CB_IDX-1:0] tail_p1, tail_p2, head_p1, head_p2;
	
	assign tail_p1 = tail + 1'd1;
	assign tail_p2 = tail + 2'd2;
	assign head_p1 = head + 1'd1;
	assign head_p2 = head + 2'd2;
	assign full = ((tail_p1) == head);
	assign full_almost = ((tail_p2) == head);

	always @* begin
		// default cases
		next_data1 = data[tail_p1];
		next_data2 = data[tail_p2];
		next_head = head;
		next_tail = tail;

		// deal with tail and data in
		if (move_tail) begin
			next_tail = tail - tail_offset;
		end else begin
			if (din1_en) begin
				next_tail = tail_p1;
				next_data1 = din1;
				if (din2_en) begin
					next_tail = tail_p2;
					next_data2 = din2;
				end
			end
		end

		// deal with head and data out
		if (dout1_req) begin
			next_head = head_p1;
			dout1 = data[head];
			if (dout2_req) begin
				next_head = head_p2;
				dout2 = data[head_p1];
			end
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			head <= `SD {CB_IDX{1'b0}};
			tail <= `SD {CB_IDX{1'b0}};
		end else begin
			data[tail+1] <= `SD next_data1;
			data[tail+2] <= `SD next_data2;
			head <= `SD next_head;
			tail <= `SD next_tail;
		end
	end

endmodule
