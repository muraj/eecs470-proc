
// Memory-Controller
module MEM_CONT ( clk, reset,
									//Inputs from the Input Logic 
									LSQ_idx, prega_in, pregb_in, rd_in, wr_in, 
									pdest_idx_in, IR_in, npc_in, rob_idx_in, EX_en_in, next_gnt,
								 //Inputs from LSQ
								 	LSQ_rob_idx, LSQ_pdest_idx, LSQ_mem_value, 
									LSQ_done, LSQ_rd_mem, LSQ_wr_mem,
									LSQ_IR, LSQ_npc,
								 //Outputs to LSQ
								 	MEM_LSQ_idx, MEM_ADDR, MEM_reg_value, MEM_valid, 
								 //Outputs to EX/CO registers
								 	result_reg, result_valid_reg, pdest_idx_reg, IR_reg, npc_reg, rob_idx_reg,
									done, done_reg, gnt_reg
									);

	input									clk, reset;
	// Inputs from the input logic in EX stage
	input [`LSQ_IDX-1:0]	LSQ_idx;	
	input [63:0]					prega_in, pregb_in;
	input 								rd_in, wr_in, EX_en_in, next_gnt;
	input [`PRF_IDX-1:0]	pdest_idx_in;
	input [31:0]					IR_in;
	input [63:0]					npc_in;
	input [`ROB_IDX-1:0]	rob_idx_in;
	// Inputs from LSQ
	input [`ROB_IDX-1:0]	LSQ_rob_idx;
	input [`PRF_IDX-1:0]	LSQ_pdest_idx;
	input [63:0]					LSQ_mem_value;
	input 								LSQ_done, LSQ_rd_mem, LSQ_wr_mem;
	input [31:0]					LSQ_IR;
	input [63:0]					LSQ_npc;
	// Outputs to LSQ
	output [`LSQ_IDX-1:0]	MEM_LSQ_idx;
	output [63:0]					MEM_ADDR, MEM_reg_value;
	output 								MEM_valid;
	// Outputs to EX/CO registers
	output reg [63:0]					result_reg;
	output reg [`PRF_IDX-1:0]	pdest_idx_reg;
	output reg [31:0]					IR_reg;
	output reg [63:0]					npc_reg;
	output reg [`ROB_IDX-1:0]	rob_idx_reg;
	output reg								result_valid_reg, done_reg, gnt_reg;
	output										done;

	// to LSQ
	assign MEM_valid = EX_en_in;
	wire [63:0]	mem_disp 	= { {48{IR_in[15]}}, IR_in[15:0]};
	assign	MEM_LSQ_idx		= LSQ_idx;
	assign	MEM_ADDR 			= mem_disp + pregb_in;
	assign	MEM_reg_value = prega_in;

`ifdef MEM_CONT_PIPELINE
	// from LSQ
	reg [`ROB_IDX-1:0]	LSQ_rob_idx_reg;
	reg [`PRF_IDX-1:0]	LSQ_pdest_idx_reg;
	reg [63:0]					LSQ_mem_value_reg;
	reg 								LSQ_done_reg, LSQ_rd_mem_reg, LSQ_wr_mem_reg;
	reg [31:0]					LSQ_IR_reg;
	reg [63:0]					LSQ_npc_reg;

    //synopsys sync_set_reset "reset"
	always @(posedge clk) begin
		if(reset) begin
			LSQ_rob_idx_reg	<= `SD 0;
			LSQ_pdest_idx_reg	<= `SD `ZERO_PRF;
			LSQ_mem_value_reg	<= `SD 0;
			LSQ_done_reg		<= `SD 0;
			LSQ_rd_mem_reg		<= `SD 0;
			LSQ_wr_mem_reg		<= `SD 0;
			LSQ_IR_reg			<= `SD `NOOP_INST;
			LSQ_npc_reg			<= `SD 0;
		end
		else begin
			LSQ_rob_idx_reg	<= `SD LSQ_rob_idx;
			LSQ_pdest_idx_reg	<= `SD LSQ_pdest_idx;
			LSQ_mem_value_reg	<= `SD LSQ_mem_value;
			LSQ_done_reg		<= `SD LSQ_done;
			LSQ_rd_mem_reg		<= `SD LSQ_rd_mem;
			LSQ_wr_mem_reg		<= `SD LSQ_wr_mem;
			LSQ_IR_reg			<= `SD LSQ_IR;
			LSQ_npc_reg			<= `SD LSQ_npc;
		end
	end


	assign done = LSQ_done_reg;

    //synopsys sync_set_reset "reset"
	always @(posedge clk) begin
		if(reset)	gnt_reg	<= `SD 0;
		else			gnt_reg	<= `SD next_gnt; 
	end

    //synopsys sync_set_reset "reset"
	always @(posedge clk) begin
		if(reset) begin
			result_reg				<= `SD 0;
			result_valid_reg	<= `SD 0;
			pdest_idx_reg			<= `SD `ZERO_PRF;
			IR_reg						<= `SD `NOOP_INST;
			npc_reg						<= `SD 0;
			rob_idx_reg				<= `SD 0;
			done_reg					<= `SD 0;
		end
		else begin
			result_reg				<= `SD LSQ_mem_value_reg;
			result_valid_reg	<= `SD LSQ_done_reg & (LSQ_rd_mem_reg | LSQ_wr_mem_reg);
			pdest_idx_reg			<= `SD (!LSQ_done_reg) ? `ZERO_PRF : LSQ_pdest_idx_reg;
			IR_reg						<= `SD (!LSQ_done_reg) ? `NOOP_INST : LSQ_IR_reg;
			npc_reg						<= `SD LSQ_npc_reg; 
			rob_idx_reg				<= `SD LSQ_rob_idx_reg;
			done_reg					<= `SD LSQ_done_reg;
		end
	end
`else
	assign done = LSQ_done;

    //synopsys sync_set_reset "reset"
	always @(posedge clk) begin
		if(reset)	gnt_reg	<= `SD 0;
		else			gnt_reg	<= `SD next_gnt; 
	end

    //synopsys sync_set_reset "reset"
	always @(posedge clk) begin
		if(reset) begin
			result_reg				<= `SD 0;
			result_valid_reg	<= `SD 0;
			pdest_idx_reg			<= `SD `ZERO_PRF;
			IR_reg						<= `SD `NOOP_INST;
			npc_reg						<= `SD 0;
			rob_idx_reg				<= `SD 0;
			done_reg					<= `SD 0;
		end
		else begin
			result_reg				<= `SD LSQ_mem_value;
			result_valid_reg	<= `SD LSQ_done & (LSQ_rd_mem | LSQ_wr_mem);
			pdest_idx_reg			<= `SD (!LSQ_done) ? `ZERO_PRF : LSQ_pdest_idx;
			IR_reg						<= `SD (!LSQ_done) ? `NOOP_INST : LSQ_IR;
			npc_reg						<= `SD LSQ_npc; 
			rob_idx_reg				<= `SD LSQ_rob_idx;
			done_reg					<= `SD LSQ_done;
		end
	end
`endif

endmodule // MEM_CONT

