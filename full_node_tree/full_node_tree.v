module Full_Node_Tree #(parameter N_of_numbers = 8, N_of_bits = 5) (
    //input wire [N_of_bits-1:0] numbers [N_of_numbers-1:0],
    input wire [N_of_numbers*N_of_bits-1:0] numbers_flat,
    input wire en,
    input wire [$clog2(N_of_numbers*(2**N_of_bits))-1:0] target,
    input wire start,

    output wire busy,
    output wire done,
    output wire isTargetMet,
    output reg [N_of_numbers-1:0] subset // Added output for the subset
);
    localparam total_rows_bits = $clog2(N_of_numbers*(2**N_of_bits));
    localparam total_rows = (2**N_of_bits-1)*N_of_numbers; 
    //localparam total_rows = (2**N_of_bits)*N_of_numbers; 


    // Internal signals
    wire s [total_rows-1:0][total_rows-1:0];
    wire d [total_rows-1:0][total_rows-1:0];
    wire [total_rows-1:0] last_signals;
    wire [total_rows-1:0] control_signals;
    wire [total_rows-1:0] control;
    wire final_row_output[total_rows-1:0];
    //wire [N_of_numbers:0] done_signals;
	
    // Control signals
    reg busy_reg;
    reg done_reg;
    reg isTargetMet_reg;

    assign busy = busy_reg;
    
    assign isTargetMet = isTargetMet_reg;

    // Decoder for 'last' signal, signalling which is the last relevant line from there we will force down the signals
    wire [total_rows_bits-1:0] last_row_idx;
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

    wire [N_of_bits-1:0] numbers [N_of_numbers-1:0];
    genvar k;
    generate
        for (k = 0; k < N_of_numbers; k = k + 1) begin : row1
            assign numbers[k] = numbers_flat[k*N_of_bits +: N_of_bits];
        end
    endgenerate

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
        reg [N_of_bits-1:0] cnt_num;
        reg flag;
    always @* begin
        subset = 0; // Reset subset
        if (final_row_output[target] == 1'b1) begin
            row_b = total_rows -1;
            col_b = target;
            cnt_num = 0;
            flag = 1'b0;
            while (row_b >= 0) begin
                $display("main while row: %d, column: %d d:%b control: %b, ssp_num: %d",row_b, col_b, d[row_b][col_b],control[row_b],cnt_num);
                if(control[row_b] == 1 && cnt_num != 0)begin
                    $display("ssp_num: %d",cnt_num);
                    end
                if(control[row_b]) begin
                    cnt_num = 0;
                    //col_b = col_b - 1;
                end
                if (d[row_b][col_b]) begin
                    if ( ~(cnt_num == 0 && control[row_b] == 0))begin
                                        //$display("enter",cnt_num);

                    cnt_num = cnt_num + 1;
                    col_b = col_b - 1;
                    end
                end
                    //$display("d %b", d[row_b - 1][col_b]);
                
                row_b = row_b - 1;
                if (row_b == 0 && cnt_num != 0)
                    $display("ssp_num: %d",cnt_num);

                /*
                if (d[row_b][col_b]) begin
                    $display("row no. %d",row_b);
                    col_b = col_b - 1;
                    //row_b = row_b - 1;
                    
                    if (control_signals[row_b])
                        cnt_num = 1;
                    else begin
                    //subset[row_b] = 1; // Include this number in the subset
                    cnt_num = cnt_num + 1;
                    flag = 1'b0;
                    end
                end
                else if (flag) begin
                    $display("num ssp. %d",cnt_num);
                    flag = 1'b0;
                    cnt_num = 0;
                end
                else begin
                  flag = 1'b1;
                  //row_b = row_b - 1; // Move up one row
                end
                row_b = row_b - 1;
                */
            end
        end
    end
    always @(posedge start or posedge done) begin
        if (start) begin
            busy_reg <= 1;
            done_reg <= 0;
            //isTargetMet_reg <= 0;
        end if (done) begin
            busy_reg <= 0;

            done_reg <= 1;
            isTargetMet_reg <= final_row_output[target] == 1'b1;
            //$display("first number: %b, second number: %b, third number: %b", numbers[0], numbers[1], numbers[2]);


        end
    end

endmodule