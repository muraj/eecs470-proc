//FIXME: TAG defines inssuffiecent... needs work
`define TAG(idx,x) x*ADDR_SZ+ADDR_SZ-1:x*ADDR_SZ+idx+3
`define IDX(idx,x) x*ADDR_SZ+idx+3-1:x*ADDR_SZ+3
module branch_predictor(clk, reset, IF_NPC, ROB_br_en, ROB_NPC, ROB_taken, ROB_taken_address, paddress, ptaken); //Branch Table
 //synopsys template
  parameter PRED_BITS =   `BRANCH_PREDICTION;
  parameter PRED_IDX  =   `PRED_IDX;
  parameter TYPE      =   1;    //Bimodal by default
  parameter HIST_IDX  =   4;
  parameter PRED_SZ   =   1 << PRED_IDX;
  parameter HIST_SZ   =   1 << HIST_IDX;
  parameter BTB_IDX   =   `BTB_IDX;
  parameter BTB_SZ    =   1 << BTB_IDX;
  parameter ADDR_SZ   =   64;

	input   wire	clk, reset; 
	input	  wire	[`SCALAR-1:0]    ROB_taken, ROB_br_en;
	input	  wire	[`SCALAR*64-1:0] IF_NPC;
	input   wire   [`SCALAR*64-1:0] ROB_NPC, ROB_taken_address;
	output  wire	[`SCALAR*64-1:0] paddress;
	output  wire	[`SCALAR-1:0]    ptaken;

  generate
    if(TYPE == 0 || PRED_BITS == 0) begin                 //Not Taken
      assign ptaken = {`SCALAR{0}};
    end
    else begin
     wire [`SCALAR-1:0] pred_taken;
     wire [`SCALAR-1:0] btb_valid;
     wire [`SCALAR*PRED_IDX-1:0] IF_pred_idx, ROB_pred_idx;
     assign ptaken = pred_taken & btb_valid;

     btb #(.IDX_SZ(BTB_IDX), .ADDR_SZ(64))
         btb0(clk, reset, IF_NPC, paddress, btb_valid, ROB_br_en, ROB_NPC, ROB_taken_address);

     saturating_counter #(.IDX(PRED_IDX), .CNT_SZ(PRED_BITS))
         cnt0(clk, reset, IF_pred_idx, pred_taken, ROB_br_en, ROB_pred_idx, ROB_taken);

     if(TYPE == 1) begin                //Bimodal 
        assign IF_pred_idx = {IF_NPC[`IDX(PRED_IDX,1)], IF_NPC[`IDX(PRED_IDX,0)]};
        assign ROB_pred_idx = {ROB_NPC[`IDX(PRED_IDX,1)], ROB_NPC[`IDX(PRED_IDX,0)]};
     end
     else if(TYPE == 2) begin           //Local
       history_table #(.IDX(HIST_IDX), .DATA_SZ(PRED_IDX))
          hist0(clk, reset, {IF_NPC[`IDX(HIST_IDX,1)], IF_NPC[`IDX(HIST_IDX,0)]}, IF_pred_idx,
                               ROB_br_en, {ROB_NPC[`IDX(HIST_IDX,1)], ROB_NPC[`IDX(HIST_IDX,0)]}, ROB_taken, ROB_pred_idx);
      end
    end
  endgenerate

endmodule

module history_table(clk, reset, rd_idx, rd_out, wr_en, wr_idx, wr_in, wr_out);
 //synopsys template
  parameter IDX=4;
  parameter DATA_SZ=2;
  parameter SZ=1<<IDX;
  input wire clk, reset;
  input wire [`SCALAR*IDX-1:0] rd_idx, wr_idx;
  input wire [`SCALAR*DATA_SZ-1:0] rd_out, wr_out;
  output wire [`SCALAR-1:0] wr_en, wr_in;
  reg [DATA_SZ-1:0] cntr [SZ-1:0];
  assign rd_out[`SEL(DATA_SZ,1)] = cntr[rd_idx[`SEL(IDX,1)]];
  assign wr_out[`SEL(DATA_SZ,1)] = cntr[wr_idx[`SEL(IDX,1)]];
  `ifdef SUPERSCALAR
  assign rd_out[`SEL(DATA_SZ,2)] = cntr[rd_idx[`SEL(IDX,2)]];
  assign wr_out[`SEL(DATA_SZ,2)] = cntr[wr_idx[`SEL(IDX,2)]];
  `endif
  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<SZ;i=i+1)
        cntr[i] <= `SD {DATA_SZ{1'b0}};
    end
    else begin
      if(wr_en[0])
        cntr[wr_idx[`SEL(IDX,1)]] <= `SD (cntr[wr_idx[`SEL(IDX, 1)]] << 1) | {{DATA_SZ-1{1'b0}}, wr_in[0]};
      if(wr_en[1])
        cntr[wr_idx[`SEL(IDX,2)]] <= `SD (cntr[wr_idx[`SEL(IDX, 2)]] << 1) | {{DATA_SZ-1{1'b0}}, wr_in[1]};
    end
  end

endmodule

module saturating_counter(clk, reset, rd_idx, rd_t, wr_en, wr_idx, wr_t);
 //synopsys template
  parameter IDX=4;
  parameter CNT_SZ=2;
  parameter SZ=1<<IDX;
  input wire clk, reset;
  input wire [`SCALAR*IDX-1:0] rd_idx, wr_idx;
  output wire [`SCALAR-1:0] rd_t, wr_en, wr_t;
  reg [CNT_SZ-1:0] cntr [SZ-1:0];
  integer i;
  wire [`SCALAR-1:0] plus_one;
  wire [`SCALAR-1:0] minus_one;

  wire [CNT_SZ-1:0] rd_cnt1 = cntr[rd_idx[`SEL(IDX,1)]];
  assign rd_t[0] = rd_cnt1[CNT_SZ-1];                   //MSB = 1 ? taken

  assign plus_one[0] = (~& cntr[wr_idx[`SEL(IDX,1)]]);  //Max out at 1111
  assign minus_one[0] = (| cntr[wr_idx[`SEL(IDX,1)]]);  //Min out at 0000
  `ifdef SUPERSCALAR

  wire [CNT_SZ-1:0] rd_cnt2 = cntr[rd_idx[`SEL(IDX,2)]];
  assign rd_t[1] = rd_cnt2[CNT_SZ-1];                   //MSB = 1 ? taken

  assign plus_one[1] = (~& cntr[wr_idx[`SEL(IDX,2)]]);  //Max out at 1111
  assign minus_one[1] = (| cntr[wr_idx[`SEL(IDX,2)]]);  //Min out at 0000
  `endif
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<SZ;i=i+1)
        cntr[i] <= `SD {1'b0, {CNT_SZ-1{1'b1}}};
    end
    else begin
      if(wr_en[0])
        cntr[wr_idx[`SEL(IDX,1)]] <= `SD cntr[wr_idx[`SEL(IDX,1)]] + (wr_t[0] & plus_one[0]) - (~wr_t[0] & minus_one[0]);
      `ifdef SUPERSCALAR
      if(wr_en[1])
        cntr[wr_idx[`SEL(IDX,2)]] <= `SD cntr[wr_idx[`SEL(IDX,2)]] + (wr_t[1] & plus_one[1]) - (~wr_t[1] & minus_one[1]);
      `endif
    end
  end   //reset
endmodule

module btb(clk, reset, rd_pc, rd_addr, rd_valid, wr_en, wr_pc, wr_addr);
 //synopsys template
  parameter IDX_SZ=4;
  parameter ADDR_SZ=64;
  parameter SZ=1<<IDX_SZ;
  input wire clk, reset;
  input wire [`SCALAR-1:0] rd_valid, wr_en;
  input wire [`SCALAR*ADDR_SZ-1:0] rd_pc, rd_addr, wr_pc, wr_addr;

  reg [ADDR_SZ-1:0] tag[SZ-1:0];
  reg [ADDR_SZ-1:0] buffer[SZ-1:0];

  assign rd_valid[0] = tag[rd_pc[`IDX(IDX_SZ,0)]] == rd_pc[`SEL(ADDR_SZ,1)];
  assign rd_addr[`SEL(64,1)] = buffer[rd_pc[`IDX(IDX_SZ,0)]];
  `ifdef SUPERSCALAR
  assign rd_valid[1] = tag[rd_pc[`IDX(IDX_SZ,1)]] == rd_pc[`SEL(ADDR_SZ,2)];
  assign rd_addr[`SEL(64,2)] = buffer[rd_pc[`IDX(IDX_SZ,1)]];
  `endif

  integer i;
  always @(posedge clk) begin
    if(reset) begin
      for(i=0;i<SZ;i=i+1) begin
        tag[i] <= `SD {ADDR_SZ{1'b0}};
        buffer[i] <= `SD {ADDR_SZ{1'b0}};
      end
    end
    else begin
      if(wr_en[0]) begin
        tag[wr_pc[`IDX(IDX_SZ,0)]] <= `SD wr_pc[`SEL(ADDR_SZ,1)];
        buffer[wr_pc[`IDX(IDX_SZ,0)]] <= `SD wr_addr[`SEL(ADDR_SZ,1)];
      end
      `ifdef SUPERSCALAR
      if(wr_en[1]) begin
        tag[wr_pc[`IDX(IDX_SZ,1)]] <= `SD wr_pc[`SEL(ADDR_SZ,2)];
        buffer[wr_pc[`IDX(IDX_SZ,1)]] <= `SD wr_addr[`SEL(ADDR_SZ,2)];
      end
      `endif
    end
  end
endmodule
