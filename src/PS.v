// PS模块：边沿检测（取下降沿）
module PS#(
    parameter  WIDTH = 1
)(
    input             s,
    input             clk,
    output            p
);

reg s_delay;

always @(posedge clk) begin
    s_delay <= s;
end

// 检测下降沿：前一周期为1，当前周期为0时输出脉冲
// 但这里输入的是 ~(hen&ven)，所以实际上是检测 hen&ven 的下降沿
// 当 s 从 0 变到 1 时产生脉冲（即 ~(hen&ven) 的上升沿 = (hen&ven) 的下降沿）
assign p = s & ~s_delay;

endmodule
