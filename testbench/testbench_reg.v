/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  testbench_RS.v                                      //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps


module testbench;

  integer idx;  //TEST VARS
  `define REG_IDX (4)
  `define REG_SZ (1<<`REG_IDX)
  `define DATA_SZ (64)
  // Registers and wires used in the testbench
  reg  clk;
  reg  [`SCALAR*`REG_IDX-1:0] rda_idx;
  reg  [`SCALAR*`REG_IDX-1:0] rdb_idx;
  reg  [`SCALAR*`REG_IDX-1:0] wr_idx;
  reg  [`SCALAR*`DATA_SZ-1:0] wr_data;
  reg  [`SCALAR-1:0] wr_en;

  wire  [`SCALAR*`DATA_SZ-1:0] rda_out;
  wire  [`SCALAR*`DATA_SZ-1:0] rdb_out;

  regfile #(.IDX_WIDTH(`REG_IDX), .DATA_WIDTH(`DATA_SZ))
                     file (rda_idx, rda_out,                // read port A
                           rdb_idx, rdb_out,                // read port B
                           wr_idx, wr_data, wr_en, clk); // write port

  // Generate System Clock
  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

  // Task to display REGISTER content
  task show_entry_content;
  begin
  `ifdef SYNTH
    $display("");
  `else
  `define DISPLAY_ENTRY(i) \
    $display("%02d | %h", i, file.registers[i]);

    $display("=================");
    $display("  IDX  |   VAL   ");
    $display("=================");
    `DISPLAY_ENTRY(15)
    `DISPLAY_ENTRY(14) 
    `DISPLAY_ENTRY(13) 
    `DISPLAY_ENTRY(12) 
    `DISPLAY_ENTRY(11) 
    `DISPLAY_ENTRY(10) 
    `DISPLAY_ENTRY(09)
    `DISPLAY_ENTRY(08)
    `DISPLAY_ENTRY(07)
    `DISPLAY_ENTRY(06)
    `DISPLAY_ENTRY(05)
    `DISPLAY_ENTRY(04)
    `DISPLAY_ENTRY(03)
    `DISPLAY_ENTRY(02)
    `DISPLAY_ENTRY(01)
    `DISPLAY_ENTRY(00)
    $display("=================\n"); 
  `endif
  end
  endtask
  task wr_reg;
  input [`REG_IDX-1:0] idx;
  input [`DATA_SZ-1:0] val;
  input which;
  begin
    if(which) begin
      wr_en[1] = 1;
      wr_idx[`SEL(`REG_IDX, 2)] = idx;
      wr_data[`SEL(`DATA_SZ, 2)] = val;
    end
    else begin
      wr_en[0] = 1;
      wr_idx[`SEL(`REG_IDX, 1)] = idx;
      wr_data[`SEL(`DATA_SZ, 1)] = val;
    end

  end
  endtask

  // Testbench
  initial
  begin
    clk = 1'b0;
    idx = 1;
    @(negedge clk);
    // Initialize input signals
    wr_en = 0;
    rda_idx = 0;
    rdb_idx = 0;
    wr_idx = 0;
    wr_data = 0;
	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Write/Read 1 value", $time);
    $display("=============================================================\n");
    @(negedge clk);
    wr_reg(idx, 64'h8BADF00D, 0);
    @(negedge clk);
    wr_en[0] = 2'b00;  //Disable write
    rda_idx[`SEL(`REG_IDX, 1)] = idx;
    @(posedge clk);     //Check at next cycle
    show_entry_content();
    if(rda_out[`SEL(`DATA_SZ, 1)] !== 64'h8BADF00D) begin
        $display("@@@ Fail! Time: %4.0f  Test case: Write/Read 1 value", $time);
        $finish;
    end
    else
        $display("@@@ Success! Time: %4.0f  Test case: Write/Read 1 value", $time);

    idx = idx + 1;

	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Write forward 1 value", $time);
    $display("=============================================================\n");
    @(negedge clk);
    wr_reg(idx, 64'hDEADBEEF, 1);
    rda_idx[`SEL(`REG_IDX, 2)] = idx;
    @(posedge clk);
    show_entry_content();
    if(rda_out[`SEL(`DATA_SZ, 2)] !== 64'hDEADBEEF) begin
        $display("@@@ Fail! Time: %4.0f  Test case: Write/Read 1 value", $time);
        $finish;
    end
    else
        $display("@@@ Success! Time: %4.0f  Test case: Write/Read 1 value", $time);
    @(negedge clk);
    wr_en[1] = 0;  //Disable write

    idx = idx + 1;

	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Write forward 1 value superscalar", $time);
    $display("=============================================================\n");
    @(negedge clk);
    wr_reg(idx, 64'hFEEDFACE, 1);
    rda_idx[`SEL(`REG_IDX, 1)] = idx;
    @(posedge clk);
    show_entry_content();
    if(rda_out[`SEL(`DATA_SZ, 1)] !== 64'hFEEDFACE) begin
        $display("@@@ Fail! Time: %4.0f  Test case: Write/Read 1 value", $time);
        $finish;
    end
    else
        $display("@@@ Success! Time: %4.0f  Test case: Write/Read 1 value", $time);
    @(negedge clk);
    wr_en[1] = 0;  //Disable write

    idx = idx + 1;

	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Write/Read 4 values superscalar", $time);
    $display("=============================================================\n");
    @(negedge clk);
    wr_reg(idx, 64'hDEADF00D, 0);
    wr_reg(idx + 1, 64'hDEADFA11, 1);
    @(negedge clk);
    wr_en = 2'b00;  //Disable write
    $display("ZERO_REG: %h", `ZERO_REG);
    rda_idx[`SEL(`REG_IDX,1)] = idx+1;
    rdb_idx[`SEL(`REG_IDX,1)] = idx;
    rda_idx[`SEL(`REG_IDX,2)] = idx-1;
    rdb_idx[`SEL(`REG_IDX,2)] = idx-2;
    @(posedge clk);     //Check at next cycle
    show_entry_content();
    if(rda_out[`SEL(`DATA_SZ, 1)] !== 64'hDEADFA11 || rdb_out[`SEL(`DATA_SZ, 1)] !== 64'hDEADF00D ||
        rda_out[`SEL(`DATA_SZ, 2)] !== 64'hFEEDFACE || rdb_out[`SEL(`DATA_SZ, 2)] !== 64'hDEADBEEF) begin
        $display("@@@ Fail! Time: %4.0f  Test case: Write/Read 4 values superscalar", $time);
        $finish;
    end
    else
        $display("@@@ Success! Time: %4.0f  Test case: Write/Read 4 values superscalar", $time);

    idx = idx + 2;

	$display("=============================================================\n");
    $display("@@@ Time: %4.0f  Test case: Write forward 2 values superscalar", $time);
    $display("=============================================================\n");
    @(negedge clk);
    wr_reg(idx, 64'hFEEEFEEE, 0);
    wr_reg(idx + 1, 64'hFDFDFDFD, 1);
    rda_idx[`SEL(`REG_IDX, 1)] = idx;
    rda_idx[`SEL(`REG_IDX, 2)] = idx+1;
    @(posedge clk);
    $display("wr_en: %b", file.wr_en);
    $display("rda_idx: %h", file.rda_idx);
    $display("rdb_idx: %h", file.rdb_idx);
    $display("rda_out: %h", file.rda_out);
    $display("rdb_out: %h", file.rdb_out);
    $display("rda_reg: %h", file.rda_reg);
    $display("rdb_reg: %h", file.rdb_reg);
    $display("wr_data: %h", file.wr_data);
    $display("wr_idx: %h", file.wr_idx);
    show_entry_content();
    if(rda_out[`SEL(`DATA_SZ, 1)] !== 64'hFEEEFEEE || rda_out[`SEL(`DATA_SZ, 2)] !== 64'hFDFDFDFD) begin
        $display("@@@ Fail! Time: %4.0f  Test case: Write forward 2 values superscalar", $time);
        $finish;
    end
    else
        $display("@@@ Success! Time: %4.0f  Test case: Write forward 2 values superscalar", $time);
    $display("@@@ Success!  All tests passed");
    $finish;
  end

endmodule  // module testbench

