/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 3                                           */
/* Hyperbolic Tangent (Tanh) testbench             */
/***************************************************/

`timescale 1 ns / 1 ps

module tanh_tb();

// Define clock period to be used in simulation
localparam CLK_PERIOD = 4; 				 
// Define number of test inputs
localparam NUM_TESTS = 50;
// Define scaling factor to convert inputs and outputs from binary to decimal values in Q2.12 format
localparam SCALE_FACTOR = 2.0**-12.0; 
// Define the error margin allowed in the produced results
localparam ERROR_TOLERANCE = 0.001; 

// Declare logic signals for the DUT's inputs and outputs
logic clk, rst;
logic [13:0] i_x, o_fx;
logic i_valid, o_valid, i_ready, o_ready;

// Instantiate the design under test (dut) and connect its input/output ports to the declared signals.
tanh dut (
    .clk(clk),
    .rst(rst),
    .i_x(i_x),
    .i_valid(i_valid),
    .o_ready(o_ready),
    .o_fx(o_fx),
    .o_valid(o_valid), 
    .i_ready(i_ready)
);

// Since the DUT tested here needs a clock signal, this initial block generates a clock signal with
// period 4ns and 50% duty cycle (i.e., 2ns high and 2ns low)
initial begin
    clk = 1'b0;
    // The forever keyword means this keeps happening until the end of time (wait for half a clock
    // period, and flip its state)
    forever #(CLK_PERIOD/2) clk = ~clk; 
end

// A behavioral function to calculate the Taylor expansion of tanh for generating golden results.
function real tanh_taylor(input real x);
real a0, a1, a2, a3, a4;
begin
    // Define tanh Taylor expansion coefficients
	a0 = -0.33333;
	a1 =  0.13333;
	a2 = -0.05397;
	a3 =  0.02187;
	a4 = -0.00886;
	// Calculate tanh Taylor expansion approximate result
	tanh_taylor = x + (a0 * (x**3)) + (a1 * (x**5)) + (a2 * (x**7)) + (a3 * (x**9)) + (a4 * (x**11));
end
endfunction

// A behavioral function to calculate the error in the produced results compared to the golden results. 
// The result of the DUT is considered correct if the error is less than the specified ERROR_THRESHOLD. 
function real error(input real x0, input real x1);
begin
	if(x0 - x1 > 0) begin
		error = x0 - x1;
	end else begin
		error = x1 - x0;
	end
end
endfunction

function real real_value(input logic [13:0] x);
begin
	if(x[13]) begin
		real_value = -1.0 * $itor(-x) * SCALE_FACTOR;
	end else begin
		real_value = $itor(x) * SCALE_FACTOR;
	end
end
endfunction

// Integers for input generation for loop counters
integer test_id; 
// Counter for number of valid inputs generated
integer num_valid_inputs;
// Arrays to store generated inputs and their corresponding valid signals
logic [13:0] generated_x [0:NUM_TESTS-1];
logic generated_valid [0:NUM_TESTS-1];
// Array to store the tanh taylor expansion results of generated inputs (error calculated vs. this)
real golden_results_taylor_tanh [0:NUM_TESTS-1];
// Array to store the real tanh value of generated inputs (just for reference)
real golden_results_real_tanh [0:NUM_TESTS-1];
// Array to store the input index each golden result corresponds to
integer golden_results_input_id [0:NUM_TESTS-1];

// Initial block to generate test inputs and calculate their golden results
initial begin
    // Set initial value of number of valid inputs to zero
    num_valid_inputs = 0;
    
    // Generate NUM_TESTS random inputs and store them in corresponding arrays
	for (test_id = 0; test_id < NUM_TESTS; test_id = test_id + 1) begin
		// Generate a random value for i_x at clock negative edge
		i_x = $random;
		// Ensure that i_x value is between -1 and 1 by setting the two integer bits to 2'b00 or 2'b11
		i_x[13] = {(2){$random % 2}};
		i_x[12] = i_x[13];
		// Generate i_valid bit randomly such that one-eighth of the time it is set to 1'b0 to test
		// the circuits functionality in this case. Increment counter if input is valid.
		i_valid = ($random % 8 != 'd0);
		// Store generated input x and valid
		generated_x[test_id] = i_x;
		generated_valid[test_id] = i_valid;
		// Generate golden results and store them if input is valid (circuit expected to generate a
		// corresponding output)
		if (i_valid) begin
            golden_results_real_tanh[num_valid_inputs] = $tanh(real_value(i_x));
            golden_results_taylor_tanh[num_valid_inputs] = tanh_taylor(real_value(i_x));
            golden_results_input_id[num_valid_inputs] = test_id;
            num_valid_inputs = num_valid_inputs + 1;
        end
    end
end

// Integer for input supply for loop counter
integer input_id;
// Integers specifying how many cycles i_ready will be set to 1'b0
integer i_ready_low_duration, i_ready_low_cycle_count;

// Initial block to supply inputs to the ciruit under test
initial begin	
    // Set initial values of circuit input and de-assert reset signal after a few cycles	
    rst = 1'b1;
	i_valid = 1'b0;
	i_x = 'd0;
	i_ready = 1'b1;
	i_ready_low_duration = 20;
	i_ready_low_cycle_count = 0;
    #(25*CLK_PERIOD);
	rst = 1'b0;
	
	// Supply inputs to the circuit
	for (input_id = 0; input_id < NUM_TESTS; input_id = input_id + 1) begin	    
		i_x = generated_x[input_id];
		i_valid = generated_valid[input_id];
		// After supplying half the inputs set i_ready to low for some cycles to test
	    // the circuit's functionality in this case
	    if (input_id == NUM_TESTS/2) begin
	       i_ready = 1'b0;
	    end
		
		// As long as the circuit is not ready to accept an input, keep it as is
		do begin
		  #(CLK_PERIOD);
		  // Set i_ready back to 1'b1 after specified number of cycles have passed
		  if (!i_ready) begin
		      if (i_ready_low_cycle_count == i_ready_low_duration) begin
		          i_ready = 1'b1;
		      end else begin
		          i_ready_low_cycle_count = i_ready_low_cycle_count + 1;
		      end
		  end
		end while (!o_ready);
	end
end

// Integers to count the number of received outputs, results matching golden output, and results not matching golden output
integer num_received_outputs, mismatched_results, matched_results;
// Real number to calculate the error between DUT result and golden result
real output_error;
// Boolean flag to declare test failure
logic sim_failed;

initial begin
    // Set time display format to be in 10^-9 sec, with 2 decimal places, and add " ns" suffix
    $timeformat(-9, 2, " ns");
    
    // Initialize all counters and flags to zero
    num_received_outputs = 0;
    mismatched_results = 0;
    matched_results = 0;
    sim_failed = 1'b0;
    
    // As long as there are more outputs expected ...
    while (num_received_outputs < num_valid_inputs) begin
        // If an output is declared by the DUT as valid ...
        if (o_valid && o_ready) begin
            // Calculate the output error and compare to the specified tolerance to determine if it is considered correct or not
            output_error = error(golden_results_taylor_tanh[num_received_outputs], real_value(o_fx));
            if (output_error < ERROR_TOLERANCE) begin
				$display("[%0t] SUCCESS\t x= %9.6f\t Real Tanh(x)= %9.6f\t Taylor Tanh(x)= %9.6f\t o_fx= %9.6f\t Error: %9.6f\t < %9.6f", 
				    $time, 
				    real_value(generated_x[golden_results_input_id[num_received_outputs]]),
				    golden_results_real_tanh[num_received_outputs], 
				    golden_results_taylor_tanh[num_received_outputs], 
				    real_value(o_fx), 
				    output_error, ERROR_TOLERANCE);
				matched_results = matched_results + 1;
			end else begin
				$display("[%0t] FAILURE\t x= %9.6f\t Real Tanh(x)= %9.6f\t Taylor Tanh(x)= %9.6f\t o_fx= %9.6f\t Error: %9.6f\t > %9.6f", 
				    $time, 
				    real_value(generated_x[golden_results_input_id[num_received_outputs]]),
				    golden_results_real_tanh[num_received_outputs], 
				    golden_results_taylor_tanh[num_received_outputs], 
				    real_value(o_fx), 
				    output_error, ERROR_TOLERANCE);
				sim_failed = 1'b1;
				mismatched_results = mismatched_results + 1;
			end
			num_received_outputs = num_received_outputs + 1;
        end
        #(CLK_PERIOD);
    end
    // Print simulation summary
    if (sim_failed) begin
        $display("TEST FAILED! %d results (out of %d) have an error higher than the specified tolerance!", mismatched_results, num_received_outputs);
    end else begin
        $display("TEST PASSED! %d results (out of %d) have an error within the specified tolerance!", matched_results, num_received_outputs);
    end
    $stop;     
end

endmodule