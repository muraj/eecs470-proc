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
  assign {current_tag, current_index} = proc2Icache_addr[63:3];


  reg [`NUM_MEM_TAGS-1:0] valid;
  reg [63:0] requested_PC [`NUM_MEM_TAGS-1:0];

  reg  [63:0] prefetch_PC;
  wor current_requested;
  wire [63:0] tag_PC = requested_PC[Imem2proc_tag];
  wire mem_forward = (valid[Imem2proc_tag] && ((Imem2proc_tag != 0 && tag_PC == {proc2Icache_addr[63:3], 3'b0})));
  wire [63:0] next_PC = (!current_requested && !cachemem_valid && !mem_forward) ? {proc2Icache_addr[63:3], 3'b0} : prefetch_PC + 8;

  assign Icache_data_out = mem_forward ? Imem2proc_data : cachemem_data;
  assign Icache_valid_out = mem_forward | cachemem_valid; 

  assign proc2Imem_addr = prefetch_PC;                  //Always ask for the next address to request
  assign proc2Imem_command = reset ? `BUS_NONE : `BUS_LOAD;               //Always load unless we're reset

  wire data_write_enable = valid[Imem2proc_tag];      //Write to icache if this is one of the tags we're looking for

  wire [63:0] last_PC = requested_PC[Imem2proc_tag];  //PC of the write to icache
  assign {last_tag, last_index} = last_PC[63:3];      //Tag and index of the write to icache

  generate
  genvar i;
  for(i=0;i<`NUM_MEM_TAGS;i=i+1) begin : ICACHE_COMPARE  //Very ineffiecent, but works
    assign current_requested = valid[i] ? {proc2Icache_addr[63:3], 3'b0} == requested_PC[i] : 1'b0;
  end
  endgenerate

  always @(posedge clock)
  begin
    if(reset)
    begin
      prefetch_PC       <= `SD 0;
      valid             <= `SD {`NUM_MEM_TAGS{1'b0}};
    end
    else
    begin
      valid[Imem2proc_tag]               <= `SD 1'b0;
      if(Imem2proc_response != 0 && !stall_icache) begin
        prefetch_PC                      <= `SD next_PC;
        valid[Imem2proc_response]        <= `SD 1'b1;
        requested_PC[Imem2proc_response] <= `SD prefetch_PC;
      end
    end
  end
endmodule
