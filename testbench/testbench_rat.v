`timescale 1ns/100ps

//FIXME : (Resolved) ZERO REGISTER FOR ARF
//FIXME : (Resolved) ERROR: When it commits, REG 0 becomes free both in RAT and RRAT [check Test case2:in then out] (see free list)
//FIXME : (Resolved) ERROR: Unlike RAT, when two PRFs commit to same ARF, only the PRFs that are mapped to ARF should be not free in RRAT. [check Test case4: mapped to same ARF]
//FIXME : (Resolved) ERROR: PRF 6, 8 doesn't work in RAT [check Test case5 : issue & commit same time] 

module testbench;

	integer idx;  //TEST VARS
  reg   clk, reset, flush;
  reg   [`SCALAR*`RAT_IDX-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
	reg  	[`SCALAR*`PRF_IDX-1:0] retire_pdest_idx_in;
  reg		[`SCALAR-1:0] issue, retire;

	wire	[`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out;
	wire  [`SCALAR-1:0] prega_valid_out, pregb_valid_out;

rat  #(.ARF_IDX(`RAT_IDX)) rat0 (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in, cdb_en, cdb_tag,
						// PRF i/o
						prega_idx_out, prega_valid_out, pregb_idx_out, pregb_valid_out, pdest_idx_out, retire_pdest_idx_in,
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
  input [`PRF_IDX-1:0] pdest1;
  input [4:0] dest2;
  input [`PRF_IDX-1:0] pdest2;
	begin

		if (num_inst > 0) begin
			retire[0] = 1'b1;
			retire[1] = 1'b0;
			retire_dest_idx_in[`SEL(5,1)] = dest1;
			retire_pdest_idx_in[`SEL(`PRF_IDX,1)] = pdest1;
			
			if (num_inst == 2) begin
				retire[1] = 1'b1;
				retire_dest_idx_in[`SEL(5,2)] = dest2;
				retire_pdest_idx_in[`SEL(`PRF_IDX,2)] = pdest2;
			end

		end else begin
			retire[0] = 1'b0;
			retire[1] = 1'b0;
		end

	end
	endtask
  
	
	task show_io;
	  begin
		
    $display("=====INPUTS==============================");
   	$display("ISSUE: %b, %b\tRETIRE: %b, %b\n", issue[0], issue[1], retire[0], retire[1]);
   	$display("       REGA REGB DEST");
		$display("Way0:  %2d   %2d   %2d", rega_idx_in[`SEL(5,1)], regb_idx_in[`SEL(5,1)], dest_idx_in[`SEL(5,1)]);
		$display("Way1:  %2d   %2d   %2d\n", rega_idx_in[`SEL(5,2)], regb_idx_in[`SEL(5,2)], dest_idx_in[`SEL(5,2)]);
   	$display("       REG  PRF");
		$display("Way0:  %2d   %2d", retire_dest_idx_in[`SEL(5,1)], retire_pdest_idx_in[`SEL(`PRF_IDX,1)]);
		$display("Way1:  %2d   %2d", retire_dest_idx_in[`SEL(5,2)], retire_pdest_idx_in[`SEL(`PRF_IDX,2)]);
    $display("=====OUTPUTS=============================");
   	$display("       PREGA PREGB PDEST FREE");
		$display("Way0:  %2d    %2d    %2d    %2d", prega_idx_out[`SEL(`PRF_IDX,1)], pregb_idx_out[`SEL(`PRF_IDX,1)], pdest_idx_out[`SEL(`PRF_IDX,1)], rat0.free_prf[`SEL(`PRF_IDX,1)]);
		$display("Way1:  %2d    %2d    %2d    %2d", prega_idx_out[`SEL(`PRF_IDX,2)], pregb_idx_out[`SEL(`PRF_IDX,2)], pdest_idx_out[`SEL(`PRF_IDX,2)], rat0.free_prf[`SEL(`PRF_IDX,2)]);
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
		for(idx=0; idx<`RAT_SZ; idx=idx+1) begin
			`DISPLAY_ENTRY_RAT(idx)
		end
    $display("==================\n"); 
    
	  end
	endtask
	
	task show_freelist;
	  begin
		 `define DISPLAY_FREE_RAT(i) \
    $display(" %2d  |  %2d  |  %2d", i, rat0.fl[i], rat0.rfl[i]);

    $display("====FREE LIST=====");
    $display(" IDX | RAT | RRAT   ");
    $display("==================");
		for(idx=0; idx<`PRF_SZ; idx=idx+1)
			begin    
				`DISPLAY_FREE_RAT(idx)
			end
    $display("==================\n"); 
    
	  end
	endtask

	task check;
  input [`ARF_IDX-1:0] rat_address;
  input [`PRF_IDX-1:0] rat_value;
  input [`ARF_IDX-1:0] rrat_address;
  input [`PRF_IDX-1:0] rrat_value;
	begin
		if (rat0.file_rat.registers[rat_address] != rat_value) begin
			$display("### Check failed: \nRAT[%2d]=%2d expected, but is instead %2d", rat_address, rat_value, rat0.file_rat.registers[rat_address]);
			$finish;
		end

		if (rat0.file_rrat.registers[rrat_address] != rrat_value) begin
			$display("### Check failed: \nRRAT[%2d]=%2d expected, but is instead %2d", rrat_address, rrat_value, rat0.file_rrat.registers[rrat_address]);
			$finish;
		end

	end
	endtask


task reset_all;
begin
  reset=0; flush=0;
  rega_idx_in=0; regb_idx_in=0; dest_idx_in=0; retire_dest_idx_in=0;
  issue=2'b00; retire=2'b00;
	retire_pdest_idx_in=0;
	reset = 1'b1; @(negedge clk); reset = 1'b0; @(negedge clk);
	$display("\n### RESETTING ALL...\n");
end
endtask
	
always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
		// always check for zero PRF mapping
		check(`ZERO_REG,`ZERO_PRF,`ZERO_REG,`ZERO_PRF);
  end

initial begin
	clk = 1'b0;
	reset_all();
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

	$display("============================================================================================ ");
  $display(" TEST2: In-order INSERT & REMOVE   ");
  $display("============================================================================================ ");
	reset_all();
	show_RAT();@(negedge clk);
//	show_freelist();
	
	show_freelist();new_inst(2,1,2);show_io();@(negedge clk);show_RAT();
	show_freelist();new_inst(2,3,4);show_io();@(negedge clk);show_RAT();
	new_inst(2,5,6);show_io();@(negedge clk);show_RAT();
	new_inst(2,7,8);show_io();@(negedge clk);show_RAT();
	new_inst(2,9,10);show_io();@(negedge clk);show_RAT();
	issue = 2'd0;
//show_freelist(); ERROR When it commits, REG 0 becomes free both in RAT and RRAT
	retire_inst(2,1,63,2,1);show_io();@(negedge clk);show_RAT();
	retire_inst(2,3,62,4,2);show_io();@(negedge clk);show_RAT();
	retire_inst(2,5,61,6,3);show_io();@(negedge clk);show_RAT();
	retire_inst(2,7,60,8,4);show_io();@(negedge clk);show_RAT();
	retire_inst(2,9,59,10,5);show_io();@(negedge clk);show_RAT();

	$display("============================================================================================ ");
  $display(" TEST3: ZERO REGISTER HANDLE");
  $display("============================================================================================ ");
	reset_all();

	new_inst(2,31,1);show_io();@(negedge clk);show_RAT(); // PRF 63 != ARF 0, PRF 1 to ARF 1
	check(1,1,31,0);
	new_inst(2,31,31);show_io();@(negedge clk);show_RAT(); // PRF 63 != ARF 0, PRF 2 != ARF 0
	check(1,1,31,0);
	new_inst(2,2,3);show_io();@(negedge clk);show_RAT(); // PRF 63 to ARF 2, PRF 2 to ARF 3
	check(2,63,31,0);
	check(3,2,31,0);
	issue = 2'd0;
	retire_inst(2,31,63,1,1);show_io();@(negedge clk);show_RAT();  
	check(31,0,1,1);
	retire_inst(2,2,63,31,2);show_io();@(negedge clk);show_RAT();  
	check(2,63,2,63);

	reset_all();
	show_freelist();

	$display("============================================================================================ ");
  $display(" TEST4: MAPPED TO SAME ARF");
  $display("============================================================================================ ");
	show_RAT();@(negedge clk);
  //Way 2 should overwrite Way 1 
	new_inst(2,1,1);show_io();@(negedge clk);show_RAT(); // PRF 63 != ARF 1, PRF 1 to ARF 1
	check(1,1,31,0);
	new_inst(2,2,2);show_io();@(negedge clk);show_RAT(); // PRF 62 != ARF 2, PRF 2 to ARF 2
	check(2,2,31,0);
	new_inst(2,3,3);show_io();@(negedge clk);show_RAT(); // PRF 61 != ARF 3, PRF 3 to ARF 3
	check(3,3,31,0);
	show_freelist(); //should show Way1 registers are not free althought they are not mapped5
	issue = 2'd0;
	retire_inst(1,1,63,1,1);show_io();@(negedge clk);show_RAT();show_freelist(); 
	retire_inst(1,1,1,1,1);show_io();@(negedge clk);show_RAT();show_freelist();
	retire_inst(2,2,62,2,2);show_io();@(negedge clk);show_RAT();show_freelist();
	retire_inst(2,3,61,3,3);show_io();@(negedge clk);show_RAT();
	show_freelist(); // (resolved) ERROR: Those are not mapped to ARF are not free RRAT

	reset_all();	show_freelist();

	$display("============================================================================================ ");
  $display(" TEST5: ISSUE and RETIRE @ sametime");
  $display("============================================================================================ ");
	
	new_inst(2,1,2);show_io();@(negedge clk);show_RAT();
  retire_inst(2,1,63,2,1);//show_io();@(negedge clk);show_RAT();
	new_inst(2,3,4);show_io();@(negedge clk);show_RAT();show_freelist(); 
	check(3,62,1,63);
	check(4,2,2,1);
	retire_inst(2,3,62,4,2);//show_io();//@(negedge clk);show_RAT();
	new_inst(2,5,6);show_io();@(negedge clk);show_RAT();show_freelist(); 
	check(5,61,3,62);
	check(6,3,4,2);
	retire_inst(2,5,61,6,3);//show_io();//@(negedge clk);show_RAT();
	new_inst(2,7,8);show_io();@(negedge clk);show_RAT();show_freelist(); //ERROR: PRF 6, 8 doesn't work in RAT. 
	retire_inst(2,7,60,8,4);//show_io();//@(negedge clk);show_RAT();	
	new_inst(2,9,10);show_io();@(negedge clk);show_RAT();
	issue = 2'd0;
	retire_inst(2,9,59,10,5);show_io();//@(negedge clk);show_RAT();

	reset_all();
	reset = 1'b1; @(negedge clk); reset = 1'b0;show_freelist();

	$display("============================================================================================ ");
  $display(" TEST6: FLUSH");
  $display("============================================================================================ ");
	new_inst(2,1,2);show_io();@(negedge clk);show_RAT();
	new_inst(2,3,4);show_io();@(negedge clk);show_RAT();
	new_inst(2,5,6);show_io();@(negedge clk);show_RAT();
	new_inst(2,7,8);show_io();@(negedge clk);show_RAT();
	new_inst(2,9,10);show_io();@(negedge clk);show_RAT();
	issue = 2'd0;
	retire_inst(2,1,63,2,1);show_io();@(negedge clk);show_RAT();
	retire_inst(2,3,62,4,2);show_io();@(negedge clk);show_RAT();
	retire_inst(2,5,61,6,3);show_io();@(negedge clk);show_RAT();
	retire_inst(2,7,60,8,4);show_io();@(negedge clk);show_RAT();
	retire_inst(2,9,59,10,5);show_io();@(negedge clk);show_RAT();
	retire = 2'd0;
	new_inst(2,1,2);show_io();@(negedge clk);show_RAT();
	new_inst(2,3,4);show_io();@(negedge clk);show_RAT();
	new_inst(2,5,6);show_io();@(negedge clk);show_RAT();
	new_inst(2,7,8);show_io();@(negedge clk);show_RAT();
	new_inst(2,9,10);show_io();@(negedge clk);show_RAT();
	show_freelist();
	flush=1;show_io();@(negedge clk);show_RAT();
	show_freelist();
	flush=0;


	
  $display("@@@ Success: All Testcases Passed!\n"); 
	$finish;
end

endmodule
