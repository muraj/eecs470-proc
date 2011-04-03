////////////////////////////////////
// Data Cache Controller 
////////////////////////////////////

module dcache(clock, reset,
             	// inputs
              Dmem2proc_response, Dmem2proc_tag,	// From Dmem
              proc2Dcache_addr,										// From Proc(LSQ)
              cachemem_data, cachemem_valid,  		// From Dcachemem
              // outputs
              proc2Dmem_command, proc2Dmem_addr, proc2Dmem_data,	// To Dmem
              Dcache_data_out, Dcache_valid_out,									// To Proc(LSQ)
              rd_idx, rd_tag, wr_idx, wr_tag, wr_enable						// To Dcachemem
             );

  input         clock, reset;
  input   [3:0] Dmem2proc_response, Dmem2proc_tag;
  input  [63:0] proc2Dcache_addr;
  input  [63:0] cachemem_data;
  input         cachemem_valid;

  output  [1:0] 								proc2Dmem_command;
  output [63:0] 								proc2Dmem_addr;
  output [63:0] 								proc2Dmem_data;
  output [63:0] 								Dcache_data_out;     
  output        								Dcache_valid_out;    
  output [`DCACHE_IDX_BITS-1:0] rd_idx, wr_idx;
  output [`DCACHE_TAG_BITS-1:0] rd_tag, wr_tag;
  output        								wr_enable;

  wire [`DCACHE_IDX_BITS-1:0] rd_idx;
  wire [`DCACHE_TAG_BITS-1:0] rd_tag;
  reg  [`DCACHE_IDX_BITS-1:0] wr_idx;
  reg  [`DCACHE_TAG_BITS-1:0] wr_tag;

  reg [3:0]	current_mem_tag;
  reg 			miss_outstanding;

	// To Dmem
  assign proc2Dmem_addr			= {proc2Dcache_addr[63:3],3'b0};
  assign proc2Dmem_command	= send_request ? `BUS_LOAD : `BUS_NONE;
	// To Proc(LSQ)
  assign Dcache_data_out		= cachemem_data;
  assign Dcache_valid_out		= cachemem_valid; 
	// To Dcachemem
  assign {rd_tag, rd_idx} 	= proc2Dcache_addr[31:3];
  assign wr_enable					= (current_mem_tag==Dmem2proc_tag) && (current_mem_tag!=0);


  wire changed_addr			= (rd_idx!=wr_idx) || (rd_tag!=wr_tag);
  wire send_request			= miss_outstanding && !changed_addr;
  wire update_mem_tag		= changed_addr | miss_outstanding | wr_enable;
  wire unanswered_miss	= changed_addr ? !Dcache_valid_out : miss_outstanding & (Dmem2proc_response==0);

  always @(posedge clock)
  begin
    if(reset)
    begin
      wr_idx     	  		<= `SD -1;   // These are -1 to get ball rolling when
      wr_tag         		<= `SD -1;   // reset goes low because addr "changes"
      current_mem_tag  	<= `SD 0;              
      miss_outstanding 	<= `SD 0;
    end
    else
    begin
      wr_idx      	 		<= `SD rd_idx;
      wr_tag         		<= `SD rd_tag;
      miss_outstanding	<= `SD unanswered_miss;
      if(update_mem_tag)
        current_mem_tag	<= `SD Dmem2proc_response;
    end
  end

endmodule

