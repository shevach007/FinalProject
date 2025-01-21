module Full_Node_Tree_tb;

    // Parameters
    parameter N_of_numbers = 3;
    parameter N_of_bits = 4;

    // Testbench signals
    reg [N_of_bits*N_of_numbers-1:0] numbers;
    reg en;
    reg [$clog2(N_of_numbers*(2**N_of_bits-1)):0] target;
    //reg [$clog2(N_of_numbers*(2**N_of_bits))-1:0] target;

    reg start;
    
    wire busy;
    wire done;
    wire isTargetMet;
    

    // DUT instantiation
    Full_Node_Tree #(
        .N_of_numbers(N_of_numbers),
        .N_of_bits(N_of_bits)
    ) fullNodeTree (
        .numbers_flat(numbers),
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
        input reg [N_of_bits*N_of_numbers-1:0] nums,
        input reg enable,
        input reg [$clog2(N_of_numbers*(2**N_of_bits))-1:0] tgt,
        input reg strt
    );
        begin
            for (i = 0; i < N_of_numbers; i = i + 1) begin
                numbers[i*N_of_bits +: N_of_bits] = nums[i*N_of_bits +: N_of_bits];
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
        input reg expected_isTargetMet
    );
        begin
            $display("start verification...");
            // Wait for 'done' to be high
            wait (done == 1);
            if (isTargetMet !== expected_isTargetMet)
                $display("Test failed: Expected isTargetMet=%0b, got %0b", expected_isTargetMet, isTargetMet);
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
            numbers[i*N_of_bits +: N_of_bits] = 0;
        end

        // Apply stimulus and verify results
        //$display("Starting Test 1:");
        //apply_stimulus({4'd5, 4'd3, 4'd6, 4'd10, 4'd7}, 1, 5'd27, 1); //fails
        //apply_stimulus({4'd2, 4'd5, 4'd9}, 1, 5'd14, 1); // succeeds
        //verify_target(1);

         $display("Starting Test 2:");
         apply_stimulus({4'd4, 4'd6, 4'd12, 4'd14, 4'd8}, 1, 5'd22, 1); //fails
         verify_target(1);


        /*
        $display("Starting Test 2: Target is not supposed to be met");
        //apply_stimulus({5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0, 5'd0}, 1, 10'b0000000001, 1);
        apply_stimulus({5'd4, 5'd6, 5'd12, 5'd14, 5'd8}, 1, 5'd11, 1);
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
