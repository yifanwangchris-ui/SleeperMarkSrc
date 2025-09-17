#!/bin/bash
# 上传到阿里云OSS的脚本

set -e

# 配置参数
BUCKET_NAME="your-sleepermark-bucket"
OSS_REGION="cn-hangzhou"
PREFIX="sleepermark"

echo "=== SleeperMark 阿里云OSS上传脚本 ==="
echo "存储桶: $BUCKET_NAME"
echo "区域: $OSS_REGION"
echo "前缀: $PREFIX"
echo ""

# 检查阿里云CLI是否安装
if ! command -v aliyun &> /dev/null; then
    echo "❌ 阿里云CLI未安装，正在安装..."
    curl -O https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
    tar -xzf aliyun-cli-linux-*.tgz
    sudo mv aliyun /usr/local/bin/
    echo "✅ 阿里云CLI安装完成"
fi

# 检查配置
if ! aliyun configure list &> /dev/null; then
    echo "❌ 请先配置阿里云CLI:"
    echo "   aliyun configure"
    echo "   输入AccessKey ID, AccessKey Secret, 区域等信息"
    exit 1
fi

# 创建存储桶（如果不存在）
echo "📦 检查/创建存储桶..."
aliyun oss mb oss://$BUCKET_NAME --region $OSS_REGION 2>/dev/null || true

# 上传函数
upload_file() {
    local file_path=$1
    local remote_path=$2
    local file_size=$(du -h "$file_path" | cut -f1)
    
    echo "📤 上传: $file_path ($file_size)"
    echo "   目标: oss://$BUCKET_NAME/$PREFIX/$remote_path"
    
    aliyun oss cp "$file_path" "oss://$BUCKET_NAME/$PREFIX/$remote_path" \
        --progress \
        --parallel 10 \
        --part-size 100 \
        2>&1 | grep -E "(progress|完成|error)" || true
    
    if [ $? -eq 0 ]; then
        echo "✅ 上传成功: $remote_path"
    else
        echo "❌ 上传失败: $remote_path"
        return 1
    fi
}

# 上传小文件
echo ""
echo "=== 上传文档和脚本 ==="
upload_file "README.md" "README.md"
upload_file "links.txt" "links.txt"
upload_file "china_deployment_guide.md" "china_deployment_guide.md"

# 上传论文
echo ""
echo "=== 上传论文 ==="
if [ -f "downloads/arxiv_paper/SleeperMark_paper.pdf" ]; then
    upload_file "downloads/arxiv_paper/SleeperMark_paper.pdf" "arxiv_paper/SleeperMark_paper.pdf"
fi

# 上传模型权重
echo ""
echo "=== 上传模型权重 ==="
for model_dir in "stage1_model_weights" "stage2_pretrained_watermark"; do
    if [ -d "downloads/$model_dir" ]; then
        echo "📁 上传目录: $model_dir"
        aliyun oss sync "downloads/$model_dir/" "oss://$BUCKET_NAME/$PREFIX/$model_dir/" \
            --delete \
            --progress \
            2>&1 | grep -E "(progress|完成|error)" || true
    fi
done

# 上传大数据集（分块）
echo ""
echo "=== 上传大数据集 ==="
for dataset in "downloads/ms_coco2014_dataset"/*.zip; do
    if [ -f "$dataset" ]; then
        filename=$(basename "$dataset")
        file_size=$(stat -f%z "$dataset" 2>/dev/null || stat -c%s "$dataset")
        
        # 如果文件大于2GB，先分割
        if [ $file_size -gt 2147483648 ]; then
            echo "📦 文件太大，正在分割: $filename"
            split -b 1GB "$dataset" "temp_${filename}_part_"
            
            for part in temp_${filename}_part_*; do
                upload_file "$part" "ms_coco2014_dataset/$(basename $part)"
                rm "$part"  # 清理临时文件
            done
        else
            upload_file "$dataset" "ms_coco2014_dataset/$filename"
        fi
    fi
done

# 生成下载脚本
echo ""
echo "=== 生成下载脚本 ==="
cat > downloads/download_from_aliyun.sh << 'EOF'
#!/bin/bash
# 从阿里云OSS下载SleeperMark数据

BUCKET_NAME="your-sleepermark-bucket"
PREFIX="sleepermark"

echo "=== 从阿里云OSS下载SleeperMark数据 ==="

# 创建目录
mkdir -p downloads/{arxiv_paper,stage1_model_weights,stage2_pretrained_watermark,ms_coco2014_dataset}

# 下载文档
aliyun oss cp oss://$BUCKET_NAME/$PREFIX/README.md ./
aliyun oss cp oss://$BUCKET_NAME/$PREFIX/links.txt ./
aliyun oss cp oss://$BUCKET_NAME/$PREFIX/china_deployment_guide.md ./

# 下载所有数据
aliyun oss sync oss://$BUCKET_NAME/$PREFIX/ ./downloads/ --delete

# 合并分片文件
cd downloads/ms_coco2014_dataset/
for prefix in train2014.zip val2014.zip; do
    if ls temp_${prefix}_part_* 1> /dev/null 2>&1; then
        echo "🔗 合并分片: $prefix"
        cat temp_${prefix}_part_* > $prefix
        rm temp_${prefix}_part_*
    fi
done

echo "✅ 下载完成！"
EOF

chmod +x downloads/download_from_aliyun.sh
upload_file "downloads/download_from_aliyun.sh" "download_from_aliyun.sh"

echo ""
echo "🎉 上传完成！"
echo ""
echo "📥 在国内服务器下载："
echo "   curl -O https://$BUCKET_NAME.oss-$OSS_REGION.aliyuncs.com/$PREFIX/download_from_aliyun.sh"
echo "   chmod +x download_from_aliyun.sh"
echo "   ./download_from_aliyun.sh"
echo ""
echo "🌐 OSS控制台: https://oss.console.aliyun.com/"
