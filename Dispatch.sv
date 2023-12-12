module Dispatch # (parameter ROB_ROW_COUNT = 64, parameter RS_ROW_COUNT = 64)
(
	input clk,
	input[47:0] reservationTable[RS_ROW_COUNT-1:0], // row size = 1 + 7 + 6 + 1 + 6 + 1 + 32 + 2 + 8 (say ROB is 2^8)
	input[45:0] reorderBuffer[ROB_ROW_COUNT-1:0], // 2^8 rows and row size = 1 + 6 + 6 + 32 + 1
	input[63:0] ready, // 1 if ready, 0 if not ready
	input[1:0] available_fu_list,
	input[6:0] opcode, // from IDModule
	input[5:0] p_rs1, // physical register from Rename
	input[5:0] p_rs2,
	input[5:0] p_rd,
	input[5:0] p_old_rd,
	input[31:0] imm, // from IDModule
	output[45:0] new_reorderBuffer[ROB_ROW_COUNT-1:0],
	output reg[47:0] new_reservationTable[RS_ROW_COUNT-1:0],
	output[1:0] new_fu_list //  0 if fu unavailable, 1 if available
);
	
	localparam[3:0] SIZE_OF_RT = 8;
	localparam[8:0] SIZE_OF_ROB = 256;
	localparam[7:0] rob_num = 0;
	localparam[2:0] fu_num = 0;
	localparam mem_au = 2'b2;
	reg arith_au = 1'b0;
	
	// TO DO: After one clock cycle,
	// 1) write in the reservation station table
	// 2) reserve a spot in reorder buffer
	always_comb begin
		for(integer i = 0; i < SIZE_OF_RT; i++)
		begin
			if(reservationTable[i] == 64'b0) 
			begin
				// reserve a spot in ROB and get line number
				for(integer j = 0; j < 256; j++)
				begin
					if(reorderBuffer[j] == 46'b0)
					begin
						rob_num = j;
						break;
					end
				end
				
				// look through the list of functional units and assign a unit according to availability (round robin)
				// fu1, fu2 are arithmetic; fu3 is memory ALU
				
				
				reservationTable[i] = {1'b1, opcode, p_rd, p_rs1, ready[p_rs1], p_rs2, ready[p_rs2], imm, rob_num, fu_num } 
				break;
			end
		end
		
		
		
	end
	
endmodule