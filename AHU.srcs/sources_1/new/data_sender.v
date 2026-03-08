`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    input start_trigger,
    input [7:0] hum_int,
    input [7:0] tem_int,
    input tx_busy,
    input tx_done,
    output reg [7:0] tx_data,
    output reg tx_start
);

    // 숫자 -> ASCII 문자로 변환
    wire [7:0] hum_10 = (hum_int / 10) % 10 + 8'h30;
    wire [7:0] hum_1  = hum_int % 10 + 8'h30;
    wire [7:0] tem_10 = (tem_int / 10) % 10 + 8'h30;
    wire [7:0] tem_1  = tem_int % 10 + 8'h30;

    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam WAIT = 2'b10;

    reg [1:0] state;
    reg [3:0] byte_cnt; // 11글자

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tx_start <= 1'b0;
            tx_data <= 8'd0;
            byte_cnt <= 4'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    tx_start <= 1'b0;
                    byte_cnt <= 4'd0;
                    if (start_trigger) begin
                        state <= SEND;
                    end
                end
                
                SEND: begin
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                     
                        case(byte_cnt)
                            4'd0:  tx_data <= 8'h54; // T
                            4'd1:  tx_data <= 8'h3A; // :
                            4'd2:  tx_data <= tem_10; 
                            4'd3:  tx_data <= tem_1;
                            4'd4:  tx_data <= 8'h0A; // \n
                            4'd5:  tx_data <= 8'h48; // H
                            4'd6:  tx_data <= 8'h3A; // :
                            4'd7:  tx_data <= hum_10; 
                            4'd8:  tx_data <= hum_1; 
                            4'd9:  tx_data <= 8'h0D; // \r
                            4'd10: tx_data <= 8'h0A; 
                            default: tx_data <= 8'h20;
                        endcase
                        
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    tx_start <= 1'b0; // 1클럭 High 유지 -> Low
                    if (tx_done) begin
                        if (byte_cnt == 4'd10) begin
                            state <= IDLE;
                        end else begin
                            byte_cnt <= byte_cnt + 1;
                            state <= SEND; // 다음 글자 전송
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule