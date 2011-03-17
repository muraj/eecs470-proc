module RS(clk, reset,
                //INPUTS
                rs_en, prega_idx, pregb_idx, pdest_idx, prega_valid, pregb_valid, //RAT
                ALUop, rd_mem, wr_mem, rs_IR,  npc, cond_branch, uncond_branch, //Issue Stage
                mult_free, ALU_free, mem_free, cdb_valid, cdb_tag, entry_flush,//Pipeline communication
                rob_idx,  //ROB

                //OUTPUT
                rs_free,  ALU_rdy, mem_rdy, mult_rdy, //Hazard detect
                pdest_idx_out, prega_idx_out, pregb_idx_out, ALUop_out, rd_mem_out,   //FU
                wr_mem_out, rs_IR_out, npc_out, rob_idx_out,                          //FU
    			rs_idx_out															  //ROB
          );

  input wire  clk, reset;
  input wire  rs_en;   // I'm being allocated
  input wire  [`PRF_IDX-1:0] prega_idx, pregb_idx, pdest_idx;
  input wire  prega_valid, pregb_valid;
  input wire  [4:0] ALUop;
  input wire  rd_mem, wr_mem;
  input wire  [31:0] rs_IR; 
  input wire  cond_branch, uncond_branch;
  input wire  [63:0] npc;
  input wire  mult_free, ALU_free, mem_free;
  input wire  [`SCALAR-1:0] cdb_valid;
  input wire  [`SCALAR*`PRF_IDX-1:0] cdb_tag;
  input wire  [`RS_SZ-1:0] entry_flush;
  input wire  [`ROB_IDX-1:0] rob_idx;

  output wire rs_free;
  output wire ALU_rdy, mem_rdy, mult_rdy;
  output wire [`PRF_IDX-1:0] pdest_idx_out, prega_idx_out, pregb_idx_out;
  output wire [4:0] ALUop_out;
  output wire rd_mem_out, wr_mem_out;
  output wire [31:0] rs_IR_out;
  output wire [63:0] npc_out;
  output wire [`ROB_IDX-1:0] rob_idx_out;
  output wire [`RS_IDX-1:0] rs_idx_out; // Output of ex encoder

  wire [`RS_SZ-1:0] entry_free;
  wire [`RS_SZ-1:0] entry_ALU_rdy, entry_mem_rdy, entry_mult_rdy;
  wire [`PRF_IDX-1:0] pdest_idx_int [`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] prega_idx_int [`RS_SZ-1:0];
  wire [`PRF_IDX-1:0] pregb_idx_int [`RS_SZ-1:0];
  wire [4:0] ALUop_int [`RS_SZ-1:0];
  wire [`RS_SZ-1:0] rd_mem_int;
  wire [`RS_SZ-1:0] wr_mem_int;
  wire [31:0] rs_IR_int [`RS_SZ-1:0];
  wire [63:0] npc_int [`RS_SZ-1:0]; 
  wire [`ROB_IDX-1:0] rob_idx_int [`RS_SZ-1:0];

  wire [`RS_SZ-1:0] entry_en; // Output of issue selector
  wire [`RS_SZ-1:0] entry_ALU_sel, entry_mem_sel, entry_mult_sel; // Output of the encoders (ALU_sel, mem_sel, mult_sel)
  wire [`RS_SZ-1:0] entry_sel; // selected entry for execution

  assign pdest_idx_out = pdest_idx_int[rs_idx_out];
  assign prega_idx_out = prega_idx_int[rs_idx_out];
  assign pregb_idx_out = pregb_idx_int[rs_idx_out];
  assign ALUop_out = ALUop_int[rs_idx_out];
  assign rd_mem_out = rd_mem_int[rs_idx_out];
  assign wr_mem_out = wr_mem_int[rs_idx_out];
  assign rs_IR_out = rs_IR_int[rs_idx_out];
  assign npc_out = npc_int[rs_idx_out];
  assign rob_idx_out = rob_idx_int[rs_idx_out];
  assign rs_free = | entry_free;

  assign ALU_rdy = | entry_ALU_rdy;
  assign mem_rdy = | entry_mem_rdy;
  assign mult_rdy = | entry_mult_rdy;

  assign entry_sel = ALU_free ? entry_ALU_sel :
					(mem_free ? entry_mem_sel :
					(mult_free ? entry_mult_sel : {`RS_SZ{1'b0}}));

ps #(.NUM_BITS(`RS_SZ)) issue_sel(.req(entry_free), .en(rs_en), .gnt(entry_en), .req_up()); 
ps #(.NUM_BITS(`RS_SZ)) ALU_sel(.req(entry_ALU_rdy), .en(ALU_free), .gnt(entry_ALU_sel), .req_up());
ps #(.NUM_BITS(`RS_SZ)) mem_sel(.req(entry_mem_rdy), .en(mem_free), .gnt(entry_mem_sel), .req_up());
ps #(.NUM_BITS(`RS_SZ)) mult_sel(.req(entry_mult_rdy), .en(mult_free), .gnt(entry_mult_sel), .req_up());
pe #(.OUT_WIDTH(`RS_IDX)) ex_encode(.gnt(entry_sel), .enc(rs_idx_out)); 



generate
  genvar i;
  for(i=0; i<`RS_SZ; i=i+1) begin : entries
    rs_entry entry ( .clk(clk),
                                  .reset(reset | entry_flush[i]),
                          //INPUTS
                                  .entry_en(entry_en[i]),  //ISSUE_SEL 
                                  .entry_sel(entry_sel[i]), //EX_SEL
                                  .prega_idx(prega_idx), 
                                  .pregb_idx(pregb_idx), 
                                  .pdest_idx(pdest_idx), 
                                  .prega_valid(prega_valid), 
                                  .pregb_valid(pregb_valid), 
                                  .ALUop(ALUop), 
                                  .rd_mem(rd_mem), 
                                  .wr_mem(wr_mem), 
                                  .rs_IR(rs_IR),
                                  .npc(npc), 
                                  .cond_branch(cond_branch), 
                                  .uncond_branch(uncond_branch), 
                                  .mult_free(mult_free),
                                  .ex_free(ex_free), 
                                  .mem_free(mem_free), 
                                  .cdb_valid(cdb_valid), 
                                  .cdb_tag(cdb_tag), 
                                  .rob_idx(rob_idx),

                          //OUTPUT
                                  .entry_free(entry_free[i]), 
                                  .ALU_rdy(entry_ALU_rdy[i]),
								  .mem_rdy(entry_mem_rdy[i]),
								  .mult_rdy(entry_mult_rdy[i]),
                                  .pdest_idx_out(pdest_idx_int[i]), 
                                  .prega_idx_out(prega_idx_int[i]), 
                                  .pregb_idx_out(pregb_idx_int[i]), 
                                  .ALUop_out(ALUop_int[i]), 
                                  .rd_mem_out(rd_mem_int[i]),
                                  .wr_mem_out(wr_mem_int[i]), 
                                  .rs_IR_out(rs_IR_int[i]), 
                                  .npc_out(npc_int[i]), 
                                  .rob_idx_out(rob_idx_int[i])
                                );
    end
endgenerate
endmodule

module rs_entry(clk, reset,
                //INPUTS
                entry_en, entry_sel, prega_idx, pregb_idx, pdest_idx, prega_valid, pregb_valid, //RAT
                ALUop, rd_mem, wr_mem, rs_IR,  npc, cond_branch, uncond_branch, //Issue Stage
                mult_free, ex_free, mem_free, cdb_valid, cdb_tag, //Pipeline communication
                rob_idx,  //ROB

                //OUTPUT
                entry_free, ALU_rdy, mem_rdy, mult_rdy,  //Pipeline Communication
                pdest_idx_out, prega_idx_out, pregb_idx_out, ALUop_out, rd_mem_out,   //FU
                wr_mem_out, rs_IR_out, npc_out, rob_idx_out                 //FU
                );



  input wire  clk, reset;
  input wire  entry_en;   // I'm being allocated
  input wire  entry_sel;  // Selected for execution
  input wire  [`PRF_IDX-1:0] prega_idx, pregb_idx, pdest_idx;
  input wire  prega_valid, pregb_valid;
  input wire  [4:0] ALUop;
  input wire  rd_mem, wr_mem;
  input wire  [31:0] rs_IR; 
  input wire  cond_branch, uncond_branch;
  input wire  [63:0] npc;
  input wire  mult_free, ex_free, mem_free;
  input wire  [`SCALAR-1:0] cdb_valid;
  input wire  [`SCALAR*`PRF_IDX-1:0] cdb_tag;
  input wire  [`ROB_IDX-1:0] rob_idx;

  output reg  entry_free, ALU_rdy, mem_rdy, mult_rdy;
  output reg  [`PRF_IDX-1:0] pdest_idx_out, prega_idx_out, pregb_idx_out;
  output reg  [4:0] ALUop_out;
  output reg  rd_mem_out, wr_mem_out;
  output reg  [31:0] rs_IR_out;
  output reg  [63:0] npc_out;
  output reg  [`ROB_IDX-1:0] rob_idx_out;

  reg  next_entry_free;
  reg  [`PRF_IDX-1:0] next_pdest_idx_out, next_prega_idx_out, next_pregb_idx_out;
  reg  [4:0] next_ALUop_out;
  reg  next_rd_mem_out, next_wr_mem_out;
  reg  [31:0] next_rs_IR_out;
  reg  [63:0] next_npc_out;
  reg  [`ROB_IDX-1:0] next_rob_idx_out;
  reg  prega_rdy, pregb_rdy;
  reg  next_prega_rdy, next_pregb_rdy;

  wire to_mult = ALUop_out == `ALU_MULQ;


  always@*
  begin
    next_entry_free = entry_free | entry_sel;
    next_pdest_idx_out = pdest_idx_out;
    next_prega_idx_out = prega_idx_out; 
    next_pregb_idx_out = pregb_idx_out; 
    next_ALUop_out = ALUop_out;
    next_rd_mem_out = rd_mem_out;
    next_wr_mem_out = wr_mem_out;
    next_rs_IR_out = rs_IR_out;
    next_npc_out = npc_out;
    next_rob_idx_out = rob_idx_out;

    if(entry_en) begin  //Newly allocated entry
      next_entry_free = 1'b0;
      next_pdest_idx_out = pdest_idx;
      next_prega_idx_out = prega_idx; 
      next_pregb_idx_out = pregb_idx; 
      next_ALUop_out = ALUop;
      next_rd_mem_out = rd_mem;
      next_wr_mem_out = wr_mem;
      next_rs_IR_out = rs_IR;
      next_npc_out = npc;
      next_rob_idx_out = rob_idx;
    end
  
  `ifdef SUPERSCALAR
    next_prega_rdy = entry_free ? 0 :
                        prega_rdy ? prega_rdy :
                         ((entry_en & prega_valid) | 
                          (cdb_valid[0] & (cdb_tag[`PRF_IDX-1:0]==(entry_en ? next_prega_idx_out : prega_idx_out))) | 
                          (cdb_valid[1] & (cdb_tag[`SCALAR*`PRF_IDX-1:`PRF_IDX]==(entry_en ? next_prega_idx_out : prega_idx_out))));
    next_pregb_rdy = entry_free ? 0 :
                        pregb_rdy ? pregb_rdy :
                         ((entry_en & pregb_valid) | 
                          (cdb_valid[0] & (cdb_tag[`PRF_IDX-1:0]==(entry_en ? next_pregb_idx_out : pregb_idx_out))) | 
                          (cdb_valid[1] & (cdb_tag[`SCALAR*`PRF_IDX-1:`PRF_IDX]==(entry_en ? next_pregb_idx_out : pregb_idx_out))));
  `else
    next_prega_rdy = entry_free ? 0 :
                        prega_rdy ? prega_rdy :
                         ((entry_en & prega_valid) | 
                          (cdb_valid[0] & (cdb_tag[`PRF_IDX-1:0]==(entry_en ? next_prega_idx_out : prega_idx_out)));
    next_pregb_rdy = entry_free ? 0 :
                        pregb_rdy ? pregb_rdy :
                         ((entry_en & pregb_valid) | 
                          (cdb_valid[0] & (cdb_tag[`PRF_IDX-1:0]==(entry_en ? next_pregb_idx_out : pregb_idx_out)));
  `endif

	mem_rdy = !entry_free & (prega_rdy | next_prega_rdy) & (pregb_rdy | next_pregb_rdy ) & (rd_mem_out | wr_mem_out);
	mult_rdy = !entry_free & (prega_rdy | next_prega_rdy) & (pregb_rdy | next_pregb_rdy ) & to_mult;
	ALU_rdy = !entry_free & (prega_rdy | next_prega_rdy) & (pregb_rdy | next_pregb_rdy ) & !mem_rdy & !mult_rdy; 
  end
   
  always @(posedge clk)
  begin
    if (reset) begin

      entry_free <= `SD 1'b1;
      pdest_idx_out <= `SD `ZERO_PRF; // FIXME
      prega_idx_out <= `SD `ZERO_PRF; // FIXME
      pregb_idx_out <= `SD `ZERO_PRF; // FIXME
      ALUop_out <= `SD 5'h1f;
      rd_mem_out <= `SD 1'b0;
      wr_mem_out <= `SD 1'b0;
      rs_IR_out <= `SD `NOOP_INST;
      npc_out <= `SD 64'h0;
      rob_idx_out <= `SD {`ROB_IDX{1'b0}};
      prega_rdy <= `SD 1'b0;
      pregb_rdy <= `SD 1'b0;

    end else begin

      entry_free <= `SD next_entry_free;
      pdest_idx_out <= `SD next_pdest_idx_out;
      prega_idx_out <= `SD next_prega_idx_out;
      pregb_idx_out <= `SD next_pregb_idx_out; 
      ALUop_out <= `SD next_ALUop_out;
      rd_mem_out <= `SD next_rd_mem_out;
      wr_mem_out <= `SD next_wr_mem_out;
      rs_IR_out <= `SD next_rs_IR_out;
      npc_out <= `SD next_npc_out;
      rob_idx_out <= `SD next_rob_idx_out;
      prega_rdy <= `SD next_prega_rdy;
      pregb_rdy <= `SD next_pregb_rdy;

    end

  end


endmodule


