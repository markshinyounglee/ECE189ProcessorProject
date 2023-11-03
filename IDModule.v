// must successfully decode 
// R-type, I-type, and Memory instructions (LW, SW)

module IDModule
import instructionList::*;
(
	input[31:0] instructionSet, 
	output reg[4:0] rs1,
	output reg[4:0] rs2,
 	output reg[4:0] rd,
	output reg[31:0] imm,
	output reg[2:0] funct3,
	output reg[6:0] funct7,
	output reg[6:0] opcode
);

	always@(*) 
	begin
		reg[11:0] rawImm = 12'bz;
		ImmediateGenerator(.inp(rawImm), .imm(imm));
		opcode = instructionset[6:0];
	
		casex(opcode)
			rtype:
				begin
					rawImm = 12'bz;
					funct7 = instructionSet[31:25];
					rs2 = instructionSet[24:20];
					rs1 = instructionSet[19:15];
					funct3 = instructionSet[14:12];
					rd = instructionSet[11:7];
				end
			itype:
				begin
					rawImm = instructionSet[31:20];
					rs1 = instructionSet[19:15];
					funct3 = instructionSet[14:12];
					rd = instructionSet[11:7];
				end
			lw:
				begin
					rawImm = instructionSet[31:20];
					rs1 = instructionSet[19:15];
					funct3 = instructionSet[14:12];
					rd = instructionSet[11:7];
				end
			sw:
				begin
					rawImm = {instructionSet[31:25], instructionSet[11:7]};
					rs1 = instructionSet[19:15];
					funct3 = instructionSet[14:12];
				end
		endcase
	end

endmodule