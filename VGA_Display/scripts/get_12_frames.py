import cv2
import os

# ================= 配置区域 =================
video_path = "1.gif"   # 换成你的视频或者是 .gif 文件名
output_folder = "frames"        # 输出文件夹
target_count = 10               # 你需要的帧数
target_size = (200, 150)        # 画布大小 (DDP 模块定义的尺寸)
# ===========================================

def extract_and_resize():
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    if total_frames < target_count:
        print(f"警告: 视频只有 {total_frames} 帧，不足 {target_count} 帧！")
        step = 1
    else:
        step = total_frames // target_count
    
    count = 0
    saved_count = 0
    
    print(f"开始处理... 总帧数: {total_frames}, 目标提取: {target_count}")

    while cap.isOpened() and saved_count < target_count:
        ret, frame = cap.read()
        if not ret:
            break
            
        # 每隔 step 帧取一张，保证均匀覆盖整个视频动作
        if count % step == 0:
            # 强制缩放到 200x150
            resized_frame = cv2.resize(frame, target_size, interpolation=cv2.INTER_AREA)
            
            filename = f"{output_folder}/frame_{saved_count}.jpg"
            cv2.imwrite(filename, resized_frame)
            print(f"已保存: {filename} (尺寸: 200x150)")
            saved_count += 1
            
        count += 1

    cap.release()
    print("完成！请检查 frames 文件夹。")

if __name__ == "__main__":
    extract_and_resize()