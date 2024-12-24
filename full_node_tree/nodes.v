
module LeftDownNode(
	input wire s,
	input wire control,
	input wire last,
	
	output wire s_next,
	output wire d_next
	);
  assign s_next = s; // always go down
  assign d_next = s & control & ~last;
endmodule



module GeneralNode(
   	input wire s, 		// straight line input
	input wire d, 		// diagonal line input
	input wire control, // decides whether to split the signal ('1') or just pass it ('0')
	input wire last, 	// decides if to force the signal down ('1') or not ('0') 
	
	output wire s_next, 	// straight forwarded signal
	output wire d_next	// diagonal forwarded signal
	);
	
  assign s_next = (d & control) | (d & last) | s;
  assign d_next = (~last & control & s) | (~last & d);
endmodule 



module RightDiagonalNode(
	input wire d,
	input wire control,
	input wire last,
	
	output wire s_next,
	output wire d_next
	);
  assign d_next = d & ~last;
  assign s_next = (control & last) | (d & last) | (d & control);
endmodule



module startNode (
    input wire init,
    output reg s_next, 
    output reg d_next
);

    // Process to handle initialization
    always @(posedge init) begin
        if (init) begin
			s_next <= 1'b1; // Set straight output
        	d_next <= 1'b1; // Set diagonal output
		end
    end

endmodule