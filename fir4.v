// 4-tap FIR filter, 16-bit signed input/output, Q1.15 coefficients.
// Output y is registered: y[n] appears one clock after x[n] is applied.
module fir4 (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [15:0] x,
    output reg  signed [15:0] y
);
    localparam signed [15:0] C0 = 16'sd3277;   // 0.1
    localparam signed [15:0] C1 = 16'sd13107;  // 0.4
    localparam signed [15:0] C2 = 16'sd13107;  // 0.4
    localparam signed [15:0] C3 = 16'sd3277;   // 0.1

    // Delay line: x1 = x[n-1], x2 = x[n-2], x3 = x[n-3]
    reg signed [15:0] x1, x2, x3;

    // 16x16 products -> 32 bit
    wire signed [31:0] p0 = C0 * x;
    wire signed [31:0] p1 = C1 * x1;
    wire signed [31:0] p2 = C2 * x2;
    wire signed [31:0] p3 = C3 * x3;

    // Sum of |coef| = 1.0, so the sum never exceeds 2^30: 32 bits is enough
    wire signed [31:0] acc = p0 + p1 + p2 + p3;

    always @(posedge clk) begin
        if (rst) begin
            x1 <= 16'sd0;
            x2 <= 16'sd0;
            x3 <= 16'sd0;
            y  <= 16'sd0;
        end else begin
            x3 <= x2;
            x2 <= x1;
            x1 <= x;
            y  <= acc >>> 15;  // back to Q1.15 (truncation)
        end
    end
endmodule
