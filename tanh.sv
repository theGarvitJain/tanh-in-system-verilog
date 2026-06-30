/***************************************************/
/* ECE 327: Digital Hardware Systems - Spring 2026 */
/* Lab 3                                           */
/* Hyperbolic Tangent (Tanh) circuit               */
/***************************************************/

module tanh (
    input  clk,         // Input clock signal
    input  rst,         // Active-high reset signal
    // Input interface
    input  [13:0] i_x,  // Input value x
    input  i_valid,     // Input value x is valid
    output o_ready,     // Circuit is ready to accept an input
    // Output interface 
    output [13:0] o_fx, // Output result f(x)
    output o_valid,     // Output result f(x) is valid
    input  i_ready      // Downstream circuit is ready to accept an input
);

// Local parameters to define the Taylor coefficients
localparam signed [13:0] A0 = 14'b11101010101011; // a0 = -0.33349609375
localparam signed [13:0] A1 = 14'b00001000100010; // a1 =  0.13330078125
localparam signed [13:0] A2 = 14'b11111100100011; // a2 = -0.05419921875
localparam signed [13:0] A3 = 14'b00000001011001; // a3 =  0.021484375
localparam signed [13:0] A4 = 14'b11111111011100; // a4 = -0.0087890625


/******* Your code starts here *******/

// Registers for intermediate values (Fully extended to 13 stages)
logic signed [13:0] x_1_r, x_2_r, x_3_r, x_4_r, x_5_r, x_6_r, x_7_r, x_8_r, x_9_r, x_10_r, x_11_r, x_12_r, x_13_r; 
logic signed [13:0] x2_2_r, x2_3_r, x2_4_r, x2_5_r, x2_6_r, x2_7_r, x2_8_r, x2_9_r, x2_10_r, x2_11_r, x2_12_r; 
logic signed [13:0] x3_1_r, x3_2_r, x3_3_r, x3_4_r, x3_5_r, x3_6_r, x3_7_r, x3_8_r, x3_9_r, x3_10_r, x3_11_r, x3_12_r; 

// Dedicated pre-computation registers to break all Add -> Mul chains
logic signed [13:0] sum_stage4_r, sum_stage6_r, sum_stage8_r, sum_stage10_r;

// Valid and Ready flags for 13 stages
logic v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13;
logic r_1, r_2, r_3, r_4, r_5, r_6, r_7, r_8, r_9, r_10, r_11, r_12, r_13;

// Combinational wires for separate additions and multiplications
logic signed [13:0] sum_stage4, sum_stage6, sum_stage8, sum_stage10;
logic signed [27:0] prod_stage2, prod_stage3, prod_stage5, prod_stage7, prod_stage9, prod_stage11, prod_stage12, prod_stage13;

always_comb begin
    // Stage 2: Calculate X^2
    prod_stage2 = x_1_r * x_1_r;
    
    // Stage 3: Calculate X^2 * A4
    prod_stage3 = x_2_r * A4;
    
    // Stage 4: Add A3
    sum_stage4  = x_3_r + A3;
    
    // Stage 5: Multiply by X^2
    prod_stage5 = sum_stage4_r * x2_4_r;
    
    // Stage 6: Add A2
    sum_stage6  = x_5_r + A2;
    
    // Stage 7: Multiply by X^2
    prod_stage7 = sum_stage6_r * x2_6_r;
    
    // Stage 8: Add A1
    sum_stage8  = x_7_r + A1;
    
    // Stage 9: Multiply by X^2
    prod_stage9 = sum_stage8_r * x2_8_r;
    
    // Stage 10: Add A0 (Now successfully broken out!)
    sum_stage10 = x_9_r + A0;
    
    // Stage 11: Multiply by X^2
    prod_stage11 = sum_stage10_r * x2_10_r;
    
    // Stage 12: Multiply by original X
    prod_stage12 = x_11_r * x3_11_r;
end

always_ff @(posedge clk) begin
    if (rst) begin
        r_1 <= 'b1; r_2 <= 'b1; r_3 <= 'b1; r_4 <= 'b1; r_5 <= 'b1; r_6 <= 'b1; r_7 <= 'b1;
        r_8 <= 'b1; r_9 <= 'b1; r_10<= 'b1; r_11<= 'b1; r_12<= 'b1; r_13<= 'b1;
        
        v_1 <= 'b0; v_2 <= 'b0; v_3 <= 'b0; v_4 <= 'b0; v_5 <= 'b0; v_6 <= 'b0; v_7 <= 'b0;
        v_8 <= 'b0; v_9 <= 'b0; v_10<= 'b0; v_11<= 'b0; v_12<= 'b0; v_13<= 'b0;
        
        x_13_r <= 14'b0;
    end else if (i_ready == 'b0) begin
        // Ultra-compact freeze blocks to keep the code clean and scannable
        {x_1_r, x3_1_r, v_1, r_1} <= {x_1_r, x3_1_r, v_1, r_1};
        {x_2_r, x2_2_r, x3_2_r, v_2, r_2} <= {x_2_r, x2_2_r, x3_2_r, v_2, r_2};
        {x_3_r, x2_3_r, x3_3_r, v_3, r_3} <= {x_3_r, x2_3_r, x3_3_r, v_3, r_3};
        {sum_stage4_r, x2_4_r, x3_4_r, v_4, r_4} <= {sum_stage4_r, x2_4_r, x3_4_r, v_4, r_4};
        {x_5_r, x2_5_r, x3_5_r, v_5, r_5} <= {x_5_r, x2_5_r, x3_5_r, v_5, r_5};
        {sum_stage6_r, x2_6_r, x3_6_r, v_6, r_6} <= {sum_stage6_r, x2_6_r, x3_6_r, v_6, r_6};
        {x_7_r, x2_7_r, x3_7_r, v_7, r_7} <= {x_7_r, x2_7_r, x3_7_r, v_7, r_7};
        {sum_stage8_r, x2_8_r, x3_8_r, v_8, r_8} <= {sum_stage8_r, x2_8_r, x3_8_r, v_8, r_8};
        {x_9_r, x2_9_r, x3_9_r, v_9, r_9} <= {x_9_r, x2_9_r, x3_9_r, v_9, r_9};
        {sum_stage10_r, x2_10_r, x3_10_r, v_10, r_10} <= {sum_stage10_r, x2_10_r, x3_10_r, v_10, r_10};
        {x_11_r, x2_11_r, x3_11_r, v_11, r_11} <= {x_11_r, x2_11_r, x3_11_r, v_11, r_11};
        {x_12_r, x3_12_r, v_12, r_12} <= {x_12_r, x3_12_r, v_12, r_12};
        {x_13_r, v_13, r_13} <= {x_13_r, v_13, r_13};
    end else begin
        // Stage 1: Sample input
        x_1_r  <= i_x;
        x3_1_r <= i_x;
        v_1    <= i_valid;
        r_1    <= i_ready;
        
        // Stage 2: Capture X^2
        x_2_r  <= prod_stage2[25:12];
        x2_2_r <= prod_stage2[25:12];
        x3_2_r <= x3_1_r;
        v_2    <= v_1;
        r_2    <= r_1;
        
        // Stage 3: Capture X^2 * A4
        x_3_r  <= prod_stage3[25:12];
        x2_3_r <= x2_2_r;
        x3_3_r <= x3_2_r;
        v_3    <= v_2;
        r_3    <= r_2;
        
        // Stage 4: Capture Add (x_3_r + A3)
        sum_stage4_r <= sum_stage4;
        x2_4_r       <= x2_3_r;
        x3_4_r       <= x3_3_r;
        v_4          <= v_3;
        r_4          <= r_3;
        
        // Stage 5: Capture Mul (sum_stage4_r * x2_4_r)
        x_5_r  <= prod_stage5[25:12];
        x2_5_r <= x2_4_r;
        x3_5_r <= x3_4_r;
        v_5    <= v_4;
        r_5    <= r_4;
        
        // Stage 6: Capture Add (x_5_r + A2)
        sum_stage6_r <= sum_stage6;
        x2_6_r       <= x2_5_r;
        x3_6_r       <= x3_5_r;
        v_6          <= v_5;
        r_6          <= r_5;
        
        // Stage 7: Capture Mul (sum_stage6_r * x2_6_r)
        x_7_r  <= prod_stage7[25:12];
        x2_7_r <= x2_6_r;
        x3_7_r <= x3_6_r;
        v_7    <= v_6;
        r_7    <= r_6;
        
        // Stage 8: Capture Add (x_7_r + A1)
        sum_stage8_r <= sum_stage8;
        x2_8_r       <= x2_7_r;
        x3_8_r       <= x3_7_r;
        v_8          <= v_7;
        r_8          <= r_7;
        
        // Stage 9: Capture Mul (sum_stage8_r * x2_8_r)
        x_9_r  <= prod_stage9[25:12];
        x2_9_r <= x2_8_r;
        x3_9_r <= x3_8_r;
        v_9    <= v_8;
        r_9    <= r_8;
        
        // Stage 10: Capture Add (x_9_r + A0)
        sum_stage10_r <= sum_stage10;
        x2_10_r       <= x2_9_r;
        x3_10_r       <= x3_9_r;
        v_10          <= v_9;
        r_10          <= r_9;
        
        // Stage 11: Capture Mul (sum_stage10_r * x2_10_r)
        x_11_r  <= prod_stage11[25:12];
        x3_11_r <= x3_10_r;
        v_11    <= v_10;
        r_11    <= r_10;
        
        // Stage 12: Capture Final Poly Mul (x_11_r * x3_11_r)
        x_12_r  <= prod_stage12[25:12];
        x3_12_r <= x3_11_r;
        v_12    <= v_11;
        r_12    <= r_11;
        
        // Stage 13: Final Accumulation with initial input X
        x_13_r <= x_12_r + x3_12_r;
        v_13   <= v_12;
        r_13   <= r_12;
    end
end

assign o_valid = v_13;
assign o_fx    = x_13_r;
assign o_ready = i_ready || !v_1;
/******* Your code ends here ********/

endmodule
