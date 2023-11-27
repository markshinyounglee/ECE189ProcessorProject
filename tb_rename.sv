`timescale 1ns / 1ps

module tb_rename(
	output reg[5:0] instr1_p_rs1,
	output reg[5:0] instr1_p_rs2,
	output reg[5:0] instr1_p_rd,
	output reg[5:0] instr1_p_old_rd,
	output reg[5:0] instr2_p_rs1,
	output reg[5:0] instr2_p_rs2,
	output reg[5:0] instr2_p_rd,
	output reg[5:0] instr2_p_old_rd
);

	reg clk;
	reg[31:0] instr1;
	reg[31:0] instr2;
	reg finish;
	
	Fetch fetch (
		.clk(clk),
		.instr1(instr1),
		.instr2(instr2),
		.finish(finish)
	);
	
	reg[4:0] instr1_rs1;
	reg[4:0] instr1_rs2;
 	reg[4:0] instr1_rd;
	reg[31:0] instr1_imm;
	reg[2:0] instr1_funct3;
	reg[6:0] instr1_funct7;
	reg[6:0] instr1_opcode;
	
	IDModule decode1 (
		.instructionSet(instr1),
		.rs1(instr1_rs1),
		.rs2(instr1_rs2),
		.rd(instr1_rd),
		.imm(instr1_imm),
		.funct3(instr1_funct3),
		.funct7(instr1_funct7),
		.opcode(instr1_opcode)
	);
	
	reg[4:0] instr2_rs1;
	reg[4:0] instr2_rs2;
 	reg[4:0] instr2_rd;
	reg[31:0] instr2_imm;
	reg[2:0] instr2_funct3;
	reg[6:0] instr2_funct7;
	reg[6:0] instr2_opcode;
	
	IDModule decode2 (
		.instructionSet(instr2),
		.rs1(instr2_rs1),
		.rs2(instr2_rs2),
		.rd(instr2_rd),
		.imm(instr2_imm),
		.funct3(instr2_funct3),
		.funct7(instr2_funct7),
		.opcode(instr2_opcode)
	);

	wire[63:0] freePool;
	wire[5:0] rat[0:31];
	
	reg[63:0] new_freePool;
	reg[5:0] new_rat[0:31];
	
	assign freePool = new_freePool;
	assign rat = new_rat;
	
	Rename rename(
		.clk(clk),
		.freePool(freePool),
		.rat(rat),
		.instr1_rs1(instr1_rs1),
		.instr1_rs2(instr1_rs2),
		.instr1_rd(instr1_rd),
		.instr2_rs1(instr2_rs1),
		.instr2_rs2(instr2_rs2),
		.instr2_rd(instr2_rd),
		.instr1_p_rs1(instr1_p_rs1),
		.instr1_p_rs2(instr1_p_rs2),
		.instr1_p_rd(instr1_p_rd),
		.instr1_p_old_rd(instr1_p_old_rd),
		.instr2_p_rs1(instr2_p_rs1),
		.instr2_p_rs2(instr2_p_rs2),
		.instr2_p_rd(instr2_p_rd),
		.instr2_p_old_rd(instr2_p_old_rd),
		.new_freePool(new_freePool),
		.new_rat(new_rat)
	);
		
	initial begin
		// Initialize Inputs
		clk = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(integer i = 0; i < 16; i++) begin
			#10 clk = ~clk;
			#10 clk = ~clk;
			#10 		
			$display("Instruction 1 rd: %d", instr1_p_rd);
			$display("Instruction 1 rs1: %d", instr1_p_rs1);
			$display("Instruction 1 rs2: %d\n", instr1_p_rs2);
			
			$display("Instruction 2 rd: %d", instr2_p_rd);
			$display("Instruction 2 rs1: %d", instr2_p_rs1);
			$display("Instruction 2 rs2: %d\n", instr2_p_rs2);
		end
	end
      
endmodule

