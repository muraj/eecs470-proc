
// Multiplier
module MULT(clk, reset, 
						// Inputs
						prega_value, pregb_value, pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in,
						next_gnt_in, stall, 
						// Outputs
						result_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
						done, done_reg, gnt_reg, MULT_free
						);
	//synopsys template
	parameter STAGES=8;

  input 								clk, reset, stall, next_gnt_in;
  input [63:0] 				 	prega_value, pregb_value;	
	
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0] 					IR_in;
	input [63:0] 					npc_in;
	input [`ROB_IDX-1:0] 	rob_idx_in;
	input 								EX_en_in;

	output [63:0]					result_reg;
	output [`PRF_IDX-1:0]	pdest_idx_reg;
	output [31:0] 				IR_reg;
	output [63:0] 				npc_reg;
	output [`ROB_IDX-1:0] rob_idx_reg;
	output 								done_reg, gnt_reg;
	output								done, MULT_free;

	wire [63:0]												mcand_out, mplier_out;
  wire [((STAGES-1)*64)-1:0] 				internal_products, internal_mcands, internal_mpliers;
	wire [((STAGES-1)*`PRF_IDX)-1:0]	internal_pdest_idx;
	wire [((STAGES-1)*32)-1:0] 				internal_IR;
  wire [((STAGES-1)*64)-1:0] 				internal_npc;
	wire [((STAGES-1)*`ROB_IDX)-1:0]	internal_rob_idx;
	wire [STAGES-2:0] 								internal_dones;
	wire [STAGES-2:0] 								internal_gnts;
	wire [STAGES-1:0] 								internal_stalls;


	// decoder for MULT
	reg	[63:0]	mcand_in, mplier_in;
	always @* begin
		mcand_in = prega_value;
		case(IR_in[31:29])
			3'b010	: mplier_in = IR_in[12] ? {56'b0, IR_in[20:13]} : pregb_value;
			default	: mplier_in = 64'hbaadbeefdeadbeef;
		endcase
	end

	assign done 			= internal_dones[STAGES-2]; 
	assign MULT_free 	= !internal_stalls[0]; 

  mult_stage mstage [STAGES-1:0] 
    (.clk(clk),
     .reset(reset),
		 .next_gnt_in({next_gnt_in, {(STAGES-1){1'b0}}}),
		 .stall_in({stall,internal_stalls[STAGES-1:1]}),
     .product_in({internal_products,64'h0}),
     .mplier_in({internal_mpliers,mplier_in}),
     .mcand_in({internal_mcands,mcand_in}),
     .start({internal_dones,EX_en_in}),
     .product_out({result_reg,internal_products}),
     .mplier_out({mplier_out,internal_mpliers}),
     .mcand_out({mcand_out,internal_mcands}),
     .done_reg({done_reg,internal_dones}),
		 .gnt_reg({gnt_reg,internal_gnts}),
		 .stall_out(internal_stalls),
		 .pdest_idx_in({internal_pdest_idx, pdest_idx_in}),
		 .IR_in({internal_IR, IR_in}),
		 .npc_in({internal_npc, npc_in}),
		 .rob_idx_in({internal_rob_idx, rob_idx_in}),
		 .pdest_idx_out({pdest_idx_reg, internal_pdest_idx}),
		 .IR_out({IR_reg, internal_IR}),
		 .npc_out({npc_reg, internal_npc}),
		 .rob_idx_out({rob_idx_reg, internal_rob_idx})
    );

endmodule // MULT

module mult_stage(clk, reset, next_gnt_in, stall_in, 
                  product_in,  mplier_in,  mcand_in,  start,
                  product_out, mplier_out, mcand_out, done_reg, gnt_reg, stall_out, 
									pdest_idx_in, IR_in, npc_in, rob_idx_in,
									pdest_idx_out, IR_out, npc_out, rob_idx_out
									);

  input 								clk, reset, next_gnt_in, stall_in, start;
  input [63:0] 					product_in, mplier_in, mcand_in;

	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0] 					IR_in;
	input [63:0] 					npc_in;
	input [`ROB_IDX-1:0] 	rob_idx_in;

  output reg						done_reg, gnt_reg;
	output								stall_out;
  output [63:0] 				product_out, mplier_out, mcand_out;
	
	output reg [`PRF_IDX-1:0]	pdest_idx_out;
	output reg [31:0] 				IR_out;
	output reg [63:0] 				npc_out;
	output reg [`ROB_IDX-1:0]	rob_idx_out;

  reg  [63:0] prod_in_reg, partial_prod_reg;
  wire [63:0] partial_product, next_mplier, next_mcand;

  reg [63:0] mplier_out, mcand_out;

	wire stall;
	assign stall = done_reg & stall_in;
	assign stall_out = stall;

  assign product_out = prod_in_reg + partial_prod_reg;
  assign partial_product = mplier_in[7:0] * mcand_in;
  assign next_mplier = {8'b0,mplier_in[63:8]};
  assign next_mcand = {mcand_in[55:0],8'b0};

  always @(posedge clk)
  begin
		if(reset) begin
	    prod_in_reg      	<= `SD 0;
  	  partial_prod_reg 	<= `SD 0;
    	mplier_out       	<= `SD 0;
    	mcand_out        	<= `SD 0;
			pdest_idx_out			<= `SD `ZERO_PRF;
			IR_out						<= `SD `NOOP_INST;
			npc_out						<= `SD 0;
			rob_idx_out				<= `SD 0;
			done_reg					<= `SD 0;
		end
		else if(!stall) begin
   		prod_in_reg      	<= `SD product_in;
    	partial_prod_reg 	<= `SD partial_product;
    	mplier_out       	<= `SD next_mplier;
    	mcand_out        	<= `SD next_mcand;
			pdest_idx_out			<= `SD pdest_idx_in;
			IR_out						<= `SD IR_in;
			npc_out						<= `SD npc_in;
			rob_idx_out				<= `SD rob_idx_in;
			done_reg					<= `SD start;
		end
  end

  always @(posedge clk)
  begin
    if(reset)	gnt_reg <= `SD 1'b0;
    else gnt_reg <= `SD next_gnt_in;
  end

endmodule // mult_stage
