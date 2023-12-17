// ALU that supports arithmetic expressions
// instantiate twice in the main module

module FU_ALU
import operationList::*;
(
	input[2:0] operation, // addition, subtraction, ...
	input[31:0] inp1,
	input[31:0] inp2, 
	output reg[31:0] outp
);

	always_comb begin
		
		casex(operation)
			addop:
				begin
					outp = inp1 + inp2;
				end
			subop:
				begin
					outp = inp1 - inp2;
				end
			andop:
				begin
					outp = inp1 & inp2;
				end
			xorop:
				begin
					outp = inp1 ^ inp2;
				end
			sraop:
				begin
					outp = inp1 >>> inp2[4:0];
				end
			default:
				begin
					outp = 32'b0;
				end
		endcase
	end

endmodule