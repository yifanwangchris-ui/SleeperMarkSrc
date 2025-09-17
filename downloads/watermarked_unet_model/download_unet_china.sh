#!/bin/bash
# 水印UNet模型国内加速下载脚本

set -e

MODEL_FILE="diffusion_pytorch_model.safetensors"
TARGET_DIR="$(pwd)"
EXPECTED_SIZE="3435973632"  # 3.2GB in bytes

echo "=== 水印UNet模型国内加速下载 ==="
echo "目标文件: $MODEL_FILE"
echo "预期大小: 3.2GB"
echo ""

# 检查是否已存在文件
if [ -f "$TARGET_DIR/$MODEL_FILE" ]; then
    current_size=$(stat -f%z "$TARGET_DIR/$MODEL_FILE" 2>/dev/null || stat -c%s "$TARGET_DIR/$MODEL_FILE")
    if [ "$current_size" -eq "$EXPECTED_SIZE" ]; then
        echo "✅ 文件已存在且大小正确，无需重新下载"
        exit 0
    else
        echo "⚠️  文件存在但大小不正确，将重新下载"
        rm "$TARGET_DIR/$MODEL_FILE"
    fi
fi

# 国内镜像源列表 (按优先级排序)
declare -a MIRRORS=(
    # 阿里云OSS (如果已上传)
    "https://sleepermark.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/$MODEL_FILE"
    
    # 腾讯云COS (如果已上传)  
    "https://sleepermark-1234567890.cos.ap-beijing.myqcloud.com/watermarked_unet_model/$MODEL_FILE"
    
    # Hugging Face 国内镜像
    "https://hf-mirror.com/yifanwangchris-ui/SleeperMark-Models/resolve/main/$MODEL_FILE"
    
    # GitHub Release (如果有)
    "https://github.com/yifanwangchris-ui/SleeperMarkSrc/releases/download/v1.0/$MODEL_FILE"
    
    # 学术镜像站
    "https://opendatalab.com/api/v1/datasets/SleeperMark/files/watermarked_unet_model/$MODEL_FILE"
    
    # 百度网盘直链 (需要配置)
    # "https://pan.baidu.com/s/xxxxx/download"
)

# 测试镜像连通性和速度
test_mirror() {
    local url=$1
    local timeout=10
    
    echo "🔍 测试镜像: $url"
    
    # 测试HTTP头信息
    if timeout $timeout curl -s --head "$url" | grep -qE "200 OK|302 Found|301 Moved"; then
        # 测试下载速度 (下载前1MB)
        local speed=$(timeout $timeout curl -r 0-1048576 -s -w "%{speed_download}" -o /dev/null "$url" 2>/dev/null || echo "0")
        local speed_mb=$(echo "scale=2; $speed/1024/1024" | bc 2>/dev/null || echo "0")
        
        if (( $(echo "$speed > 0" | bc -l 2>/dev/null || echo "0") )); then
            echo "   ✅ 可用，速度: ${speed_mb} MB/s"
            return 0
        else
            echo "   ❌ 连接失败"
            return 1
        fi
    else
        echo "   ❌ 不可用"
        return 1
    fi
}

# 选择最佳镜像
echo "🚀 正在测试镜像源..."
best_mirror=""
best_speed=0

for mirror in "${MIRRORS[@]}"; do
    if test_mirror "$mirror"; then
        # 更详细的速度测试
        speed=$(timeout 30 curl -r 0-10485760 -s -w "%{speed_download}" -o /dev/null "$mirror" 2>/dev/null || echo "0")
        
        if (( $(echo "$speed > $best_speed" | bc -l 2>/dev/null || echo "0") )); then
            best_speed=$speed
            best_mirror=$mirror
        fi
    fi
    echo ""
done

# 开始下载
if [ -n "$best_mirror" ]; then
    echo "🎯 选择最快镜像: $best_mirror"
    echo "📥 开始下载 $MODEL_FILE..."
    echo ""
    
    # 创建临时文件
    temp_file="${TARGET_DIR}/${MODEL_FILE}.tmp"
    
    # 使用curl下载，支持断点续传和进度显示
    if curl -L -C - --progress-bar \
            --connect-timeout 30 \
            --max-time 3600 \
            --retry 3 \
            --retry-delay 5 \
            -o "$temp_file" \
            "$best_mirror"; then
        
        # 验证下载的文件
        if [ -f "$temp_file" ]; then
            downloaded_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file")
            
            if [ "$downloaded_size" -eq "$EXPECTED_SIZE" ]; then
                mv "$temp_file" "$TARGET_DIR/$MODEL_FILE"
                echo ""
                echo "✅ 下载完成！"
                echo "📁 文件位置: $TARGET_DIR/$MODEL_FILE"
                echo "📊 文件大小: $(echo "scale=2; $downloaded_size/1024/1024/1024" | bc) GB"
                
                # 简单的文件类型验证
                if file "$TARGET_DIR/$MODEL_FILE" | grep -q "data"; then
                    echo "🔍 文件类型验证通过"
                else
                    echo "⚠️  文件类型可能不正确，请手动验证"
                fi
                
            else
                echo "❌ 文件大小不匹配！"
                echo "   预期: $EXPECTED_SIZE 字节"
                echo "   实际: $downloaded_size 字节"
                rm -f "$temp_file"
                exit 1
            fi
        else
            echo "❌ 下载的临时文件不存在"
            exit 1
        fi
    else
        echo "❌ 下载失败"
        rm -f "$temp_file"
        exit 1
    fi
    
else
    echo "❌ 所有镜像源都不可用"
    echo ""
    echo "🛠️  替代方案："
    echo "1. 手动下载原始链接:"
    echo "   https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw"
    echo ""
    echo "2. 使用分片下载脚本:"
    echo "   ./download_unet_chunks.sh"
    echo ""
    echo "3. 使用VPN访问原始链接"
    echo ""
    echo "4. 联系项目维护者获取其他下载方式"
    exit 1
fi

echo ""
echo "🎉 模型下载完成！可以开始使用了"
echo ""
echo "📋 下一步："
echo "1. 将模型文件放到 Stage2/Output/ 目录"
echo "2. 运行推理脚本:"
echo "   python eval.py --unet_dir Output/unet --pretrainedWM_dir pretrainedWM"
