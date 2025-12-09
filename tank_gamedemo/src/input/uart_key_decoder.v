// 串口按键解码模块
// 接收电脑发来的按键命令

module uart_key_decoder (
    input           clk,
    input           rstn,
    
    input [7:0]     rx_data,
    input           rx_valid,
    
    // P1 控制 (WASD + J)
    output reg      p1_up,
    output reg      p1_down,
    output reg      p1_left,
    output reg      p1_right,
    output reg      p1_fire,
    
    // P2 控制 (IKJL + 空格)  
    output reg      p2_up,
    output reg      p2_down,
    output reg      p2_left,
    output reg      p2_right,
    output reg      p2_fire
);

    // 协议: 单字节命令
    // 按下: 小写字母
    // 松开: 大写字母
    //
    // P1: w/W=上, s/S=下, a/A=左, d/D=右, j/J=开火
    // P2: i/I=上, k/K=下, j/J=左, l/L=右, 空格=开火 (用 n/N 代替)
    //
    // 为避免冲突，P2改用: i=上, k=下, h=左, l=右, n=开火
    
    always @(posedge clk) begin
        if (!rstn) begin
            p1_up    <= 0; p1_down  <= 0; p1_left  <= 0; p1_right <= 0; p1_fire  <= 0;
            p2_up    <= 0; p2_down  <= 0; p2_left  <= 0; p2_right <= 0; p2_fire  <= 0;
        end
        else if (rx_valid) begin
            case (rx_data)
                // P1 按下
                "w": p1_up    <= 1;
                "s": p1_down  <= 1;
                "a": p1_left  <= 1;
                "d": p1_right <= 1;
                "j": p1_fire  <= 1;
                
                // P1 松开
                "W": p1_up    <= 0;
                "S": p1_down  <= 0;
                "A": p1_left  <= 0;
                "D": p1_right <= 0;
                "J": p1_fire  <= 0;
                
                // P2 按下
                "i": p2_up    <= 1;
                "k": p2_down  <= 1;
                "h": p2_left  <= 1;
                "l": p2_right <= 1;
                "n": p2_fire  <= 1;
                
                // P2 松开
                "I": p2_up    <= 0;
                "K": p2_down  <= 0;
                "H": p2_left  <= 0;
                "L": p2_right <= 0;
                "N": p2_fire  <= 0;
            endcase
        end
    end

endmodule
