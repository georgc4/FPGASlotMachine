module machine(input CLOCK_50,
				input [3:0] KEY,
				inout PS2_CLK, PS2_DAT,
				output [6:0] seg1, seg2, seg3, betSeg0, betSeg1,
				output light
				);

logic leftButton, middleButton, rightButton, buttonPressed, upOrDown;
logic [3:0] bet;
logic [7:0] credits;
logic [11:0] randomCount;
logic [11:0] reels;
mouseControl mouseIn(.*);
upDown12bit randomCounter(.clk (CLOCK_50), .upDown (1), .rstN (KEY[0]), .cnt (randomCount[11:0]));
upDown12bit betCounter(.clk(buttonPressed), .upDown(upOrDown), .rstN (KEY[0]), .cnt(bet[3:0]));
driver7seg seg1Get(.numIn (reels[11:8]), .segments (seg1[6:0]));
driver7seg seg2Get(.numIn (reels[7:4]), .segments (seg2[6:0]));
driver7seg seg3Get(.numIn (reels[3:0]), .segments (seg3[6:0]));
driver7segDec getBet(.numIn (bet[3:0]), .segment0 (betSeg0[6:0]), .segment1 (betSeg1[6:0]));
assign light = middleButton;

always_ff @ (posedge leftButton or posedge rightButton) begin 
	
	case ({leftButton,rightButton})
	2'b00:begin
	 buttonPressed <= 0;
	upOrDown <= 1;
end
	2'b01: begin
	upOrDown <= 1;
	buttonPressed <= 1;
	end
	2'b10:begin
	upOrDown <= 0;
   buttonPressed <=1;
	end
	2'b11: buttonPressed <=0;
		default : begin buttonPressed <= 0;
					upOrDown <= 1;
				end
	endcase
	end

always_ff @ (posedge middleButton) begin

	reels <= randomCount;

end

endmodule


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
  input logic [3:0] numIn,
   output logic [6:0] segment0, segment1
);
always_comb begin
case (numIn) 
  4'b0000:  begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 1;
      end
  4'b0001: begin
        segment1[0] = 1;        segment0[0] = 1;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 1;
            end
  4'b0010: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 1;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 0;
      end 
  4'b0011: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 0;
      end
  4'b0100: begin
        segment1[0] = 1;        segment0[0] = 1;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0;
      end
  4'b0101: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 1;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0;
      end 
  4'b0110: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 1;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0;
      end  
  4'b0111: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 1;
      end
  4'b1000: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0; 
      end
  4'b1001: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 1;        segment0[1] = 0;
        segment1[2] = 1;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0; 
      end
  4'b1010: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 1; 
      end
  4'b1011: begin
        segment1[0] = 1;        segment0[0] = 1;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 1; 
      end
  4'b1100: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 1;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 0;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 0; 
      end
  4'b1101: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 1;
        segment1[6] = 1;        segment0[6] = 0; 
      end
  4'b1110: begin
        segment1[0] = 1;        segment0[0] = 1;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 1;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0; 
      end 
  4'b1111: begin
        segment1[0] = 1;        segment0[0] = 0;
        segment1[1] = 0;        segment0[1] = 1;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 1;        segment0[3] = 0;
        segment1[4] = 1;        segment0[4] = 1;
        segment1[5] = 1;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 0; 
      end                          
   default: begin
        segment1[0] = 0;        segment0[0] = 0;
        segment1[1] = 0;        segment0[1] = 0;
        segment1[2] = 0;        segment0[2] = 0;
        segment1[3] = 0;        segment0[3] = 0;
        segment1[4] = 0;        segment0[4] = 0;
        segment1[5] = 0;        segment0[5] = 0;
        segment1[6] = 1;        segment0[6] = 1;
      end 
  endcase
end
endmodule