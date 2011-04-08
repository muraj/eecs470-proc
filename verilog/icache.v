// Number of cachelines. must update both on a change
`define ICACHE_IDX_BITS       7      // log2(ICACHE_LINES)
`define ICACHE_TAG_BITS      21      //These should go in sys_defs.vh
`define ICACHE_LINES (1<<`ICACHE_IDX_BITS)

module icache(// inputs
              clock,
              reset,
              
              Imem2proc_response,
              Imem2proc_data,
              Imem2proc_tag,

              proc2Icache_addr,
              cachemem_data,
              cachemem_valid,  

              // outputs
              proc2Imem_command,
              proc2Imem_addr,

              Icache_data_out,
              Icache_valid_out,   

              current_index,
              current_tag,
              last_index,
              last_tag,
              data_write_enable,
              stall_icache
             );

  input         clock;
  input         reset;
  input   [3:0] Imem2proc_response;
  input  [63:0] Imem2proc_data;
  input   [3:0] Imem2proc_tag;

  input  [63:0] proc2Icache_addr;
  input  [63:0] cachemem_data;
  input         cachemem_valid;
  input         stall_icache;

  output  [1:0] proc2Imem_command;
  output [63:0] proc2Imem_addr;

  output [63:0] Icache_data_out;     // value is memory[proc2Icache_addr]
  output        Icache_valid_out;    // when this is high

  output  [`ICACHE_IDX_BITS-1:0] current_index;
  output  [`ICACHE_TAG_BITS-1:0] current_tag;
  output  [`ICACHE_IDX_BITS-1:0] last_index;
  output  [`ICACHE_TAG_BITS-1:0] last_tag;
  output        data_write_enable;


  wire  [`ICACHE_IDX_BITS-1:0] current_index;
  wire  [`ICACHE_TAG_BITS-1:0] current_tag;
  assign {current_tag, current_index} = proc2Icache_addr[31:3];


  reg [15:0] valid;
  reg [63:0] requested_PC [15:0];

  generate
  genvar i;
  for(i=0;i<16;i=i+1) begin : RESET_BUFFER
    always @(posedge clock) begin
      if(reset) begin
        valid[i]          <= `SD 1'b0;
        requested_PC[i]   <= `SD 64'b0;
      end
    end
  end
  endgenerate

  reg  [63:0] prefetch_PC, prefetch_counter;
  reg  prefetch_miss;   //Did we miss last time?
  wire [63:0] next_addr = prefetch_PC + (prefetch_counter << 3);  //x8
  wire [63:0] next_counter = (proc2Icache_addr >= prefetch_PC && proc2Icache_addr <= next_addr+8) ? 
                              (~prefetch_miss & ~cachemem_valid ? 0 : prefetch_counter + 1)
                             : 0;

  assign Icache_data_out = (Imem2proc_tag != 0 && requested_PC[Imem2proc_tag] == {proc2Icache_addr[63:3], 3'b0}) ? Imem2proc_data : cachemem_data;
  assign Icache_valid_out = (Imem2proc_tag != 0 && requested_PC[Imem2proc_tag] == {proc2Icache_addr[63:3], 3'b0}) || cachemem_valid; 

  assign proc2Imem_addr = next_addr;                  //Always ask for the next address to request
  assign proc2Imem_command = reset ? `BUS_NONE : `BUS_LOAD;               //Always load unless we're reset

  wire data_write_enable = valid[Imem2proc_tag];      //Write to icache if this is one of the tags we're looking for

  wire [63:0] last_PC = requested_PC[Imem2proc_tag];  //PC of the write to icache
  assign {last_tag, last_index} = last_PC[31:3];      //Tag and index of the write to icache

  always @(posedge clock)
  begin
    if(reset)
    begin
      prefetch_PC       <= `SD 0;
      prefetch_counter  <= `SD 0;
      prefetch_miss     <= `SD 0;
    end
    else
    begin
      valid[Imem2proc_tag]               <= `SD 1'b0;
      if(!stall_icache)
        prefetch_miss <= `SD ~cachemem_valid;
      if(next_counter == 0)   //Restarted! Start again!
        prefetch_PC                      <= `SD {proc2Icache_addr[63:3], 3'b0};
      if(Imem2proc_response != 0 && !stall_icache) begin
        prefetch_counter                 <= `SD next_counter;
        valid[Imem2proc_response]        <= `SD 1'b1;
        requested_PC[Imem2proc_response] <= `SD next_addr;
      end
    end
  end
endmodule

