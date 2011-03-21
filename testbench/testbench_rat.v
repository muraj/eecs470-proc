`timescale 1ns/100ps

//FIX ME : ZERO REGISTER FOR ARF


module testbench;

	integer idx;  //TEST VARS
  reg   clk, reset, flush;
  reg   [`SCALAR*`RAT_IDX-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
	reg  	[`SCALAR*`PRF_IDX-1:0] retire_pdest_idx_in;
  reg		[`SCALAR-1:0] issue, retire;
	wire	[`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out;

rat  #(.IDX_WIDTH(`RAT_IDX)) rat0 (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in,
						// PRF i/o
						prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in,
						// enable signals for rat and rrat
						issue, retire
				 	 );
/*					
  task new_inst;
	input [1:0] num_inst;
  input [4:0] rega1, regb1, regc1, rega2, regb2, regc2;
	begin
		
		if (num_inst > 0) begin
			issue[0] = 1'b1;
			issue[1] = 1'b0;
			rega_idx_in[`SEL(5,1)] = rega1;
			regb_idx_in[`SEL(5,1)] = regb1;
			dest_idx_in[`SEL(5,1)] = regc1;
			

			if (num_inst == 2) begin
				issue[1] = 1'b1;
				rega_idx_in[`SEL(5,2)] = rega2;
				regb_idx_in[`SEL(5,2)] = regb2;
				dest_idx_in[`SEL(5,2)] = regc2;
			end
		end else begin
			issue[0] = 1'b0;
			issue[1] = 1'b0;
		end

	end
	endtask
*/

  task new_inst;
	input [1:0] num_inst;
  input [4:0] regc1,regc2;
	begin
		
		if (num_inst > 0) begin
			issue[0] = 1'b1;
			issue[1] = 1'b0;
			rega_idx_in[`SEL(5,1)] = 15; //3
			regb_idx_in[`SEL(5,1)] = 14; //4
			dest_idx_in[`SEL(5,1)] = regc1;
			

			if (num_inst == 2) begin
				issue[1] = 1'b1;
				rega_idx_in[`SEL(5,2)] = 13; //2
				regb_idx_in[`SEL(5,2)] = 12; //7
				dest_idx_in[`SEL(5,2)] = regc2;
			end
		end else begin
			issue[0] = 1'b0;
			issue[1] = 1'b0;
		end

	end
	endtask

  task retire_inst;
	input [1:0] num_inst;
  input [4:0] dest1;
  input [`PRF_IDX:0] pdest1;
  input [4:0] dest2;
  input [`PRF_IDX:0] pdest2;
	begin

		if (num_inst > 0) begin
			retire[0] = 1'b1;
			retire[1] = 1'b0;
			retire_dest_idx_in[`SEL(5,1)] = dest1;
			retire_pdest_idx_in[`SEL(5,1)] = pdest1;
			
			if (num_inst == 2) begin
				retire[1] = 1'b0;
				retire_dest_idx_in[`SEL(5,2)] = dest2;
				retire_pdest_idx_in[`SEL(5,2)] = pdest2;
			end

		end else begin
			retire[0] = 1'b0;
			retire[1] = 1'b0;
		end

	end
	endtask
  
	
	task show_io;
	  begin
		
    $display("=====OUTPUTS=============================");
   	$display("       PRF1 PRF2 PDEST");
		$display("Way0: %2d   %2d   %2d", prega_idx_out[`SEL(`PRF_IDX,1)], pregb_idx_out[`SEL(`PRF_IDX,1)], pdest_idx_out[`SEL(`PRF_IDX,1)]);
		$display("Way1: %2d   %2d   %2d", prega_idx_out[`SEL(`PRF_IDX,2)], pregb_idx_out[`SEL(`PRF_IDX,2)], pdest_idx_out[`SEL(`PRF_IDX,2)]);
    $display("=========================================\n");

	  end
	endtask
  

	task show_RAT;
	  begin
		 `define DISPLAY_ENTRY_RAT(i) \
    $display(" %2d  |  %2d  |  %2d", i, rat0.file_rat.registers[i], rat0.file_rrat.registers[i]);

    $display("==================");
    $display(" IDX | RAT | RRAT   ");
    $display("==================");
    `DISPLAY_ENTRY_RAT(15)
    `DISPLAY_ENTRY_RAT(14) 
    `DISPLAY_ENTRY_RAT(13) 
    `DISPLAY_ENTRY_RAT(12) 
    `DISPLAY_ENTRY_RAT(11) 
    `DISPLAY_ENTRY_RAT(10) 
    `DISPLAY_ENTRY_RAT(09)
    `DISPLAY_ENTRY_RAT(08)
    `DISPLAY_ENTRY_RAT(07)
    `DISPLAY_ENTRY_RAT(06)
    `DISPLAY_ENTRY_RAT(05)
    `DISPLAY_ENTRY_RAT(04)
    `DISPLAY_ENTRY_RAT(03)
    `DISPLAY_ENTRY_RAT(02)
    `DISPLAY_ENTRY_RAT(01)
    `DISPLAY_ENTRY_RAT(00)
    $display("==================\n"); 
    
	  end
	endtask
	
	task show_freelist;
	  begin
		 `define DISPLAY_FREE(i) \
    $display(" %2d  |  %2d", i, rat0.fl[i]);

    $display("==================");
    $display(" IDX | RAT | RRAT   ");
    $display("==================");
		for(idx=0; idx<`PRF_SZ; idx=idx+1)
			begin    
				`DISPLAY_FREE(idx)
			end
    $display("==================\n"); 
    
	  end
	endtask

task reset_all;
begin
  clk=0; reset=0; flush=0;
  rega_idx_in=0; regb_idx_in=0; dest_idx_in=0; retire_dest_idx_in=0;
  issue=0; retire=0;
	retire_pdest_idx_in=0;
end
endtask
	
always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

initial begin

	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;
	show_RAT();@(negedge clk);
	$display("============================================================================================ ");
  $display(" TEST1: RANDOM INSERT  ");
  $display("============================================================================================ ");

 

	new_inst(2,4,5);show_io();@(negedge clk);show_RAT();
	new_inst(2,12,2);show_io();@(negedge clk);show_RAT();
	new_inst(1,9,2);show_io();@(negedge clk);show_RAT();
	new_inst(2,7,8);show_io();@(negedge clk);show_RAT();
	new_inst(0,9,2);show_io();@(negedge clk);show_RAT();
//	show_freelist();
	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;

	$display("============================================================================================ ");
  $display(" TEST2: In-order INSERT & REMOVE   ");
  $display("============================================================================================ ");
	show_RAT();@(negedge clk);
//	show_freelist();
	
	new_inst(2,0,1);show_io();@(negedge clk);show_RAT();
	new_inst(2,2,3);show_io();@(negedge clk);show_RAT();
	new_inst(2,4,5);show_io();@(negedge clk);show_RAT();
	new_inst(2,6,7);show_io();@(negedge clk);show_RAT();
	new_inst(2,8,9);show_io();@(negedge clk);show_RAT();
	issue[0] = 1'b0;
  issue[1] = 1'b0;
//	retire_inst(2,0,62,1,0);show_io();@(negedge clk);show_RAT();
	retire_inst(2,2,61,3,1);show_io();@(negedge clk);show_RAT();
	retire_inst(2,4,60,5,2);show_io();@(negedge clk);show_RAT();
	retire_inst(2,6,59,7,3);show_io();@(negedge clk);show_RAT();
	retire_inst(2,8,68,9,4);show_io();@(negedge clk);show_RAT();



	$finish;
end

endmodule
