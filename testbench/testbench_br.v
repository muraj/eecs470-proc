`timescale 1ns/100ps

// testbench works with length
`define PR_SZ (1<<`PRED_IDX)

module testbench;

  integer count,limbo,idx;  //TEST VARS
	reg	clk, reset; 
	reg		[`SCALAR-1:0]    ROB_taken, ROB_br_en;
	reg		[`SCALAR*64-1:0] IF_NPC;
	reg	  [`SCALAR*64-1:0] ROB_NPC, ROB_taken_address;
	wire	[`SCALAR*64-1:0] paddress;
	wire	[`SCALAR-1:0]    ptaken;

	branch_predictor br0 (clk, reset, IF_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, paddress, ptaken); //Branch Table

  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

	task reset_all;
		begin
		IF_NPC=0;
		ROB_br_en=0;
		ROB_taken=0;
		ROB_NPC=0;
		ROB_taken_address=0;
		end
	endtask
/*

	task show_BP;
	  begin
		 `define DISPLAY_BTB(i) \
    $display(" %2d |	%2d 	|	%2d	|	%2d	|	", i, br0.predictor[i], br0.BTB_npc[i], br0.BTB_addr[i]);
    $display("=================================================");
    $display(" IDX |  PRED	|	NPC	|	ADDR	| ");
		$display("=================================================");
		for(idx=0; idx<`PR_SZ; idx=idx+1)
			begin    
				`DISPLAY_BTB(idx)
			end
    $display("================================================\n"); 
    
	  end
	endtask


  task show_IO_content;
	  begin
		
    $display("============================================================================================ ");
    $display("IF_NPC1  |  IF_NPC2  | predict address1 | predict taken1 | predict address2 | predict taken2");
    $display("============================================================================================ ");

    $display(" %2d    | 	 %2d     |   			%2d   	  | 			%b 			 | 				%2d			  | 			%b      ", IF_NPC[`SEL(64,1)], IF_NPC[`SEL(64,2)],paddress[`SEL(64,1)], ptaken[0], paddress[`SEL(64,2)], ptaken[1]);
    $display("============================================================================================ ");
	  end
	endtask


//insert(BR_en, RB_taken, NPC1, NPC2, RB_NPC1, RB_NPC2, RB_taken address1,RB_taken address2)
	task insert;
	input		[`SCALAR-1:0]    RB_br_en, RB_taken ;
	input		[63:0] NPC1,NPC2, RB_NPC1, RB_NPC2;
	input	  [63:0] RB_taken_address1,RB_taken_address2 ;
		begin

		if (RB_br_en > 0) begin
			ROB_br_en[0] = 1'b1;
			ROB_br_en[1] = 1'b0;
			IF_NPC[`SEL(64,1)] = NPC1;
			ROB_NPC[`SEL(64,1)] = RB_NPC1;
			ROB_taken_address[`SEL(64,1)] = RB_taken_address1;
				if(RB_taken[0]) begin
				ROB_taken[0] =1;
				end
		if (RB_br_en == 2) begin
			ROB_br_en[1] = 1'b1;
			IF_NPC[`SEL(64,2)] = NPC2;
			ROB_NPC[`SEL(64,2)] = RB_NPC2;
			ROB_taken_address[`SEL(64,2)] = RB_taken_address2;
				if(RB_taken[1]) begin
				ROB_taken[1] =1;
				end
	  end
		end else begin
			ROB_br_en[0] = 1'b0;
			ROB_br_en[1] = 1'b0;
		end
		end
	endtask
*/
initial
begin
	clk = 1'b0;
	reset_all();
	@(negedge clk);
	$display("============================================================================================ ");
  $display(" TEST1: RANDOM INSERT  ");
  $display("============================================================================================ ");

$finish;
end
		
endmodule
