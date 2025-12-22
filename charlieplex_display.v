/*
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

`ifndef __vbb__charlieplex_display_v__
`define __vbb__charlieplex_display_v__

`default_nettype none

`include "charlieplexer.v"

/* Fully addressable display of PIXELCOUNT pixels
 * that shows the image using a charlieplexer.
 *
 * pixelclock: clock at which individual pixels are multiplexed
 * enable:     global enable flag for display
 * pixelstate: display state to show
 * out_en:     flags indicating that an output shall be driven instead of tristated
 * out_value:  values for non-tristated outputs (0=GND, 1=VCC)
 */
module charlieplex_display(
	input  wire pixelclock,
	input  wire enable,
	input  wire [PIXELCOUNT-1:0] pixelstate,
	output wire [PINCOUNT-1:0] out_en,
	output wire [PINCOUNT-1:0] out_value);

	parameter PIXELCOUNT = 12;
	localparam PINCOUNT = $rtoi($ceil( (1.0 + $sqrt(1.0 + 4.0 * PIXELCOUNT)) / 2 ));
	localparam INDEXBITS = $clog2(PIXELCOUNT+1);

	reg [INDEXBITS-1:0] current_pixel = 0;
	reg [PIXELCOUNT-1:0] nextstate = 0;
	always @(posedge pixelclock) begin
		if(current_pixel >= PIXELCOUNT-1) begin
			current_pixel <= 0;
			nextstate <= pixelstate;
		end else begin
			current_pixel <= current_pixel + 1;
			nextstate <= {1'b0, nextstate[PIXELCOUNT-1:1]};
		end
	end

	wire current_pixel_on = enable & nextstate[0];

	charlieplexer #(.PINCOUNT(PINCOUNT)) plexer(
		.in(current_pixel),
		.enable(current_pixel_on),
		.out_en(out_en),
		.out_value(out_value));
endmodule

`endif // __vbb__charlieplex_display_v__
