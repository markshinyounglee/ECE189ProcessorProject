module Fetch
(
	input clk,
	output reg[31:0] instr1,
	output reg[31:0] instr2,
	output reg finish
);

	reg[7:0] instructionMem[0:255];
	reg[7:0] pc;
	
	initial begin
		instr1 = 0;
		instr2 = 0;
		pc = 0;
		finish = 0;
		$readmemh("C:/Users/Brandon/OneDrive/Documents/Classes/ECEM116C/189/ECE189ProcessorProject/r-test-hex.txt", instructionMem);
	end
	
	always@(posedge clk) begin
		
		if(instructionMem[pc] === 8'hxx || finish == 1'b1) begin
			instr1 <= 32'b0;
			finish <= 1'b1;
		end
		else begin
			instr1 <= {instructionMem[pc],instructionMem[pc+1],instructionMem[pc+2],instructionMem[pc+3]};
		end
		
		if(instructionMem[pc+4] === 8'hXX || finish == 1'b1) begin
			instr2 <= 32'b0;
			finish <= 1'b1;
		end
		else begin
			instr2 <= {instructionMem[pc+4],instructionMem[pc+5],instructionMem[pc+6],instructionMem[pc+7]};
			pc <= pc + 8'd8;
		end
	end
	
endmodule