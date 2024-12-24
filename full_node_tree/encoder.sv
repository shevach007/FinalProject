module Encoder #(parameter N_of_numbers = 8, N_of_bits = 5) (
    input wire [N_of_bits-1:0] numbers [N_of_numbers-1:0],  // Input: vector of numbers
    output wire [N_of_numbers * 2**N_of_bits - 1:0] encoded_output         // Output: flattened encoded vector
);

    localparam max_rows = N_of_numbers * 2**N_of_bits;
    integer i;
    reg [2**N_of_bits-1:0] encoded_num;    // Register for encoding each number
    reg [max_rows-1:0] temp_encoded;  // Temporary register to hold the flattened result

    always @* begin
        temp_encoded = 0;  // Reset the temporary encoded vector
        encoded_num = 0;  // Reset the temporary encoded num
        for (i = 0; i < N_of_numbers; i = i + 1) begin
            // Encode each number as x-1 zeros followed by one '1'
            encoded_num = (1 << (numbers[i] - 1));  // Create a vector with x-1 zeroes followed by one '1'

            // OR the encoded number with shifted result achieved so far
            temp_encoded = encoded_num | (temp_encoded << numbers[i]);
        end
    end

    assign encoded_output = temp_encoded;  // Output the final concatenated result

endmodule
