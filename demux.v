`default_nettype none

// demuxer module. NOTE: UNTESTED AND NEVER USED SO FAR.
module demux(input wire [INPUT_WIDTH-1:0] in, output wire [OUTPUT_WIDTH-1:0] out);
	parameter OUTPUT_WIDTH = 'd3;

	localparam INPUT_WIDTH = $clog2(OUTPUT_WIDTH);

	genvar i;
	generate
		for(i = 0; i < OUTPUT_WIDTH; i++) begin
			assign out[i] = (in == i);
		end
	endgenerate
endmodule

