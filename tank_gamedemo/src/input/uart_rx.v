// UART 接收模块
// 波特率: 115200, 8N1

module uart_rx (
    input           clk,        // 100MHz
    input           rstn,
    input           rx,         // UART RX 引脚
    
    output reg [7:0] data,      // 接收到的数据
    output reg       valid      // 数据有效脉冲
);

    // 115200 波特率, 100MHz 时钟
    // 100_000_000 / 115200 ≈ 868
    localparam CLKS_PER_BIT = 868;
    
    // 状态机
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;
    
    reg [2:0] state;
    reg [9:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] rx_data;
    
    // 输入同步
    reg rx_sync1, rx_sync2;
    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end
    
    always @(posedge clk) begin
        if (!rstn) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            data <= 0;
            valid <= 0;
            rx_data <= 0;
        end
        else begin
            valid <= 0;
            
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    
                    if (rx_sync2 == 0) begin  // 检测起始位
                        state <= START;
                    end
                end
                
                START: begin
                    if (clk_cnt == CLKS_PER_BIT / 2) begin
                        if (rx_sync2 == 0) begin
                            clk_cnt <= 0;
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;  // 假起始位
                        end
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        rx_data[bit_idx] <= rx_sync2;
                        
                        if (bit_idx == 7) begin
                            bit_idx <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        valid <= 1;
                        data <= rx_data;
                        state <= IDLE;
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
