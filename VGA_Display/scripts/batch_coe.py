#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
批量 COE 文件生成脚本
功能：将图片批量转换为 Vivado Block RAM 初始化文件 (.coe)
作者：题目 3-3 参考实现
依赖：pip install pillow
"""

from PIL import Image
import os
import sys

def image_to_coe(img_path, coe_path, width=200, height=150):
    """
    将单张图片转换为 COE 文件
    
    参数:
        img_path: 输入图片路径
        coe_path: 输出 COE 文件路径
        width: 图片宽度
        height: 图片高度
    """
    
    # 检查文件是否存在
    if not os.path.exists(img_path):
        print(f"错误：找不到图片文件 '{img_path}'")
        return False
    
    try:
        # 打开并处理图片
        img = Image.open(img_path)
        img = img.resize((width, height), Image.LANCZOS)
        img = img.convert("RGB")
        
        # 转换为 RGB444 格式
        img_w, img_h = img.size
        for i in range(img_w):
            for j in range(img_h):
                data = img.getpixel((i, j))
                # 每个通道取高 4 位
                r = (data[0] >> 4) << 4
                g = (data[1] >> 4) << 4
                b = (data[2] >> 4) << 4
                img.putpixel((i, j), (r, g, b))
        
        # 写入 COE 文件
        with open(coe_path, "w") as file:
            # 文件头
            file.write(";VGA Video Frame COE File\n")
            file.write(";Memory Size: 32k x 12 bits\n")
            file.write(";Image Size: 200 x 150 pixels\n")
            file.write("memory_initialization_radix=16;\n")
            file.write("memory_initialization_vector=\n")
            
            # 写入像素数据
            pixel_count = 0
            for j in range(height):
                for i in range(width):
                    data = img.getpixel((i, j))
                    # 转换为 12 位十六进制 (RGB444)
                    r = data[0] >> 4  # 高 4 位
                    g = data[1] >> 4
                    b = data[2] >> 4
                    hex_value = f"{r:X}{g:X}{b:X}"
                    
                    file.write(hex_value)
                    pixel_count += 1
                    
                    # 每 16 个像素换行
                    if pixel_count % 16 == 0:
                        file.write("\n")
                    else:
                        file.write(" ")
            
            # 填充剩余空间到 32k (32768 个地址)
            remaining = 32768 - width * height
            for i in range(remaining):
                file.write("000")
                if (pixel_count + i + 1) % 16 == 0:
                    file.write("\n")
                else:
                    file.write(" ")
            
            # 文件结束符
            file.write("\n;")
        
        return True
        
    except Exception as e:
        print(f"错误：处理图片 '{img_path}' 时出错: {e}")
        return False

def batch_convert(input_dir='./frames', output_dir='./coe_files', num_frames=10):
    """
    批量转换所有帧
    
    参数:
        input_dir: 输入图片目录
        output_dir: 输出 COE 文件目录
        num_frames: 帧数
    """
    
    # 创建输出目录
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"创建输出目录: {output_dir}")
    
    print("\n" + "="*60)
    print("批量生成 COE 文件")
    print(f"输入目录: {os.path.abspath(input_dir)}")
    print(f"输出目录: {os.path.abspath(output_dir)}")
    print(f"帧数: {num_frames}")
    print("="*60 + "\n")
    
    success_count = 0
    fail_count = 0
    
    for i in range(num_frames):
        img_path = os.path.join(input_dir, f'frame_{i}.jpg')
        coe_path = os.path.join(output_dir, f'frame_{i}.coe')
        
        if os.path.exists(img_path):
            print(f"[{i+1}/{num_frames}] 转换: {img_path} -> {coe_path}")
            if image_to_coe(img_path, coe_path):
                success_count += 1
                # 显示文件大小
                file_size = os.path.getsize(coe_path) / 1024
                print(f"           成功 (大小: {file_size:.1f} KB)")
            else:
                fail_count += 1
                print(f"           失败")
        else:
            print(f"[{i+1}/{num_frames}] 警告: 找不到 {img_path}")
            fail_count += 1
    
    print("\n" + "="*60)
    print(f"完成！成功: {success_count}, 失败: {fail_count}")
    print(f"COE 文件位于: {os.path.abspath(output_dir)}")
    print("="*60 + "\n")
    
    # 生成文件清单
    manifest_path = os.path.join(output_dir, "file_list.txt")
    with open(manifest_path, "w") as f:
        f.write("COE File List\n")
        f.write("="*40 + "\n")
        for i in range(num_frames):
            coe_file = f'frame_{i}.coe'
            if os.path.exists(os.path.join(output_dir, coe_file)):
                f.write(f"{coe_file}\n")
    print(f"生成文件清单: {manifest_path}")

def main():
    """
    主函数
    """
    # 默认参数
    input_dir = "./frames"
    output_dir = "./coe_files"
    num_frames = 10
    
    # 命令行参数解析（可选）
    if len(sys.argv) > 1:
        input_dir = sys.argv[1]
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    if len(sys.argv) > 3:
        num_frames = int(sys.argv[3])
    
    # 批量转换
    batch_convert(input_dir, output_dir, num_frames)

if __name__ == "__main__":
    # 使用示例：
    # python batch_coe.py ./frames ./coe_files 10
    
    main()