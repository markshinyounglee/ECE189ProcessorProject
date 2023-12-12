package RSTableROBStruct;
	localparam[6:0] RS_ROW_COUNT = 64;
	localparam[6:0] ROB_ROW_COUNT = 64;
	localparam[6:0] RS_ROW_SIZE = 48; //  row size = 48 = 1+7+6+6+1+6+1+12+2+6 (ROB has 2^8 rows)
	localparam[6:0] ROB_ROW_SIZE = 46; // row size = 46 = 1+6+6+32+1
	
	
	typedef struct RSTable_Structure
	{
		reg used[RS_ROW_COUNT-1:0];
		reg[6:0] op[RS_ROW_COUNT-1:0];
		reg[5:0] destreg[RS_ROW_COUNT-1:0];
		reg[5:0] srcreg1[RS_ROW_COUNT-1:0];
		reg ready1[RS_ROW_COUNT-1:0];
		reg[5:0] srcreg2[RS_ROW_COUNT-1:0];
		reg ready2[RS_ROW_COUNT-1:0];
		reg[11:0] imm[RS_ROW_COUNT-1:0];
		reg[1:0] fu[RS_ROW_COUNT-1:0];
		reg[5:0] rob[RS_ROW_COUNT-1:0];
	} RSTableStruct;
	
	typedef struct ROB_Structure {
		reg used[ROB_ROW_COUNT-1:0];
		reg[5:0] destreg[ROB_ROW_COUNT-1:0];
		reg[5:0] old_destreg[ROB_ROW_COUNT-1:0];
		reg[31:0] pc[ROB_ROW_COUNT-1:0];
		reg completed[ROB_ROW_COUNT-1:0];
	} ROBStruct;
endpackage