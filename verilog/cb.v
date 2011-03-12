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
	output [CB_WIDTH-1:0] dout1, dout2;

	// internal regs
	reg [CB_IDX-1:0] head, tail;
	reg [CB_WIDTH-1:0] data [CB_LENGTH-1:0];
	reg [CB_IDX-1:0] next_head, next_tail;
	
	// purely combinational
	assign full = ((tail + 1'b1) == head);
	assign full_almost = ((tail + 1'b2) == head);

	always @* begin
		next_data = data;

		// deal with tail and data in
		if (move_tail) begin
			next_tail = tail - tail_offset;
		end else begin
			if (din1_en) begin
				next_tail = tail + 1;
				next_data[next_tail] = din1;
				if (din2_en) begin
					next_tail = tail + 2;
					next_data[next_tail] = din2;
				end
			end else begin
				next_tail = tail;
			end
		end

		// deal with head and data out
		if (dout1_req) begin
			next_head = head + 1;
			dout1 = data[head];
			if (dout2_req) begin
				next_head = head + 2;
				dout2 = data[head+1];
			end
		end else begin
			next_head = head;
		end

	end

	always @(posedge clk) begin
		if (reset) begin
			data <= `SD 0;
			head <= `SD {CB_IDX{1'b0}};
			tail <= `SD {CB_IDX{1'b0}};
		end else begin
			data <= `SD next_data;
			head <= `SD next_head;
			tail <= `SD next_tail;
		end
	end

