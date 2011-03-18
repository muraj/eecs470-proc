module if_id(clk, reset, if_id_enable,din1_en, din2_en, dout1_req, dout2_req, if_NPC_out1, if_IR_out1, if_valid_inst_out1, if_id_NPC1, if_id_IR1, if_id_valid_inst1, if_NPC_out2, if_IR_out2, if_valid_inst_out2, if_id_NPC2, if_id_IR2, if_id_valid_inst2, full, full_almost);


	input clk, reset, if_id_enable;
  input din1_en, din2_en, dout1_req, dout2_req;
	//input 1	
	input	[63:0]	if_NPC_out1;
	input [31:0]	if_IR_out1;
  input				  if_valid_inst_out1;
	//input 2
	input	[63:0]	if_NPC_out2;
	input [31:0]	if_IR_out2;
  input				  if_valid_inst_out2;
	//output 1
 	output wire [63:0] if_id_NPC1;
  output wire [31:0] if_id_IR1;
  output wire        if_id_valid_inst1;
	//output 2	
	output wire [63:0] if_id_NPC2;
  output wire [31:0] if_id_IR2;
  output wire        if_id_valid_inst2;
	output wire				 full_almost,full;

	reg	din1_enTemp, din2_enTemp, dout1_reqTemp, dout2_reqTemp; //enable signals



 //NPC circular buffer
	cb #(.CB_IDX(`IF_ID_IDX),.CB_WIDTH(64),.CB_LENGTH(`IF_ID_SZ)) cb0 (.clk(clk), .reset(reset), .move_tail(), .tail_new(), .din1_en(din1_enTemp), .din2_en(din2_enTemp),.dout1_req(dout1_reqTemp), .dout2_req(dout2_reqTemp), .din1(if_NPC_out1), .din2(if_NPC_out2), .dout1(if_id_NPC1), .dout2(if_id_NPC2), .full(full), .full_almost(full));
 //IR circular buffer
	cb #(.CB_IDX(`IF_ID_IDX),.CB_WIDTH(32),.CB_LENGTH(`IF_ID_SZ)) cb1 (.clk(clk), .reset(reset), .move_tail(), .tail_new(), .din1_en(din1_enTemp), .din2_en(din2_enTemp),.dout1_req(dout1_reqTemp), .dout2_req(dout2_reqTemp), .din1(if_IR_out1), .din2(if_IR_out2), .dout1(if_id_IR1), .dout2(if_id_IR2), .full(), .full_almost());
 //valid circular buffer
	cb #(.CB_IDX(`IF_ID_IDX),.CB_WIDTH(1),.CB_LENGTH(`IF_ID_SZ)) cb2 (.clk(clk), .reset(reset), .move_tail(), .tail_new(), .din1_en(din1_enTemp), .din2_en(din2_enTemp),.dout1_req(dout1_reqTemp), .dout2_req(dout2_reqTemp), .din1(if_valid_inst_out1), .din2(if_valid_inst_out2), .dout1(if_id_valid_inst1), .dout2(if_id_valid_inst2), .full(), .full_almost());

	always@*
		begin
			if(if_id_enable) 
				begin
					din1_enTemp=din1_en; 
					din2_enTemp=din2_en; 
					dout1_reqTemp=dout1_req; 
					dout2_reqTemp=dout2_req;
				end
			else
				begin
					din1_enTemp=0; 
					din2_enTemp=0; 
					dout1_reqTemp=0; 
					dout2_reqTemp=0;
				end
	end	
/*
assign if_id_enable = 1'b1; // always enabled
  always @(posedge clk)
  begin
    if(reset)
    begin
      if_id_NPC        <= `SD 0;
      if_id_IR         <= `SD `NOOP_INST;
      if_id_valid_inst <= `SD `FALSE;
    end // if (reset)
    else if (if_id_enable)
      begin
        if_id_NPC        <= `SD if_NPC_out;
        if_id_IR         <= `SD if_IR_out;
        if_id_valid_inst <= `SD if_valid_inst_out;
      end // if (if_id_enable)
  end // always
*/
endmodule
