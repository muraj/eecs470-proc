`timescale 1ns/100ps

module testbench;

	integer idx;  //TEST VARS
  reg   clk, reset, flush;
  reg   [`SCALAR*`RAT_IDX-1:0] rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in;
  reg		[`SCALAR-1:0] issue, commit;
  wire  [`RAT_SZ*`PRF_IDX-1:0] rrat_data;   // 32, 64-bit Registers
	wire	[`SCALAR*`PRF_IDX-1:0] prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in;

rat  #(.IDX_WIDTH(`RAT_IDX)) rat0 (clk, reset, flush,
						// ARF inputs
						rega_idx_in, regb_idx_in, dest_idx_in, retire_dest_idx_in,
						// PRF i/o
						prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in,
						// enable signals for rat and rrat
						issue, commit
				 	 );
										
  task show_io;
	  begin
		
    $display("=====================OUTPUTS===================================");
   	$display("PRF_out1\tPRF_out2\tPRF_out_dest\tPRF_out_retire");
		$display("%b\t%b\t%b\t%b\t", prega_idx_out, pregb_idx_out, pdest_idx_out, retire_pdest_idx_in);
    $display("=============================================================\n");

	  end
	endtask
  

	task show_RAT;
	  begin
		 `define DISPLAY_ENTRY_RAT(i) \
    $display("%02d | %h", i, rat0.file_rat.registers[i]);

    $display("=================");
    $display("  IDX  |   PRF   ");
    $display("=================");
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
    $display("=================\n"); 

    
	  end
	endtask

	task show_RRAT;
	  begin
		 `define DISPLAY_ENTRY_RRAT(i) \
    $display("%02d | %h", i, rat0.file_rrat.registers[i]);

    $display("=================");
    $display("  IDX  |   PRF   ");
    $display("=================");
    `DISPLAY_ENTRY_RRAT(15)
    `DISPLAY_ENTRY_RRAT(14) 
    `DISPLAY_ENTRY_RRAT(13) 
    `DISPLAY_ENTRY_RRAT(12) 
    `DISPLAY_ENTRY_RRAT(11) 
    `DISPLAY_ENTRY_RRAT(10) 
    `DISPLAY_ENTRY_RRAT(09)
    `DISPLAY_ENTRY_RRAT(08)
    `DISPLAY_ENTRY_RRAT(07)
    `DISPLAY_ENTRY_RRAT(06)
    `DISPLAY_ENTRY_RRAT(05)
    `DISPLAY_ENTRY_RRAT(04)
    `DISPLAY_ENTRY_RRAT(03)
    `DISPLAY_ENTRY_RRAT(02)
    `DISPLAY_ENTRY_RRAT(01)
    `DISPLAY_ENTRY_RRAT(00)
    $display("=================\n"); 

    
	  end
	endtask


always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

initial
  begin



	end

endmodule
