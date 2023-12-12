module ReservationStation # (parameter ROB_ROW_COUNT = 64, parameter RS_ROW_COUNT = 64, 
						parameter ROB_ROW_SIZE = 46, parameter RS_ROW_SIZE = 48)
::import RSTableROBStruct::*; // should output inputs to the functional unit and ready table
(
	input clk,
	input[63:0] ready, // 64-bit ready table
	input[1:0] available_fu_list,
	input[6:0] opcode, // from IDModule
	input[5:0] p_rs1, // physical register from Rename
	input[5:0] p_rs2,
	input[5:0] p_rd,
	input[5:0] p_old_rd,
	input[31:0] imm, // from IDModule
	output[63:0] ready, // 64-bit ready table
	output[1:0] new_fu_list //  0 if fu unavailable, 1 if available
);
	

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
		
	/*
	always_comb begin // most of issue including forwarding
		for(integer i = 0; i < SIZE_OF_RT;i++) begin
			if(table[i].valid == 1) begin
				if(!table[i].rs1ready && ready[i]) begin // check for forwarding
					forward data
					set table[i].rs1ready to 1
				if(!table[i].rs2ready && ready[i]) begin
					forward data
					set table[i].rs2ready to 1
				if(table[i].rs1ready && table[i].rs2ready && table[i].fu && fuflag not set)begin
					output = table[i] entries
					flag fu is set
					mark flag that row is not valid
				end
			end
		end
	end
	
	always@(posedge clk) begin // mostly dispatch
		logic to insert entries
		update ready
		clear rs table entries in fu // issue
	end
	
	*/
	
		
	end
	
endmodule