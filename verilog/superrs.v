module SUPER_RS(clk, reset,
                //INPUTS
                inst_valid, prega_idx, pregb_idx, pdest_idx, prega_valid, pregb_valid, //RAT
                ALUop, rd_mem, wr_mem, rs_IR,  npc, cond_branch, uncond_branch,        //Issue Stage
                multfu_free, exfu_free, memfu_free, cdb_valid, cdb_tag, entry_flush,   //Pipeline communication
                rob_idx,                                                               //ROB

                //OUTPUT
                rs_stall,  rs_rdy,                                                     //Hazard detect
                pdest_idx_out, prega_idx_out, pregb_idx_out, ALUop_out, rd_mem_out,    //FU
                wr_mem_out, rs_IR_out, npc_out, rob_idx_out, en_out,                   //FU
                rs_idx_out                                                             //ROB
          );

  input wire  clk, reset;
  input wire  [`SCALAR-1:0] inst_valid;   // Instruction ready
  input wire  [`SCALAR*`PRF_IDX-1:0] prega_idx;
  input wire  [`SCALAR*`PRF_IDX-1:0] pregb_idx;
  input wire  [`SCALAR*`PRF_IDX-1:0] pdest_idx;
  input wire  [`SCALAR-1:0] prega_valid, pregb_valid;
  input wire  [5*`SCALAR-1:0] ALUop;
  input wire  [`SCALAR-1:0] rd_mem, wr_mem;
  input wire  [32*`SCALAR-1:0] rs_IR; 
  input wire  [`SCALAR-1:0] cond_branch, uncond_branch;
  input wire  [64*`SCALAR-1:0] npc;
  input wire  [`SCALAR-1:0] multfu_free, exfu_free, memfu_free, cdb_valid;
  input wire  [`SCALAR*`PRF_IDX-1:0] cdb_tag;
  input wire  [`SCALAR*`ROB_IDX-1:0] rob_idx;
  input wire  [`SCALAR*`RS_SZ-1:0] entry_flush;

  output wire [`SCALAR-1:0] rs_stall, rs_rdy;
  output wire [`SCALAR*`PRF_IDX-1:0] pdest_idx_out;
  output wire [`SCALAR*`PRF_IDX-1:0] prega_idx_out;
  output wire [`SCALAR*`PRF_IDX-1:0] pregb_idx_out;
  output wire [5*`SCALAR-1:0] ALUop_out;
  output wire [`SCALAR-1:0] rd_mem_out, wr_mem_out;
  output wire [32*`SCALAR-1:0] rs_IR_out;
  output wire [64*`SCALAR-1:0] npc_out;
  output wire [`SCALAR*`ROB_IDX-1:0] rob_idx_out;
  output wire [`SCALAR*`RS_IDX-1:0] rs_idx_out;
  output wire [`SCALAR-1:0] en_out;

  wire [`SCALAR-1:0] ALU_rdy, mem_rdy, mult_rdy;

  wire [`SCALAR-1:0] rs_free;
  wire rs0_en = rs_free[0] & inst_valid[0];
  wire rs0_ex_free = exfu_free[0] & ALU_rdy[0];
  wire rs0_mem_free = memfu_free[0] & mem_rdy[0];
  wire rs0_mult_free = multfu_free[0] & mult_rdy[0];

  assign en_out[0] = rs0_ex_free | rs0_mem_free | rs0_mult_free;
`ifdef SUPERSCALAR
  wire rs1_en, rs1_sel;
  wire rs1_ex_free = (rs0_ex_free ? exfu_free[1] : exfu_free[0]) & ALU_rdy[1];
  wire rs1_mem_free = (rs0_mem_free ? memfu_free[1] : memfu_free[0]) & mem_rdy[1];
  wire rs1_mult_free = (rs0_mult_free ? multfu_free[1] : multfu_free[0]) & mult_rdy[1];
  assign rs1_en = rs_free[1] & (inst_valid[1] | (inst_valid[0] & ~rs_free[0]));
  assign rs1_sel = ~rs_free[0];
  assign en_out[1] = rs1_ex_free | rs1_mem_free | rs1_mult_free;
 `define SEL(WIDTH, WHICH) WIDTH*(WHICH)-1:WIDTH*(WHICH - 1)
 wire [`PRF_IDX-1:0] rs1_prega_idx = rs1_sel ? prega_idx[`SEL(`PRF_IDX, 2)] : prega_idx[`SEL(`PRF_IDX, 1)];
 wire [`PRF_IDX-1:0] rs1_pregb_idx = rs1_sel ? prega_idx[`SEL(`PRF_IDX, 2)] : prega_idx[`SEL(`PRF_IDX, 1)];
 wire [`PRF_IDX-1:0] rs1_pdest_idx = rs1_sel ? pdest_idx[`SEL(`PRF_IDX, 2)] : pdest_idx[`SEL(`PRF_IDX, 1)];
 wire [5-1:0] rs1_ALUop = rs1_sel ? ALUop[`SEL(5, 2)] : ALUop[`SEL(5, 1)];
 wire [32-1:0] rs1_rs_IR = rs1_sel ? rs_IR[`SEL(32, 2)] : rs_IR[`SEL(32, 1)];
 wire [64-1:0] rs1_npc = rs1_sel ? npc[`SEL(64, 2)] : npc[`SEL(64, 1)];
 wire [`ROB_IDX-1:0] rs1_rob_idx = rs1_sel ? rob_idx[`SEL(`ROB_IDX, 2)] : rob_idx[`SEL(`ROB_IDX, 1)];
`endif
  assign rs_stall = ~rs_free;

  RS rs0(clk, reset,
                    //INPUTS
                    rs0_en, prega_idx[`PRF_IDX-1:0], pregb_idx[`PRF_IDX-1:0], pdest_idx[`PRF_IDX-1:0], prega_valid[0], pregb_valid[0],
                    ALUop[4:0], rd_mem[0], wr_mem[0], rs_IR[31:0], npc[63:0], cond_branch[0], uncond_branch[0],
                    rs0_mult_free, rs0_mem_free, rs0_mult_free, cdb_valid, cdb_tag, entry_flush[`RS_SZ-1:0], rob_idx[`ROB_IDX-1:0],

                    //OUTPUTS
                    rs_free[0], ALU_rdy[0], mem_rdy[0], mult_rdy[0],
                    pdest_idx_out[`PRF_IDX-1:0], prega_idx_out[`PRF_IDX-1:0], pregb_idx_out[`PRF_IDX-1:0], ALUop_out[4:0], rd_mem_out[0],
                    wr_mem_out[0], rs_IR_out[31:0], npc_out[63:0], rob_idx_out[`ROB_IDX-1:0],
                    rs_idx_out[`RS_IDX-1:0]);

`ifdef SUPERSCALAR
  RS rs1(clk, reset,
                    //INPUTS
                    rs1_en, rs1_prega_idx, rs1_pregb_idx, rs1_pdest_idx, prega_valid[rs1_sel], pregb_valid[rs1_sel],
                    rs1_ALUop, rd_mem[rs1_sel], wr_mem[rs1_sel], rs1_rs_IR, rs1_npc, cond_branch[rs1_sel], uncond_branch[rs1_sel],
                    rs1_ex_free, rs1_mem_free, rs1_mult_free, cdb_valid, cdb_tag, entry_flush[`SEL(`RS_SZ, 1)], rs1_rob_idx,

                    //OUTPUTS
                    rs_free[1], ALU_rdy[1], mem_rdy[1], mult_rdy[1],
                    pdest_idx_out[`SEL(`PRF_IDX,2)], prega_idx_out[`SEL(`PRF_IDX,2)], pregb_idx_out[`SEL(`PRF_IDX,2)], ALUop_out[`SEL(5,2)], rd_mem_out[1],
                    wr_mem_out[1], rs_IR_out[`SEL(32,2)], npc_out[`SEL(64,2)], rob_idx_out[`SEL(`ROB_IDX,2)],
                    rs_idx_out[`SEL(`RS_IDX,2)]);
`endif

endmodule
