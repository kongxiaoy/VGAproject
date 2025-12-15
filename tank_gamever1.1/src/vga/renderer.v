// 游戏渲染模块 - 带像素文字

module renderer #(
    parameter integer BULLET_NUM = 64
) (
    input           pclk,
    input           rstn,
    
    input [7:0]     pixel_x,
    input [8:0]     pixel_y,
    input           in_display,
    
    // 游戏状态
    input           game_start,
    input           game_over,
    input           p1_win,
    input [1:0]     p1_skill_sel,
    input [1:0]     p2_skill_sel,
    input           p1_ready,
    input           p2_ready,
    
    // P1 坦克
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input [1:0]     p1_dir,
    input [1:0]     p1_hp,
    input           p1_alive,
    input           p1_shield,
    
    // P2 坦克
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input [1:0]     p2_dir,
    input [1:0]     p2_hp,
    input           p2_alive,
    input           p2_shield,
    
    // 子弹（支持 64/128）
    input [BULLET_NUM-1:0]     bullet_active,
    input [BULLET_NUM*8-1:0]   bullet_x,
    input [BULLET_NUM*8-1:0]   bullet_y,
    input [BULLET_NUM-1:0]     bullet_owner,
    
    // 地图
    output [7:0]    map_rd_x,
    output [7:0]    map_rd_y,
    input           map_wall,
    
    output reg [11:0] rgb
);

    // 颜色定义
    localparam COLOR_BG        = 12'hFFF;
    localparam COLOR_WALL      = 12'h333;
    localparam COLOR_P1_TANK   = 12'h0A0;
    localparam COLOR_P2_TANK   = 12'h00A;
    localparam COLOR_BULLET    = 12'hF80;
    localparam COLOR_HEART     = 12'hF00;
    localparam COLOR_SHIELD    = 12'h0FF;
    localparam COLOR_TEXT      = 12'h000;
    localparam COLOR_SELECT    = 12'hFF0;
    localparam COLOR_WIN_P1    = 12'h0F0;
    localparam COLOR_WIN_P2    = 12'h00F;
    
    localparam TANK_W = 3;
    localparam TANK_H = 4;
    localparam BULLET_SIZE = 2;
    localparam STATUS_HEIGHT = 8;
    
    // 子弹数组（拆包）
    wire [7:0] bx [0:BULLET_NUM-1];
    wire [7:0] by [0:BULLET_NUM-1];
    genvar bgi;
    generate
        for (bgi = 0; bgi < BULLET_NUM; bgi = bgi + 1) begin : unpack_bullets
            assign bx[bgi] = bullet_x[bgi*8 +: 8];
            assign by[bgi] = bullet_y[bgi*8 +: 8];
        end
    endgenerate
    
    // 游戏区域坐标
    wire [8:0] game_y = pixel_y - STATUS_HEIGHT;
    assign map_rd_x = pixel_x;
    assign map_rd_y = game_y[7:0];
    
    // 区域判断
    wire in_status = (pixel_y < STATUS_HEIGHT);
    wire in_game = (pixel_y >= STATUS_HEIGHT && pixel_y < 150);
    
    // ========== 5x7 像素字体 ROM ==========
    // 数字 0-9, 字母 P, W, I, N, R, S, H, D, Y, Q
    
    // 获取字符像素 (5列 x 7行)
    // row: 0-6, col: 0-4
    function get_char_pixel;
        input [7:0] char;
        input [2:0] row;
        input [2:0] col;
        reg [4:0] line;
        begin
            line = 5'b00000;
            case (char)
                "0": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10011;
                    3'd3: line = 5'b10101;
                    3'd4: line = 5'b11001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b01110;
                endcase
                "1": case (row)
                    3'd0: line = 5'b00100;
                    3'd1: line = 5'b01100;
                    3'd2: line = 5'b00100;
                    3'd3: line = 5'b00100;
                    3'd4: line = 5'b00100;
                    3'd5: line = 5'b00100;
                    3'd6: line = 5'b01110;
                endcase
                "2": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b00001;
                    3'd3: line = 5'b00110;
                    3'd4: line = 5'b01000;
                    3'd5: line = 5'b10000;
                    3'd6: line = 5'b11111;
                endcase
                "3": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b00001;
                    3'd3: line = 5'b00110;
                    3'd4: line = 5'b00001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b01110;
                endcase
                "4": case (row)
                    3'd0: line = 5'b00010;
                    3'd1: line = 5'b00110;
                    3'd2: line = 5'b01010;
                    3'd3: line = 5'b10010;
                    3'd4: line = 5'b11111;
                    3'd5: line = 5'b00010;
                    3'd6: line = 5'b00010;
                endcase
                "7": case (row)
                    3'd0: line = 5'b11111;
                    3'd1: line = 5'b00001;
                    3'd2: line = 5'b00010;
                    3'd3: line = 5'b00100;
                    3'd4: line = 5'b01000;
                    3'd5: line = 5'b01000;
                    3'd6: line = 5'b01000;
                endcase
                "8": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b01110;
                    3'd4: line = 5'b10001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b01110;
                endcase
                "9": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b01111;
                    3'd4: line = 5'b00001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b01110;
                endcase
                "P": case (row)
                    3'd0: line = 5'b11110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b11110;
                    3'd4: line = 5'b10000;
                    3'd5: line = 5'b10000;
                    3'd6: line = 5'b10000;
                endcase
                "W": case (row)
                    3'd0: line = 5'b10001;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b10101;
                    3'd4: line = 5'b10101;
                    3'd5: line = 5'b10101;
                    3'd6: line = 5'b01010;
                endcase
                "I": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b00100;
                    3'd2: line = 5'b00100;
                    3'd3: line = 5'b00100;
                    3'd4: line = 5'b00100;
                    3'd5: line = 5'b00100;
                    3'd6: line = 5'b01110;
                endcase
                "N": case (row)
                    3'd0: line = 5'b10001;
                    3'd1: line = 5'b11001;
                    3'd2: line = 5'b10101;
                    3'd3: line = 5'b10101;
                    3'd4: line = 5'b10011;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b10001;
                endcase
                "S": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10000;
                    3'd3: line = 5'b01110;
                    3'd4: line = 5'b00001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b01110;
                endcase
                "H": case (row)
                    3'd0: line = 5'b10001;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b11111;
                    3'd4: line = 5'b10001;
                    3'd5: line = 5'b10001;
                    3'd6: line = 5'b10001;
                endcase
                "D": case (row)
                    3'd0: line = 5'b11100;
                    3'd1: line = 5'b10010;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b10001;
                    3'd4: line = 5'b10001;
                    3'd5: line = 5'b10010;
                    3'd6: line = 5'b11100;
                endcase
                "R": case (row)
                    3'd0: line = 5'b11110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b11110;
                    3'd4: line = 5'b10100;
                    3'd5: line = 5'b10010;
                    3'd6: line = 5'b10001;
                endcase
                "Q": case (row)
                    3'd0: line = 5'b01110;
                    3'd1: line = 5'b10001;
                    3'd2: line = 5'b10001;
                    3'd3: line = 5'b10001;
                    3'd4: line = 5'b10101;
                    3'd5: line = 5'b10010;
                    3'd6: line = 5'b01101;
                endcase
                ":": case (row)
                    3'd0: line = 5'b00000;
                    3'd1: line = 5'b00100;
                    3'd2: line = 5'b00000;
                    3'd3: line = 5'b00000;
                    3'd4: line = 5'b00100;
                    3'd5: line = 5'b00000;
                    3'd6: line = 5'b00000;
                endcase
                default: line = 5'b00000;
            endcase
            get_char_pixel = line[4 - col];
        end
    endfunction
    
    // ========== 技能选择界面文字绘制 ==========
    // P1区域: x=20-80, y=20-130
    // P2区域: x=120-180, y=20-130
    
    // P1标题 "P1" 位置 (35, 15)
    wire in_p1_title = !game_start && (pixel_x >= 35) && (pixel_x < 47) && (pixel_y >= 15) && (pixel_y < 22);
    wire [2:0] p1_title_col = pixel_x - 35;
    wire [2:0] p1_title_row = pixel_y - 15;
    wire p1_title_pixel = (p1_title_col < 5) ? get_char_pixel("P", p1_title_row, p1_title_col) :
                          (p1_title_col >= 7 && p1_title_col < 12) ? get_char_pixel("1", p1_title_row, p1_title_col - 7) : 1'b0;
    
    // P2标题 "P2" 位置 (135, 15)
    wire in_p2_title = !game_start && (pixel_x >= 135) && (pixel_x < 147) && (pixel_y >= 15) && (pixel_y < 22);
    wire [2:0] p2_title_col = pixel_x - 135;
    wire [2:0] p2_title_row = pixel_y - 15;
    wire p2_title_pixel = (p2_title_col < 5) ? get_char_pixel("P", p2_title_row, p2_title_col) :
                          (p2_title_col >= 7 && p2_title_col < 12) ? get_char_pixel("2", p2_title_row, p2_title_col - 7) : 1'b0;
    
    // 技能数字 (每个选项旁边显示对应数字)
    // P1: 1,2,3,4  P2: 7,8,9,0
    // 选项位置: y=35,55,75,95 (每个选项高度15)
    
    // P1选项数字位置
    wire in_p1_num = !game_start && (pixel_x >= 22) && (pixel_x < 27);
    wire [1:0] p1_num_idx = (pixel_y >= 35 && pixel_y < 42) ? 2'd0 :
                            (pixel_y >= 55 && pixel_y < 62) ? 2'd1 :
                            (pixel_y >= 75 && pixel_y < 82) ? 2'd2 :
                            (pixel_y >= 95 && pixel_y < 102) ? 2'd3 : 2'd0;
    wire in_p1_num_valid = in_p1_num && ((pixel_y >= 35 && pixel_y < 42) ||
                                          (pixel_y >= 55 && pixel_y < 62) ||
                                          (pixel_y >= 75 && pixel_y < 82) ||
                                          (pixel_y >= 95 && pixel_y < 102));
    wire [2:0] p1_num_row = (pixel_y >= 95) ? pixel_y - 95 :
                            (pixel_y >= 75) ? pixel_y - 75 :
                            (pixel_y >= 55) ? pixel_y - 55 : pixel_y - 35;
    wire [2:0] p1_num_col = pixel_x - 22;
    wire p1_num_pixel = (p1_num_idx == 2'd0) ? get_char_pixel("1", p1_num_row, p1_num_col) :
                        (p1_num_idx == 2'd1) ? get_char_pixel("2", p1_num_row, p1_num_col) :
                        (p1_num_idx == 2'd2) ? get_char_pixel("3", p1_num_row, p1_num_col) :
                                               get_char_pixel("4", p1_num_row, p1_num_col);
    
    // P2选项数字位置
    wire in_p2_num = !game_start && (pixel_x >= 122) && (pixel_x < 127);
    wire [1:0] p2_num_idx = (pixel_y >= 35 && pixel_y < 42) ? 2'd0 :
                            (pixel_y >= 55 && pixel_y < 62) ? 2'd1 :
                            (pixel_y >= 75 && pixel_y < 82) ? 2'd2 :
                            (pixel_y >= 95 && pixel_y < 102) ? 2'd3 : 2'd0;
    wire in_p2_num_valid = in_p2_num && ((pixel_y >= 35 && pixel_y < 42) ||
                                          (pixel_y >= 55 && pixel_y < 62) ||
                                          (pixel_y >= 75 && pixel_y < 82) ||
                                          (pixel_y >= 95 && pixel_y < 102));
    wire [2:0] p2_num_row = (pixel_y >= 95) ? pixel_y - 95 :
                            (pixel_y >= 75) ? pixel_y - 75 :
                            (pixel_y >= 55) ? pixel_y - 55 : pixel_y - 35;
    wire [2:0] p2_num_col = pixel_x - 122;
    wire p2_num_pixel = (p2_num_idx == 2'd0) ? get_char_pixel("7", p2_num_row, p2_num_col) :
                        (p2_num_idx == 2'd1) ? get_char_pixel("8", p2_num_row, p2_num_col) :
                        (p2_num_idx == 2'd2) ? get_char_pixel("9", p2_num_row, p2_num_col) :
                                               get_char_pixel("0", p2_num_row, p2_num_col);
    
    // 技能选项框
    wire in_p1_skill_area = !game_start && (pixel_x >= 30) && (pixel_x < 75);
    wire in_p1_skill0 = in_p1_skill_area && (pixel_y >= 32) && (pixel_y < 47);
    wire in_p1_skill1 = in_p1_skill_area && (pixel_y >= 52) && (pixel_y < 67);
    wire in_p1_skill2 = in_p1_skill_area && (pixel_y >= 72) && (pixel_y < 87);
    wire in_p1_skill3 = in_p1_skill_area && (pixel_y >= 92) && (pixel_y < 107);
    
    wire in_p2_skill_area = !game_start && (pixel_x >= 130) && (pixel_x < 175);
    wire in_p2_skill0 = in_p2_skill_area && (pixel_y >= 32) && (pixel_y < 47);
    wire in_p2_skill1 = in_p2_skill_area && (pixel_y >= 52) && (pixel_y < 67);
    wire in_p2_skill2 = in_p2_skill_area && (pixel_y >= 72) && (pixel_y < 87);
    wire in_p2_skill3 = in_p2_skill_area && (pixel_y >= 92) && (pixel_y < 107);
    
    // 技能颜色条 (区分技能类型)
    wire in_skill_color_p1 = in_p1_skill_area && (pixel_x >= 30) && (pixel_x < 35);
    wire in_skill_color_p2 = in_p2_skill_area && (pixel_x >= 130) && (pixel_x < 135);
    
    // Ready按钮
    wire in_p1_ready_btn = !game_start && (pixel_x >= 32) && (pixel_x < 73) && (pixel_y >= 115) && (pixel_y < 130);
    wire in_p2_ready_btn = !game_start && (pixel_x >= 132) && (pixel_x < 173) && (pixel_y >= 115) && (pixel_y < 130);
    
    // "Q" 和 "P" Ready按键提示
    wire in_p1_q = !game_start && (pixel_x >= 48) && (pixel_x < 53) && (pixel_y >= 119) && (pixel_y < 126);
    wire [2:0] p1_q_row = pixel_y - 119;
    wire [2:0] p1_q_col = pixel_x - 48;
    wire p1_q_pixel = get_char_pixel("Q", p1_q_row, p1_q_col);
    
    wire in_p2_p = !game_start && (pixel_x >= 148) && (pixel_x < 153) && (pixel_y >= 119) && (pixel_y < 126);
    wire [2:0] p2_p_row = pixel_y - 119;
    wire [2:0] p2_p_col = pixel_x - 148;
    wire p2_p_pixel = get_char_pixel("P", p2_p_row, p2_p_col);
    
    // ========== 获胜界面 ==========
    // "P1 WIN" 或 "P2 WIN" 居中显示
    wire in_win_box = game_over && (pixel_x >= 70) && (pixel_x < 130) && (pixel_y >= 60) && (pixel_y < 90);
    wire in_win_text = game_over && (pixel_x >= 78) && (pixel_x < 122) && (pixel_y >= 70) && (pixel_y < 77);
    wire [6:0] win_text_x = pixel_x - 78;
    wire [2:0] win_text_row = pixel_y - 70;
    // P, 1/2, 空格, W, I, N
    wire win_text_pixel = (win_text_x < 5) ? get_char_pixel("P", win_text_row, win_text_x[2:0]) :
                          (win_text_x >= 6 && win_text_x < 11) ? (p1_win ? get_char_pixel("1", win_text_row, win_text_x[2:0] - 3'd6) : get_char_pixel("2", win_text_row, win_text_x[2:0] - 3'd6)) :
                          (win_text_x >= 14 && win_text_x < 19) ? get_char_pixel("W", win_text_row, win_text_x[2:0] - 3'd6) :
                          (win_text_x >= 20 && win_text_x < 25) ? get_char_pixel("I", win_text_row, win_text_x[2:0] - 3'd4) :
                          (win_text_x >= 26 && win_text_x < 31) ? get_char_pixel("N", win_text_row, win_text_x[2:0] - 3'd2) : 1'b0;
    
    // "PRESS R" 提示
    wire in_reset_hint = game_over && (pixel_x >= 75) && (pixel_x < 125) && (pixel_y >= 80) && (pixel_y < 87);
    
    // ========== 坦克渲染 ==========
    wire in_p1_area = p1_alive && in_game &&
                      (pixel_x >= p1_x) && (pixel_x < p1_x + TANK_W) &&
                      (game_y >= p1_y) && (game_y < p1_y + TANK_H);
    
    reg p1_pixel;
    wire [7:0] p1_dx = pixel_x - p1_x;
    wire [7:0] p1_dy = game_y - p1_y;
    
    always @(*) begin
        p1_pixel = 1'b0;
        if (in_p1_area) begin
            case (p1_dir)
                2'd0: begin
                    if (p1_dy == 0 && p1_dx == 1) p1_pixel = 1'b1;
                    if (p1_dy >= 1 && p1_dy <= 3) p1_pixel = 1'b1;
                end
                2'd1: begin
                    if (p1_dy == 3 && p1_dx == 1) p1_pixel = 1'b1;
                    if (p1_dy >= 0 && p1_dy <= 2) p1_pixel = 1'b1;
                end
                2'd2: begin
                    if (p1_dx == 0 && p1_dy == 1) p1_pixel = 1'b1;
                    if (p1_dx >= 1 && p1_dx <= 2 && p1_dy <= 2) p1_pixel = 1'b1;
                end
                2'd3: begin
                    if (p1_dx == 2 && p1_dy == 1) p1_pixel = 1'b1;
                    if (p1_dx >= 0 && p1_dx <= 1 && p1_dy <= 2) p1_pixel = 1'b1;
                end
            endcase
        end
    end
    
    wire in_p2_area = p2_alive && in_game &&
                      (pixel_x >= p2_x) && (pixel_x < p2_x + TANK_W) &&
                      (game_y >= p2_y) && (game_y < p2_y + TANK_H);
    
    reg p2_pixel;
    wire [7:0] p2_dx = pixel_x - p2_x;
    wire [7:0] p2_dy = game_y - p2_y;
    
    always @(*) begin
        p2_pixel = 1'b0;
        if (in_p2_area) begin
            case (p2_dir)
                2'd0: begin
                    if (p2_dy == 0 && p2_dx == 1) p2_pixel = 1'b1;
                    if (p2_dy >= 1 && p2_dy <= 3) p2_pixel = 1'b1;
                end
                2'd1: begin
                    if (p2_dy == 3 && p2_dx == 1) p2_pixel = 1'b1;
                    if (p2_dy >= 0 && p2_dy <= 2) p2_pixel = 1'b1;
                end
                2'd2: begin
                    if (p2_dx == 0 && p2_dy == 1) p2_pixel = 1'b1;
                    if (p2_dx >= 1 && p2_dx <= 2 && p2_dy <= 2) p2_pixel = 1'b1;
                end
                2'd3: begin
                    if (p2_dx == 2 && p2_dy == 1) p2_pixel = 1'b1;
                    if (p2_dx >= 0 && p2_dx <= 1 && p2_dy <= 2) p2_pixel = 1'b1;
                end
            endcase
        end
    end
    
    // 护盾显示
    wire in_p1_shield = p1_shield && p1_alive && in_game &&
                        (pixel_x >= p1_x - 1) && (pixel_x < p1_x + TANK_W + 1) &&
                        (game_y >= p1_y - 1) && (game_y < p1_y + TANK_H + 1) &&
                        !in_p1_area;
    
    wire in_p2_shield = p2_shield && p2_alive && in_game &&
                        (pixel_x >= p2_x - 1) && (pixel_x < p2_x + TANK_W + 1) &&
                        (game_y >= p2_y - 1) && (game_y < p2_y + TANK_H + 1) &&
                        !in_p2_area;
    
    // ========== 子弹检测 ==========
    wire [BULLET_NUM-1:0] in_bullet;
    genvar i;
    generate
        for (i = 0; i < BULLET_NUM; i = i + 1) begin : bullet_check
            assign in_bullet[i] = bullet_active[i] && in_game &&
                                  (pixel_x >= bx[i]) && (pixel_x < bx[i] + BULLET_SIZE) &&
                                  (game_y >= by[i]) && (game_y < by[i] + BULLET_SIZE);
        end
    endgenerate
    
    // 所有子弹统一颜色
    wire any_bullet = |in_bullet;
    
    // ========== 状态栏HP ==========
    wire in_p1_hp1 = in_status && (pixel_x >= 2) && (pixel_x < 7) && (pixel_y >= 2) && (pixel_y < 6) && (p1_hp >= 1);
    wire in_p1_hp2 = in_status && (pixel_x >= 9) && (pixel_x < 14) && (pixel_y >= 2) && (pixel_y < 6) && (p1_hp >= 2);
    wire in_p1_hp3 = in_status && (pixel_x >= 16) && (pixel_x < 21) && (pixel_y >= 2) && (pixel_y < 6) && (p1_hp >= 3);
    
    wire in_p2_hp1 = in_status && (pixel_x >= 179) && (pixel_x < 184) && (pixel_y >= 2) && (pixel_y < 6) && (p2_hp >= 1);
    wire in_p2_hp2 = in_status && (pixel_x >= 186) && (pixel_x < 191) && (pixel_y >= 2) && (pixel_y < 6) && (p2_hp >= 2);
    wire in_p2_hp3 = in_status && (pixel_x >= 193) && (pixel_x < 198) && (pixel_y >= 2) && (pixel_y < 6) && (p2_hp >= 3);
    
    wire any_hp = in_p1_hp1 | in_p1_hp2 | in_p1_hp3 | in_p2_hp1 | in_p2_hp2 | in_p2_hp3;
    wire in_status_line = (pixel_y == STATUS_HEIGHT - 1);
    
    // ========== 像素输出 ==========
    always @(posedge pclk) begin
        if (!rstn || !in_display) begin
            rgb <= 12'h000;
        end
        else if (game_over) begin
            // 获胜界面
            if (in_win_text && win_text_pixel) rgb <= COLOR_TEXT;
            else if (in_reset_hint) rgb <= 12'h888;
            else if (in_win_box) rgb <= p1_win ? COLOR_WIN_P1 : COLOR_WIN_P2;
            // 背景继续显示游戏画面
            else if (any_bullet) rgb <= COLOR_BULLET;
            else if (p1_pixel) rgb <= COLOR_P1_TANK;
            else if (p2_pixel) rgb <= COLOR_P2_TANK;
            else if (in_game && map_wall) rgb <= COLOR_WALL;
            else if (any_hp) rgb <= COLOR_HEART;
            else if (in_status_line) rgb <= COLOR_WALL;
            else rgb <= COLOR_BG;
        end
        else if (!game_start) begin
            // 技能选择界面
            // 标题文字
            if (in_p1_title && p1_title_pixel) rgb <= COLOR_P1_TANK;
            else if (in_p2_title && p2_title_pixel) rgb <= COLOR_P2_TANK;
            // 数字
            else if (in_p1_num_valid && p1_num_pixel) rgb <= COLOR_TEXT;
            else if (in_p2_num_valid && p2_num_pixel) rgb <= COLOR_TEXT;
            // 技能颜色条
            else if (in_skill_color_p1 && in_p1_skill0) rgb <= 12'hF00;  // 加速-红
            else if (in_skill_color_p1 && in_p1_skill1) rgb <= 12'h0FF;  // 护盾-青
            else if (in_skill_color_p1 && in_p1_skill2) rgb <= 12'hFF0;  // 穿墙-黄
            else if (in_skill_color_p1 && in_p1_skill3) rgb <= 12'hF0F;  // 散弹-紫
            else if (in_skill_color_p2 && in_p2_skill0) rgb <= 12'hF00;
            else if (in_skill_color_p2 && in_p2_skill1) rgb <= 12'h0FF;
            else if (in_skill_color_p2 && in_p2_skill2) rgb <= 12'hFF0;
            else if (in_skill_color_p2 && in_p2_skill3) rgb <= 12'hF0F;
            // 技能选项高亮
            else if (in_p1_skill0 && (p1_skill_sel == 2'd0)) rgb <= COLOR_SELECT;
            else if (in_p1_skill1 && (p1_skill_sel == 2'd1)) rgb <= COLOR_SELECT;
            else if (in_p1_skill2 && (p1_skill_sel == 2'd2)) rgb <= COLOR_SELECT;
            else if (in_p1_skill3 && (p1_skill_sel == 2'd3)) rgb <= COLOR_SELECT;
            else if (in_p2_skill0 && (p2_skill_sel == 2'd0)) rgb <= COLOR_SELECT;
            else if (in_p2_skill1 && (p2_skill_sel == 2'd1)) rgb <= COLOR_SELECT;
            else if (in_p2_skill2 && (p2_skill_sel == 2'd2)) rgb <= COLOR_SELECT;
            else if (in_p2_skill3 && (p2_skill_sel == 2'd3)) rgb <= COLOR_SELECT;
            // 技能选项背景
            else if (in_p1_skill0 || in_p1_skill1 || in_p1_skill2 || in_p1_skill3) rgb <= 12'hEEE;
            else if (in_p2_skill0 || in_p2_skill1 || in_p2_skill2 || in_p2_skill3) rgb <= 12'hEEE;
            // Ready按钮文字
            else if (in_p1_q && p1_q_pixel) rgb <= p1_ready ? 12'hFFF : COLOR_TEXT;
            else if (in_p2_p && p2_p_pixel) rgb <= p2_ready ? 12'hFFF : COLOR_TEXT;
            // Ready按钮
            else if (in_p1_ready_btn) rgb <= p1_ready ? COLOR_P1_TANK : 12'hAAA;
            else if (in_p2_ready_btn) rgb <= p2_ready ? COLOR_P2_TANK : 12'hAAA;
            else rgb <= COLOR_BG;
        end
        else begin
            // 游戏画面
            if (any_bullet) rgb <= COLOR_BULLET;
            else if (in_p1_shield) rgb <= COLOR_SHIELD;
            else if (in_p2_shield) rgb <= COLOR_SHIELD;
            else if (p1_pixel) rgb <= COLOR_P1_TANK;
            else if (p2_pixel) rgb <= COLOR_P2_TANK;
            else if (in_game && map_wall) rgb <= COLOR_WALL;
            else if (any_hp) rgb <= COLOR_HEART;
            else if (in_status_line) rgb <= COLOR_WALL;
            else rgb <= COLOR_BG;
        end
    end

endmodule