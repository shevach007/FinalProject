module Full_Node_Tree #(parameter N_of_numbers = 8, N_of_bits = 5) (
    //input wire [N_of_bits-1:0] numbers [N_of_numbers-1:0],
    input wire [N_of_numbers*N_of_bits-1:0] numbers_flat,
    input wire en,
    input wire [$clog2(N_of_numbers*(2**N_of_bits))-1:0] target,
    input wire start,

    output reg busy,
    output wire done, // Variable that indicated that we finished traversing the nodes
    output reg isTargetMet,
    output reg [N_of_numbers-1:0] subset // Added output for the subset
);
    //localparam total_rows_bits = $clog2(N_of_numbers*(2**N_of_bits));
    //localparam total_rows = (2**N_of_bits-1)*N_of_numbers; 
    //localparam total_rows = (2**N_of_bits)*N_of_numbers; 

localparam rows_per_input = (2**N_of_bits - 1);
localparam total_rows = rows_per_input * N_of_numbers;
localparam total_rows_bits = $clog2(total_rows);
    // Internal signals
    wire s [total_rows-1:0][total_rows-1:0];
    wire d [total_rows-1:0][total_rows-1:0];
    wire [total_rows-1:0] last_signals;
    wire [total_rows-1:0] control_signals;
    wire [total_rows-1:0] control; // later used to determine the subsets
    wire final_row_output[total_rows-1:0];


    // Decoder for 'last' signal, signalling which is the last relevant line from there we will force down the signals
    Decoder #(N_of_numbers, N_of_bits) decoder (
        .numbers_flat(numbers_flat),
        .en(en),
        .y(last_signals)
    );

  // Encoder to build a vector for the 'control' signals
    Encoder #(N_of_numbers, N_of_bits) encoder (
        .numbers_flat(numbers_flat),
        .encoded_output(control_signals)
    );
    /* ----We dont use this 'numbers' signal here-----
    wire [N_of_bits-1:0] numbers [N_of_numbers-1:0]; // Unflatted the numbers
    genvar k;
    generate
        for (k = 0; k < N_of_numbers; k = k + 1) begin : row1
            assign numbers[k] = numbers_flat[k*N_of_bits +: N_of_bits];
        end
    endgenerate
    */
    
    // Generate the tree structure
    genvar i, j;
  
    generate
        for (i = 0; i < total_rows; i = i + 1) begin: row
            for (j = 0; j <= i; j = j + 1) begin: col
              if (i == 0 && j == 0) begin
                  //top node 
                  startNode top_node(
                    .init(start),
                    .s_next(s[1][0]),
                    .d_next(d[1][1])
                  );
              end else if (j == 0 && i != total_rows-1) begin
                  LeftDownNode left_node (
                    .s(s[i][j]),
                    .control(control_signals[i-1]),
                    .last(last_signals[i]),
                    .s_next(s[i+1][j]),
                    .d_next(d[i+1][j+1])
                  );
              end else if (j == 0 && i == total_rows-1) begin
                  LeftDownNode left_node (
                    .s(s[total_rows-1][0]),
                    .control(control_signals[i-1]),
                    .last(last_signals[total_rows-1]),
                    .s_next(final_row_output[0])
                    //.d_next(d[i+1][j+1])
                  );
              end else if (j < i && i != total_rows-1) begin
                  GeneralNode general_node (
                    .s(s[i][j]),
                    .d(d[i][j]),
                    .control(control_signals[i-1]),
                    .last(last_signals[i]),
                    .s_next(s[i+1][j]),
                    .d_next(d[i+1][j+1])
                  );
              end else if (j < i && i == total_rows-1) begin
                  GeneralNode general_node (
                    .s(s[total_rows-1][j]),
                    .d(d[total_rows-1][j]),
                    .control(control_signals[i-1]),
                    .last(last_signals[total_rows-1]),
                    .s_next(final_row_output[j])
                    //.d_next(d[i+1][j+1])
                  );
              end else if (j == i && i != total_rows-1) begin
                  RightDiagonalNode right_node (
                      .d(d[i][j]),
                      .control(control_signals[i-1]),
                      .last(last_signals[i]),
                      .s_next(s[i+1][j]),
                      .d_next(d[i+1][j+1])
                  );
              end else begin
                  RightDiagonalNode right_node (
                    .d(d[total_rows-1][total_rows-1]),
                    .control(control_signals[i-1]),
                    .last(last_signals[total_rows-1]),
                    .s_next(final_row_output[total_rows-1])
                    //.d_next(d[i+1][j+1])
                  );
              end 
            end
        end
    endgenerate
    assign done = final_row_output[0];
    assign control = {control_signals[total_rows-2:0], 1'b0}; //for better integration with the first node 
        assign d[0][0] = 1;

  //assign isTargetMet = (done == 1'b1 && row[total_rows-1].col[target].general_node.s_next == 1)? 1'b1 : 1'b0;
  //assign isTargetMet = (done == 1'b1 && final_row_output[target] == 1'b1) ? 1'b1 : 1'b0;
  //assign isTargetMet = isTargetMet_reg;
    
    // Manage signals for busy, done, and isTargetMet
        integer row_b, col_b;
        reg[N_of_bits-1:0] diag_cnt;
        reg[N_of_bits-1:0] cnt_num;
    always @* begin
        diag_cnt = 0;
        subset = 0; // Reset subset
        row_b = total_rows -1;
        col_b = target;
        cnt_num = 0;
        if (final_row_output[target] == 1'b1) begin
            
            for (row_b = total_rows - 1; row_b >= 0; row_b = row_b - 1) begin
                //$display("main while row: %d, column: %d d:%b control: %b, ssp_num: %d",row_b, col_b, d[row_b][col_b],control[row_b],cnt_num);
                if(control[row_b] == 1 && cnt_num != 0)begin // if met, we have a new number that's part of the ssp
                    $display("ssp_num: %d",cnt_num);
                
                    end
                if(control[row_b]) begin // reset the number
                    cnt_num = 0;
                    if (d[row_b][col_b]) begin
                        subset[diag_cnt] = 1;
                    end
                    else begin
                        subset[diag_cnt] = 0;
                    end
                    diag_cnt = diag_cnt + 1;
                end
                if (d[row_b][col_b]) begin
                
                    if ( ~(cnt_num == 0 && control[row_b] == 0))begin //to stay on track of our original path

                        cnt_num = cnt_num + 1;
                        col_b = col_b - 1; //move diagonally 
                    end
                end
                    //$display("d %b", d[row_b - 1][col_b]);
                
                //row_b = row_b - 1;
                if (row_b == 0 && cnt_num != 0)begin
                    $display("ssp_num: %d",cnt_num); // initial path we took from the tip of the triangle
                end
            end
        end
        
    end
    always @(posedge start or posedge done) begin
            busy <= 0;
            isTargetMet <= 0;
        if (start) begin
            busy <= 1;
        end if (done) begin
            isTargetMet <= final_row_output[target] == 1'b1;
        end
        
    end

endmodule