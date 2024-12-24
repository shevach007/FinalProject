module Full_Node_Tree_tb;

    // Parameters
    parameter N_of_numbers = 5;
    parameter N_of_bits = 4;

    // Testbench signals
    logic [N_of_bits-1:0] numbers [N_of_numbers-1:0];
    logic en;
    logic [$clog2(N_of_numbers*(2**N_of_bits))-1:0] target;
    logic start;
    
    wire busy;
    wire done;
    wire isTargetMet;

    // DUT instantiation
    Full_Node_Tree #(
        .N_of_numbers(N_of_numbers),
        .N_of_bits(N_of_bits)
    ) fullNodeTree (
        .numbers(numbers),
        .en(en),
        .target(target),
        .start(start),
        .busy(busy),
        .done(done),
        .isTargetMet(isTargetMet)
    );

    // Testbench variables
    integer i;

    // Task to apply stimulus
    task automatic apply_stimulus(
        input logic [N_of_bits-1:0] nums [N_of_numbers-1:0],
        input logic enable,
        input logic [$clog2(N_of_numbers*(2**N_of_bits))-1:0] tgt,
        input logic strt
    );
        begin
            for (i = 0; i < N_of_numbers; i = i + 1) begin
                numbers[i] = nums[i];
            end
            en = enable;
            target = tgt;
            start = strt;
            #10; // Short pulse for the start signal
            start = 0;
            #5;
        end
    endtask

    // Task to verify results
    task automatic verify_target(
        input logic expected_isTargetMet
    );
        begin
            $display("start verification...");
            // Wait for 'done' to be high
            wait (done == 1);
            if (isTargetMet !== expected_isTargetMet)
                $error("Test failed: Expected isTargetMet=%0b, got %0b", expected_isTargetMet, isTargetMet);
            else
                $display("Test passed: isTargetMet=%0b", isTargetMet);             
        end
    endtask

    // Test sequences
    initial begin
        $display("Starting simulation...");
        #1; // Ensure at least 1 time unit is simulated
        
        // Initialize signals
        en = 0;
        start = 0;
        target = 0;
        for (i = 0; i < N_of_numbers; i = i + 1) begin
            numbers[i] = 0;
        end

        // Apply stimulus and verify results
        $display("Starting Test 1:");
        //apply_stimulus('{5'd5, 5'd3, 5'd6, 5'd10, 5'd7}, 1, 5'd27, 1); //fails
        apply_stimulus('{5'd5, 5'd3, 5'd6, 5'd10, 5'd7}, 1, 5'd19, 1); // succeeds
        verify_target(1);

        /*
        $display("Starting Test 2: Target is not supposed to be met");
        //apply_stimulus('{5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0}, 1, 10'b0000000001, 1);
        apply_stimulus('{5'd4, 5'd6, 5'd12, 5'd14, 5'd8}, 1, 5'd11, 1);
        verify_target(0);
        
    
        $display("Starting Test 3: Edge case - Large numbers");
        apply_stimulus('{5'd15, 5'd15, 5'd15, 5'd15, 5'd15, 5'd15, 5'd15, 5'd15}, 1, 10'b1000000000, 1);
        verify_target(1);
        */  

        // End simulation
        $display("Testbench completed");
        $finish;
    end

endmodule
