// 吃豆人按键解码模块
// 简化版：只需要方向键 + 复位

module pacman_input (
    input           clk,
    input           rstn,
    input [7:0]     rx_data,
    input           rx_valid,
    
    output reg      key_up,
    output reg      key_down,
    output reg      key_left,
    output reg      key_right,
    output reg      key_reset
);

    // 按键映射
    // W/w = 上, S/s = 下, A/a = 左, D/d = 右
    // R/r = 复位
    
    always @(posedge clk) begin
        if (!rstn) begin
            key_up <= 1'b0;
            key_down <= 1'b0;
            key_left <= 1'b0;
            key_right <= 1'b0;
            key_reset <= 1'b0;
        end
        else if (rx_valid) begin
            case (rx_data)
                // 按下
                "w": key_up <= 1'b1;
                "s": key_down <= 1'b1;
                "a": key_left <= 1'b1;
                "d": key_right <= 1'b1;
                "r": key_reset <= 1'b1;
                
                // 松开
                "W": key_up <= 1'b0;
                "S": key_down <= 1'b0;
                "A": key_left <= 1'b0;
                "D": key_right <= 1'b0;
                "R": key_reset <= 1'b0;
            endcase
        end
    end

endmodule
