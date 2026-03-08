`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    inout dht11_data,

    output ds1302_ce,
    output ds1302_sclk, 
    inout ds1302_data, 

    input btnL,
    input RsRx,
    output RsTx,
    output [7:0] seg,
    output [3:0] an
    );

    wire [7:0] w_hum_int, w_hum_dec, w_tem_int, w_tem_dec;
    wire [7:0] w_rtc_sec, w_rtc_min, w_rtc_hour, w_rtc_day, w_rtc_month, w_rtc_year;
    wire w_btn_debouncer;
    wire [13:0] w_fnd_in_data;
    wire w_tick_1Hz;

    btn_debouncer #(.DEBOUNCE_LIMIT(20'd999_999)) u_btn_debouncer(
        .clk        (clk),
        .reset      (reset),
        .noisy_btn  (btnL),
        .clean_btn  (w_btn_debouncer)
    );

    tick_gen #(
        .INPUT_FREQ (100_000_000),
        .TICK_Hz    (1)
    ) u_tick_gen(
        .clk    (clk),
        .reset  (reset),
        .tick   (w_tick_1Hz)
    );

    control_tower u_control_tower(
        .clk        (clk),
        .reset      (reset),
        .btnL       (w_btn_debouncer), 
        .hum_int    (w_hum_int),
        .hum_dec    (w_hum_dec),
        .tem_int    (w_tem_int),
        .tem_dec    (w_tem_dec),
        .rtc_sec    (w_rtc_sec),
        .rtc_min    (w_rtc_min),
        .rtc_hour   (w_rtc_hour),
        .rtc_day    (w_rtc_day),
        .rtc_month  (w_rtc_month),
        .rtc_year   (w_rtc_year),
        .fnd_data   (w_fnd_in_data) 
    );

    dht_controller u_dht_controller(
        .clk            (clk),
        .reset          (reset),
        .start_trigger  (w_tick_1Hz),
        .dht11_data     (dht11_data),
        .hum_int        (w_hum_int),
        .hum_dec        (w_hum_dec),
        .tem_int        (w_tem_int),
        .tem_dec        (w_tem_dec)
    );

    ds1302_controller u_ds1302(
        .clk            (clk),
        .reset          (reset),
        .start_trigger  (w_tick_1Hz),
        .ce             (ds1302_ce),
        .sclk           (ds1302_sclk),
        .ds1302_data    (ds1302_data),
        .o_sec          (w_rtc_sec),
        .o_min          (w_rtc_min),
        .o_hour         (w_rtc_hour),
        .o_day          (w_rtc_day),
        .o_month        (w_rtc_month),
        .o_year         (w_rtc_year)
    );

    uart_controller u_uart_controller(
        .clk            (clk),
        .reset          (reset),
        .start_trigger  (w_tick_1Hz),
        .hum_int        (w_hum_int),
        .tem_int        (w_tem_int),
        .rx_data        (),
        .rx_done        (),
        .rx             (RsRx),
        .tx             (RsTx)
    );

    fnd_controller u_fnd_controller(
        .clk        (clk),
        .reset      (reset), 
        .in_data    (w_fnd_in_data),
        .seg        (seg),
        .an         (an)
    );

endmodule
