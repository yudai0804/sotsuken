module led 
#(
    // 27MHz
    parameter CLK_FREQ = 27_000_000
)(
    input clk,
    input rst_n,
    output reg [5:0] led
);

localparam HALF = CLK_FREQ / 2;
reg [23:0] counter;

// counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 24'd0;
    else if (counter < HALF) // 0.5s delay
        counter <= counter + 1'b1;
    else
        counter <= 24'd0;
end

// led
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        led <= 6'b111110;
    else if (counter == HALF) // 0.5s delay
        led[5:0] <= {led[4:0],led[5]};
    else
        led <= led;
end

endmodule

