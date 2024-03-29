import instructionList::*;
import RSTableROBStruct::*;
import operationList::*;

module ReservationStation #(parameter RS_ROW_COUNT = 64, parameter ROB_ROW_COUNT = 64)
(
	input clk,
	input[63:0] reg_ready, // 64-bit ready table
	input[2:0] fu_ready,
	input finish_fetch,
	// instruction 1
	input[6:0] instr1_opcode, // from IDModule
	input[5:0] instr1_p_rs1, // physical register from Rename
	input[5:0] instr1_p_rs2,
	input[5:0] instr1_p_rd,
	input[31:0] instr1_imm, // from IDModule
	input[6:0] instr1_funct7,
	input[2:0] instr1_funct3,
	input[5:0] instr1_p_old_rd,
	
	// instruction 2
	input[6:0] instr2_opcode, // from IDModule
	input[5:0] instr2_p_rs1, // physical register from Rename
	input[5:0] instr2_p_rs2,
	input[5:0] instr2_p_rd,
	input[31:0] instr2_imm, // from IDModule
	input[6:0] instr2_funct7,
	input[2:0] instr2_funct3,
	input[5:0] instr2_p_old_rd,
	
	//FU output
	input[31:0] fu_out[0:2],
	
	output reg[63:0] new_reg_ready,	// 64-bit ready table
	output reg[2:0] new_fu_ready,
	
	output reg[2:0] fu_operation[0:2],
	output reg[31:0] fu_inp1[0:2],
	output reg[31:0] fu_inp2[0:2],
	
	//Mem FU input
	output reg[31:0] write_address1,
	output reg[31:0] write_data1,
	output reg we1,
	
	output reg[31:0] write_address2,
	output reg[31:0] write_data2,
	output reg we2,
	
	//Registers to free from retire
	output reg[5:0] free_reg1,
	output reg[5:0] free_reg2,
	
	output reg[31:0] clean_regfile[0:63],
	output reg finish
	
);
	reg finish_state;
	reg[31:0] dirty_regfile[0:63];


	reg[5:0] first_empty_row;
	reg[5:0] second_empty_row;
	reg first_empty_flag;
	reg second_empty_flag;
	
	reg fu_roundrobin;
	
	reg[5:0] row_issue[0:2];
	reg[2:0] issue;
	reg[2:0] issue_flag;
	
	reg[5:0] fu_rob_inp[0:2];
	
	reg fumem_state;
	
	reg[5:0] next_robrow;
	reg[5:0] next_robretire;
	
	reg[5:0] forward_reg[0:2];

	//For SW, destreg is register to read and data is the address
	struct{
		reg used[ROB_ROW_COUNT-1:0];
		reg[5:0] destreg[ROB_ROW_COUNT-1:0];
		reg[5:0] old_destreg[ROB_ROW_COUNT-1:0];
		reg[31:0] data[ROB_ROW_COUNT-1:0];
		reg completed[ROB_ROW_COUNT-1:0];
		reg sw[ROB_ROW_COUNT-1:0];
	} rob;
	
	initial begin
		dirty_regfile[0] = 32'b0;
		clean_regfile[0] = 32'b0;
		
		new_fu_ready[0] = 1;
		new_fu_ready[1] = 1;
		new_fu_ready[2] = 1;
		
		for(integer i = 0; i < RS_ROW_COUNT; i++) begin
			rstable.used[i] = 0;
		end
		for(integer i = 0; i < ROB_ROW_COUNT; i++) begin
			rob.used[i] = 0;
		end
		for(integer i = 0; i < RS_ROW_COUNT; i++) begin
			new_reg_ready[i] = 1;
		end
		
		fu_roundrobin = 0;
		fumem_state = 0;
		
		next_robrow = 0;
		next_robretire = 0;
		
		finish = 0;
	end
	
	always_comb begin
		//Determine which rows to issue
		row_issue[0] = 6'b0;
		row_issue[1] = 6'b0;
		row_issue[2] = 6'b0;
		issue[0] = 0;
		issue[1] = 0;
		issue[2] = 0;
		issue_flag = 0;
		issue_flag = 0;
		issue_flag = 0;
		
		for(integer i = 0; i < RS_ROW_COUNT; i++) begin
			if(rstable.used[i] && (rstable.ready1[i] || rstable.srcreg1[i] == forward_reg[0] || rstable.srcreg1[i] == forward_reg[1] || rstable.srcreg1[i] == forward_reg[2]) && (rstable.ready2[i] || rstable.srcreg2[i] == forward_reg[0] || rstable.srcreg2[i] == forward_reg[1] || rstable.srcreg2[i] == forward_reg[2]) && fu_ready[rstable.fu[i]] && ~issue_flag[rstable.fu[i]]) begin
				issue_flag[rstable.fu[i]] = 1;
				issue[rstable.fu[i]] = 1;
				row_issue[rstable.fu[i]] = i;
			end
		end
		
		//Determine which rows to insert entry
		first_empty_flag = 0;
		second_empty_flag = 0;
		first_empty_row = 6'b0;
		second_empty_row = 6'b0;
	
		if(~rstable.used[next_robrow]) begin
			first_empty_row = next_robrow;
		end
		
		if(~rstable.used[next_robrow + 1]) begin
			second_empty_row = next_robrow + 1;
		end
		
		if(rstable.used[next_robrow] || rstable.used[next_robrow + 1]) begin
			for(integer i = 0; i < RS_ROW_COUNT; i++) begin
				if(~rstable.used[i] && ~first_empty_flag && ~second_empty_flag) begin
					first_empty_flag = 1;
					first_empty_row = i;
				end
				else if(~rstable.used[i] && first_empty_flag && ~second_empty_flag) begin
					second_empty_flag = 1;
					second_empty_row = i;
				end
			end
		end
		
		//Write to mem from retire
		write_address1 = 0;
		write_data1 = 0;
		we1 = 0;
		write_address2 = 0;
		write_data2 = 0;
		we2 = 0;
		
		if(rob.used[next_robretire] && rob.sw[next_robretire]) begin
			write_address1 = rob.data[next_robretire];
			write_data1 = clean_regfile[rob.destreg[next_robretire]];
			we1 = 1;
		end
		if(rob.used[next_robretire] && rob.completed[next_robretire] && rob.used[next_robretire + 1] && rob.sw[next_robretire + 1]) begin
			write_address2 = rob.data[next_robretire + 1];
			write_data2 = clean_regfile[rob.destreg[next_robretire + 1]];
			we2 = 1;
		end
	end	
	
	always @(posedge clk) begin
		finish_state <= finish_fetch;
		//Instruction 1 dispatch
		if(instr1_opcode != 7'b0) begin
			//RS Table insert
			rstable.used[first_empty_row] <= 1;
			rstable.op[first_empty_row] <= instr1_opcode;
			rstable.funct7[first_empty_row] <= instr1_funct7;
			rstable.funct3[first_empty_row] <= instr1_funct3;
			rstable.destreg[first_empty_row] <= instr1_p_rd;
			rstable.srcreg1[first_empty_row] <= instr1_p_rs1;
			if(reg_ready[instr1_p_rs1]) begin
				rstable.ready1[first_empty_row] <= 1;
				rstable.srcreg1_data[first_empty_row] <= dirty_regfile[instr1_p_rs1];
			end
			else begin
				rstable.ready1[first_empty_row] <= 0;
			end
			rstable.srcreg2[first_empty_row] <= instr1_p_rs2;
			if(reg_ready[instr1_p_rs2]) begin
				rstable.ready2[first_empty_row] <= 1;
				rstable.srcreg2_data[first_empty_row] <= dirty_regfile[instr1_p_rs2];
			end
			else begin
				rstable.ready2[first_empty_row] <= 0;
			end
			rstable.imm[first_empty_row] <= instr1_imm;
			rstable.rob[first_empty_row] <= next_robrow;
			
			if(instr1_p_rd != 0) begin
				new_reg_ready[instr1_p_rd] <= 0;
			end
			
			//ROB Insert
			rob.used[next_robrow] <= 1;
			if(instr1_opcode != sw) begin
				rob.destreg[next_robrow] <= instr1_p_rd;
				rob.sw[next_robrow] <= 0;
			end
			else begin
				rob.destreg[next_robrow] <= instr1_p_rs2;
				rob.sw[next_robrow] <= 1;
			end
			rob.old_destreg[next_robrow] <= instr1_p_old_rd;
			rob.completed[next_robrow] <= 0;
			
		end
		
		//Instruction 2 Dispatch
		if(instr2_opcode != 7'b0) begin
			//RS Table Insert
			rstable.used[second_empty_row] <= 1;
			rstable.op[second_empty_row] <= instr2_opcode;
			rstable.funct7[second_empty_row] <= instr2_funct7;
			rstable.funct3[second_empty_row] <= instr2_funct3;
			rstable.destreg[second_empty_row] <= instr2_p_rd;
			rstable.srcreg1[second_empty_row] <= instr2_p_rs1;
			if(reg_ready[instr2_p_rs1] && instr2_p_rs1 != instr1_p_rd) begin
				rstable.ready1[second_empty_row] <= 1;
				rstable.srcreg1_data[second_empty_row] <= dirty_regfile[instr2_p_rs1];
			end
			else begin
				rstable.ready1[second_empty_row] <= 0;
			end
			rstable.srcreg2[second_empty_row] <= instr2_p_rs2;
			if(reg_ready[instr2_p_rs2] && instr2_p_rs2 != instr1_p_rd) begin
				rstable.ready2[second_empty_row] <= 1;
				rstable.srcreg2_data[second_empty_row] <= dirty_regfile[instr2_p_rs2];
			end
			else begin
				rstable.ready2[second_empty_row] <= 0;
			end
			rstable.imm[second_empty_row] <= instr2_imm;
			rstable.rob[second_empty_row] <= next_robrow + 1;
			
			if(instr2_p_rd != 0) begin
				new_reg_ready[instr2_p_rd] <= 0;
			end
			
			//ROB Insert
			
			rob.used[next_robrow + 1] <= 1;
			if(instr2_opcode != sw) begin
				rob.destreg[next_robrow + 1] <= instr2_p_rd;
				rob.sw[next_robrow + 1] <= 0;
			end
			else begin
				rob.destreg[next_robrow + 1] <= instr2_p_rs2;
				rob.sw[next_robrow + 1] <= 1;
			end
			rob.old_destreg[next_robrow + 1] <= instr2_p_old_rd;
			rob.completed[next_robrow + 1] <= 0;
			
		end
		
		//Update next_robrow to insert rob
		if(instr1_opcode != 7'b0 && instr2_opcode != 7'b0) begin
			next_robrow <= next_robrow + 2;
		end
		else if(instr1_opcode != 7'b0) begin
			next_robrow <= next_robrow + 1;
		end
		
		//Determine FU
		if(~(instr1_opcode == lw || instr1_opcode == sw) && ~(instr2_opcode == lw || instr2_opcode == sw)) begin
			rstable.fu[first_empty_row] <= 0;
			rstable.fu[second_empty_row] <= 1;
		end
		else begin
			if(instr1_opcode == lw || instr1_opcode == sw) begin
				rstable.fu[first_empty_row] <= 2;
			end
			else begin
				rstable.fu[first_empty_row] <= fu_roundrobin;
				fu_roundrobin <= ~fu_roundrobin;
			end
			
			if(instr2_opcode == lw || instr2_opcode == sw) begin
				rstable.fu[second_empty_row] <= 2;
			end
			else begin
				rstable.fu[second_empty_row] <= fu_roundrobin;
				fu_roundrobin <= ~fu_roundrobin;
			end
		end
		
		//Forwarding
		for(integer i = 0; i < RS_ROW_COUNT; i++) begin
			if(rstable.used[i]) begin
				if(~rstable.ready1[i] && reg_ready[rstable.srcreg1[i]]) begin
					rstable.ready1[i] <= 1;
					rstable.srcreg1_data[i] <= dirty_regfile[rstable.srcreg1[i]];
				end
				
				if(~rstable.ready2[i] && reg_ready[rstable.srcreg2[i]]) begin
					rstable.ready2[i] <= 1;
					rstable.srcreg2_data[i] <= dirty_regfile[rstable.srcreg2[i]];
				end
			end
		end
		
		//Issue
		for(integer i = 0; i < 3; i++) begin
			if(issue[i]) begin
				new_fu_ready[i] <= 0;
				rstable.used[row_issue[i]] <= 0;
				//Setting FU outputs
				fu_rob_inp[i] <= rstable.rob[row_issue[i]];
				case(rstable.op[row_issue[i]])
					rtype: begin
						fu_inp1[i] <= (~rstable.ready1[row_issue[i]]) ? dirty_regfile[rstable.srcreg1[row_issue[i]]] : rstable.srcreg1_data[row_issue[i]];
						fu_inp2[i] <= (~rstable.ready2[row_issue[i]]) ? dirty_regfile[rstable.srcreg2[row_issue[i]]] : rstable.srcreg2_data[row_issue[i]];
						if(rstable.funct3[row_issue[i]] == 3'b000 && rstable.funct7[row_issue[i]] == 7'b0000000) begin
							fu_operation[i] <= addop;
						end
						else if(rstable.funct3[row_issue[i]] == 3'b000 && rstable.funct7[row_issue[i]] == 7'b0100000) begin
							fu_operation[i] <= subop;
						end
						else if(rstable.funct3[row_issue[i]] == 3'b100) begin
							fu_operation[i] <= xorop;
						end
						else begin
							fu_operation[i] <= sraop;
						end
					end
					itype: begin
						fu_inp1[i] <= (~rstable.ready1[row_issue[i]]) ? dirty_regfile[rstable.srcreg1[row_issue[i]]] : rstable.srcreg1_data[row_issue[i]];
						fu_inp2[i] <= rstable.imm[row_issue[i]];
						if(rstable.funct3[row_issue[i]] == 3'b000) begin
							fu_operation[i] <= addop;
						end
						else begin
							fu_operation[i] <= andop;
						end
					end
					lw: begin
						fu_inp1[i] <= (~rstable.ready1[row_issue[i]]) ? dirty_regfile[rstable.srcreg1[row_issue[i]]] : rstable.srcreg1_data[row_issue[i]];
						fu_inp2[i] <= rstable.imm[row_issue[i]];
						fu_operation[i] <= load;
					end
					sw: begin
						fu_inp1[i] <= (~rstable.ready1[row_issue[i]]) ? dirty_regfile[rstable.srcreg1[row_issue[i]]] : rstable.srcreg1_data[row_issue[i]];
						fu_inp2[i] <= rstable.imm[row_issue[i]];
						fu_operation[i] <= store;
					end
				endcase				
				
			end
		end
		
		//Complete
		for(integer i = 0; i < 3; i++) begin
			if(fu_ready[i] == 0) begin
				if(fu_operation[i] == store) begin
					rob.data[fu_rob_inp[i]] <= fu_out[i];
					rob.completed[fu_rob_inp[i]] <= 1;
					new_fu_ready[i] <= 1;
					forward_reg[i] <= 0;
				end
				else if(fu_operation[i] != load) begin
					if(rob.destreg[fu_rob_inp[i]] != 0) begin
						rob.data[fu_rob_inp[i]] <= fu_out[i];
						dirty_regfile[rob.destreg[fu_rob_inp[i]]] <= fu_out[i];
						new_reg_ready[rob.destreg[fu_rob_inp[i]]] <= 1;
					end
					rob.completed[fu_rob_inp[i]] <= 1;
					new_fu_ready[i] <= 1;
					forward_reg[i] <= rob.destreg[fu_rob_inp[i]];
				end
				else begin
					if(~fumem_state) begin
						fumem_state <= 1;
						forward_reg[i] <= 0;
					end
					else begin
						if(rob.destreg[fu_rob_inp[i]] != 0) begin
							rob.data[fu_rob_inp[i]] <= fu_out[i];
							dirty_regfile[rob.destreg[fu_rob_inp[i]]] <= fu_out[i];
							new_reg_ready[rob.destreg[fu_rob_inp[i]]] <= 1;
						end
						rob.completed[fu_rob_inp[i]] <= 1;
						new_fu_ready[i] <= 1;
						forward_reg[i] <= rob.destreg[fu_rob_inp[i]];
						
						fumem_state <= 0;
					end
				end
			end
			else begin
				forward_reg[i] <= 0;
			end
		end
		
		//Retire
		if(rob.completed[next_robretire] && rob.used[next_robretire]) begin
			rob.used[next_robretire] <= 0;
			if(~rob.sw[next_robretire]) begin
				free_reg1 <= rob.old_destreg[next_robretire];
				if(rob.destreg[next_robretire] != 0) begin
					clean_regfile[rob.destreg[next_robretire]] <= rob.data[next_robretire];
				end
			end
			else begin
				free_reg1 <= 0;
			end
			
			if(rob.completed[next_robretire + 1] && rob.used[next_robretire + 1]) begin
				rob.used[next_robretire + 1] <= 0;
				if(~rob.sw[next_robretire + 1]) begin
					free_reg2 <= rob.old_destreg[next_robretire + 1];
					if(rob.destreg[next_robretire + 1] != 0) begin
						clean_regfile[rob.destreg[next_robretire + 1]] <= rob.data[next_robretire + 1];
					end
				end
				else begin
					free_reg2 <= 0;
				end
				next_robretire <= next_robretire + 2;
			end
			else begin
				next_robretire <= next_robretire + 1;
				free_reg2 <= 0;
			end
		end
		else begin
			free_reg1 <= 0;
			free_reg2 <= 0;
		end
		
		if(finish_state && next_robretire == next_robrow) begin
			finish <= 1;
		end
		
	end
	
endmodule