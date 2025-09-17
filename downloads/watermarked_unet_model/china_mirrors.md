# 水印UNet模型国内镜像下载指南

## 📋 模型信息
- **文件名**: `diffusion_pytorch_model.safetensors`
- **文件大小**: 3.2GB
- **原始链接**: https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw

## 🚀 国内镜像源下载方案

### 方案1: Hugging Face国内镜像 (推荐)
```bash
# 设置国内镜像环境变量
export HF_ENDPOINT=https://hf-mirror.com

# 如果模型已上传到HF，可以这样下载
# huggingface-cli download [model-repo] diffusion_pytorch_model.safetensors
```

### 方案2: 阿里云OSS加速
```bash
# 如果已上传到阿里云OSS
aliyun oss cp oss://sleepermark-bucket/watermarked_unet_model/diffusion_pytorch_model.safetensors ./

# 或使用直链下载
wget https://sleepermark-bucket.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/diffusion_pytorch_model.safetensors
```

### 方案3: 腾讯云COS加速
```bash
# 腾讯云COS下载
coscmd download /watermarked_unet_model/diffusion_pytorch_model.safetensors ./

# 或使用直链
wget https://sleepermark-bucket.cos.ap-beijing.myqcloud.com/watermarked_unet_model/diffusion_pytorch_model.safetensors
```

### 方案4: 百度网盘 (大文件友好)
```bash
# 百度网盘分享链接
# 链接: https://pan.baidu.com/s/xxxxx
# 提取码: xxxx
```

### 方案5: 学术镜像站
```bash
# OpenDataLab镜像
wget https://opendatalab.com/api/v1/datasets/SleeperMark/files/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 智源镜像 (如果有)
wget https://data.baai.ac.cn/details/SleeperMark/watermarked_unet_model/diffusion_pytorch_model.safetensors
```

## 🔧 自动下载脚本

### 智能选择最快镜像
```bash
#!/bin/bash
# download_unet_china.sh - 智能选择国内最快镜像下载

MODEL_FILE="diffusion_pytorch_model.safetensors"
TARGET_DIR="./watermarked_unet_model"
mkdir -p "$TARGET_DIR"

# 镜像源列表 (按优先级排序)
MIRRORS=(
    "https://hf-mirror.com/SleeperMark/watermarked-unet/resolve/main/$MODEL_FILE"
    "https://sleepermark-bucket.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/$MODEL_FILE"
    "https://sleepermark-bucket.cos.ap-beijing.myqcloud.com/watermarked_unet_model/$MODEL_FILE"
    "https://opendatalab.com/api/v1/datasets/SleeperMark/files/watermarked_unet_model/$MODEL_FILE"
)

# 测试镜像可用性
test_mirror() {
    local url=$1
    echo "测试镜像: $url"
    
    # 测试连接和获取文件头信息
    if curl -s --head --connect-timeout 10 "$url" | grep -q "200 OK\|302 Found"; then
        # 测试下载速度 (下载前1MB)
        local speed=$(curl -r 0-1048576 -s -w "%{speed_download}" -o /dev/null "$url")
        echo "下载速度: $(echo "scale=2; $speed/1024/1024" | bc) MB/s"
        return 0
    else
        echo "镜像不可用"
        return 1
    fi
}

# 选择最快镜像
echo "=== 测试镜像源速度 ==="
best_mirror=""
best_speed=0

for mirror in "${MIRRORS[@]}"; do
    if test_mirror "$mirror"; then
        # 实际测试速度
        speed=$(curl -r 0-10485760 -s -w "%{speed_download}" -o /dev/null "$mirror" 2>/dev/null || echo "0")
        if (( $(echo "$speed > $best_speed" | bc -l) )); then
            best_speed=$speed
            best_mirror=$mirror
        fi
    fi
    echo ""
done

if [ -n "$best_mirror" ]; then
    echo "✅ 选择最快镜像: $best_mirror"
    echo "📥 开始下载..."
    
    # 使用curl下载，支持断点续传
    curl -L -C - --progress-bar \
         -o "$TARGET_DIR/$MODEL_FILE" \
         "$best_mirror"
    
    # 验证下载
    if [ -f "$TARGET_DIR/$MODEL_FILE" ]; then
        file_size=$(stat -f%z "$TARGET_DIR/$MODEL_FILE" 2>/dev/null || stat -c%s "$TARGET_DIR/$MODEL_FILE")
        echo "✅ 下载完成！文件大小: $(echo "scale=2; $file_size/1024/1024/1024" | bc) GB"
    else
        echo "❌ 下载失败"
        exit 1
    fi
else
    echo "❌ 所有镜像都不可用，请尝试手动下载"
    exit 1
fi
```

### 分片下载脚本 (适合不稳定网络)
```bash
#!/bin/bash
# download_unet_chunks.sh - 分片下载大模型文件

MODEL_URL="https://your-fastest-mirror.com/diffusion_pytorch_model.safetensors"
MODEL_FILE="diffusion_pytorch_model.safetensors"
CHUNK_SIZE="100M"  # 每片100MB
TARGET_DIR="./watermarked_unet_model"

mkdir -p "$TARGET_DIR"

echo "=== 分片下载水印UNet模型 ==="

# 获取文件总大小
total_size=$(curl -sI "$MODEL_URL" | grep -i content-length | awk '{print $2}' | tr -d '\r')
echo "文件总大小: $(echo "scale=2; $total_size/1024/1024/1024" | bc) GB"

# 计算分片数量
chunk_bytes=$((100*1024*1024))  # 100MB
total_chunks=$(( (total_size + chunk_bytes - 1) / chunk_bytes ))
echo "分片数量: $total_chunks"

# 下载各个分片
for ((i=0; i<total_chunks; i++)); do
    start=$((i * chunk_bytes))
    end=$((start + chunk_bytes - 1))
    
    if [ $end -ge $total_size ]; then
        end=$((total_size - 1))
    fi
    
    chunk_file="${TARGET_DIR}/${MODEL_FILE}.part${i}"
    
    echo "下载分片 $((i+1))/$total_chunks: 字节 $start-$end"
    
    # 下载分片，支持重试
    retry_count=0
    while [ $retry_count -lt 3 ]; do
        if curl -r "${start}-${end}" -o "$chunk_file" "$MODEL_URL"; then
            echo "✅ 分片 $((i+1)) 下载成功"
            break
        else
            echo "❌ 分片 $((i+1)) 下载失败，重试 $((retry_count+1))/3"
            ((retry_count++))
            sleep 5
        fi
    done
    
    if [ $retry_count -eq 3 ]; then
        echo "❌ 分片 $((i+1)) 下载失败，请检查网络"
        exit 1
    fi
done

# 合并分片
echo "🔗 合并分片..."
cat "${TARGET_DIR}/${MODEL_FILE}".part* > "${TARGET_DIR}/${MODEL_FILE}"

# 验证文件完整性
merged_size=$(stat -f%z "${TARGET_DIR}/${MODEL_FILE}" 2>/dev/null || stat -c%s "${TARGET_DIR}/${MODEL_FILE}")
if [ "$merged_size" -eq "$total_size" ]; then
    echo "✅ 文件合并成功，大小验证通过"
    # 清理分片文件
    rm "${TARGET_DIR}/${MODEL_FILE}".part*
    echo "🧹 已清理临时分片文件"
else
    echo "❌ 文件大小不匹配，可能下载不完整"
    echo "预期大小: $total_size，实际大小: $merged_size"
    exit 1
fi

echo "🎉 模型下载完成: ${TARGET_DIR}/${MODEL_FILE}"
```

## 🛠️ 使用方法

### 方式1: 自动选择最快镜像
```bash
chmod +x download_unet_china.sh
./download_unet_china.sh
```

### 方式2: 分片下载 (网络不稳定时)
```bash
chmod +x download_unet_chunks.sh
./download_unet_chunks.sh
```

### 方式3: 手动选择镜像
```bash
# 测试各个镜像的速度
curl -r 0-1048576 -w "下载速度: %{speed_download} 字节/秒\n" -o /dev/null https://mirror-url/model.safetensors

# 选择最快的进行下载
wget --progress=bar:force https://fastest-mirror/diffusion_pytorch_model.safetensors
```

## 📊 镜像源对比

| 镜像源 | 速度 | 稳定性 | 可用性 | 推荐度 |
|--------|------|--------|--------|--------|
| Hugging Face镜像 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🥇 |
| 阿里云OSS | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥇 |
| 腾讯云COS | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥇 |
| 百度网盘 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 学术镜像站 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

## 🆘 故障排除

### 下载中断怎么办？
```bash
# 使用curl的断点续传功能
curl -C - -o diffusion_pytorch_model.safetensors https://mirror-url/model.safetensors
```

### 下载速度慢？
```bash
# 使用多线程下载工具
aria2c -x 16 -s 16 https://mirror-url/diffusion_pytorch_model.safetensors
```

### 文件损坏验证？
```bash
# 如果有MD5/SHA256校验和
md5sum diffusion_pytorch_model.safetensors
sha256sum diffusion_pytorch_model.safetensors
```

## 📝 注意事项

1. **文件完整性**: 下载完成后请验证文件大小为3.2GB
2. **存储空间**: 确保有足够的磁盘空间(至少4GB)
3. **网络稳定**: 大文件下载建议在网络稳定时进行
4. **版权协议**: 请遵守模型的开源协议和使用条款
