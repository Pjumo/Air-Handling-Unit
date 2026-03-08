`timescale 1ns / 1ps

module ds1302_controller(
    input clk,
    input reset,
    input start_trigger,
    output ce,
    output sclk,
    inout ds1302_data,

    output [7:0] o_sec,
    output [7:0] o_min,
    output [7:0] o_hour,
    output [7:0] o_day,
    output [7:0] o_month,
    output [7:0] o_year
);
    wire w_io_mode, w_o_data, w_i_data;

    ds1302_main_logic u_ds1302_main_logic(
        .clk            (clk),
        .reset          (reset),
        .start_trigger  (start_trigger),
        .i_data         (w_i_data),
        .ce             (ce),
        .sclk           (sclk),
        .io_mode        (w_io_mode),
        .o_data         (w_o_data),

        .o_sec          (o_sec),
        .o_min          (o_min),
        .o_hour         (o_hour),
        .o_day          (o_day),
        .o_month        (o_month),
        .o_year         (o_year)
    );

    ds1302 u_ds1302(
        .io_mode        (w_io_mode),
        .o_data         (w_o_data),
        .i_data         (w_i_data),
        .ds1302_data    (ds1302_data)
    );

endmodule


module ds1302_main_logic(
    input clk,
    input reset,
    input start_trigger,
    input i_data,
    output reg ce,
    output reg sclk,
    output reg io_mode, // 1: input, 0: output
    output reg o_data,

    output reg [7:0] o_sec,
    output reg [7:0] o_min,
    output reg [7:0] o_hour,
    output reg [7:0] o_day,
    output reg [7:0] o_month,
    output reg [7:0] o_year
);

    localparam IDLE         = 3'd0;
    localparam CHOOSE_CMD   = 3'd1;
    localparam CE_HIGH      = 3'd2;
    localparam SEND_CMD     = 3'd3;
    localparam READ_DATA    = 3'd4;
    localparam CE_LOW       = 3'd5;
    localparam STORE_DATA   = 3'd6;

    localparam WAIT_TO_READ = 8'h00;
    localparam READ_SECOND  = 8'h81;
    localparam READ_MINUTE  = 8'h83;
    localparam READ_HOUR    = 8'h85;
    localparam READ_DAY     = 8'h87;
    localparam READ_MONTH   = 8'h89;
    localparam READ_YEAR    = 8'h8D;

    localparam TIME_250ns   = 25;

    reg [2:0] state;
    reg [3:0] bit_cnt;  // bit 수
    reg [7:0] cmd_reg;  // read or write 과정에서 보낼 command
    reg [7:0] data_reg; // 읽어온 데이터 저장
    reg sclk_state;     // 1: sclk 2MHz, 0: nothing
    reg prev_sclk;      // 이전 clk의 sclk 저장

    reg [21:0] counter;
    
    // FSM
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            ce <= 0;
            io_mode <= 0;
            o_data <= 0;
            bit_cnt <= 0;
            sclk_state <= 0;
            cmd_reg <= WAIT_TO_READ;

            o_sec <= 0;
            o_min <= 0;
            o_hour <= 0;
            o_day <= 0;
            o_month <= 0;
            o_year <= 0;
        end else begin
            case(state)
                IDLE: begin
                    ce <= 0;
                    sclk_state <= 0;
                    bit_cnt <= 0;
                    io_mode <= 0;   // 기본 output mode
                    cmd_reg <= WAIT_TO_READ;

                    if(start_trigger) begin
                        state <= CHOOSE_CMD;
                    end
                end

                CHOOSE_CMD: begin
                    case(cmd_reg)
                        WAIT_TO_READ:   cmd_reg <= READ_SECOND;
                        READ_SECOND:    cmd_reg <= READ_MINUTE;
                        READ_MINUTE:    cmd_reg <= READ_HOUR;
                        READ_HOUR:      cmd_reg <= READ_DAY;
                        READ_DAY:       cmd_reg <= READ_MONTH;
                        READ_MONTH:     cmd_reg <= READ_YEAR;
                        READ_YEAR:      cmd_reg <= WAIT_TO_READ;
                        default:        state <= IDLE;
                    endcase

                    if(cmd_reg == READ_YEAR) begin
                        state <= IDLE;
                    end else begin
                        state <= CE_HIGH;
                    end
                end

                CE_HIGH: begin
                    ce <= 1;    // ce를 high (start)
                    sclk_state <= 1;    // sclk 2MHz 파형 생성
                    state <= SEND_CMD;
                    io_mode <= 1;
                end

                SEND_CMD: begin
                    if(sclk && !prev_sclk) begin    // sclk 상승에지마다
                        o_data <= cmd_reg[bit_cnt];
                        bit_cnt <= bit_cnt + 1;

                        if(bit_cnt >= 7) begin
                            bit_cnt <= 0;
                            state <= READ_DATA;
                            io_mode <= 0;
                        end
                    end
                end

                READ_DATA: begin
                    if(!sclk && prev_sclk) begin    // sclk 하강에지마다
                        data_reg[bit_cnt] <= i_data;
                        bit_cnt <= bit_cnt + 1;

                        if(bit_cnt >= 7) begin
                            bit_cnt <= 0;
                            state <= CE_LOW;
                        end
                    end
                end

                CE_LOW: begin
                    ce <= 0;
                    sclk_state <= 0;
                    state <= STORE_DATA;
                end

                STORE_DATA: begin
                    case(cmd_reg)
                        READ_SECOND:    o_sec <= (data_reg[6:4] * 10) + (data_reg[3:0]);
                        READ_MINUTE:    o_min <= (data_reg[6:4] * 10) + (data_reg[3:0]);
                        READ_HOUR:      o_hour <= data_reg[4:0];
                        READ_DAY:       o_day <= (data_reg[4] * 10) + (data_reg[3:0]);
                        READ_MONTH:     o_month <= data_reg;
                        READ_YEAR:      o_year <= (data_reg[7:4] * 10) + (data_reg[3:0]);
                        default:        state <= IDLE;
                    endcase

                    state <= CHOOSE_CMD;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // sclk 생성
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            sclk <= 0;
            counter <= 0;
        end else begin
            if(sclk_state) begin
                if(counter >= TIME_250ns - 1) begin // 2MHz sclk
                    counter <= 0;
                    sclk <= ~sclk;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                sclk <= 0;
                counter <= 0;
            end
            prev_sclk <= sclk;
        end
    end

endmodule


module ds1302(
    input io_mode,
    input o_data,
    output i_data,
    inout ds1302_data
);
    assign ds1302_data = io_mode ? 1'bz : o_data;
    assign i_data = ds1302_data;
endmodule
