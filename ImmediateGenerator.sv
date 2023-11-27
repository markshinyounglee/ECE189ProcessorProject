module ImmediateGenerator
(
	input reg[11:0] inp, 
	output reg[31:0] imm
);

	// sign-extend upper bits, zero-pad lower bits
	assign imm = {inp[11] == 1'b0 ? 20'hFFFF : 20'h0000, inp};

endmodule