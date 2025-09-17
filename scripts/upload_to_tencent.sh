#!/bin/bash
# 上传到腾讯云COS的脚本

set -e

# 配置参数
BUCKET_NAME="sleepermark-1234567890"  # 替换为你的bucket名称
COS_REGION="ap-beijing"
PREFIX="sleepermark"

echo "=== SleeperMark 腾讯云COS上传脚本 ==="
echo "存储桶: $BUCKET_NAME"
echo "区域: $COS_REGION"
echo "前缀: $PREFIX"
echo ""

# 检查COSCMD是否安装
if ! command -v coscmd &> /dev/null; then
    echo "❌ COSCMD未安装，正在安装..."
    pip install coscmd
    echo "✅ COSCMD安装完成"
fi

# 检查配置
if [ ! -f ~/.cos.conf ]; then
    echo "❌ 请先配置COSCMD:"
    echo "   coscmd config -a <SecretId> -s <SecretKey> -b $BUCKET_NAME -r $COS_REGION"
    exit 1
fi

# 上传函数
upload_file() {
    local file_path=$1
    local remote_path=$2
    local file_size=$(du -h "$file_path" | cut -f1)
    
    echo "📤 上传: $file_path ($file_size)"
    echo "   目标: $PREFIX/$remote_path"
    
    coscmd upload "$file_path" "/$PREFIX/$remote_path"
    
    if [ $? -eq 0 ]; then
        echo "✅ 上传成功: $remote_path"
    else
        echo "❌ 上传失败: $remote_path"
        return 1
    fi
}

# 批量上传目录
upload_directory() {
    local local_dir=$1
    local remote_dir=$2
    
    echo "📁 上传目录: $local_dir -> $remote_dir"
    coscmd upload -r "$local_dir" "/$PREFIX/$remote_dir"
}

# 上传基础文件
echo ""
echo "=== 上传文档 ==="
upload_file "README.md" "README.md"
upload_file "links.txt" "links.txt"
upload_file "china_deployment_guide.md" "china_deployment_guide.md"

# 上传downloads目录（排除大文件）
echo ""
echo "=== 上传项目文件 ==="
if [ -d "downloads/arxiv_paper" ]; then
    upload_directory "downloads/arxiv_paper" "arxiv_paper"
fi

if [ -d "downloads/stage1_model_weights" ]; then
    upload_directory "downloads/stage1_model_weights" "stage1_model_weights"
fi

if [ -d "downloads/stage2_pretrained_watermark" ]; then
    upload_directory "downloads/stage2_pretrained_watermark" "stage2_pretrained_watermark"
fi

# 处理大数据集文件
echo ""
echo "=== 处理大数据集 ==="
for dataset in downloads/ms_coco2014_dataset/*.zip; do
    if [ -f "$dataset" ]; then
        filename=$(basename "$dataset")
        file_size=$(stat -f%z "$dataset" 2>/dev/null || stat -c%s "$dataset")
        
        # 使用分片上传处理大文件
        echo "📦 分片上传大文件: $filename"
        coscmd upload "$dataset" "/$PREFIX/ms_coco2014_dataset/$filename" --part-size 10 --max-thread 5
    fi
done

# 生成下载脚本
echo ""
echo "=== 生成下载脚本 ==="
cat > downloads/download_from_tencent.sh << 'EOF'
#!/bin/bash
# 从腾讯云COS下载SleeperMark数据

BUCKET_NAME="sleepermark-1234567890"
PREFIX="sleepermark"

echo "=== 从腾讯云COS下载SleeperMark数据 ==="

# 安装COSCMD
if ! command -v coscmd &> /dev/null; then
    pip install coscmd
fi

# 提醒配置
if [ ! -f ~/.cos.conf ]; then
    echo "请先配置COSCMD:"
    echo "coscmd config -a <SecretId> -s <SecretKey> -b $BUCKET_NAME -r <Region>"
    exit 1
fi

# 创建目录
mkdir -p downloads

# 下载所有文件
coscmd download -r /$PREFIX/ ./downloads/

echo "✅ 下载完成！"
EOF

chmod +x downloads/download_from_tencent.sh
upload_file "downloads/download_from_tencent.sh" "download_from_tencent.sh"

echo ""
echo "🎉 上传完成！"
echo ""
echo "📥 在国内服务器下载："
echo "   wget https://$BUCKET_NAME.cos.$COS_REGION.myqcloud.com/$PREFIX/download_from_tencent.sh"
echo "   chmod +x download_from_tencent.sh"
echo "   ./download_from_tencent.sh"
echo ""
echo "🌐 COS控制台: https://console.cloud.tencent.com/cos"
