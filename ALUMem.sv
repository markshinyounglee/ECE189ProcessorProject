// ALU that supports memory instruction
// instantiate once in the top level

module ALUMem
import operationList::*;
(
	input clk,
	
	input[31:0] write_address1,
	input[31:0] write_data1,
	input we1,
	
	input[31:0] write_address2,
	input[31:0] write_data2,
	input we2,
	
	input[2:0] operation, 
	input[31:0] inp1,
	input[31:0] inp2,
	
	output reg[31:0] address,
	output reg[31:0] lw_data,
	output reg[7:0] print_test
);

	reg[7:0] mem[0:1023];
	
	always_comb begin
		address = inp1 + inp2;
		print_test = mem[4];
	end

	always @(posedge clk) begin
		//Write 1
		if(we1) begin
			mem[write_address1] <= write_data1[7:0];
			mem[write_address1 + 1] <= write_data1[15:8];
			mem[write_address1 + 2] <= write_data1[23:16];
			mem[write_address1 + 3] <= write_data1[31:24];
		end
		//Write 2
		if(we2) begin
			mem[write_address2] <= write_data2[7:0];
			mem[write_address2 + 1] <= write_data2[15:8];
			mem[write_address2 + 2] <= write_data2[23:16];
			mem[write_address2 + 3] <= write_data2[31:24];
		end
		//Read
		if(operation == load) begin
			lw_data[7:0] <= mem[address];
			lw_data[15:8] <= mem[address + 1];
			lw_data[23:16] <= mem[address + 2];
			lw_data[31:24] <= mem[address + 3];
		end
		else begin
			lw_data <= 0;
		end
	end
endmodule

