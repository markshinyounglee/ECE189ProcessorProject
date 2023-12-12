// ALU that supports memory instruction
// instantiate once in the top level

module ALUMem
import operationList::*
(
	input available,
	input[3:0] operation, // addition, subtraction, ...
	input[31:0] inp1,
	input[31:0] inp2
);

	always_comb begin
		if(available)
		begin
			casex(operation)
				load:
					begin
						// TO DO: perform lw/sw
					end
				store:
					begin
					
					end
				default:
					begin
						outp = 32'b0;
					end
			endcase
		end
	end

endmodule

