module Rename #(parameter NUM_PHYSICAL_REGISTERS = 64) (
	input clk,
	input[NUM_PHYSICAL_REGISTERS - 1:0] freePool,
	input[5:0] rat[0:31],
	input[4:0] instr1_rs1,
	input[4:0] instr1_rs2,
	input[4:0] instr1_rd,
	input[4:0] instr2_rs1,
	input[4:0] instr2_rs2,
	input[4:0] instr2_rd,
	output reg[5:0] instr1_p_rs1,
	output reg[5:0] instr1_p_rs2,
	output reg[5:0] instr1_p_rd,
	output reg[5:0] instr1_p_old_rd,
	output reg[5:0] instr2_p_rs1,
	output reg[5:0] instr2_p_rs2,
	output reg[5:0] instr2_p_rd,
	output reg[5:0] instr2_p_old_rd,
	output reg[NUM_PHYSICAL_REGISTERS - 1:0] new_freePool,
	output reg[5:0] new_rat[0:31]
);

	reg flag;
	initial begin
	
		for(integer i = 0; i < 32; i++) begin
			new_rat[i] = i;
			new_freePool[i] = 1'b0;
		end
		
		for(integer i = 32; i < 64; i++) begin
			new_freePool[i] = 1'b1;
		end
		
	end
	
	always_comb begin
	
		flag = 0;
		instr1_p_rd = 0;
		instr2_p_rd = 0;
		
		//Rename both destination registers
		if(instr1_rd != 5'b0 && instr2_rd != 5'b0) begin
			for(integer i = 1; i < NUM_PHYSICAL_REGISTERS; i++) begin
				if(freePool[i] && ~flag) begin
					instr1_p_rd = i;
					flag = 1;
				end
				else if(freePool[i] && flag) begin
					instr2_p_rd = i;
				end
			end
		end
		//Rename only instruction2's destination register
		else if(instr1_rd == 5'b0 && instr2_rd != 5'b0) begin
			for(integer i = NUM_PHYSICAL_REGISTERS - 1; i > 0; i--) begin
				if(freePool[i]) begin
					instr2_p_rd = i;
				end
			end
		end
		//Rename only instruction1's destination register
		else if(instr1_rd != 5'b0 && instr2_rd == 5'b0) begin
			for(integer i = NUM_PHYSICAL_REGISTERS - 1; i > 0; i--) begin
				if(freePool[i]) begin
					instr1_p_rd = i;
				end
			end
		end

		instr1_p_rs1 = rat[instr1_rs1];
		instr1_p_rs2 = rat[instr1_rs2];
		
		instr2_p_rs1 = (instr2_rs1 == instr1_rd) ? instr1_p_rd : rat[instr2_rs1];
		instr2_p_rs2 = (instr2_rs2 == instr1_rd) ? instr1_p_rd : rat[instr2_rs2];
		
		instr1_p_old_rd = rat[instr1_rd];
		instr2_p_old_rd = rat[instr2_rd];
		
	end
	
	always @(posedge clk) begin
		new_freePool <= freePool & ~({{NUM_PHYSICAL_REGISTERS-1{1'b0}}, 1'b1} << instr1_p_rd) & ~({{NUM_PHYSICAL_REGISTERS-1{1'b0}}, 1'b1} << instr2_p_rd);
		
		new_rat[0] <= 5'b0;
		for(integer i = 1; i < 32; i++) begin
			if(i == instr1_rd) begin
				new_rat[i] <= instr1_p_rd;
			end
			else if(i == instr2_rd) begin
				new_rat[i] <= instr2_p_rd;
			end
			else begin
				new_rat[i] <= rat[i];
			end
		end
		
	end
	
endmodule