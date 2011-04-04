////////////////////////////////////
// Data Cache Controller 
////////////////////////////////////

module dcache(clock, reset,
             	// inputs
              Dmem2Dcache_response, Dmem2Dcache_tag, Dmem2Dcache_data,	// From Dmem
              proc2Dcache_addr, proc2Dcache_command, proc2Dcache_data,	// From Proc(LSQ)
              cachemem_data, cachemem_valid,  													// From Dcachemem
              // outputs
              Dcache2Dmem_command, Dcache2Dmem_addr, Dcache2Dmem_data,	// To Dmem
              Dcache2proc_data, Dcache2proc_valid, Dcache2proc_tag, 		// To Proc(LSQ)
              rd_idx, rd_tag, wr_idx, wr_tag, wr_data, wr_en						// To Dcachemem
             );

  input         clock, reset;
  input   [3:0] Dmem2Dcache_response, Dmem2Dcache_tag;
	input  [63:0]	Dmem2Dcache_data;
	input   [1:0]	proc2Dcache_command;
  input  [63:0] proc2Dcache_addr, proc2Dcache_data;
  input  [63:0] cachemem_data;
  input         cachemem_valid;

  output reg  [1:0] 								Dcache2Dmem_command;
  output reg [63:0] 								Dcache2Dmem_addr, Dcache2Dmem_data;
  output reg [63:0] 								Dcache2proc_data;     
  output reg        								Dcache2proc_valid;    
	output reg  [3:0]									Dcache2proc_tag;
  output reg [`DCACHE_IDX_BITS-1:0] rd_idx, wr_idx;
  output reg [`DCACHE_TAG_BITS-1:0] rd_tag, wr_tag;
	output reg [63:0]									wr_data;
  output reg        								wr_en;

	reg	[63:0]	addr_reg	[15:0];
	reg	[63:0]	next_addr_reg, wr_addr;
	reg					rd_miss;

	always @(posedge clock) begin
		if(rd_miss) addr_reg[Dmem2Dcache_response]	<= `SD next_addr_reg; // in case of READ MISS, store the missed address.
	end // always @(posedge clock)

	always @* begin
		// Default Values
  	Dcache2Dmem_addr = 0;	Dcache2Dmem_data = 0;	Dcache2Dmem_command = `BUS_NONE;	// To DMEM
   	rd_idx = 0;	rd_tag = 0;	wr_idx = 0;	wr_tag = 0;	wr_data = 0;	wr_en = 0;			// To dcachemem
	  Dcache2proc_data = 0;	Dcache2proc_valid = 0;	Dcache2proc_tag = 0;						// To Proc (LSQ)
		next_addr_reg = 0;	wr_addr = 0;	rd_miss = 0;																// Internal Signals

		// Dmem2Dcache_tag = 0 -> Do whatever Proc requests
		if (Dmem2Dcache_tag == 4'b0) begin 
			// If Proc requests LOAD
			if (proc2Dcache_command == `BUS_LOAD) begin
				rd_tag							= proc2Dcache_addr[`DCACHE_IDX_BITS+`DCACHE_TAG_BITS+2:`DCACHE_IDX_BITS+3];
				rd_idx							=	proc2Dcache_addr[`DCACHE_IDX_BITS+2:3];
				Dcache2proc_data		= cachemem_data;
				Dcache2proc_valid		= cachemem_valid;
				Dcache2proc_tag			= 0;
				Dcache2Dmem_command	= `BUS_NONE;
  			Dcache2Dmem_addr		= {proc2Dcache_addr[63:3],3'b0};
					// If the requested LOAD is miss -> provide a new tag to Proc(LSQ), and store the missed address for the future WRITE 
					if (!cachemem_valid) begin	
						Dcache2proc_tag			= Dmem2Dcache_response;
						Dcache2Dmem_command = `BUS_LOAD;
						next_addr_reg				= proc2Dcache_addr;
						rd_miss							= 1'b1;
					end
			end
			// If Proc requests STORE -> Write the data into both DMEM and cachemem
			else if (proc2Dcache_command == `BUS_STORE) begin
				wr_tag							= proc2Dcache_addr[`DCACHE_IDX_BITS+`DCACHE_TAG_BITS+2:`DCACHE_IDX_BITS+3];
				wr_idx							=	proc2Dcache_addr[`DCACHE_IDX_BITS+2:3];
				wr_en								= 1'b1;
				wr_data							= proc2Dcache_data;
  			Dcache2Dmem_addr		= {proc2Dcache_addr[63:3],3'b0};
				Dcache2Dmem_command	= `BUS_STORE;
				Dcache2Dmem_data		= proc2Dcache_data;
			end
		end

		// Dmem2Dcache_tag != 0 (some loaded value have been come out from DMEM) -> Store the loaded value into cachemem, and also pass it to Proc(LSQ). LSQ should be stalled. 
		else begin
			wr_addr	= addr_reg[Dmem2Dcache_tag];
			wr_tag	= wr_addr[`DCACHE_IDX_BITS+`DCACHE_TAG_BITS+2:`DCACHE_IDX_BITS+3];
			wr_idx	=	wr_addr[`DCACHE_IDX_BITS+2:3];
			wr_en		= 1'b1;
			wr_data	= Dmem2Dcache_data;
			Dcache2proc_data	= Dmem2Dcache_data;
			Dcache2proc_valid	= 1'b1;
			Dcache2proc_tag		= Dmem2Dcache_tag;
		end
	end // always @*

endmodule

