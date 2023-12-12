import instructionList::*;
import RSTableROBStruct::*;

module ReservationStation # (parameter ROB_ROW_COUNT = 64, parameter RS_ROW_COUNT = 64, 
						parameter ROB_ROW_SIZE = 46, parameter RS_ROW_SIZE = 48)
(
	input clk,
	input[63:0] ready, // 64-bit ready table
	
	// instruction 1
	input[31:0] one_pc;
	input[6:0] one_opcode, // from IDModule
	input[5:0] one_p_rs1, // physical register from Rename
	input[5:0] one_p_rs2,
	input[5:0] one_p_rd,
	input[5:0] one_p_old_rd,
	input[31:0] one_imm, // from IDModule
	
	// instruction 2
	input[31:0] two_pc;
	input[6:0] two_opcode, // from IDModule
	input[5:0] two_p_rs1, // physical register from Rename
	input[5:0] two_p_rs2,
	input[5:0] two_p_rd,
	input[5:0] two_p_old_rd,
	input[31:0] two_imm, // from IDModule
	
	output[63:0] ready, // 64-bit ready table
);

	// list of flags
	reg robFoundFlag = 1'b0; 
	reg robFullFlag = 1'b0;
	reg rsFullFlag = 1'b0;
	reg instrOneWrittenFlag = 1'b0;  
	reg instrTwoWrittenFlag = 1'b0; 
	
	
	reg finalOpCode[6:0] = 7'b0; // we should account for NOP case
	reg [2:0] fu_used = 3'b0; // initially, all three are available
	reg fu_available = 1'b0; // checks if the fu we desire is available
	
	reg[7:0] rob_num = 0;
	localparam mem_au = 2'b2; // only ALU 2 is memory ALU
	reg arith_au = 1'b0; // used for round robin
	
	// https://stackoverflow.com/questions/22697639/what-should-default1-do-in-system-verilog
	// https://electronics.stackexchange.com/questions/179142/systemverilog-structure-initialization-with-default-
	parameter RSTableStruct rstable = '{default:'0}; // make all entries to 0
	parameter ROBStruct robtable s= '{default:'0}; 
	
	
	// TO DO: After one clock cycle,
	// 1) write in the reservation station table -- DONE
	// 2) reserve a spot in reorder buffer -- DONE
	// 3) TO DO: update ready table
	// 4) TO DO: clear rstable entries in fu (?)
	always@(posedge clk) begin
		// 1,2) logic to insert entries
		for(integer i = 0; i < RS_ROW_COUNT; i++)
		begin
			if(!instrOneWrittenFlag || !instrTwoWrittenFlag) 
			begin
				if(rstable[i].used == 1'b0) 
				begin
					// reserve a spot in ROB and get line number
					for(integer j = 0; j < ROB_ROW_COUNT; j++)
					begin
						if(robtable[j] == 46'b0 && !robFoundFlag)
						begin
							rob_num = j;
							robFoundFlag = 1'b1;
						end
					end
					
					// if ROB is full (so !robFound), push NOP (Opcode = 7'b0)
					// else, push proper opcode
					if (!robFound) 
					begin
						finalOpCode = 7'b0;
						robFullFlag = 1'b0;
					end
					else 
					begin
						finalOpCode = one_opcode;
						robFullFlag = 1'b1;
					end
					robFoundFlag = 1'b0;
					
					// if opcode is LW or SW, check FU 2 (memory ALU)
					// otherwise, check arithmetic ALUs FU 0 and 1 (round-robin)
					if(finalOpCode == lw || finalOpCode == sw) // lw, sw from instructionList.sv
					begin
						if(!fu_used[mem_au]) // if memory ALU is available
						begin
							fu_available = 1'b1;
							fu_used[mem_au] = 1'b1;
						end
						else
						begin
							fu_available = 1'b0;
						end
					end
					else
					begin
						if(fu_used[0] && fu_used[1]) 
						begin
							fu_available = 1'b0;
						end
						else if(!fu_used[0])
						begin
							fu_available = 1'b1;
							fu_used[mem_au] = 1'b0;
						end
						else if(!fu_used[1])
						begin
							fu_available = 1'b1;
							fu_used[mem_au] = 1'b1;
						end
					end
				
					// insert a row into reservation station and ROB
					if(!instrOneWrittenFlag)
					begin
						rstable[i].op = finalOpCode;
						rstable[i].destreg = one_p_rd;
						rstable[i].srcreg1 = one_p_rs1;
						rstable[i].ready1 = ready[one_p_rs1];
						rstable[i].srcreg2 = one_p_rs2;
						rstable[i].ready2 = ready[one_p_rs2];
						rstable[i].imm = one_imm;
						rstable[i].fu = fu_available;
						rstable[i].rob = rob_num;
						instrOneWrittenFlag = 1'b1;
						
						robtable[rob_num].used = 1;
						robtable[rob_num].destreg = one_p_rd;
						robtable[rob_num].old_destreg = one_old_p_rd;
						robtable[rob_num].pc = one_pc;
						robtable[rob_num].completed = 1'b0;
					end
					else if(!instrTwoWrittenFlag)
					begin
						rstable[i].op = finalOpCode;
						rstable[i].destreg = two_p_rd;
						rstable[i].srcreg1 = two_p_rs1;
						rstable[i].ready1 = ready[two_p_rs1];
						rstable[i].srcreg2 = two_p_rs2;
						rstable[i].ready2 = ready[two_p_rs2];
						rstable[i].imm = two_imm;
						rstable[i].fu = fu_available;
						rstable[i].rob = rob_num;
						instrTwoWrittenFlag = 1'b1;
						
						robtable[rob_num].used = 1;
						robtable[rob_num].destreg = two_p_rd;
						robtable[rob_num].old_destreg = two_old_p_rd;
						robtable[rob_num].pc = two_pc;
						robtable[rob_num].completed = 1'b0;
					end
				end
			end
			
			// 3) update ready table
			
			
			// 4) clear rstable entries in fu (issue)
		end
		
		
	// pseudocode
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