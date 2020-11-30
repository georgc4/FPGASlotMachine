module machine(input CLOCK_50, 
				input [3:0] KEY,
				inout PS2_CLK, PS2_DAT,
				output [6:0] seg1, seg2, seg3, betSeg0, betSeg1, credSeg1, credSeg2,
				output [17:0] LEDR,
				output [7:0]  LEDG
				);
//declaring internal nodes
logic leftButton, middleButton, rightButton, buttonPressed, upOrDown, CLOCK_20, CLOCK_2, luck, rstN, resetFlick, noBet;
logic [2:0] gettingWinner;
logic [3:0] bet, randReel;
logic [4:0] flickCount;
logic [7:0] credits, newCredits, multiplier;
logic [11:0] randomCount, loseCount, winCount;
logic [11:0] reels, winReel, loseReel;

//driver for PS/2 interface
mouseControl mouseIn(.*);

//various counters used in machine
upDown12bit randomCounter(.clk (CLOCK_20), .upDown (1), .rstN (KEY[0]), .cnt (randomCount[11:0])); //used to generate animation
upDown12bit loseCounter(.clk (CLOCK_50), .upDown (1), .rstN (KEY[0]), .cnt (loseCount[11:0])); //used to determine reel displayed on loss
upDown12bit winCounter(.clk (CLOCK_50), .upDown (0), .rstN (KEY[0]), .cnt (winCount[11:0]));   //used to determine reel displayed on win
upDown12bit betCounter(.clk(buttonPressed), .upDown(upOrDown), .rstN (noBet), .cnt(bet[3:0])); //used to keep track of current bet
upDown12bit    flickCounter(.clk(CLOCK_20), .upDown(1), .rstN(resetFlick), .cnt(flickCount[4:0])); //used to time animation

//drivers for seven segment displays
driver7seg seg1Get(.numIn (reels[11:8]), .segments (seg1[6:0]));
driver7seg seg2Get(.numIn (reels[7:4]), .segments (seg2[6:0]));
driver7seg seg3Get(.numIn (reels[3:0]), .segments (seg3[6:0]));
driver7segDec getCred(.numIn (credits[7:0]), .segment0 (credSeg2[6:0]), .segment1 (credSeg1[6:0]));
driver7segDec getBet(.numIn (bet[3:0]), .segment0 (betSeg1[6:0]), .segment1 (betSeg0[6:0]));

//clock dividers
twenty_hertz      flickClock(.clk_50mhz(CLOCK_50), .clk_20hz(CLOCK_20));
two_hertz  		 lightClock(.clk_50mhz(CLOCK_50), .clk_2hz(CLOCK_2));

//used to get a winning reel (fairly arbitrary)
goodReel      getWinner(.choose(gettingWinner[2:0]), .goodReel(winReel));

//continuous assignments
assign rstN = KEY[0];
assign randReel = randomCount[3:0]; //animated segments
assign resetFlick = ~middleButton; //reset animation counter on click
assign noBet = !(credits <= 8'h00); //not allow you to bet after game over

enum logic [1:0] { Idle = 2'B00, Flicker = 2'B01}  //state machine bits (room for four states in case of expansion)
PresentState, NextState;

always_ff @(posedge CLOCK_20 or negedge rstN)  //state register
  if(~rstN) PresentState <= Idle;
   else      PresentState <= NextState;




always_ff @(posedge middleButton or negedge rstN) //on click of middle button
if(!rstN)
	loseReel <= 12'h000; //reset reels
else begin
loseReel <= loseCount; //sample loseCounter to display random reel in case of loss
luck <= (winCount[2:0] == 7 || winCount[2:0] == 1); //arbitrary decision of luck (1/4 chance of winning)
gettingWinner <= randomCount; //used to choose which winning reel is shown
end

always_comb begin
	if (credits <= 8'h00 || credits[7]) begin //if youve lost, credits will remain at 0
		multiplier = 8'h00;
	end	

else begin
	 if (luck) begin 				//if you won, your winnings are which reel you won * your current bet
		if (gettingWinner == 3'h0) 
			multiplier = (gettingWinner+1) * bet[3:0];
		else							//this is the arbitrary part where you could modify code to produce different jackpots 
			multiplier = gettingWinner * bet[3:0]; 
	end
	
	else
		multiplier = -bet; //if you lost, you simply lose whatever you bet
	
	
	end
	newCredits = credits + multiplier;
end

always_ff @(negedge PresentState[0] or negedge rstN) begin //credits register
	if(!rstN) 
		credits <= 8'd50; //reset to start of game
	else if ((newCredits) > 8'd99 && luck) //ensure it doesn't go over 99 when you win
		credits <= 8'd99;
	else if (newCredits<= 8'h00 || newCredits[7] ) //to ensure credits register holds 0
		credits <= 8'h00;
	
	

	else 	//otherwise just update credits
		credits <= newCredits;

end

always_comb begin //next state logic
  case (PresentState)
    Idle: if(middleButton) NextState = Flicker; //animate on click
    else      NextState = Idle;

    Flicker: if(flickCount == 30) NextState = Idle; //animation state
    else      NextState = Flicker;
    default : NextState = Idle;
  endcase
end

always_comb begin  //output logic
case (PresentState)
    Idle: begin
    if(!middleButton) begin //this ensures the leds dont flash prematurely
      if(luck) begin //if you won, display the winning reel
      		reels = winReel;
      		
          if(CLOCK_2) begin //animated leds
          		LEDR= 18'h000000;
      			LEDG = 8'hAA;
      		end
      		else begin
      			LEDR= 18'h000000;
      			LEDG = 8'h55;
      		end
      	end
          else  begin //losing case
          	
          	reels = loseReel;
          if(CLOCK_2) begin

          		LEDG = 8'h00;
      			LEDR = 18'h0000AA;
      		end
      		else begin
      			LEDG = 8'h00;
      			LEDR = 18'h000055;
      		end
      	end
      end
     else begin //this logic should never be reached because if middlebutton then we're in the flicker state
     	if(luck) begin
      		reels = winReel;
      		 LEDG = 8'h00;
     		 LEDR= 18'h000000;
     		end
      	else begin
      		reels = loseReel;
      		 LEDG = 8'h00;
      		LEDR= 18'h000000;
      	end
      end
    end


    Flicker: begin //animation state, no led's for suspense
      reels = {3{randReel}};
      LEDG = 8'h00;
      LEDR= 18'h000000;
  end
    default :  begin
      reels = 12'h000;
      LEDG = 8'h00;
      LEDR= 18'h000000;
  end

  endcase
end



always_ff @ (posedge leftButton or posedge rightButton) begin //interface for bet counter
	buttonPressed <= (leftButton ^ rightButton) || (credits==0);
	upOrDown = rightButton && !leftButton;
	end

endmodule


module goodReel (  //this module chooses which winning reel you get, and is random, 777 is the highest prize
  input [2:0] choose,    // Clock
  output [11:0] goodReel  
);
always_comb begin 
  case (choose)
    3'h0: goodReel = 12'hAAA;
    3'h1: goodReel = 12'h111;
    3'h2: goodReel = 12'h222;
    3'h3: goodReel = 12'h333;
    3'h4: goodReel = 12'h444;
    3'h5: goodReel = 12'h555;
    3'h6: goodReel = 12'h666;
    3'h7: goodReel = 12'h777;
  
    default : goodReel = 12'h777;
  endcase

end

endmodule



module twenty_hertz (  //20hz clock divider
input logic clk_50mhz,    //input FGPA frequency 50Mhz  
output logic clk_20hz    //output converted frequency 1Hz
);

logic [24:0] count;     //count to keep track the value of counter

always_ff @ (posedge clk_50mhz)  //50 Mhz clock can count 0 - 49999999 in 1 sec
begin

if(count == 1249999)     //counting half way to get the rising edge of output clock pulse
begin
  count <= 0;
  clk_20hz <= ~clk_20hz;    //inverting the output clock pulse to falling edge 
end

else
 count <= count + 1;    //continue counting up until halfway

end
endmodule

module two_hertz ( //2 hertz clock divider
input logic clk_50mhz,    //input FGPA frequency 50Mhz  
output logic clk_2hz    //output converted frequency 1Hz
);

logic [24:0] count;     //count to keep track the value of counter

always_ff @ (posedge clk_50mhz)  //50 Mhz clock can count 0 - 49999999 in 1 sec
begin

if(count == 12499999)     //counting half way to get the rising edge of output clock pulse
begin
  count <= 0;
  clk_2hz <= ~clk_2hz;    //inverting the output clock pulse to falling edge 
end

else
 count <= count + 1;    //continue counting up until halfway

end
endmodule
















//jk flip flop used for counting
module jk_ff ( input logic j,
               input logic k,
               input logic clk,
               output logic q);
   always @ (posedge clk)
      case ({j,k})
         2'b00 :  q <= q;
         2'b01 :  q <= 0;
         2'b10 :  q <= 1;
         2'b11 :  q <= ~q;
      endcase
endmodule



//counter module used many times in different situations for the machine
module upDown12bit (
  input logic clk,    // Clock
  input logic upDown,
  input logic rstN,  // synchronous reset active low
  output logic [11:0] cnt

);
logic [11:0] j, k; 
logic [10:0] upCount, downCount;
always_comb begin
upCount[0] = cnt[0] & upDown;
downCount[0] = ~cnt[0] & ~upDown;
upCount[1] = cnt[1] & upCount[0];
downCount[1] = ~cnt[1] & downCount[0];
upCount[2] = cnt[2] & upCount[1];
downCount[2] = ~cnt[2] & downCount[1]; 
upCount[3] = cnt[3] & upCount[2];
downCount[3] = ~cnt[3] & downCount[2]; 
upCount[4] = cnt[4] & upCount[3];
downCount[4] = ~cnt[4] & downCount[3]; 
upCount[5] = cnt[5] & upCount[4];
downCount[5] = ~cnt[5] & downCount[4]; 
upCount[6] = cnt[6] & upCount[5];
downCount[6] = ~cnt[6] & downCount[5]; 
upCount[7] = cnt[7] & upCount[6];
downCount[7] = ~cnt[7] & downCount[6]; 
upCount[8] = cnt[8] & upCount[7];
downCount[8] = ~cnt[8] & downCount[7]; 
upCount[9] = cnt[9] & upCount[8];
downCount[9] = ~cnt[9] & downCount[8]; 
upCount[10] = cnt[10] & upCount[9];
downCount[10] = ~cnt[10] & downCount[9]; 
  if (!rstN) begin
    j =12'h000;
    k =12'hfff;
  end


  else 
  begin
    j[0] = 1;
    k[0] = 1;
    j[1] = (upCount[0]) | (downCount[0]);
    k[1] = (upCount[0]) | (downCount[0]); 
    j[2] = (upCount[1]) | (downCount[1]);
    k[2] = (upCount[1]) | (downCount[1]);
    j[3] = (upCount[2]) | (downCount[2]);
    k[3] = (upCount[2]) | (downCount[2]);
    j[4] = (upCount[3]) | (downCount[3]);
    k[4] = (upCount[3]) | (downCount[3]);
    j[5] = (upCount[4]) | (downCount[4]);
    k[5] = (upCount[4]) | (downCount[4]);
    j[6] = (upCount[5]) | (downCount[5]);
    k[6] = (upCount[5]) | (downCount[5]);
    j[7] = (upCount[6]) | (downCount[6]);
    k[7] = (upCount[6]) | (downCount[6]);
    j[8] = (upCount[7]) | (downCount[7]);
    k[8] = (upCount[7]) | (downCount[7]);
    j[9] = (upCount[8]) | (downCount[8]);
    k[9] = (upCount[8]) | (downCount[8]);
    j[10] = (upCount[9]) | (downCount[9]);
    k[10] = (upCount[9]) | (downCount[9]);
    j[11] = (upCount[10]) | (downCount[10]);
    k[11] = (upCount[10]) | (downCount[10]);

  end

end

jk_ff jkf0 (j[0], k[0], clk, cnt[0]);
jk_ff jkf1 (j[1], k[1], clk, cnt[1]);
jk_ff jkf2 (j[2], k[2], clk, cnt[2]);
jk_ff jkf3 (j[3], k[3], clk, cnt[3]);
jk_ff jkf4 (j[4], k[4], clk, cnt[4]);
jk_ff jkf5 (j[5], k[5], clk, cnt[5]);
jk_ff jkf6 (j[6], k[6], clk, cnt[6]);
jk_ff jkf7 (j[7], k[7], clk, cnt[7]);
jk_ff jkf8 (j[8], k[8], clk, cnt[8]);
jk_ff jkf9 (j[9], k[9], clk, cnt[9]);
jk_ff jkf10 (j[10], k[10], clk, cnt[10]);
jk_ff jkf11 (j[11], k[11], clk, cnt[11]);
endmodule



//7 segment driver modules
module driver7seg (
	input logic [3:0] numIn,
   output logic [6:0] segments);

always_comb begin 
case (numIn) 
	4'b0000:	begin
		   	segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 1;
			end
	4'b0001: begin
		    segments[0] = 1;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 1;
		   	segments[4] = 1;
		   	segments[5] = 1;
		   	segments[6] = 1;
            end
	4'b0010: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 1;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 1;
		   	segments[6] = 0;
			end 
	4'b0011: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 1;
		   	segments[5] = 1;
		   	segments[6] = 0;
			end
	4'b0100: begin
			segments[0] = 1;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 1;
		   	segments[4] = 1;
		   	segments[5] = 0;
		   	segments[6] = 0;
			end
	4'b0101: begin
			segments[0] = 0;
		   	segments[1] = 1;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 1;
		   	segments[5] = 0;
		   	segments[6] = 0;
			end 
	4'b0110: begin
			segments[0] = 0;
		   	segments[1] = 1;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0;
			end	 
	4'b0111: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 1;
		   	segments[4] = 1;
		   	segments[5] = 1;
		   	segments[6] = 1; 
			end
	4'b1000: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end
	4'b1001: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 1;
		   	segments[4] = 1;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end		
	4'b1010: begin
			segments[0] = 0;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 1;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end		
	4'b1011: begin
			segments[0] = 1;
		   	segments[1] = 1;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end		
	4'b1100: begin
			segments[0] = 0;
		   	segments[1] = 1;
		   	segments[2] = 1;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 1; 
			end		
	4'b1101: begin
			segments[0] = 1;
		   	segments[1] = 0;
		   	segments[2] = 0;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 1;
		   	segments[6] = 0; 
			end		
	4'b1110: begin
			segments[0] = 0;
		   	segments[1] = 1;
		   	segments[2] = 1;
		   	segments[3] = 0;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end		
	4'b1111: begin
			segments[0] = 0;
		   	segments[1] = 1;
		   	segments[2] = 1;
		   	segments[3] = 1;
		   	segments[4] = 0;
		   	segments[5] = 0;
		   	segments[6] = 0; 
			end				
   default: begin
   			segments[0] = 1;
		   	segments[1] = 1;
		   	segments[2] = 1;
		   	segments[3] = 1;
		   	segments[4] = 1;
		   	segments[5] = 1;
		   	segments[6] = 1;
			end	
	endcase
end
endmodule


module driver7segDec (
  input logic [7:0] numIn,
  output logic [6:0] segment0, segment1
);
always_comb begin
case (numIn) 
	8'd0: begin
		segment0 = 8'h7f;
		segment1 = 8'h40;
	end
	8'd1: begin
		segment0 = 8'h7f;
		segment1 = 8'h79;
	end
	8'd2: begin
		segment0 = 8'h7f;
		segment1 = 8'h24;
	end
	8'd3: begin
		segment0 = 8'h7f;
		segment1 = 8'h30;
	end
	8'd4: begin
		segment0 = 8'h7f;
		segment1 = 8'h19;
	end
	8'd5: begin
		segment0 = 8'h7f;
		segment1 = 8'h12;
	end
	8'd6: begin
		segment0 = 8'h7f;
		segment1 = 8'h02;
	end
	8'd7: begin
		segment0 = 8'h7f;
		segment1 = 8'h78;
	end
	8'd8: begin
		segment0 = 8'h7f;
		segment1 = 8'h00;
	end
	8'd9: begin
		segment0 = 8'h7f;
		segment1 = 8'h18;
	end
	8'd10: begin
		segment0 = 8'h79;
		segment1 = 8'h40;
	end
	8'd11: begin
		segment0 = 8'h79;
		segment1 = 8'h79;
	end
	8'd12: begin
		segment0 = 8'h79;
		segment1 = 8'h24;
	end
	8'd13: begin
		segment0 = 8'h79;
		segment1 = 8'h30;
	end
	8'd14: begin
		segment0 = 8'h79;
		segment1 = 8'h19;
	end
	8'd15: begin
		segment0 = 8'h79;
		segment1 = 8'h12;
	end
	8'd16: begin
		segment0 = 8'h79;
		segment1 = 8'h02;
	end
	8'd17: begin
		segment0 = 8'h79;
		segment1 = 8'h78;
	end
	8'd18: begin
		segment0 = 8'h79;
		segment1 = 8'h00;
	end
	8'd19: begin
		segment0 = 8'h79;
		segment1 = 8'h18;
	end
	8'd20: begin
		segment0 = 8'h24;
		segment1 = 8'h40;
	end
	8'd21: begin
		segment0 = 8'h24;
		segment1 = 8'h79;
	end
	8'd22: begin
		segment0 = 8'h24;
		segment1 = 8'h24;
	end
	8'd23: begin
		segment0 = 8'h24;
		segment1 = 8'h30;
	end
	8'd24: begin
		segment0 = 8'h24;
		segment1 = 8'h19;
	end
	8'd25: begin
		segment0 = 8'h24;
		segment1 = 8'h12;
	end
	8'd26: begin
		segment0 = 8'h24;
		segment1 = 8'h02;
	end
	8'd27: begin
		segment0 = 8'h24;
		segment1 = 8'h78;
	end
	8'd28: begin
		segment0 = 8'h24;
		segment1 = 8'h00;
	end
	8'd29: begin
		segment0 = 8'h24;
		segment1 = 8'h18;
	end
	8'd30: begin
		segment0 = 8'h30;
		segment1 = 8'h40;
	end
	8'd31: begin
		segment0 = 8'h30;
		segment1 = 8'h79;
	end
	8'd32: begin
		segment0 = 8'h30;
		segment1 = 8'h24;
	end
	8'd33: begin
		segment0 = 8'h30;
		segment1 = 8'h30;
	end
	8'd34: begin
		segment0 = 8'h30;
		segment1 = 8'h19;
	end
	8'd35: begin
		segment0 = 8'h30;
		segment1 = 8'h12;
	end
	8'd36: begin
		segment0 = 8'h30;
		segment1 = 8'h02;
	end
	8'd37: begin
		segment0 = 8'h30;
		segment1 = 8'h78;
	end
	8'd38: begin
		segment0 = 8'h30;
		segment1 = 8'h00;
	end
	8'd39: begin
		segment0 = 8'h30;
		segment1 = 8'h18;
	end
	8'd40: begin
		segment0 = 8'h19;
		segment1 = 8'h40;
	end
	8'd41: begin
		segment0 = 8'h19;
		segment1 = 8'h79;
	end
	8'd42: begin
		segment0 = 8'h19;
		segment1 = 8'h24;
	end
	8'd43: begin
		segment0 = 8'h19;
		segment1 = 8'h30;
	end
	8'd44: begin
		segment0 = 8'h19;
		segment1 = 8'h19;
	end
	8'd45: begin
		segment0 = 8'h19;
		segment1 = 8'h12;
	end
	8'd46: begin
		segment0 = 8'h19;
		segment1 = 8'h02;
	end
	8'd47: begin
		segment0 = 8'h19;
		segment1 = 8'h78;
	end
	8'd48: begin
		segment0 = 8'h19;
		segment1 = 8'h00;
	end
	8'd49: begin
		segment0 = 8'h19;
		segment1 = 8'h18;
	end
	8'd50: begin
		segment0 = 8'h12;
		segment1 = 8'h40;
	end
	8'd51: begin
		segment0 = 8'h12;
		segment1 = 8'h79;
	end
	8'd52: begin
		segment0 = 8'h12;
		segment1 = 8'h24;
	end
	8'd53: begin
		segment0 = 8'h12;
		segment1 = 8'h30;
	end
	8'd54: begin
		segment0 = 8'h12;
		segment1 = 8'h19;
	end
	8'd55: begin
		segment0 = 8'h12;
		segment1 = 8'h12;
	end
	8'd56: begin
		segment0 = 8'h12;
		segment1 = 8'h02;
	end
	8'd57: begin
		segment0 = 8'h12;
		segment1 = 8'h78;
	end
	8'd58: begin
		segment0 = 8'h12;
		segment1 = 8'h00;
	end
	8'd59: begin
		segment0 = 8'h12;
		segment1 = 8'h18;
	end
	8'd60: begin
		segment0 = 8'h02;
		segment1 = 8'h40;
	end
	8'd61: begin
		segment0 = 8'h02;
		segment1 = 8'h79;
	end
	8'd62: begin
		segment0 = 8'h02;
		segment1 = 8'h24;
	end
	8'd63: begin
		segment0 = 8'h02;
		segment1 = 8'h30;
	end
	8'd64: begin
		segment0 = 8'h02;
		segment1 = 8'h19;
	end
	8'd65: begin
		segment0 = 8'h02;
		segment1 = 8'h12;
	end
	8'd66: begin
		segment0 = 8'h02;
		segment1 = 8'h02;
	end
	8'd67: begin
		segment0 = 8'h02;
		segment1 = 8'h78;
	end
	8'd68: begin
		segment0 = 8'h02;
		segment1 = 8'h00;
	end
	8'd69: begin
		segment0 = 8'h02;
		segment1 = 8'h18;
	end
	8'd70: begin
		segment0 = 8'h78;
		segment1 = 8'h40;
	end
	8'd71: begin
		segment0 = 8'h78;
		segment1 = 8'h79;
	end
	8'd72: begin
		segment0 = 8'h78;
		segment1 = 8'h24;
	end
	8'd73: begin
		segment0 = 8'h78;
		segment1 = 8'h30;
	end
	8'd74: begin
		segment0 = 8'h78;
		segment1 = 8'h19;
	end
	8'd75: begin
		segment0 = 8'h78;
		segment1 = 8'h12;
	end
	8'd76: begin
		segment0 = 8'h78;
		segment1 = 8'h02;
	end
	8'd77: begin
		segment0 = 8'h78;
		segment1 = 8'h78;
	end
	8'd78: begin
		segment0 = 8'h78;
		segment1 = 8'h00;
	end
	8'd79: begin
		segment0 = 8'h78;
		segment1 = 8'h18;
	end
	8'd80: begin
		segment0 = 8'h00;
		segment1 = 8'h40;
	end
	8'd81: begin
		segment0 = 8'h00;
		segment1 = 8'h79;
	end
	8'd82: begin
		segment1 = 8'h24;
		segment0 = 8'h00;
	end
	8'd83: begin
		segment0 = 8'h00;
		segment1 = 8'h30;
	end
	8'd84: begin
		segment0 = 8'h00;
		segment1 = 8'h19;
	end
	8'd85: begin
		segment0 = 8'h00;
		segment1 = 8'h12;
	end
	8'd86: begin
		segment0 = 8'h00;
		segment1 = 8'h02;
	end
	8'd87: begin
		segment0 = 8'h00;
		segment1 = 8'h78;
	end
	8'd88: begin
		segment0 = 8'h00;
		segment1 = 8'h00;
	end
	8'd89: begin
		segment0 = 8'h00;
		segment1 = 8'h18;
	end
	8'd90: begin
		segment0 = 8'h18;
		segment1 = 8'h40;
	end
	8'd91: begin
		segment0 = 8'h18;
		segment1 = 8'h79;
	end
	8'd92: begin
		segment0 = 8'h18;
		segment1 = 8'h24;
	end
	8'd93: begin
		segment0 = 8'h18;
		segment1 = 8'h30;
	end
	8'd94: begin
		segment0 = 8'h18;
		segment1 = 8'h19;
	end
	8'd95: begin
		segment0 = 8'h18;
		segment1 = 8'h12;
	end
	8'd96: begin
		segment0 = 8'h18;
		segment1 = 8'h02;
	end
	8'd97: begin
		segment0 = 8'h18;
		segment1 = 8'h78;
	end
	8'd98: begin
		segment0 = 8'h18;
		segment1 = 8'h00;
	end
	8'd99: begin
		segment0 = 8'h18;
		segment1 = 8'h18;
	end


	
   default: begin
      	segment0 = 8'h7f;
		segment1 = 8'h40;
      end 
  endcase
end
endmodule