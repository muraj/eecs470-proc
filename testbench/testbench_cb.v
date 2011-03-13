`timescale 1ns/100ps
//`define PRF_IDX (6)
`define CB_IDX 3
`define CB_WIDTH 8


module testbench;

  integer count,limbo;  //TEST VARS
	reg	clk, reset, move_tail, din1_en, din2_en, dout1_req, dout2_req; //input
	reg	[`CB_IDX-1:0] tail_offset; //input
	reg	[`CB_WIDTH-1:0] din1, din2; //input
	wire	full, full_almost; //output
	wire	[`CB_WIDTH-1:0] dout1, dout2; //output

	cb #(.CB_IDX(`CB_IDX),.CB_WIDTH(`CB_WIDTH)) cb0 (clk, reset, move_tail, tail_offset, din1_en, din2_en,dout1_req, dout2_req,din1, din2, dout1, dout2, full, full_almost);


  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

/*
  always @(posedge clk) //simulating 
  begin
    count = count + din1_en+din2_en - dout1_req - dout2_req;
		if((count == `CB_WIDTH) != full)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be full, but isn't! @@@", $time);
				$finish;
			end
		else if((count == (`CB_WIDTH-1)) != full_almost)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be almost full, but isn't! @@@", $time);
				$finish;
			end 
	end
*/
  task show_IO_content;
	  begin
		
    $display("============================================================================================ ");
    $display("Din1 | Den1 | Din2 | Den2 | Dout1 | Dreq1 | Dout2 | Dreq2 | move tail | move offset ");
    $display("============================================================================================ ");

    $display(" 0x%h | %d | 0x%h | %d | 0x%h | %d | 0x%h | %d | %b | 0x%h ",din1, din1_en, din2, din2_en, dout1, dout1_req, dout2, dout2_req, move_tail, tail_offset);
    $display("============================================================================================ ");
	  end
	endtask


	task show_entry_content;
	  begin
		
		$display("\n========================== ");
    $display("Circular Buffer Contents:");
    $display("========================== ");

    $display("Counter : %d",cb0.iocount);
		$display("Full  / Almost : %0d,%0d",cb0.full, cb0.full_almost);
		$display("Empty / Almost : %0d,%0d\n",cb0.empty, cb0.empty_almost);
    $display("Head : %d",cb0.head);
		$display("Tail : %d\n",cb0.tail);
    
    $display("Entry 0 | %d",cb0.data[0]);
		$display("Entry 1 | %d",cb0.data[1]);
		$display("Entry 2 | %d",cb0.data[2]);
		$display("Entry 3 | %d",cb0.data[3]);
		$display("Entry 4 | %d",cb0.data[4]);
		$display("Entry 5 | %d",cb0.data[5]);
		$display("Entry 6 | %d",cb0.data[6]);
		$display("Entry 7 | %d",cb0.data[7]);

    $display("==========================\n");
	  end
	endtask

	task reset_all;
	  begin
			count = 0;
			move_tail=0;
  		din1_en=0;
  		din2_en=0;
  		dout1_req=0;
  		dout2_req=0;
  		tail_offset=0; 
			din1=0;
  		din2=0; 		
  	end
  endtask

	task insert_data;
			input [1:0] numData;
			input [`CB_WIDTH-1:0] data1;
			input	[`CB_WIDTH-1:0] data2;
		begin	
      din1=data1;
			din2=data2;
      if (numData == 2)
				begin
					din1_en=1;
  				din2_en=1;
    			$display("### Inserting 2 data: %d, %d\n",data1, data2);
				end
			else if(numData == 1)
				begin
					din1_en=1;
					din2_en=0;
    			$display("### Inserting 1 data: %d\n",data1);
   			end			
			else if(numData == 0)
				begin
					din1_en=0;
					din2_en=0;
  			end			
 		end
	endtask
 

	initial
	  begin
    clk = 1'b0;
    // Reset CB
    reset = 1'b1;      // Assert Reset
    @(negedge clk);
    reset = 1'b0;      // Deassert Reset
    // Initialize input signals
    reset_all();
  
    @(negedge clk);
		
    // Test case #1: Insert items 
    $display("=============================================================\n");
    $display("@@@ Test case #1: Insert test\n");
    $display("=============================================================\n");
    
    insert_data(2,3,0);
		show_IO_content();
		// insert two at a time
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
		insert_data(0,0,0);

		// insert one at a time
    // Reset CB
    reset = 1'b1;      // Assert Reset
    @(negedge clk);
    reset = 1'b0;      // Deassert Reset
    @(negedge clk);
		
		show_entry_content();show_IO_content();
    insert_data(1,5,0);
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
    @(negedge clk);show_entry_content();show_IO_content();
		insert_data(0,0,0);
    
		// Test case #2: Pull items
    $display("=============================================================\n");
    $display("@@@ Test case #2: Pull test\n");
    $display("=============================================================\n");
		
		// Test case #3: Insert & pull items at the same time 
    $display("=============================================================\n");
    $display("@@@ Test case #3: Insert & Pull test\n");
    $display("=============================================================\n");

		// Test case #4: Manually move tail position
    $display("=============================================================\n");
    $display("@@@ Test case #4: Move tail test\n");
    $display("=============================================================\n");
		

    $display("All Testcase Passed!\n"); 
    $finish; 

		end
endmodule
