// 串口按键解码模块 - 新键位
// P1: WASD移动, H开火, J技能, 1234选技能
// P2: 方向键移动, 小键盘1开火, 小键盘2技能, 小键盘7890选技能
// R: 游戏复位

module uart_key_decoder (
    input           clk,
    input           rstn,
    
    input [7:0]     rx_data,
    input           rx_valid,
    
    // P1 控制
    output reg      p1_up,
    output reg      p1_down,
    output reg      p1_left,
    output reg      p1_right,
    output reg      p1_fire,
    output reg      p1_skill,
    output reg [1:0] p1_skill_sel,
    output reg      p1_ready,
    
    // P2 控制
    output reg      p2_up,
    output reg      p2_down,
    output reg      p2_left,
    output reg      p2_right,
    output reg      p2_fire,
    output reg      p2_skill,
    output reg [1:0] p2_skill_sel,
    output reg      p2_ready,
    
    // 游戏复位
    output reg      game_reset
);

    // 按键码定义 (由Python程序发送)
    // P1移动: w/W, s/S, a/A, d/D
    // P1开火: h/H
    // P1技能: j/J
    // P1选择: 1,2,3,4 (数字键)
    // P1确认: q
    
    // P2移动: i/I, k/K, l/L, o/O (用字母代替方向键)
    // P2开火: n/N (代替小键盘2)
    // P2技能: m/M (代替小键盘3)
    // P2选择: 7,8,9,0
    // P2确认: p
    
    // 空格开始游戏: ' '
    
    always @(posedge clk) begin
        if (!rstn) begin
            p1_up <= 0; p1_down <= 0; p1_left <= 0; p1_right <= 0;
            p1_fire <= 0; p1_skill <= 0; p1_skill_sel <= 2'd0; p1_ready <= 0;
            p2_up <= 0; p2_down <= 0; p2_left <= 0; p2_right <= 0;
            p2_fire <= 0; p2_skill <= 0; p2_skill_sel <= 2'd0; p2_ready <= 0;
            game_reset <= 0;
        end
        else begin
            // 复位信号只持续一个周期
            game_reset <= 0;
            
            if (rx_valid) begin
                case (rx_data)
                // P1 移动
                "w": p1_up    <= 1;
                "W": p1_up    <= 0;
                "s": p1_down  <= 1;
                "S": p1_down  <= 0;
                "a": p1_left  <= 1;
                "A": p1_left  <= 0;
                "d": p1_right <= 1;
                "D": p1_right <= 0;
                
                // P1 开火和技能
                "h": p1_fire  <= 1;
                "H": p1_fire  <= 0;
                "j": p1_skill <= 1;
                "J": p1_skill <= 0;
                
                // P1 技能选择
                "1": p1_skill_sel <= 2'd0;  // 加速
                "2": p1_skill_sel <= 2'd1;  // 护盾
                "3": p1_skill_sel <= 2'd2;  // 穿墙弹
                "4": p1_skill_sel <= 2'd3;  // 散弹
                
                // P1 确认
                "q": p1_ready <= 1;
                
                // P2 移动 (用字母键代替方向键)
                "i": p2_up    <= 1;
                "I": p2_up    <= 0;
                "k": p2_down  <= 1;
                "K": p2_down  <= 0;
                "l": p2_right <= 1;
                "L": p2_right <= 0;
                "o": p2_left  <= 1;  // 注意：o是左
                "O": p2_left  <= 0;
                
                // P2 开火和技能
                "n": p2_fire  <= 1;
                "N": p2_fire  <= 0;
                "m": p2_skill <= 1;
                "M": p2_skill <= 0;
                
                // P2 技能选择
                "7": p2_skill_sel <= 2'd0;
                "8": p2_skill_sel <= 2'd1;
                "9": p2_skill_sel <= 2'd2;
                "0": p2_skill_sel <= 2'd3;
                
                // P2 确认
                "p": p2_ready <= 1;
                
                // 游戏复位
                "r", "R": game_reset <= 1;
                
                default: ;
            endcase
            end
        end
    end

endmodule