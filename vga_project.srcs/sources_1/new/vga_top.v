`timescale 1ns / 1ps

module vh_sync (
	input wire clk,
	input wire clr,
	input wire en,
	input [11:0] sw,
	output a,
	output b,
	output c,
	output d,
	output e,
	output f,
	output g,
	output dp,
	output wire hsync,
	output wire vsync,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue,
    output reg [11:0] led,
    output [7:0] an
	);
	
parameter hpixels = 800;
parameter vlines = 521;
parameter hpulse = 96;
parameter vpulse = 2;
parameter hbp = 144;
parameter hfp = 784;
parameter vbp = 31;
parameter vfp = 511;

reg [9:0] hc;
reg [9:0] vc;

reg [3:0] first;
reg [3:0] second;
reg [3:0] third;
reg [3:0] sixth;
reg [4:0] seventh;
reg [4:0] eigth;

reg [28:0] count;
reg [11:0] counter;
wire tick;

reg [1:0] pxclk;

always @ (posedge clk)
begin
	pxclk = pxclk + 1;
	segcount = segcount + 1;
	if (count == 1000000)
	   count <= 0;
    else
       count <= count + 1;
end    

assign tick = (count == 1000000) ? 1:0;

always @ (posedge tick)
begin
    if (counter == 12'b111111111111)
        counter <= 0;
    else if (en)
        counter <= counter;
    else
        counter <= counter + 1;
end

reg [3:0] redcount;
reg [3:0] greencount;
reg [3:0] bluecount;

always @ (*)
begin
	first <= bluecount;
	second <= greencount;
	third <= redcount;
	sixth <= 11; // B
	seventh <= 16; //G
	eigth <= 17; // R
end

localparam N = 18;

reg [N-1:0] segcount;
reg [6:0] sseg;
reg [7:0] an_temp;

always @ (*)
begin
	case(segcount[N-1:N-3])
		3'b000:
			begin
				sseg = first;
				an_temp = 8'b11111110;
			end
		3'b001:
			begin
				sseg = second;
				an_temp = 8'b11111101;
			end
		3'b010:
			begin
				sseg = third;
				an_temp = 8'b11111011;
			end
		3'b011:
			begin
				sseg = sixth;
				an_temp = 8'b11011111;
			end
		3'b100:
			begin
				sseg = seventh;
				an_temp = 8'b10111111;
			end
		3'b101:
			begin
				sseg = eigth;
				an_temp = 8'b01111111;
			end
        default: an_temp = 8'b11111111;
	endcase
end

assign an = an_temp;

reg [6:0] sseg_temp;

always @ (*) begin
	case(sseg)
		0 : sseg_temp = 7'b1000000; //0
		1 : sseg_temp = 7'b1111001; //1
		2 : sseg_temp = 7'b0100100; //2
		3 : sseg_temp = 7'b0110000; //3
		4 : sseg_temp = 7'b0011001; //4
		5 : sseg_temp = 7'b0010010; //5
		6 : sseg_temp = 7'b0000010; //6
		7 : sseg_temp = 7'b1111000; //7
		8 : sseg_temp = 7'b0000000; //8
		9 : sseg_temp = 7'b0011000; //9
		10: sseg_temp = 7'b0001000; //A
		11: sseg_temp = 7'b0000011; //B
		12: sseg_temp = 7'b1000110; //C
		13: sseg_temp = 7'b0100001; //D
		14: sseg_temp = 7'b0000110; //E
		15: sseg_temp = 7'b0001110; //F
		16: sseg_temp = 7'b0010000; //G
		17: sseg_temp = 7'b0101111; //R
		default : sseg_temp = 7'b0111111; //dash
	endcase
end

assign {g, f, e, d, c, b, a} = sseg_temp;
assign dp = 1'b1;

always @ (counter)
begin
    if (en)
    begin
        led = sw;
        redcount[0] = sw[0];
        redcount[1] = sw[1];
        redcount[2] = sw[2];
        redcount[3] = sw[3];
        greencount[0] = sw[4];
        greencount[1] = sw[5];
        greencount[2] = sw[6];
        greencount[3] = sw[7];
        bluecount[0] = sw[8];
        bluecount[1] = sw[9];
        bluecount[2] = sw[10];
        bluecount[3] = sw[11];
    end
    else
    begin
        led = counter;
        redcount[0] = counter[0];
        redcount[1] = counter[5];
        redcount[2] = counter[6];
        redcount[3] = counter[11];
        greencount[0] = counter[1];
        greencount[1] = counter[4];
        greencount[2] = counter[7];
        greencount[3] = counter[10];
        bluecount[0] = counter[2];
        bluecount[1] = counter[3];
        bluecount[2] = counter[8];
        bluecount[3] = counter[9];
    end
end

wire pclk;

assign pclk = pxclk[1];

always @ (posedge pclk or posedge clr)
begin
	if (clr == 1)
	begin
		hc <= 0;
		vc <= 0;
	end
	else
	begin
		if (hc < hpixels - 1)
			hc <= hc + 1;
		else
		begin
			hc <= 0;
			if (vc < vlines - 1)
				vc <= vc + 1;
			else
				vc <= 0;
		end
	end
end

assign hsync = (hc < hpulse) ? 0:1;
assign vsync = (vc < vpulse) ? 0:1;

always @ (*)
begin
    if (vc >= vbp && vc < vfp)
    begin
        if (en)
        begin
            if (vc >= (vbp + 100) && vc < (vfp - 100))
                begin
                if (vc >= (vbp + 411 - (redcount * 15)) && hc >= (hbp + 120) && hc < (hbp + 140))
                begin
                    red = 4'b1111;
                    green = 4'b0000;
                    blue = 4'b0000;
                end
                else if (vc >= (vbp + 411 - (greencount * 15)) && hc >= (hbp + 150) && hc < (hbp + 170))
                begin
                    red = 4'b0000;
                    green = 4'b1111;
                    blue = 4'b0000;
                end
                else if (vc >= (vbp + 411 - (bluecount * 15)) && hc >= (hbp + 180) && hc < (hbp + 200))
                begin
                    red = 4'b0000;
                    green = 4'b0000;
                    blue = 4'b1111;
                end
                else if (vc >= (vbp + 200) && vc < (vbp + 300) && hc >= (hbp + 300) && hc < (hbp + 400))
                begin
                    red[0] = sw[0];
                    red[1] = sw[1];
                    red[2] = sw[2];
                    red[3] = sw[3];
                    green[0] = sw[4];
                    green[1] = sw[5];
                    green[2] = sw[6];
                    green[3] = sw[7];
                    blue[0] = sw[8];
                    blue[1] = sw[9];
                    blue[2] = sw[10];
                    blue[3] = sw[11];
                end
                else if (hc >= (hbp + 100) && hc < (hbp + 105))
                begin
                    red = 4'b1111;
                    green = 4'b1111;
                    blue = 4'b1111;
                end
                else
                begin
                    red = 0;
                    green = 0;
                    blue = 0;
                end
            end
            else if (vc >= (vfp - 100) && vc < (vfp - 95) && hc >= (hbp + 100) && hc < (hbp + 500))
            begin
                red = 4'b1111;
                green = 4'b1111;
                blue = 4'b1111;
            end
            else
            begin
                red = 0;
                green = 0;
                blue = 0;
            end
        end
        else
        begin
            if (vc >= (vbp + 100) && vc < (vfp - 100))
            begin
                if (vc >= (vbp + 411 - (redcount * 15)) && hc >= (hbp + 120) && hc < (hbp + 140))
                begin
                    red = 4'b1111;
                    green = 4'b0000;
                    blue = 4'b0000;
                end
                else if (vc >= (vbp + 411 - (greencount * 15)) && hc >= (hbp + 150) && hc < (hbp + 170))
                begin
                    red = 4'b0000;
                    green = 4'b1111;
                    blue = 4'b0000;
                end
                else if (vc >= (vbp + 411 - (bluecount * 15)) && hc >= (hbp + 180) && hc < (hbp + 200))
                begin
                    red = 4'b0000;
                    green = 4'b0000;
                    blue = 4'b1111;
                end
                else if (vc >= (vbp + 200) && vc < (vbp + 300) && hc >= (hbp + 300) && hc < (hbp + 400))
                begin
                    red[0] = counter[0];
                    red[1] = counter[5];
                    red[2] = counter[6];
                    red[3] = counter[11];
                    green[0] = counter[1];
                    green[1] = counter[4];
                    green[2] = counter[7];
                    green[3] = counter[10];
                    blue[0] = counter[2];
                    blue[1] = counter[3];
                    blue[2] = counter[8];
                    blue[3] = counter[9];
                end
                else if (hc >= (hbp + 100) && hc < (hbp + 105))
                begin
                    red = 4'b1111;
                    green = 4'b1111;
                    blue = 4'b1111;
                end
                else
                begin
                    red = 0;
                    green = 0;
                    blue = 0;
                end
            end
            else if (vc >= (vfp - 100) && vc < (vfp - 95) && hc >= (hbp + 100) && hc < (hbp + 500))
            begin
                red = 4'b1111;
                green = 4'b1111;
                blue = 4'b1111;
            end
            else
            begin
                red = 0;
                green = 0;
                blue = 0;
            end
        end
    end
    else
    begin
        red = 0;
        green = 0;
        blue = 0;
    end
end

endmodule