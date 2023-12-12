module ReservationStation #(parameter ROB_ROW_COUNT = 64, parameter RS_ROW_COUNT = 64)(
	input clk,
	input rob, 
	output reg[47:0] new_reservationTable[RS_ROW_COUNT-1:0], // 64 rows and each row has 1+7+6+6+1+6+1+12+2+6
	output reg[45:0] rob[ROB_ROW_COUNT-1:0] // 64 rows and each row has 1+6+6+32+1=46
);
	
	/*
	pseudocode:
	
	for i = 0 to length(new_reservattionTable)-1
	{
		if src1 == (1 or -) and src == (1 or -) 
		{
			
		}
	}
	
	*/
	integer i;
	always@(posedge clk) 
	begin
		for(i = 0; i < 64; i++)
		begin
			
		end
	end
	
endmodule