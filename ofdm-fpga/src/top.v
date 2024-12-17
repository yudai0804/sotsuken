// iverilog -o testbench top.v uart_tx.v uart_rx.v led.v mcp3002.v -DSIMULATOR && vvp testbench && gtkwave testbench.vcd
// TODO: ADCのピンの割当はまだ行っていないので注意
`ifdef SIMULATOR

`timescale 1ns / 1ps

module testbench;
reg clk;
reg rst_n;
wire [5:0] led;
reg rx_pin;
reg adc_dout;

`else

module top(
    input clk,
    input rst_n,
    input rx_pin,
    output tx_pin,
    output [5:0] led,
    output adc_clk,
    output adc_din,
    input adc_dout,
    output adc_cs
);
`endif

// 27MHz
parameter CLK_FREQ = 27_000_000;
parameter CLK_FREQ_MHZ = 27.0;
// 115.2kbps
parameter BOUD_RATE = 115200;
// 0.9MHz
parameter MCP3002_CLK_FREQ = 900_000;

localparam UART_ONE_CYCLE = (CLK_FREQ / BOUD_RATE);
localparam UART_CYCLE = (CLK_FREQ / BOUD_RATE) * 10;

localparam SPI_CYCLE = CLK_FREQ / MCP3002_CLK_FREQ;

reg [15:0] uart_cycle;
reg [7:0] tx_data;
reg [7:0] index;
reg tx_enable;
wire tx_available;
wire [7:0] rx_data;
wire rx_available;
reg clear_rx_available;
reg [23:0] counter;

reg adc_enable;
// シミュレーションのためにregではなくwireにする
wire [9:0] adc_data;
// シミュレーションのためにregではなくwireにする
wire adc_available;
reg adc_clear_available;

`ifdef SIMULATOR

// Generate clock
initial begin
    clk = 0;
end
always begin
    #(((1 / CLK_FREQ_MHZ) / 2.0) * 1000) clk = ~clk;
end

`endif

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        adc_enable <= 1'd1;
        adc_clear_available <= 1'd0;
    end
    else begin
        adc_enable <= 1'd1;
    end
end

/*
// UARTのオウム返し。TXとRXのテスト用
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_enable <= 1'd0;
        uart_cycle <= 16'hffff;
        clear_rx_available <= 1'd0;
    end
    else if (tx_enable == 1'd1) begin
        if (uart_cycle != UART_CYCLE - 2 - 1) begin
            if (uart_cycle != 16'd1)
                clear_rx_available <= 1'd0;
            uart_cycle <= uart_cycle + 1'd1;
        end
        else begin
            // uart_cycle == UART_CYCLE
            uart_cycle <= 16'hffff;
            tx_enable <= 1'd0;
        end
    end
    else begin
        // tx_enable == 0
        if (rx_available == 1'd1 && tx_available == 1'd1) begin
            // successは自動で0になる
            tx_data <= rx_data;
            tx_enable <= 1'd1;
            uart_cycle <= 16'hffff;
            clear_rx_available <= 1'd1;
        end
    end
end
*/
/*
// 0.5sおきにAを出力する
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 少しシフト
        uart_cycle <= 16'hffff;
        tx_data <= "A";
        index <= 8'd0;
        tx_enable <= 1'd0;
        counter <= 24'd0;
    end
    else begin
        if (uart_cycle == 16'hffff) begin
            tx_enable <= 1'd1;
        end

        if (uart_cycle != UART_CYCLE - 2)
            uart_cycle <= uart_cycle + 1'd1;
        else begin
            tx_enable <= 1'd0;
            if (counter < 24'd13_499_999) 
                counter <= counter + 1'd1;
            else begin
                counter <= 24'd0;
                uart_cycle <= 16'hffff;
            end
        end
    end
end
*/
/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_data <= "A";
        tx_enable <= 1'd1;
    end
    else begin
        tx_data <= "A";
        tx_enable <= 1'd1;
    end
end
*/
/*
// print "hello"
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 少しシフト
        uart_cycle <= 16'hffff;
        tx_data <= 8'd0;
        index <= 8'd0;
        tx_enable <= 1'd0;
    end
    else begin
        if (uart_cycle != UART_CYCLE - 2) begin
            uart_cycle <= uart_cycle + 1'd1; 
        end
        else begin
            // uart_cycle == UART_CYCLE
            case (index)
                8'd0:
                    tx_data <= "H";
                8'd1:
                    tx_data <= "e";
                8'd2:
                    tx_data <= "l";
                8'd3:
                    tx_data <= "l";
                8'd4:
                    tx_data <= "o";
                8'd5:
                    // \r
                    tx_data <= 8'h0d;
                8'd6:
                    tx_data <= "\n";
                default:
                    tx_data <= 8'd0;
            endcase
            // index <= index + 1'd1;
            if (index == 8'd6) begin
                index <= 8'd0;
            end else begin
                index <= index + 1'd1;
            end
            tx_enable <= 1'd1;
            uart_cycle <= 16'hffff;
        end
    end
end
*/
mcp3002#(
    .CLK_FREQ(CLK_FREQ),
    .MCP3002_CLK_FREQ(MCP3002_CLK_FREQ)
)mcp3002_instance(
    .clk(clk),
    .rst_n(rst_n),
    .adc_clk(adc_clk),
    .adc_din(adc_din),
    .adc_dout(adc_dout),
    .adc_cs(adc_cs),
    .adc_enable(adc_enable),
    .adc_data(adc_data),
    .adc_available(adc_available)
);

uart_rx#
(
    .CLK_FREQ(CLK_FREQ),
    .BOUD_RATE(BOUD_RATE)
)uart_rx_instance(
    .clk(clk),
    .rst_n(rst_n),
    .rx_pin(rx_pin),
    .rx_data(rx_data),
    .rx_available(rx_available),
    .clear_rx_available(clear_rx_available)
);
uart_tx#
(
    .CLK_FREQ(CLK_FREQ),
    .BOUD_RATE(BOUD_RATE)
)uart_tx_instance(
    .clk(clk),
    .rst_n(rst_n),
    .tx_pin(tx_pin),
    .tx_enable(tx_enable),
    .tx_data(tx_data),
    .tx_available(tx_available)
);
led#
(
    .CLK_FREQ(CLK_FREQ)
)led_instance(
    .clk(clk),
    .rst_n(rst_n),
    .led(led)
);

`ifdef SIMULATOR
initial begin
    // シミュレーションの開始
    $dumpfile("testbench.vcd"); // 波形出力ファイル
    $dumpvars(0, testbench);

    // 初期化
    #0 rst_n = 0;
    #0 rst_n = 1;

    // SPI test
    #0 adc_dout = 0;

    #(1 / 27.0 * 1000 * SPI_CYCLE * 5) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;

    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;

    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;

    #(1 / 27.0 * 1000 * SPI_CYCLE * 2) adc_dout = 0;

    #(1 / 27.0 * 1000 * SPI_CYCLE * 5) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;

    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 0;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;

    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;
    #(1 / 27.0 * 1000 * SPI_CYCLE) adc_dout = 1;

    #(1 / 27.0 * 1000 * SPI_CYCLE * 2) adc_dout = 0;

    // finish
    #(1 / 27.0 * 1000 * SPI_CYCLE * 10) $finish;

    /*
    // UARTでA B Cの文字を送信する
    #0 rx_pin = 1;
    // A
    // IDLE
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    // START
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // DATA
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // STOP
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    // B
    // START
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // DATA
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // STOP
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    // C
    // START
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // DATA
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 0;
    // STOP
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    // IDLE
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) rx_pin = 1;
    #(1 / 27.0 * 1000 * UART_ONE_CYCLE) $finish;
    */
end
`endif

endmodule
