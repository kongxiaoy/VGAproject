# TransToCoe.py
# 将图片自动转换为指定大小的.coe文件
# 最终的文件默认200*150大小

from PIL import Image
import sys
import os

def convert_image_to_coe(input_path, output_path="result.coe", width=200, height=150):
    """
    将图片转换为FPGA BRAM初始化用的coe文件
    
    参数:
        input_path: 输入图片路径
        output_path: 输出coe文件路径
        width: 目标宽度 (默认200)
        height: 目标高度 (默认150)
    """
    
    # 打开图片
    img_raw = Image.open(input_path)
    
    # 打印原始图片信息
    print(f"原始图片尺寸: {img_raw.size}")
    print(f"图片格式: {img_raw.format}")
    print(f"图片模式: {img_raw.mode}")
    
    # 调整图片大小
    img = img_raw.resize((width, height), Image.Resampling.LANCZOS)
    
    # 转换为RGB模式
    img = img.convert("RGB")
    
    # 将颜色量化为4位（16级）
    img_w = img.size[0]
    img_h = img.size[1]
    
    for i in range(img_w):
        for j in range(img_h):
            data = img.getpixel((i, j))
            # 将8位颜色转换为4位
            re = (16 * (data[0] // 16), 16 * (data[1] // 16), 16 * (data[2] // 16))
            img.putpixel((i, j), re)
    
    # 保存缩略图预览
    thumb_path = os.path.splitext(output_path)[0] + "_thumb.jpg"
    img.save(thumb_path, 'JPEG')
    print(f"缩略图已保存: {thumb_path}")
    
    # 生成coe文件
    with open(output_path, "w") as file:
        # 写入coe文件头
        file.write(f"; {width}x{height} = {width*height} pixels, 12bit RGB\n")
        file.write("memory_initialization_radix=16;\n")
        file.write("memory_initialization_vector=\n")
        
        # 写入像素数据
        for j in range(height):
            for i in range(width):
                data = img.getpixel((i, j))
                # 将RGB转换为12位十六进制 (4位R + 4位G + 4位B)
                r = data[0] // 16
                g = data[1] // 16
                b = data[2] // 16
                hex_val = f"{r:01X}{g:01X}{b:01X}"
                
                if j == height - 1 and i == width - 1:
                    file.write(hex_val)  # 最后一个像素不加逗号
                else:
                    file.write(hex_val + ",\n" if i == width - 1 else hex_val + ",")
        
        # 填充剩余空间到32K (如果需要)
        total_pixels = width * height
        mem_size = 32 * 1024  # 32K
        
        if total_pixels < mem_size:
            file.write(",\n")
            for i in range(mem_size - total_pixels):
                if i == mem_size - total_pixels - 1:
                    file.write("000")
                else:
                    file.write("000,\n" if (i + 1) % width == 0 else "000,")
        
        file.write(";\n")
    
    print(f"COE文件已生成: {output_path}")
    print(f"共 {width * height} 个像素")


def merge_frames_to_coe(input_paths, output_path="video_frames.coe", width=200, height=150):
    """
    将多张图片合并为一个coe文件，用于视频播放
    
    参数:
        input_paths: 输入图片路径列表
        output_path: 输出coe文件路径
        width: 目标宽度 (默认200)
        height: 目标高度 (默认150)
    """
    
    frame_size = width * height
    total_frames = len(input_paths)
    
    with open(output_path, "w") as file:
        file.write(f"; Video frames: {total_frames} frames, {width}x{height} each\n")
        file.write("memory_initialization_radix=16;\n")
        file.write("memory_initialization_vector=\n")
        
        for frame_idx, input_path in enumerate(input_paths):
            print(f"处理帧 {frame_idx + 1}/{total_frames}: {input_path}")
            
            img_raw = Image.open(input_path)
            img = img_raw.resize((width, height), Image.Resampling.LANCZOS)
            img = img.convert("RGB")
            
            # 量化颜色
            for i in range(width):
                for j in range(height):
                    data = img.getpixel((i, j))
                    re = (16 * (data[0] // 16), 16 * (data[1] // 16), 16 * (data[2] // 16))
                    img.putpixel((i, j), re)
            
            # 写入像素数据
            for j in range(height):
                for i in range(width):
                    data = img.getpixel((i, j))
                    r = data[0] // 16
                    g = data[1] // 16
                    b = data[2] // 16
                    hex_val = f"{r:01X}{g:01X}{b:01X}"
                    
                    is_last = (frame_idx == total_frames - 1 and j == height - 1 and i == width - 1)
                    if is_last:
                        file.write(hex_val)
                    else:
                        file.write(hex_val + ",\n" if i == width - 1 else hex_val + ",")
            
            if frame_idx < total_frames - 1:
                file.write(",\n")
        
        file.write(";\n")
    
    print(f"视频COE文件已生成: {output_path}")
    print(f"共 {total_frames} 帧, {total_frames * frame_size} 个像素")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法:")
        print("  单张图片: python TransToCoe.py <image_path> [output.coe]")
        print("  多张图片: python TransToCoe.py --video <image1> <image2> ... [--output video.coe]")
        print("")
        print("示例:")
        print("  python TransToCoe.py test.jpg")
        print("  python TransToCoe.py test.jpg result.coe")
        print("  python TransToCoe.py --video frame1.jpg frame2.jpg frame3.jpg --output video.coe")
    elif sys.argv[1] == "--video":
        # 视频模式
        output_path = "video_frames.coe"
        input_paths = []
        
        i = 2
        while i < len(sys.argv):
            if sys.argv[i] == "--output":
                output_path = sys.argv[i + 1]
                i += 2
            else:
                input_paths.append(sys.argv[i])
                i += 1
        
        merge_frames_to_coe(input_paths, output_path)
    else:
        # 单张图片模式
        input_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else "result.coe"
        convert_image_to_coe(input_path, output_path)
