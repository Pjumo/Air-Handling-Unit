`timescale 1ns / 1ps

module control_tower(
    input clk,
    input reset,
    input btnL,

    input [7:0] hum_int,
    input [7:0] hum_dec,
    input [7:0] tem_int,
    input [7:0] tem_dec,

    input [7:0] rtc_sec,
    input [7:0] rtc_min,
    input [7:0] rtc_hour,
    input [7:0] rtc_date,
    input [7:0] rtc_month,
    input [7:0] rtc_year,

    input ds1302_busy,

    output reg [13:0] fnd_data,
    output reg ds1302_write_req
);
    reg r_prev;
    reg ds1302_init;
    reg mode;   // 0: 공조기, 1: clock

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            mode <= 1'b0;
            r_prev <= 1'b0;
        end else begin
            if (btnL == 1'b1 && r_prev == 1'b0) begin
                mode <= ~mode;
            end
            r_prev <= btnL;
        end
    end

    // ds1302 write_req
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            ds1302_init <= 0;
        end else begin
            ds1302_write_req <= 0;
            if(!ds1302_init && !ds1302_busy) begin
                ds1302_init <= 1;
                ds1302_write_req <= 1;
            end
        end
    end

    always @(*) begin
        if (mode == 1'b0) begin
            fnd_data = (tem_int * 100) + hum_int;
        end else begin
            fnd_data = (rtc_min * 100) + rtc_sec;
        end
    end

endmodule
