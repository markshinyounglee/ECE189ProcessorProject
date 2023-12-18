`timescale 1ns / 1ps

module RISCV_CPU
import operationList::*;
(
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
	reg finish_fetch;
	
	Fetch fetch (
		.clk(clk),
		.instr1(instr1),
		.instr2(instr2),
		.finish(finish_fetch)
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

	reg[63:0] freePool;
	wire[5:0] rat[0:31];
	
	reg[63:0] re_freePool;
	reg[5:0] re_rat[0:31];
	
	assign rat = re_rat;
	
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
		.new_freePool(re_freePool),
		.new_rat(re_rat)
	);
		
		
	wire[63:0] reg_ready;
	wire[2:0] fu_ready;
	
	reg[63:0] rs_reg_ready;
	reg[2:0] rs_fu_ready;
		
	reg[31:0] fu_out[0:2];
	
	reg[2:0] fu_operation[0:2];
	reg[31:0] fu_inp1[0:2];
	reg[31:0] fu_inp2[0:2];
	
	reg[5:0] free_reg1;
	reg[5:0] free_reg2;
	
	reg[31:0] clean_regfile[0:63];
	
	reg finish_rs;
	
	assign reg_ready = rs_reg_ready;
	assign fu_ready = rs_fu_ready;
	
	reg[31:0] write_address1;
	reg[31:0] write_data1;
	reg we1;
	
	reg[31:0] write_address2;
	reg[31:0] write_data2;
	reg we2;
	
	ReservationStation rs(
		.clk(clk),
		.reg_ready(reg_ready),
		.fu_ready(fu_ready),
		.finish_fetch(finish_fetch),
		.instr1_p_rs1(instr1_p_rs1),
		.instr1_p_rs2(instr1_p_rs2),
		.instr1_p_rd(instr1_p_rd),
		.instr2_p_rs1(instr2_p_rs1),
		.instr2_p_rs2(instr2_p_rs2),
		.instr2_p_rd(instr2_p_rd),
		.instr1_imm(instr1_imm),
		.instr1_funct3(instr1_funct3),
		.instr1_funct7(instr1_funct7),
		.instr1_p_old_rd(instr1_p_old_rd),
		.instr1_opcode(instr1_opcode),
		.instr2_imm(instr2_imm),
		.instr2_funct3(instr2_funct3),
		.instr2_funct7(instr2_funct7),
		.instr2_p_old_rd(instr2_p_old_rd),
		.instr2_opcode(instr2_opcode),
		.fu_out(fu_out),
		.new_reg_ready(rs_reg_ready),
		.new_fu_ready(rs_fu_ready),
		.fu_operation(fu_operation),
		.fu_inp1(fu_inp1),
		.fu_inp2(fu_inp2),
		.write_address1(write_address1),
		.write_data1(write_data1),
		.we1(we1),
		.write_address2(write_address2),
		.write_data2(write_data2),
		.we2(we2),
		.free_reg1(free_reg1),
		.free_reg2(free_reg2),
		.clean_regfile(clean_regfile),
		.finish(finish_rs)
	);
	
	FU_ALU fu0(
		.operation(fu_operation[0]),
		.inp1(fu_inp1[0]),
		.inp2(fu_inp2[0]),
		.outp(fu_out[0])
	);
	
	FU_ALU fu1(
		.operation(fu_operation[1]),
		.inp1(fu_inp1[1]),
		.inp2(fu_inp2[1]),
		.outp(fu_out[1])
	);
	
	reg[31:0] fu2_address;
	reg[31:0] lw_data;
	ALUMem fu2(
		.clk(clk),
		.write_address1(write_address1),
		.write_data1(write_data1),
		.we1(we1),
		.write_address2(write_address2),
		.write_data2(write_data2),
		.we2(we2),
		.operation(fu_operation[2]),
		.inp1(fu_inp1[2]),
		.inp2(fu_inp2[2]),
		.address(fu2_address),
		.lw_data(lw_data)
	);
	
	always_comb begin
		for(integer i = 1; i < 64; i++) begin
			if(free_reg1 == i) begin
				freePool[i] = 1;
			end
			else if(free_reg2 == i) begin
				freePool[i] = 1;
			end
			else begin
				freePool[i] = re_freePool[i];
			end
		end
		
		fu_out[2] = (fu_operation[2] == load) ? lw_data : fu2_address;
	end
	
	reg[31:0] clk_count;
	initial begin
		// Initialize Inputs
		clk = 0;
		clk_count = 0;
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(integer i = 0; i < 250; i++) begin
			#10 clk = ~clk;
			#10 clk = ~clk; 
			clk_count = clk_count + 1;
			if(finish_rs) begin
				break;
			end
		end
		
		for(integer i = 0; i < 10; i++) begin
			$display("x%d = %d", i, clean_regfile[rat[i]]);
		end
		$display("Clock Count: %d", clk_count);
	end
      
endmodule

