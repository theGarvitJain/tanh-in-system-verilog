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

// Not 350MHz yet, next step would be to make each add its own stage


logic signed [13:0] x_1_r, x_2_r, x_3_r, x_4_r, x_5_r, x_6_r, x_7_r, x_8_r; // intermediate results
logic signed [13:0] x2_2_r, x2_3_r, x2_4_r, x2_5_r, x2_6_r, x2_7_r; // carry forward x squared
logic signed [13:0] x3_1_r, x3_2_r, x3_3_r, x3_4_r, x3_5_r, x3_6_r, x3_7_r; // carry forward x
logic v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8; // valid stage
logic r_1, r_2, r_3, r_4, r_5, r_6, r_7, r_8; // ready

// 28-bit product wires for multiplication operations
logic signed [27:0] prod_stage2, prod_stage3, prod_stage4, prod_stage5, prod_stage6, prod_stage7, prod_stage8;

always_comb begin
    prod_stage2 = x_1_r * x_1_r;
    prod_stage3 = x_2_r * A4;
    prod_stage4 = (x_3_r + A3) * x2_3_r;
    prod_stage5 = (x_4_r + A2) * x2_4_r;
    prod_stage6 = (x_5_r + A1) * x2_5_r;
    prod_stage7 = (x_6_r + A0) * x2_6_r;
    prod_stage8 = x_7_r * x3_7_r;
end

always_ff @(posedge(clk)) begin
    if (rst) begin
    r_1 <= 'b1;
    r_2 <= 'b1;
    r_3 <= 'b1;
    r_4 <= 'b1;
    r_5 <= 'b1;
    r_6 <= 'b1;
    r_7 <= 'b1;
    r_8 <= 'b1;
    v_1 <= 'b0;
    v_2 <= 'b0;
    v_3 <= 'b0;
    v_4 <= 'b0;
    v_5 <= 'b0;
    v_6 <= 'b0;
    v_7 <= 'b0;
    v_8 <= 'b0;
   
    x_8_r <= 14'b00;
    end else if (i_ready == 'b0) begin
       
        // stage 1
        x_1_r  <= x_1_r;
        x3_1_r <= x3_1_r;
        v_1    <= v_1;
        r_1    <= r_1;
       
        // stage 2
        x_2_r  <= x_2_r;
        x2_2_r <= x2_2_r;
        x3_2_r <= x3_2_r;
        v_2    <= v_2;
        r_2    <= r_2;
       
        // stage 3
        x_3_r  <= x_3_r;
        x2_3_r <= x2_3_r;
        x3_3_r <= x3_3_r;
        v_3    <= v_3;
        r_3    <= r_3;
       
        // stage 4
        x_4_r  <= x_4_r;
        x2_4_r <= x2_4_r;
        x3_4_r <= x3_4_r;
        v_4    <= v_4;
        r_4    <= r_4;
       
        // stage 5
        x_5_r  <= x_5_r;
        x2_5_r <= x2_5_r;
        x3_5_r <= x3_5_r;
        v_5    <= v_5;
        r_5    <= r_5;
       
        // stage 6
        x_6_r  <= x_6_r;
        x2_6_r <= x2_6_r;
        x3_6_r <= x3_6_r;
        v_6    <= v_6;
        r_6    <= r_6;
       
        // stage 7
        x_7_r  <= x_7_r;
        x2_7_r <= x2_7_r;
        x3_7_r <= x3_7_r;
        v_7    <= v_7;
        r_7    <= r_7;
       
        // stage 8
        x_8_r  <= x_8_r;
        v_8    <= v_8;
        r_8    <= r_8;
       
    end else begin
   
    x_1_r <= i_x; //stage 1
    x3_1_r <= i_x;
    v_1 <= i_valid;
    r_1 <= i_ready;
   
    x_2_r <= prod_stage2[25:12]; // stage 2
    x2_2_r <= prod_stage2[25:12];
    x3_2_r <= x3_1_r;
    v_2 <= v_1;
    r_2 <= r_1;
   
    x_3_r <= prod_stage3[25:12]; // stage 3
    x2_3_r <= x2_2_r;
    x3_3_r <= x3_2_r;
    v_3 <= v_2;
    r_3 <= r_2;
   
    x_4_r <= prod_stage4[25:12]; // stage 4
    x2_4_r <= x2_3_r;
    x3_4_r <= x3_3_r;
    v_4 <= v_3;
    r_4 <= r_3;
   
    x_5_r <= prod_stage5[25:12]; // stage 5
    x2_5_r <= x2_4_r;
    x3_5_r <= x3_4_r;
    v_5 <= v_4;
    r_5 <= r_4;
   
    x_6_r <= prod_stage6[25:12]; // stage 6
    x2_6_r <= x2_5_r;
    x3_6_r <= x3_5_r;
    v_6 <= v_5;
    r_6 <= r_5;
   
    x_7_r <= prod_stage7[25:12]; // stage 7
    x2_7_r <= x2_6_r;
    x3_7_r <= x3_6_r;
    v_7 <= v_6;
    r_7 <= r_6;
   
    x_8_r <= prod_stage8[25:12] + x3_7_r; // stage 8
    v_8 <= v_7;
    r_8 <= r_7;
    end
   
end

assign o_valid = v_8;
assign o_fx = x_8_r;
assign o_ready = i_ready || !v_1;
/******* Your code ends here ********/

endmodule