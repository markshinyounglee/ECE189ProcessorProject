`timescale 1ns / 1ps

module tb_fetch(
	output reg[31:0] instr1,
	output reg[31:0] instr2,
	output reg finish
);

	reg clk;
	
	Fetch uut (
		.clk(clk),
		.instr1(instr1),
		.instr2(instr2),
		.finish(finish)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(integer i = 0; i < 500; i++) begin
			#10 clk = ~clk;
		end
	end
      
endmodule

