/*****************************************************************************
 *                                                                           *
 * Module:      Mouse_interface                                      		 *
 *      Modified 12/2/15 by Kevin Perkins and Tarun Rajendran                * 
 *		Last modified 12/3/16 by Tianqi Liu & Yikuan Chen					 *
 *                                                                           *
 *****************************************************************************/



module initialTesting (	
				input CLOCK_50,
				input [3:0] KEY,
				inout PS2_CLK, PS2_DAT,
				output logic leftButton, middleButton, rightButton
				);

logic					ps2_data_ready;
logic			[7:0]	ps2_data, byte1, byte2, byte3;
logic			[1:0]   counter;

assign 	leftButton = byte1[0];
assign 	middleButton = byte1[2];
assign 	rightButton = byte1[1];

PS2_Controller PS2 (
	.CLOCK_50			(CLOCK_50),
	.reset				(~KEY[0]),
	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),
	.received_data		(ps2_data),
	.received_data_en	(ps2_data_ready)
);


always_ff @(posedge CLOCK_50)
begin
	if (KEY[0] == 1'b0)
	begin
		byte1 <= 8'h00;
		counter <= 2'b00;
	end
	// new packet available to read
	else if (ps2_data_ready == 1'b1)
	begin
		// Byte 3 for X Movement
		if (counter == 0)
		begin
			byte3 <= ps2_data;
			counter <= 2'b01;
		end
		// Byte 2 for Y Movement
		else if (counter == 1)
		begin

			byte2 <= ps2_data;
			counter <= 2'b10;
		end
		// Byte 1 for Button presses and sign bits
		else
		begin
			byte1 <= ps2_data;
			counter <= 2'b00;
		end
	end
end

endmodule







