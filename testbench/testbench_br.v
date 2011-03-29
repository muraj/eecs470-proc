`timescale 1ns/100ps

// testbench works with length

module testbench;

  integer count,limbo,idx;  //TEST VARS
	reg	clk,reset;
	reg	[`SCALAR-1:0]	ROB_taken, ROB_br_en, ROB_valid;
	reg	[`SCALAR*64-1:0] ID_NPC, ROB_NPC, ROB_taken_address;
	wire	[63:0] paddress1, paddress2;
	wire	ptaken1, ptaken2;

 br_file br0 (clk, reset, ID_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, ROB_valid, paddress1, ptaken1, paddress2, ptaken2);

  always
  begin
    #(`VERILOG_CLOCK_PERIOD/2.0);
    clk = ~clk;
  end

	task reset_all;
		begin
		ID_NPC=0;
		ROB_br_en=0;
		ROB_taken=0;
		ROB_taken_address=0;
		ROB_valid=0;
		end
	endtask
	
	task show_freelist;
	  begin
		 `define DISPLAY_FREE(i) \
    $display(" %2d  |  %2d  |  %2d", i, br0.br_entries[i]., br0.BTB_entries[i]);

    $display("==================");
    $display(" IDX | RAT | RRAT   ");
    $display("==================");
		for(idx=0; idx<`BR_SZ; idx=idx+1)
			begin    
				`DISPLAY_FREE(idx)
			end
    $display("==================\n"); 
    
	  end
	endtask

  task show_IO_content;
	  begin
		
    $display("============================================================================================ ");
    $display("ID_NPC1  |  ID_NPC2  | predict address1 | predict taken1 | predict address2 | predict taken2");
    $display("============================================================================================ ");

    $display(" 0x%h    |  0x%h     |    0x%h  | %b | 0x%h | %b",ID_NPC[`SEL(64,1)], ID_NPC[`SEL(64,2)],paddress1, ptaken1, paddress2, ptaken2);
    $display("============================================================================================ ");
	  end
	endtask

	task show_content;
	  begin
		
    $display("============================================================================================ ");
    $display("");
    $display("============================================================================================ ");

    $display(" 0x%h    |  0x%h     |    0x%h  | %b | 0x%h | %b",ID_NPC[`SEL(64,1)], ID_NPC[`SEL(64,2)],paddress1, ptaken1, paddress2, ptaken2);
    $display("============================================================================================ ");
	  end
	endtask


	task insert_PC;
			input [`BR_IDX-1:0] pc;
		begin
		end
	endtask


initial
begin
$finish;
end
		
endmodule
