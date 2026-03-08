`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input [7:0] hum_int,
    input [7:0] tem_int,
    input rx,
    input start_trigger,
    output tx,
    output [7:0] rx_data,
    output rx_done
);
    wire w_tx_start, w_tx_busy, w_tx_done;
    wire [7:0] w_tx_data;

    data_sender u_data_sender(
        .clk            (clk),
        .reset          (reset),
        .start_trigger  (start_trigger),
        .hum_int        (hum_int),
        .tem_int        (tem_int),
        .tx_busy        (w_tx_busy),
        .tx_done        (w_tx_done),
        .tx_data        (w_tx_data),
        .tx_start       (w_tx_start)
    );

    uart_tx #(
        .BPS(9600)
    ) u_uart_tx(
        .clk        (clk),
        .reset      (reset),
        .tx_data    (w_tx_data),
        .tx_start   (w_tx_start),
        .tx         (tx),
        .tx_done    (w_tx_done),
        .tx_busy    (w_tx_busy)
    );

    uart_rx #(
        .BPS(9600)
    ) u_uart_rx(
        .clk        (clk),
        .reset      (reset),
        .rx         (rx),
        .data_out   (rx_data),
        .rx_done    (rx_done)
    );

endmodule
