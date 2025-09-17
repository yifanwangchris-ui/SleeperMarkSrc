#!/bin/bash
# 分片下载水印UNet模型 - 适合网络不稳定环境

set -e

# 原始Google Drive链接的文件ID (需要从分享链接中提取)
GDRIVE_FILE_ID="1OnpVaXC6r1014oOambHETAPcF3-PILlw"
MODEL_FILE="diffusion_pytorch_model.safetensors"
EXPECTED_SIZE="3435973632"  # 3.2GB
CHUNK_SIZE=$((100*1024*1024))  # 100MB per chunk
TARGET_DIR="$(pwd)"

echo "=== 分片下载水印UNet模型 ==="
echo "文件: $MODEL_FILE"
echo "大小: 3.2GB"
echo "分片: 100MB"
echo ""

# 检查现有文件
if [ -f "$TARGET_DIR/$MODEL_FILE" ]; then
    current_size=$(stat -f%z "$TARGET_DIR/$MODEL_FILE" 2>/dev/null || stat -c%s "$TARGET_DIR/$MODEL_FILE")
    if [ "$current_size" -eq "$EXPECTED_SIZE" ]; then
        echo "✅ 文件已存在且完整"
        exit 0
    fi
fi

# 备用下载链接 (需要实际配置)
declare -a DOWNLOAD_URLS=(
    # 阿里云OSS直链
    "https://sleepermark.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/$MODEL_FILE"
    
    # 腾讯云COS直链
    "https://sleepermark-1234567890.cos.ap-beijing.myqcloud.com/watermarked_unet_model/$MODEL_FILE"
    
    # 百度网盘直链 (需要配置)
    # "https://pan.baidu.com/s/xxxxx/download"
    
    # 其他镜像源
    # "https://your-mirror.com/path/to/model.safetensors"
)

# 尝试获取可用的下载链接
get_working_url() {
    for url in "${DOWNLOAD_URLS[@]}"; do
        echo "🔍 测试链接: $url"
        if curl -s --head --connect-timeout 10 "$url" | grep -qE "200 OK|302 Found"; then
            echo "✅ 找到可用链接"
            echo "$url"
            return 0
        fi
    done
    
    echo "❌ 没有找到可用的直链"
    return 1
}

# 分片下载函数
download_chunks() {
    local download_url=$1
    local total_chunks=$(( (EXPECTED_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE ))
    
    echo "📦 开始分片下载..."
    echo "总分片数: $total_chunks"
    echo ""
    
    # 下载各个分片
    for ((i=0; i<total_chunks; i++)); do
        local start=$((i * CHUNK_SIZE))
        local end=$((start + CHUNK_SIZE - 1))
        
        if [ $end -ge $EXPECTED_SIZE ]; then
            end=$((EXPECTED_SIZE - 1))
        fi
        
        local chunk_file="${TARGET_DIR}/${MODEL_FILE}.part$(printf "%03d" $i)"
        local progress=$((i * 100 / total_chunks))
        
        echo "📥 下载分片 $((i+1))/$total_chunks (${progress}%): 字节 $start-$end"
        
        # 跳过已存在且大小正确的分片
        if [ -f "$chunk_file" ]; then
            local chunk_size=$(stat -f%z "$chunk_file" 2>/dev/null || stat -c%s "$chunk_file")
            local expected_chunk_size=$((end - start + 1))
            
            if [ "$chunk_size" -eq "$expected_chunk_size" ]; then
                echo "   ⏭️  分片已存在，跳过"
                continue
            else
                echo "   🔄 分片大小不正确，重新下载"
                rm -f "$chunk_file"
            fi
        fi
        
        # 下载分片，支持重试
        local retry_count=0
        local max_retries=3
        
        while [ $retry_count -lt $max_retries ]; do
            if curl -r "${start}-${end}" \
                    --connect-timeout 30 \
                    --max-time 300 \
                    --progress-bar \
                    -o "$chunk_file" \
                    "$download_url"; then
                
                # 验证分片大小
                local downloaded_size=$(stat -f%z "$chunk_file" 2>/dev/null || stat -c%s "$chunk_file")
                local expected_size=$((end - start + 1))
                
                if [ "$downloaded_size" -eq "$expected_size" ]; then
                    echo "   ✅ 分片 $((i+1)) 下载成功"
                    break
                else
                    echo "   ❌ 分片大小不匹配，重试..."
                    rm -f "$chunk_file"
                fi
            fi
            
            ((retry_count++))
            if [ $retry_count -lt $max_retries ]; then
                echo "   🔄 重试 $retry_count/$max_retries (5秒后)"
                sleep 5
            fi
        done
        
        if [ $retry_count -eq $max_retries ]; then
            echo "   ❌ 分片 $((i+1)) 下载失败，已重试 $max_retries 次"
            echo "   💡 请检查网络连接或稍后重试"
            exit 1
        fi
        
        # 显示总体进度
        local completed=$((i + 1))
        local overall_progress=$((completed * 100 / total_chunks))
        echo "   📊 总进度: $completed/$total_chunks ($overall_progress%)"
        echo ""
    done
}

# 合并分片
merge_chunks() {
    echo "🔗 合并分片文件..."
    
    local temp_file="${TARGET_DIR}/${MODEL_FILE}.tmp"
    
    # 按顺序合并所有分片
    cat "${TARGET_DIR}/${MODEL_FILE}".part* > "$temp_file"
    
    # 验证合并后的文件大小
    local merged_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file")
    
    if [ "$merged_size" -eq "$EXPECTED_SIZE" ]; then
        mv "$temp_file" "$TARGET_DIR/$MODEL_FILE"
        echo "✅ 文件合并成功"
        
        # 清理分片文件
        echo "🧹 清理临时分片文件..."
        rm -f "${TARGET_DIR}/${MODEL_FILE}".part*
        
        echo "📁 最终文件: $TARGET_DIR/$MODEL_FILE"
        echo "📊 文件大小: $(echo "scale=2; $merged_size/1024/1024/1024" | bc) GB"
        
    else
        echo "❌ 文件大小不匹配！"
        echo "   预期: $EXPECTED_SIZE 字节"
        echo "   实际: $merged_size 字节"
        echo "   请检查网络或重新下载"
        rm -f "$temp_file"
        exit 1
    fi
}

# 主程序
main() {
    echo "🔍 寻找可用的下载链接..."
    
    if download_url=$(get_working_url); then
        echo "🎯 使用链接: $download_url"
        echo ""
        
        download_chunks "$download_url"
        merge_chunks
        
        echo ""
        echo "🎉 模型下载完成！"
        echo ""
        echo "📋 使用说明:"
        echo "1. 将模型文件复制到项目目录:"
        echo "   cp $MODEL_FILE ../../Stage2/Output/"
        echo ""
        echo "2. 运行推理脚本:"
        echo "   cd ../../Stage2"
        echo "   python eval.py --unet_dir Output/unet --pretrainedWM_dir pretrainedWM"
        
    else
        echo ""
        echo "🛠️  替代下载方案:"
        echo ""
        echo "1. 手动下载 Google Drive 链接:"
        echo "   https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw"
        echo ""
        echo "2. 使用其他镜像源脚本:"
        echo "   ./download_unet_china.sh"
        echo ""
        echo "3. 使用百度网盘等其他方式"
        echo ""
        echo "4. 联系项目作者获取备用下载链接"
        
        exit 1
    fi
}

# 执行主程序
main
