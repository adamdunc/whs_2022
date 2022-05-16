// Pong VGA game
// (c) fpga4fun.com

module pong(clkin, vga_h_sync, vga_v_sync, btnL, btnR, LED,  vgaRed, vgaBlue, vgaGreen, SSEG_CA, SSEG_AN); //
input clkin;
output [7:0] LED;
output reg vgaRed;
output reg vgaGreen;
output reg vgaBlue;
output reg [7:0] SSEG_CA;
output reg [3:0] SSEG_AN;
output vga_h_sync, vga_v_sync;//, vga_R, vga_G, vga_B;
input btnL, btnR;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

reg [3:0] counter=4'd4;
reg clk;
reg [18:0] slow_counter = 19'd4;
reg slow_clk;

always @(posedge clkin)
begin
 counter <= counter + 4'd1;
 if(counter>=(4-1))
  counter <= 4'd0;
 clk <= (counter<4/2)?1'b1:1'b0;
end

always @(posedge clkin)
begin
 slow_counter <= slow_counter + 4'd1;
 if(slow_counter>=(28'd200000-1))
  slow_counter <= 4'd0;
 slow_clk <= (slow_counter<28'd200000/2)?1'b1:1'b0;
end

hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
  .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

/////////////////////////////////////////////////////////////////
// Paddle control section
reg [8:0] PaddlePosition;

always @(posedge slow_clk)
begin
    if (!btnL)
        begin
        if(~&PaddlePosition) // make sure the value doesn't overflow
            PaddlePosition <= PaddlePosition + 1;
        end
    else if (!btnR)
        begin
        if(|PaddlePosition)        // make sure the value doesn't underflow
			PaddlePosition <= PaddlePosition - 1;
		end
end

/////////////////////////////////////////////////////////////////
reg [9:0] ballX;
reg [8:0] ballY;
reg ball_inX, ball_inY;

always @(posedge clk)
if(ball_inX==0) ball_inX <= (CounterX==ballX) & ball_inY; else ball_inX <= !(CounterX==ballX+16);

always @(posedge clk)
if(ball_inY==0) ball_inY <= (CounterY==ballY); else ball_inY <= !(CounterY==ballY+16);

wire ball = ball_inX & ball_inY;

/////////////////////////////////////////////////////////////////
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire paddle = (CounterX>=PaddlePosition+8) && (CounterX<=PaddlePosition+120) && (CounterY[8:4]==27);
wire BouncingObject = border | paddle; // active if the border or paddle is redrawing itself

reg ResetCollision;
always @(posedge clk) ResetCollision <= (CounterY==500) & (CounterX==0);  // active only once for every video frame

reg CollisionX1, CollisionX2, CollisionY1, CollisionY2;
always @(posedge clk) if(ResetCollision) CollisionX1<=0; else if(BouncingObject & (CounterX==ballX   ) & (CounterY==ballY+ 8)) CollisionX1<=1;
always @(posedge clk) if(ResetCollision) CollisionX2<=0; else if(BouncingObject & (CounterX==ballX+16) & (CounterY==ballY+ 8)) CollisionX2<=1;
always @(posedge clk) if(ResetCollision) CollisionY1<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY   )) CollisionY1<=1;
always @(posedge clk) if(ResetCollision) CollisionY2<=0; else if(BouncingObject & (CounterX==ballX+ 8) & (CounterY==ballY+16)) CollisionY2<=1;

/////////////////////////////////////////////////////////////////
// Ball movement section
wire UpdateBallPosition = ResetCollision;  // update the ball position at the same time that we reset the collision detectors

reg ball_dirX, ball_dirY;
reg [4:0] ball_speed = 1;
always @(posedge clk)
if(UpdateBallPosition)
begin
	if(~(CollisionX1 & CollisionX2))        // if collision on both X-sides, don't move in the X direction
	begin
		ballX <= ballX + ball_speed * (ball_dirX ? -1 : 1);
		if(CollisionX2) ball_dirX <= 1; else if(CollisionX1) ball_dirX <= 0;
	end

	if(~(CollisionY1 & CollisionY2))        // if collision on both Y-sides, don't move in the Y direction
	begin
		ballY <= ballY + ball_speed * (ball_dirY ? -1 : 1);
		if(CollisionY2) ball_dirY <= 1; else if(CollisionY1) ball_dirY <= 0;
	end
end 

//////////////////////////////////////////////////////////////////
// Score calculation section
reg PaddleCollision = 0;
always @(posedge clk) if(ResetCollision) PaddleCollision<=0; else if(paddle & (CounterX==ballX+ 8) & (CounterY==ballY+16)) PaddleCollision<=1;

reg [15:0] score = 0;
always @ (posedge ResetCollision)
begin
    if (PaddleCollision & ~ball_dirY)
    begin
        score <= score + 1;
    end
end

/////////////////////////////////////////////////////////////////
// VGA Color section
wire R = BouncingObject | ball | (CounterX[4] ^ CounterY[4]);
wire G = BouncingObject | ball;
wire B = BouncingObject | ball;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
	if (R & inDisplayArea) 
	   vgaRed = 1'b1; else vgaRed = 1'b0;
	if (G & inDisplayArea) 
	   vgaGreen = 1'b1; else vgaGreen = 1'b0; 
	if (B & inDisplayArea) 
	   vgaBlue = 1'b1; else vgaBlue = 1'b0;
end

////////////////////////////////////////////////////////////////
// standard LED section


//////////////////////////////////////////////////////////////////
// 7 segment LED section

endmodule