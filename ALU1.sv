// ALU that supports arithmetic expressions
// instantiate twice in the main module

module ALU1
import operationList::*
(
	input available,
	input[3:0] operation, // addition, subtraction, ...
	input[31:0] inp1,
	input[31:0] inp2, 
	output[31:0] reg outp,
	output reg zero_flag
);

	always_comb begin
		if(available)
		begin
			casex(operation)
				add:
					begin
						outp = inp1 + inp2;
						zero_flag = 1'b0;
					end
				sub:
					begin
						outp = inp - inp2;
						zero_flag = (inp == inp2 ? 1'b1 : 1'b0);
					end
				andop:
					begin
						outp = inp & inp2;
						zero_flag = 1'b0;
					end
				orop:
					begin
						outp = inp | inp2;
						zero_flag = 1'b0;
					end
				default:
					begin
						outp = 32'b0;
						zero_flag = 1'b0;
					end
			endcase
		end
	end

endmodule