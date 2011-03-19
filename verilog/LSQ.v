//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  LSQ.v			                                          //
//                                                                      //
//  Description :  This is a fake LSQ, 																	//
//								for testing the first version of EX_STAGE.						//
//								Now it has Input/Output ports 												//
//								only for the connection with EX_STAGE.								//
//								Input/Output ports MUST be fully redefined						//
//								to make a real LSQ.																		//
//								Remove this description after a complete LSQ is done.	//
//                                                                      //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module LSQ (clk, reset,
						//Inputs
						LSQ_idx_in, ADDR_in, reg_value_in,

						//Inputs (to control the outputs manuall)
						rob_idx_in, pdest_idx_in, mem_value_in, done_in, rd_mem_in, wr_mem_in

						//Outputs
						rob_idx_out, pdest_idx_out, mem_value_out, done_out, rd_mem_out, wr_mem_out
						);
	input [`LSQ_IDX*`SCALAR-1:0]	LSQ_idx_in;
	input [64*`SCALAR-1:0]				ADDR_in;
	input [64*`SCALAR-1:0]				reg_value_in;

	input [`ROB_IDX*`SCALAR-1:0]	rob_idx_in;
	input [`PRF_IDX*`SCALAR-1:0]	pdest_idx_in;
	input [64*`SCALAR-1:0]				mem_value_in;
	input [`SCALAR-1:0]						done_in;
	input [`SCALAR-1:0]						rd_mem_in;
	input [`SCALAR-1:0]						wr_mem_in;

	output [`ROB_IDX*`SCALAR-1:0]	rob_idx_out;
	output [`PRF_IDX*`SCALAR-1:0]	pdest_idx_out;
	output [64*`SCALAR-1:0]				mem_value_out;
	output [`SCALAR-1:0]					done_out;
	output [`SCALAR-1:0]					rd_mem_out;
	output [`SCALAR-1:0]					wr_mem_out;

	assign rob_idx_out = rob_idx_in;
	assign pdest_idx_out = pdest_idx_in;
	assign mem_value_out = mem_value_in;
	assign done_out = done_in;
	assign rd_mem_out = rd_mem_in;
	assign wr_mem_out = wr_mem_in;

endmodule

