package RSTableROBStruct;
	localparam RS_ROW_COUNT = 64;
	localparam ROB_ROW_COUNT = 64;
	
	
	struct{
		reg used[RS_ROW_COUNT-1:0];
		reg[6:0] op[RS_ROW_COUNT-1:0];
		reg[6:0] funct7[RS_ROW_COUNT-1:0];
		reg[2:0] funct3[RS_ROW_COUNT-1:0];
		reg[5:0] destreg[RS_ROW_COUNT-1:0];
		reg[5:0] srcreg1[RS_ROW_COUNT-1:0];
		reg ready1[RS_ROW_COUNT-1:0];
		reg[31:0] srcreg1_data[RS_ROW_COUNT-1:0];
		reg[5:0] srcreg2[RS_ROW_COUNT-1:0];
		reg ready2[RS_ROW_COUNT-1:0];
		reg[31:0] srcreg2_data[RS_ROW_COUNT-1:0];
		reg[31:0] imm[RS_ROW_COUNT-1:0];
		reg[1:0] fu[RS_ROW_COUNT-1:0];
		reg[5:0] rob[RS_ROW_COUNT-1:0];
	} rstable;
	
	/*struct{
		reg valid[ROB_ROW_COUNT-1:0];
		reg[5:0] rd[ROB_ROW_COUNT-1:0];
		reg[5:0] old_destreg[ROB_ROW_COUNT-1:0];
		reg[31:0] data[ROB_ROW_COUNT-1:0];
		reg completed[ROB_ROW_COUNT-1:0];
		reg is_sw[ROB_ROW_COUNT-1:0];
	} robtable;*/
	
endpackage