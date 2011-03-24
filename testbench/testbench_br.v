`timescale 1ns/100ps

// testbench works with length

module testbench;

  integer count,limbo,idx;  //TEST VARS
	reg clk, reset, sel;
  reg [`BR_IDX-1:0] pc_idx;
	wire taken;

	br_file br0 ( .clk(clk), .reset(reset), .pc_idx(pc_idx), .taken(taken)); 

  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end



  task show_IO_content;
	  begin
		
    $display("============================================================================================ ");
    $display("PC IDX | TAKEN");
    $display("============================================================================================ ");

    $display("%b     |  %d  ",pc_idx, taken);
    $display("============================================================================================ ");
	  end
	endtask

initial
begin
$finish;
end
		
endmodule
