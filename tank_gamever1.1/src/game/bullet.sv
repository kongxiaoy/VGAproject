// 子弹管理模块 - 支持反弹、散弹、穿墙
// 子弹速度为坦克速度的1.5倍（坦克速度1，子弹速度使用计数器实现1.5）

module bullet #(
    parameter integer BULLET_NUM = 64
) (
    input           clk,
    input           rstn,
    input           game_tick,
    input           game_start,
    
    // P1 发射
    input           p1_fire,
    input           p1_spread,
    input           p1_pierce,
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input [1:0]     p1_dir,
    
    // P2 发射
    input           p2_fire,
    input           p2_spread,
    input           p2_pierce,
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input [1:0]     p2_dir,
    
    // 墙壁碰撞（兼容旧接口：本版本在内部直接判断墙壁，不再依赖外部 map 端口）
    output reg [7:0]    wall_check_x,
    output reg [7:0]    wall_check_y,
    input               wall_hit,
    
    // 子弹状态输出
    output reg [BULLET_NUM-1:0]         bullet_active,
    output     [BULLET_NUM*8-1:0]       bullet_x,
    output     [BULLET_NUM*8-1:0]       bullet_y,
    output     [BULLET_NUM*2-1:0]       bullet_dir,
    output reg [BULLET_NUM-1:0]         bullet_owner,
    output reg [BULLET_NUM-1:0]         bullet_pierce
);

    // ============================================================
    // 可修改参数区域
    // ============================================================
    // 子弹每个 game_tick 的移动距离（像素）。
    // 提示：本模块已加入“逐像素扫掠”墙壁检测，较大步长也不会穿墙。
    localparam integer BULLET_MOVE_PIXELS = 5;
    localparam MAX_BOUNCES = 3;          // 最大反弹次数
    // ============================================================

    localparam integer IDX_W = $clog2(BULLET_NUM);

    // 内部存储
    reg [7:0] b_x [0:BULLET_NUM-1];
    reg [7:0] b_y [0:BULLET_NUM-1];
    reg [1:0] b_dir [0:BULLET_NUM-1];
    reg [1:0] b_bounce [0:BULLET_NUM-1];  // 反弹计数
    
    // 游戏边界
    localparam MIN_X = 2;
    localparam MAX_X = 196;
    localparam MIN_Y = 2;
    localparam MAX_Y = 140;
    
    // 说明：旧版本使用“每个 tick 只更新 1 颗子弹”的状态机，
    // 当子弹数量增大（64/128）时会导致子弹更新极慢。
    // 新版本在每个 game_tick 中对所有 active 子弹进行一次更新。
    
    // 输出打包
    genvar gi;
    generate
        for (gi = 0; gi < BULLET_NUM; gi = gi + 1) begin : pack_out
            assign bullet_x[gi*8 +: 8]   = b_x[gi];
            assign bullet_y[gi*8 +: 8]   = b_y[gi];
            assign bullet_dir[gi*2 +: 2] = b_dir[gi];
        end
    endgenerate
    
    // 找空闲槽位（支持 64/128）
    reg [IDX_W-1:0] free_slot, free_slot2, free_slot3;
    reg has_free, has_free2, has_free3;
    reg [BULLET_NUM-1:0] active_after_1, active_after_2;
    integer j;
    always @(*) begin
        // slot1
        has_free = 1'b0;
        free_slot = {IDX_W{1'b0}};
        for (j = 0; j < BULLET_NUM; j = j + 1) begin
            if (!bullet_active[j] && !has_free) begin
                has_free = 1'b1;
                free_slot = j[IDX_W-1:0];
            end
        end
        active_after_1 = bullet_active;
        if (has_free) active_after_1[free_slot] = 1'b1;

        // slot2
        has_free2 = 1'b0;
        free_slot2 = {IDX_W{1'b0}};
        for (j = 0; j < BULLET_NUM; j = j + 1) begin
            if (!active_after_1[j] && !has_free2) begin
                has_free2 = 1'b1;
                free_slot2 = j[IDX_W-1:0];
            end
        end
        active_after_2 = active_after_1;
        if (has_free2) active_after_2[free_slot2] = 1'b1;

        // slot3
        has_free3 = 1'b0;
        free_slot3 = {IDX_W{1'b0}};
        for (j = 0; j < BULLET_NUM; j = j + 1) begin
            if (!active_after_2[j] && !has_free3) begin
                has_free3 = 1'b1;
                free_slot3 = j[IDX_W-1:0];
            end
        end
    end
    
    integer i;
    
    // ============================================================
    // 墙壁判定函数（复制 map.v 的墙壁规则）
    // ============================================================
    function automatic is_wall;
        input [7:0] x;
        input [7:0] y;
        reg w;
        begin
            w = 1'b0;
            // 外边框
            if (y < 2) w = 1'b1;
            if (y >= 142) w = 1'b1;
            if (x < 2) w = 1'b1;
            if (x >= 198) w = 1'b1;
            // 水平墙壁
            if (y >= 20 && y < 22) begin
                if (x >= 30 && x <= 50) w = 1'b1;
                if (x >= 70 && x <= 90) w = 1'b1;
                if (x >= 110 && x <= 130) w = 1'b1;
                if (x >= 150 && x <= 170) w = 1'b1;
            end
            if (y >= 40 && y < 42) begin
                if (x >= 10 && x <= 40) w = 1'b1;
                if (x >= 60 && x <= 80) w = 1'b1;
                if (x >= 120 && x <= 140) w = 1'b1;
                if (x >= 160 && x <= 190) w = 1'b1;
            end
            if (y >= 60 && y < 62) begin
                if (x >= 30 && x <= 60) w = 1'b1;
                if (x >= 90 && x <= 110) w = 1'b1;
                if (x >= 140 && x <= 170) w = 1'b1;
            end
            if (y >= 80 && y < 82) begin
                if (x >= 20 && x <= 50) w = 1'b1;
                if (x >= 70 && x <= 130) w = 1'b1;
                if (x >= 150 && x <= 180) w = 1'b1;
            end
            if (y >= 100 && y < 102) begin
                if (x >= 10 && x <= 40) w = 1'b1;
                if (x >= 60 && x <= 90) w = 1'b1;
                if (x >= 110 && x <= 140) w = 1'b1;
                if (x >= 160 && x <= 190) w = 1'b1;
            end
            if (y >= 120 && y < 122) begin
                if (x >= 30 && x <= 60) w = 1'b1;
                if (x >= 80 && x <= 120) w = 1'b1;
                if (x >= 140 && x <= 170) w = 1'b1;
            end
            // 垂直墙壁
            if (x >= 40 && x < 42) begin
                if (y >= 20 && y <= 40) w = 1'b1;
                if (y >= 100 && y <= 120) w = 1'b1;
            end
            if (x >= 80 && x < 82) begin
                if (y >= 40 && y <= 60) w = 1'b1;
                if (y >= 100 && y <= 120) w = 1'b1;
            end
            if (x >= 120 && x < 122) begin
                if (y >= 20 && y <= 40) w = 1'b1;
                if (y >= 100 && y <= 120) w = 1'b1;
            end
            if (x >= 160 && x < 162) begin
                if (y >= 40 && y <= 60) w = 1'b1;
                if (y >= 100 && y <= 120) w = 1'b1;
            end
            if (x >= 20 && x < 22) begin
                if (y >= 60 && y <= 80) w = 1'b1;
            end
            if (x >= 60 && x < 62) begin
                if (y >= 80 && y <= 100) w = 1'b1;
            end
            if (x >= 100 && x < 102) begin
                if (y >= 60 && y <= 80) w = 1'b1;
            end
            if (x >= 140 && x < 142) begin
                if (y >= 80 && y <= 100) w = 1'b1;
            end
            if (x >= 180 && x < 182) begin
                if (y >= 60 && y <= 80) w = 1'b1;
            end
            is_wall = w;
        end
    endfunction

    always @(posedge clk) begin
        if (!rstn || !game_start) begin
            bullet_active <= {BULLET_NUM{1'b0}};
            bullet_owner <= {BULLET_NUM{1'b0}};
            bullet_pierce <= {BULLET_NUM{1'b0}};
            wall_check_x <= 8'd0;
            wall_check_y <= 8'd0;
            for (i = 0; i < BULLET_NUM; i = i + 1) begin
                b_x[i] <= 8'd0;
                b_y[i] <= 8'd0;
                b_dir[i] <= 2'd0;
                b_bounce[i] <= 2'd0;
            end
        end
        else begin
            // P1 发射
            if (p1_fire && has_free) begin
                bullet_active[free_slot] <= 1'b1;
                b_x[free_slot] <= p1_x;
                b_y[free_slot] <= p1_y;
                b_dir[free_slot] <= p1_dir;
                b_bounce[free_slot] <= 2'd0;
                bullet_owner[free_slot] <= 1'b0;
                bullet_pierce[free_slot] <= p1_pierce;
                
                // 散弹
                if (p1_spread && has_free2) begin
                    bullet_active[free_slot2] <= 1'b1;
                    b_x[free_slot2] <= p1_x + 3;
                    b_y[free_slot2] <= p1_y;
                    b_dir[free_slot2] <= p1_dir;
                    b_bounce[free_slot2] <= 2'd0;
                    bullet_owner[free_slot2] <= 1'b0;
                    bullet_pierce[free_slot2] <= p1_pierce;

                    if (has_free3) begin
                        bullet_active[free_slot3] <= 1'b1;
                        b_x[free_slot3] <= (p1_x > 3) ? p1_x - 3 : 8'd0;
                        b_y[free_slot3] <= p1_y;
                        b_dir[free_slot3] <= p1_dir;
                        b_bounce[free_slot3] <= 2'd0;
                        bullet_owner[free_slot3] <= 1'b0;
                        bullet_pierce[free_slot3] <= p1_pierce;
                    end
                end
            end
            
            // P2 发射
            if (p2_fire && has_free) begin
                bullet_active[free_slot] <= 1'b1;
                b_x[free_slot] <= p2_x;
                b_y[free_slot] <= p2_y;
                b_dir[free_slot] <= p2_dir;
                b_bounce[free_slot] <= 2'd0;
                bullet_owner[free_slot] <= 1'b1;
                bullet_pierce[free_slot] <= p2_pierce;
                
                if (p2_spread && has_free2) begin
                    bullet_active[free_slot2] <= 1'b1;
                    b_x[free_slot2] <= p2_x + 3;
                    b_y[free_slot2] <= p2_y;
                    b_dir[free_slot2] <= p2_dir;
                    b_bounce[free_slot2] <= 2'd0;
                    bullet_owner[free_slot2] <= 1'b1;
                    bullet_pierce[free_slot2] <= p2_pierce;

                    if (has_free3) begin
                        bullet_active[free_slot3] <= 1'b1;
                        b_x[free_slot3] <= (p2_x > 3) ? p2_x - 3 : 8'd0;
                        b_y[free_slot3] <= p2_y;
                        b_dir[free_slot3] <= p2_dir;
                        b_bounce[free_slot3] <= 2'd0;
                        bullet_owner[free_slot3] <= 1'b1;
                        bullet_pierce[free_slot3] <= p2_pierce;
                    end
                end
            end
            
            // 更新子弹位置（每个 game_tick 更新所有 active 子弹）
            if (game_tick) begin
                integer bi, step;
                reg [7:0] cx, cy;
                reg [7:0] nx, ny;
                reg [1:0] cd;
                reg hit_something;
                reg [7:0] dx, dy;

                for (bi = 0; bi < BULLET_NUM; bi = bi + 1) begin
                    if (bullet_active[bi]) begin
                        cx = b_x[bi];
                        cy = b_y[bi];
                        cd = b_dir[bi];
                        hit_something = 1'b0;

                        // 逐像素扫掠移动，避免“5 像素一步”穿墙
                        for (step = 0; step < BULLET_MOVE_PIXELS; step = step + 1) begin
                            if (!hit_something) begin
                                dx = 8'd0; dy = 8'd0;
                                case (cd)
                                    2'd0: dy = 8'hFF; // -1
                                    2'd1: dy = 8'd1;
                                    2'd2: dx = 8'hFF; // -1
                                    2'd3: dx = 8'd1;
                                endcase
                                nx = cx + dx;
                                ny = cy + dy;

                                // 边界反弹/销毁
                                if (nx <= MIN_X || nx >= MAX_X) begin
                                    if (b_bounce[bi] < MAX_BOUNCES) begin
                                        if (cd == 2'd2) cd = 2'd3;
                                        else if (cd == 2'd3) cd = 2'd2;
                                        b_bounce[bi] <= b_bounce[bi] + 1'b1;
                                        cx = (nx <= MIN_X) ? (MIN_X + 1) : (MAX_X - 1);
                                    end else begin
                                        bullet_active[bi] <= 1'b0;
                                    end
                                    hit_something = 1'b1;
                                end
                                else if (ny <= MIN_Y || ny >= MAX_Y) begin
                                    if (b_bounce[bi] < MAX_BOUNCES) begin
                                        if (cd == 2'd0) cd = 2'd1;
                                        else if (cd == 2'd1) cd = 2'd0;
                                        b_bounce[bi] <= b_bounce[bi] + 1'b1;
                                        cy = (ny <= MIN_Y) ? (MIN_Y + 1) : (MAX_Y - 1);
                                    end else begin
                                        bullet_active[bi] <= 1'b0;
                                    end
                                    hit_something = 1'b1;
                                end
                                else if (is_wall(nx, ny) && !bullet_pierce[bi]) begin
                                    // 墙壁反弹/销毁（不进入墙内）
                                    if (b_bounce[bi] < MAX_BOUNCES) begin
                                        case (cd)
                                            2'd0: cd = 2'd1;
                                            2'd1: cd = 2'd0;
                                            2'd2: cd = 2'd3;
                                            2'd3: cd = 2'd2;
                                        endcase
                                        b_bounce[bi] <= b_bounce[bi] + 1'b1;
                                    end else begin
                                        bullet_active[bi] <= 1'b0;
                                    end
                                    hit_something = 1'b1;
                                end
                                else begin
                                    // 正常前进一步
                                    cx = nx;
                                    cy = ny;
                                end
                            end
                        end

                        // 写回
                        b_x[bi]   <= cx;
                        b_y[bi]   <= cy;
                        b_dir[bi] <= cd;
                    end
                end

                // 旧接口兼容：保持为 0
                wall_check_x <= 8'd0;
                wall_check_y <= 8'd0;
            end
        end
    end

endmodule