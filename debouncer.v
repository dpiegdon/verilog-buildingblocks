`default_nettype none

// input debouncer.
// if CLOCKED_EDGE_OUT, it yields a rising edge in out to
// indicate a button press and nothing when the button is released.
// if not CLOCKED_EDGE_OUT, it yields the debounced value of the input.
module debouncer(
	input wire clk,
	input wire in,
	output reg out = 0);

	parameter DEBOUNCE_CYCLES = 1000;
	parameter CLOCKED_EDGE_OUT = 0;

	reg old = 0;
	reg new = 0;
	reg running = 0;
	reg [$clog2(DEBOUNCE_CYCLES+1)-1 : 0] decay = 0;

	always @(posedge clk) begin
		if(new != in) begin
			running <= 1;
			decay <= 0;
		end else begin
			if(running) begin
				decay <= decay - 1;
				if(decay == 0) begin
					running <= 0;
					out <= in;
				end else begin
					if(CLOCKED_EDGE_OUT == 0) begin
						out <= 0;
					end
				end
			end else begin
				if(CLOCKED_EDGE_OUT == 0) begin
					out <= 0;
				end
			end
		end

		old <= new;
		new <= in;
	end

endmodule

