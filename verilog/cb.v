module cb (clk, reset, 
					 // for manually moving the tail
					 move_tail, tail_new, 
					 // en writes data, req reads data
					 din1_en, din2_en, dout1_req, dout2_req, 
					 // actual data i/o
					 din1, din2, dout1, dout2, 
					 // indicators for higher level to decide how/what to input
					 full, full_almost, 
					 // head and tail
					 head, tail);

	//synopsys template
	parameter CB_IDX = 4;
	parameter CB_WIDTH = 8;
	parameter CB_LENGTH = 1 << CB_IDX;

  input clk, reset, move_tail, din1_en, din2_en, dout1_req, dout2_req;
	input [CB_IDX-1:0] tail_new;
	input [CB_WIDTH-1:0] din1, din2;
	output reg full, full_almost;
	output reg [CB_WIDTH-1:0] dout1, dout2;
	output reg [CB_IDX-1:0] head, tail;

	// internal regs
	reg [CB_WIDTH-1:0] data [CB_LENGTH-1:0];
	reg [CB_WIDTH-1:0] next_data1, next_data2;
	reg [CB_IDX-1:0] next_head, next_tail;

	// i/o counter
	reg [CB_IDX:0] iocount;
	wire [CB_IDX:0] next_iocount;
	reg [1:0] incount, outcount;
	reg empty, empty_almost;

	// purely combinational
	wire [CB_IDX-1:0] tail_p1, tail_p2, head_p1, head_p2, cur_size;
	wire next_full, next_full_almost, next_empty, next_empty_almost;
	
	assign tail_p1 = tail + 1'd1;
	assign tail_p2 = tail + 2'd2;
	assign head_p1 = head + 1'd1;
	assign head_p2 = head + 2'd2;
	
	// need to keep track of the current buffer size
	assign cur_size = (next_tail>=next_head)? (next_tail - next_head) : (next_tail + CB_LENGTH - next_head);
	assign next_iocount = (move_tail)? cur_size : iocount + incount - outcount;
	assign next_full = next_iocount == CB_LENGTH;
	assign next_full_almost = next_iocount == (CB_LENGTH-1);
	assign next_empty = next_iocount == 0;
	assign next_empty_almost = next_iocount == 1;

	always @* begin
		// default cases
		next_data1 = data[tail];
		next_data2 = data[tail_p1];
		next_head = head;
		next_tail = tail;
		incount = 2'd0;
		outcount = 2'd0;
		dout1 = data[head];
		dout2 = data[head_p1];

		// deal with tail and data in
		if (move_tail) begin
			next_tail = tail_new;
		end else begin
			if (din1_en && !full) begin
				next_tail = tail_p1;
				next_data1 = din1;
				incount = 2'd1;
				if (din2_en && !full_almost) begin
					next_tail = tail_p2;
					next_data2 = din2;
					incount = 2'd2;
				end
			end
		end

		// deal with head and data out
		if (dout1_req && !empty) begin
			next_head = head_p1;
			outcount = 2'd1;
			if (dout2_req && !empty_almost) begin
				next_head = head_p2;
				outcount = 2'd2;
			end
		end
	end

	always @(posedge clk) begin
		if (reset) begin
			head 					<= `SD {CB_IDX{1'b0}};
			tail 					<= `SD {CB_IDX{1'b0}};
			iocount 			<= `SD {CB_IDX+1{1'b0}};
			full 					<= `SD 1'b0;
			full_almost 	<= `SD 1'b0;
			empty					<= `SD 1'b0;
			empty_almost	<= `SD 1'b0;
		end else begin
			data[tail]		<= `SD next_data1;
			data[tail_p1] <= `SD next_data2;
			head 					<= `SD next_head;
			tail					<= `SD next_tail;
			iocount 			<= `SD next_iocount;
			full 					<= `SD next_full;
			full_almost 	<= `SD next_full_almost;
			empty					<= `SD next_empty;
			empty_almost	<= `SD next_empty_almost;
		end
	end

endmodule
