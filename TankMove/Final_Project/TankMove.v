
module TankMove (KEY, CLOCK_50, SW,

		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,				   //	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						   //	VGA Blue[9:0]
		);

input [1:0]KEY; 
input CLOCK_50; 
input [0:0]SW; 

output			VGA_CLK;   				//	VGA Clock
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output			VGA_BLANK_N;				//	VGA BLANK
output			VGA_SYNC_N;				//	VGA SYNC
output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
output	[7:0]	VGA_B;   				//	VGA Blue[7:0]

wire[7:0]Xpos;
wire initialx, Mleft, Mright, resetn;
wire [7:0]numOfPixToMove;
wire [2:0] moveDir;

assign resetn = SW[0];
assign numOfPixToMove = 8'b1;
assign Mleft = KEY[1];
assign Mright = KEY[0];
assign clk = CLOCK_50;

reg [1:0]Mstate;

always@(*)
begin
if(Mleft == 1'b1 && Mright == 1'b0)
	Mstate = 2'b10;
else if (Mleft == 1'b0 && Mright == 1'b1)
	Mstate = 2'b01;
else
	Mstate = 2'b00;
end

control C1(clk, resetn, Mstate, moveDir);
position P1(moveDir, clk, resetn, numOfPixToMove, Xpos);

//////////////////////////////////VGA Adapter////////////////////////////////////////////////////////////////////////////////////////////////////
vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(3'b010),
			.x(Xpos),
			.y(5),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

endmodule

//////////////////////////////////CONTROL////////////////////////////////////////////////////////////////////////////////////////////////////
module control(input clk, resetn,input [1:0]Mstate, output reg [3:0]moveDir);

reg [2:0] current_state;
reg [2:0] next_state;

localparam moveLeft = 3'b100, moveRight = 3'b001, stationary = 3'b010;
    

    always@(*)
    begin: state_table
        case (current_state)
            moveLeft: next_state = (Mstate == 2'b10) ? moveLeft : stationary;
            moveRight: next_state = (Mstate == 2'b01) ? moveRight : stationary;
            stationary: next_state = (Mstate == 2'b10) ? moveLeft : moveRight;
            default: next_state = stationary;
        endcase
    end
	 
	 // State Registers
    always @(*)
    begin: state_FFs
        if(resetn == 1'b0)
            current_state <=  stationary;
        else
            current_state <= next_state;
				moveDir <= current_state;
    end
	 
endmodule

//////////////////////////////////Position////////////////////////////////////////////////////////////////////////////////////////////////////
module position(input[2:0]moveDir, input clk, input resetn, input numOfPixToMove, output reg [7:0]xpos);

always@(posedge clk)
begin
if(resetn == 1'b0)
xpos = 8'b00000000;

else if(moveDir == 3'b100)
xpos <= xpos + numOfPixToMove;

else if(moveDir == 3'b001)
xpos <= xpos - numOfPixToMove;
end

endmodule
