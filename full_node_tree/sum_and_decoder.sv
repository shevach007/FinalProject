module Decoder #(parameter N_of_numbers = 8, N_of_bits = 5) (
    
    input wire [N_of_bits-1:0] numbers [N_of_numbers-1:0], // Input array
    input wire en,                                     // Enable signal
    output wire [N_of_numbers*(2**N_of_bits)-1:0] y                   // Output (vector of zeros except one place with 1)
);

    localparam total_rows = N_of_numbers*(2**N_of_bits);
    // Internal signals
    reg [N_of_bits+$clog2(N_of_numbers)-1:0] sum; // Adjusted sum width (log2(largest_value*N_of_numbers) = 
												  // = log2(largest_value) + log2(N_of_numbers)
                                                  // = N_of_bits + log2(N_of_numbers)
	integer i;

    // Combinational process to calculate the sum
    always @* begin
        sum = 0; // Initialize the sum to 0
        if (en) begin
            // Add all input numbers
            for (i = 0; i < N_of_numbers; i = i + 1) begin
                sum = sum + numbers[i];
            end
        end
    end

    // Generate the decoded output
    assign y = en ? (1 << sum) : 0;

endmodule