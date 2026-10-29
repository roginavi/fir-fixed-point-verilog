`timescale 1ns/1ps
// Self-checking testbench: compares RTL output to the Python golden model.
module fir4_tb;
    localparam N = 256;

    reg clk = 0;
    reg rst = 1;
    reg  signed [15:0] x = 0;
    wire signed [15:0] y;

    reg [15:0] in_mem  [0:N-1];
    reg [15:0] exp_mem [0:N-1];

    integer i, errors;

    fir4 dut (.clk(clk), .rst(rst), .x(x), .y(y));

    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $dumpfile("fir4.vcd");
        $dumpvars(0, fir4_tb);
        $readmemh("input.hex", in_mem);
        $readmemh("expected.hex", exp_mem);
        errors = 0;

        repeat (2) @(posedge clk);
        #1 rst = 0;

        for (i = 0; i < N; i = i + 1) begin
            x = in_mem[i];
            @(posedge clk);
            #1;
            if (y !== $signed(exp_mem[i])) begin
                errors = errors + 1;
                $display("MISMATCH n=%0d: got %0d expected %0d", i, y, $signed(exp_mem[i]));
            end
        end

        if (errors == 0) $display("PASS: all %0d samples match the golden model", N);
        else             $display("FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
