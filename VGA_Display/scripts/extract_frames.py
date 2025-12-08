#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
视频帧提取脚本
功能：从视频文件中提取指定数量的帧，并转换为 200x150 分辨率的 RGB444 图片
作者：题目 3-3 参考实现
依赖：pip install opencv-python pillow
"""

import cv2
from PIL import Image
import os
import sys

def extract_video_frames(video_path, num_frames=10, output_dir='./frames'):
    """
    从视频中提取帧并处理
    
    参数:
        video_path: 视频文件路径
        num_frames: 要提取的帧数
        output_dir: 输出目录
    """
    
    # 检查视频文件是否存在
    if not os.path.exists(video_path):
        print(f"错误：找不到视频文件 '{video_path}'")
        sys.exit(1)
    
    # 创建输出目录
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"创建输出目录: {output_dir}")
    
    # 打开视频文件
    cap = cv2.VideoCapture(video_path)
    
    if not cap.isOpened():
        print(f"错误：无法打开视频文件 '{video_path}'")
        sys.exit(1)
    
    # 获取视频信息
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    duration = total_frames / fps if fps > 0 else 0
    
    print("\n" + "="*60)
    print("视频信息:")
    print(f"  文件路径: {video_path}")
    print(f"  分辨率:   {width}x{height}")
    print(f"  总帧数:   {total_frames}")
    print(f"  帧率:     {fps:.2f} FPS")
    print(f"  时长:     {duration:.2f} 秒")
    print(f"  提取帧数: {num_frames}")
    print("="*60 + "\n")
    
    if num_frames > total_frames:
        print(f"警告：请求帧数 ({num_frames}) 超过视频总帧数 ({total_frames})")
        num_frames = total_frames
    
    # 计算采样间隔（均匀分布）
    interval = max(1, total_frames // num_frames)
    
    frame_idx = 0
    saved_count = 0
    
    print("开始提取帧...")
    
    while saved_count < num_frames:
        ret, frame = cap.read()
        
        if not ret:
            print(f"警告：视频读取结束，已提取 {saved_count} 帧")
            break
        
        # 按间隔提取帧
        if frame_idx % interval == 0 and saved_count < num_frames:
            # BGR 转 RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(frame_rgb)
            
            # 调整到 200x150 分辨率
            img_resized = img.resize((200, 150), Image.LANCZOS)
            
            # 转换为 RGB444 格式（每个颜色通道 4 位）
            img_w, img_h = img_resized.size
            for i in range(img_w):
                for j in range(img_h):
                    r, g, b = img_resized.getpixel((i, j))
                    # 取每个通道的高 4 位，然后乘以 16 恢复到 8 位
                    r_4bit = (r >> 4) << 4
                    g_4bit = (g >> 4) << 4
                    b_4bit = (b >> 4) << 4
                    img_resized.putpixel((i, j), (r_4bit, g_4bit, b_4bit))
            
            # 保存图片
            output_path = os.path.join(output_dir, f'frame_{saved_count}.jpg')
            img_resized.save(output_path, 'JPEG', quality=95)
            
            print(f"  [{saved_count+1}/{num_frames}] 保存: {output_path} (原始帧 #{frame_idx})")
            
            saved_count += 1
        
        frame_idx += 1
    
    cap.release()
    
    print("\n" + "="*60)
    print(f"完成！共提取 {saved_count} 帧")
    print(f"输出目录: {os.path.abspath(output_dir)}")
    print("="*60 + "\n")

def main():
    """
    主函数
    """
    # 默认参数
    video_file = "your_video.mp4"  # 修改为你的视频文件路径
    num_frames = 10
    output_dir = "./frames"
    
    # 命令行参数解析（可选）
    if len(sys.argv) > 1:
        video_file = sys.argv[1]
    if len(sys.argv) > 2:
        num_frames = int(sys.argv[2])
    if len(sys.argv) > 3:
        output_dir = sys.argv[3]
    
    # 提取帧
    extract_video_frames(video_file, num_frames, output_dir)

if __name__ == "__main__":
    # 使用示例：
    # python extract_frames.py video.mp4 10 ./frames
    
    main()