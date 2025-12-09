# gif_to_coe.py
# 将GIF动图转换为COE文件，用于FPGA视频播放

from PIL import Image
import sys
import os

def gif_to_coe(gif_path, output_path="video_frames.coe", width=200, height=150, max_frames=None):
    """
    将GIF动图转换为COE文件
    
    参数:
        gif_path: GIF文件路径
        output_path: 输出COE文件路径
        width: 目标宽度 (默认200)
        height: 目标高度 (默认150)
        max_frames: 最大帧数限制 (None表示不限制)
    """
    
    # 打开GIF
    gif = Image.open(gif_path)
    
    # 获取GIF信息
    print(f"GIF文件: {gif_path}")
    print(f"原始尺寸: {gif.size}")
    print(f"目标尺寸: {width}x{height}")
    
    # 提取所有帧
    frames = []
    try:
        frame_idx = 0
        while True:
            # 复制当前帧并转换为RGB
            frame = gif.copy().convert("RGB")
            frames.append(frame)
            frame_idx += 1
            
            # 检查是否达到最大帧数
            if max_frames and frame_idx >= max_frames:
                print(f"达到最大帧数限制: {max_frames}")
                break
            
            # 跳到下一帧
            gif.seek(frame_idx)
    except EOFError:
        pass  # 已经读取完所有帧
    
    total_frames = len(frames)
    frame_size = width * height
    total_pixels = total_frames * frame_size
    
    print(f"")
    print(f"提取帧数: {total_frames}")
    print(f"每帧像素: {frame_size}")
    print(f"总像素数: {total_pixels}")
    print(f"所需BRAM: {total_pixels * 12 / 1024:.1f} Kbit")
    print(f"")
    
    # 检查容量
    max_bram = 4860  # XC7A100T的BRAM容量 (Kbit)
    used_bram = total_pixels * 12 / 1024
    if used_bram > max_bram * 0.8:
        print(f"警告: 使用了 {used_bram/max_bram*100:.1f}% 的BRAM容量!")
    
    # 生成COE文件
    print(f"正在生成COE文件...")
    
    with open(output_path, "w") as file:
        # 写入文件头
        file.write(f"; GIF to COE - {os.path.basename(gif_path)}\n")
        file.write(f"; Frames: {total_frames}, Size: {width}x{height}\n")
        file.write(f"; Total pixels: {total_pixels}\n")
        file.write(f"; BRAM config: Width=12, Depth={total_pixels}\n")
        file.write("memory_initialization_radix=16;\n")
        file.write("memory_initialization_vector=\n")
        
        pixel_count = 0
        
        for frame_idx, frame in enumerate(frames):
            print(f"  处理帧 {frame_idx + 1}/{total_frames}...", end="\r")
            
            # 调整大小
            img = frame.resize((width, height), Image.Resampling.LANCZOS)
            
            # 写入像素
            for j in range(height):
                for i in range(width):
                    data = img.getpixel((i, j))
                    
                    # 转换为4位颜色 (0-15)
                    r = data[0] // 16
                    g = data[1] // 16
                    b = data[2] // 16
                    hex_val = f"{r:01X}{g:01X}{b:01X}"
                    
                    pixel_count += 1
                    
                    # 最后一个像素不加逗号
                    if pixel_count == total_pixels:
                        file.write(hex_val)
                    else:
                        file.write(hex_val + ",\n")
        
        file.write(";\n")
    
    print(f"")
    print(f"========================================")
    print(f"生成完成!")
    print(f"========================================")
    print(f"输出文件: {output_path}")
    print(f"帧数: {total_frames}")
    print(f"")
    print(f"Vivado Block Memory Generator 配置:")
    print(f"  - Memory Type: Single Port ROM")
    print(f"  - Port A Width: 12")
    print(f"  - Port A Depth: {total_pixels}")
    print(f"  - Load Init File: {output_path}")
    print(f"")
    print(f"Verilog 参数:")
    print(f"  - FRAME_COUNT = {total_frames}")
    print(f"  - FRAME_SIZE  = {frame_size}")
    print(f"========================================")
    
    return total_frames, frame_size


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("GIF转COE工具 - 用于FPGA视频播放")
        print("")
        print("用法:")
        print("  python gif_to_coe.py <gif文件> [选项]")
        print("")
        print("选项:")
        print("  -o <文件名>     输出文件名 (默认: video_frames.coe)")
        print("  -w <宽度>       目标宽度 (默认: 200)")
        print("  -h <高度>       目标高度 (默认: 150)")
        print("  -m <帧数>       最大帧数限制")
        print("")
        print("示例:")
        print("  python gif_to_coe.py animation.gif")
        print("  python gif_to_coe.py animation.gif -o output.coe")
        print("  python gif_to_coe.py animation.gif -m 8")
        print("  python gif_to_coe.py animation.gif -w 100 -h 75 -m 16")
    else:
        # 解析参数
        gif_path = sys.argv[1]
        output_path = "video_frames.coe"
        width = 200
        height = 150
        max_frames = None
        
        i = 2
        while i < len(sys.argv):
            if sys.argv[i] == "-o":
                output_path = sys.argv[i + 1]
                i += 2
            elif sys.argv[i] == "-w":
                width = int(sys.argv[i + 1])
                i += 2
            elif sys.argv[i] == "-h":
                height = int(sys.argv[i + 1])
                i += 2
            elif sys.argv[i] == "-m":
                max_frames = int(sys.argv[i + 1])
                i += 2
            else:
                i += 1
        
        gif_to_coe(gif_path, output_path, width, height, max_frames)
