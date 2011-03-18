`timescale 1ns/100ps
//`define PRF_IDX (6)

module testbench;
	integer count,limbo,idx;  //TEST VARS
	reg clk, reset, if_id_enable;
  reg din1_en, din2_en, dout1_req, dout2_req;
	//input 1	
	reg	[63:0]	if_NPC_out1;
	reg [31:0]	if_IR_out1;
  reg				  if_valid_inst_out1;
	//input 2
	reg	[63:0]	if_NPC_out2;
	reg [31:0]	if_IR_out2;
  reg				  if_valid_inst_out2;
	//output 1
 	wire [63:0] if_id_NPC1;
  wire [31:0] if_id_IR1;
  wire        if_id_valid_inst1;
	//output 2	
	wire [63:0] if_id_NPC2;
  wire [31:0] if_id_IR2;
  wire        if_id_valid_inst2;
	wire				 full_almost,full;

  if_id  if_id0(clk, reset, if_id_enable,din1_en, din2_en, dout1_req, dout2_req, if_NPC_out1, if_IR_out1, if_valid_inst_out1, if_id_NPC1, if_id_IR1, if_id_valid_inst1, if_NPC_out2, if_IR_out2, if_valid_inst_out2, if_id_NPC2, if_id_IR2, if_id_valid_inst2, full, full_almost);

  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;

  end

/*
  always @(posedge clk) //simulating 
  begin
     #2;
    count = count + din1_en+din2_en - dout1_req - dout2_req;
    count = (count >= `CB_WIDTH) ?  `CB_WIDTH : (count <= 0) ? 0 : count;  
		if((count < `CB_WIDTH) && full)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be full, but isn't! count: %d int_count: %d @@@", $time, count, if_id0.cb0.iocount);
				$finish;
			end
		else if((count > 0) && if_id0.cb0.empty)
			begin
	      $display("@@@ Fail! Time: %4.0f CB is supposed to be empty, but isn't! count: %d int_count: %d@@@", $time, count, if_id0.cb0.iocount);
				$finish;
			end 
	end
*/
/*
  task show_IO_content;
	  begin
		$display("======================================INPUT================================================= ");
    $display("NPC1 | IR1 | valid | Din_en1 | NPC2 | IR2 | valid | Din_en2 ");
    $display("============================================================================================ ");
    $display("0x%h | 0x%h | %d |  %d   | 0x%h | 0x%h | %d |  %d  ",if_NPC_out1, if_IR_out1, if_valid_inst_out1, din1_en,if_NPC_out2, if_IR_out2, if_valid_inst_out2, din2_en);
    $display("============================================================================================ ");


   $display("======================================OUTPUT================================================= ");
    $display("NPC1 | IR1 | valid | Dout_req1 | NPC2 | IR2 | valid |Dout_req2 ");
    $display("============================================================================================ ");
    $display("0x%h | 0x%h | %d |  %d   | 0x%h | 0x%h | %d |  %d  ",if_id_NPC1, if_id_IR1, if_id_valid_inst1, dout1_req, if_id_NPC2, if_id_IR2, if_id_valid_inst2, dout2_req);
    $display("============================================================================================ ");
	  end
	endtask


	task show_entry_content;
	  begin
		
		$display("\n========================== ");
    $display("Circular Buffer Contents:");
    $display("========================== ");

    $display("Counter : %d",if_id0.cb0.iocount);
		$display("Full  / Almost : %0d,%0d",if_id0.cb0.full, if_id0.cb0.full_almost);
		$display("Empty / Almost : %0d,%0d\n",if_id0.cb0.empty, if_id0.cb0.empty_almost);
    $display("Head : %d",if_id0.cb0.head);
		$display("Tail : %d\n",if_id0.cb0.tail);
    $display("Entry:  | NPC |  IR | valid");
    $display("Entry 0 | %d | %d | %d ",if_id0.cb0.data[0],if_id0.cb1.data[0],if_id0.cb2.data[0]);
		$display("Entry 1 | %d | %d | %d ",if_id0.cb0.data[1],if_id0.cb1.data[1],if_id0.cb2.data[1]);
		$display("Entry 2 | %d | %d | %d ",if_id0.cb0.data[2],if_id0.cb1.data[2],if_id0.cb2.data[2]);
		$display("Entry 3 | %d | %d | %d ",if_id0.cb0.data[3],if_id0.cb1.data[3],if_id0.cb2.data[3]);
		$display("Entry 4 | %d | %d | %d ",if_id0.cb0.data[4],if_id0.cb1.data[4],if_id0.cb2.data[4]);
		$display("Entry 5 | %d | %d | %d ",if_id0.cb0.data[5],if_id0.cb1.data[5],if_id0.cb2.data[5]);
		$display("Entry 6 | %d | %d | %d ",if_id0.cb0.data[6],if_id0.cb1.data[6],if_id0.cb2.data[6]);
		$display("Entry 7 | %d | %d | %d ",if_id0.cb0.data[7],if_id0.cb1.data[7],if_id0.cb2.data[7]);

    $display("==========================\n");
	  end
	endtask
*/
/*
	task reset_all;
	  begin
			count = 0;
  		din1_en=0;
  		din2_en=0;
  		dout1_req=0;
  		dout2_req=0;
			
			if_NPC_out1=0;
			if_IR_out1=0;
 			if_valid_inst_out1=0;

			if_NPC_out2=0;
			if_IR_out2=0;
 			if_valid_inst_out2=0;
  	end
  endtask

	task insert_data;
			input [1:0] numData;
			input [63:0] NPC1;
			input	[63:0] NPC2;
			input [31:0] IR1;
			input	[31:0] IR2;
			input	valid1;
			input	valid2;



		begin	
			if_NPC_out1=NPC1;
			if_IR_out1=IR1;
 			if_valid_inst_out1=valid1;

			if_NPC_out2=NPC2;
			if_IR_out2=IR2;
 			if_valid_inst_out2=valid2;

      if (numData == 2)
				begin
					din1_en=1;
  				din2_en=1;
    			$display("### Inserting 2 data");
				end
			else if(numData == 1)
				begin
					din1_en=1;
					din2_en=0;
    			$display("### Inserting 1 data");
   			end			
			else if(numData == 0)
				begin
					din1_en=0;
					din2_en=0;
  			end			
 		end
	endtask
 

	task remove_data;
			input [1:0] numData;
		begin	

      if (numData == 2)
				begin
      		dout1_req=1;
  				dout2_req=1;
				end
			else if(numData == 1)
				begin
      		dout1_req=1;
  				dout2_req=0;
   			end			
			else if(numData == 0)
				begin
					dout1_req=0;
  				dout2_req=0;
  			end			
 		end
	endtask
*/
endmodule
