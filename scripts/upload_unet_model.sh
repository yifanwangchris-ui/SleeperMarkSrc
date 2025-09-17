#!/bin/bash
# 上传水印UNet模型到国内云存储

set -e

MODEL_FILE="downloads/watermarked_unet_model/diffusion_pytorch_model.safetensors"
MODEL_SIZE="3.2GB"

echo "=== 水印UNet模型云存储上传 ==="
echo "文件: $MODEL_FILE"
echo "大小: $MODEL_SIZE"
echo ""

# 检查文件是否存在
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ 模型文件不存在: $MODEL_FILE"
    echo "请确保文件已下载完成"
    exit 1
fi

# 获取文件大小
FILE_SIZE=$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE")
echo "📊 实际文件大小: $(echo "scale=2; $FILE_SIZE/1024/1024/1024" | bc) GB"

show_usage() {
    echo "用法: $0 [选项] <云服务商>"
    echo ""
    echo "云服务商:"
    echo "  aliyun    - 阿里云OSS"
    echo "  tencent   - 腾讯云COS"
    echo "  huggingface - Hugging Face (需要大文件LFS)"
    echo "  all       - 上传到所有可用的服务"
    echo ""
    echo "选项:"
    echo "  -b, --bucket BUCKET     存储桶名称"
    echo "  -r, --region REGION     区域"
    echo "  -p, --public            设置为公开访问"
    echo "  -c, --cdn               启用CDN加速"
    echo "  -h, --help              显示帮助"
}

# 默认参数
PROVIDER=""
BUCKET=""
REGION=""
PUBLIC_ACCESS=false
ENABLE_CDN=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket)
            BUCKET="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -p|--public)
            PUBLIC_ACCESS=true
            shift
            ;;
        -c|--cdn)
            ENABLE_CDN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "未知选项: $1"
            show_usage
            exit 1
            ;;
        *)
            PROVIDER="$1"
            shift
            ;;
    esac
done

if [ -z "$PROVIDER" ]; then
    echo "❌ 请指定云服务商"
    show_usage
    exit 1
fi

# 上传到阿里云OSS
upload_to_aliyun() {
    local bucket=${BUCKET:-"sleepermark"}
    local region=${REGION:-"cn-hangzhou"}
    local object_path="watermarked_unet_model/diffusion_pytorch_model.safetensors"
    
    echo "☁️  上传到阿里云OSS..."
    echo "存储桶: $bucket"
    echo "区域: $region"
    echo ""
    
    # 检查阿里云CLI
    if ! command -v aliyun &> /dev/null; then
        echo "❌ 阿里云CLI未安装"
        echo "安装命令: curl -O https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz"
        exit 1
    fi
    
    # 创建存储桶 (如果不存在)
    echo "📦 检查/创建存储桶..."
    aliyun oss mb "oss://$bucket" --region "$region" 2>/dev/null || true
    
    # 使用分片上传处理大文件
    echo "📤 开始上传 (使用分片上传)..."
    aliyun oss cp "$MODEL_FILE" "oss://$bucket/$object_path" \
        --region "$region" \
        --parallel 10 \
        --part-size 100 \
        --progress \
        --retry-times 3
    
    if [ $? -eq 0 ]; then
        echo "✅ 阿里云OSS上传成功！"
        
        # 设置公开访问权限
        if [ "$PUBLIC_ACCESS" = true ]; then
            echo "🌐 设置公开访问权限..."
            aliyun oss set-acl "oss://$bucket/$object_path" --acl public-read
        fi
        
        # 生成访问链接
        local access_url="https://$bucket.oss-$region.aliyuncs.com/$object_path"
        echo "🔗 访问链接: $access_url"
        
        # 启用CDN (需要额外配置)
        if [ "$ENABLE_CDN" = true ]; then
            echo "⚡ CDN加速域名需要在阿里云控制台配置"
            echo "🌐 控制台: https://oss.console.aliyun.com/"
        fi
        
        # 更新下载脚本中的链接
        update_download_script_aliyun "$access_url"
        
    else
        echo "❌ 阿里云OSS上传失败"
        exit 1
    fi
}

# 上传到腾讯云COS
upload_to_tencent() {
    local bucket=${BUCKET:-"sleepermark-1234567890"}
    local region=${REGION:-"ap-beijing"}
    local object_path="watermarked_unet_model/diffusion_pytorch_model.safetensors"
    
    echo "☁️  上传到腾讯云COS..."
    echo "存储桶: $bucket"
    echo "区域: $region"
    echo ""
    
    # 检查COSCMD
    if ! command -v coscmd &> /dev/null; then
        echo "❌ COSCMD未安装"
        echo "安装命令: pip install coscmd"
        exit 1
    fi
    
    # 上传大文件 (自动分片)
    echo "📤 开始上传 (自动分片处理)..."
    coscmd upload "$MODEL_FILE" "/$object_path" \
        --part-size 10 \
        --max-thread 5 \
        --retry 3
    
    if [ $? -eq 0 ]; then
        echo "✅ 腾讯云COS上传成功！"
        
        # 设置公开访问权限
        if [ "$PUBLIC_ACCESS" = true ]; then
            echo "🌐 设置公开访问权限..."
            coscmd putobjectacl "/$object_path" --grant-read uri="http://cam.qcloud.com/groups/global/AllUsers"
        fi
        
        # 生成访问链接
        local access_url="https://$bucket.cos.$region.myqcloud.com/$object_path"
        echo "🔗 访问链接: $access_url"
        
        # 更新下载脚本中的链接
        update_download_script_tencent "$access_url"
        
    else
        echo "❌ 腾讯云COS上传失败"
        exit 1
    fi
}

# 上传到Hugging Face
upload_to_huggingface() {
    local repo_name="SleeperMark-Models"
    local model_path="watermarked_unet_model"
    
    echo "🤗 上传到Hugging Face..."
    echo "仓库: $repo_name"
    echo ""
    
    # 检查Hugging Face CLI
    if ! command -v huggingface-cli &> /dev/null; then
        echo "❌ Hugging Face CLI未安装"
        echo "安装命令: pip install huggingface_hub"
        exit 1
    fi
    
    # 检查登录状态
    if ! huggingface-cli whoami &> /dev/null; then
        echo "❌ 请先登录Hugging Face"
        echo "登录命令: huggingface-cli login"
        exit 1
    fi
    
    # 创建仓库 (如果不存在)
    echo "📦 检查/创建模型仓库..."
    huggingface-cli repo create "$repo_name" --type model --private || true
    
    # 由于文件很大，使用Git LFS
    echo "📤 使用Git LFS上传大文件..."
    
    # 创建临时目录
    temp_dir="/tmp/hf_upload_$$"
    mkdir -p "$temp_dir"
    
    cd "$temp_dir"
    
    # 克隆仓库
    git clone "https://huggingface.co/$(huggingface-cli whoami | grep -o '[^/]*$')/$repo_name" .
    
    # 配置Git LFS
    git lfs track "*.safetensors"
    git add .gitattributes
    
    # 复制模型文件
    mkdir -p "$model_path"
    cp "$OLDPWD/$MODEL_FILE" "$model_path/"
    
    # 创建README
    cat > README.md << 'EOF'
---
license: mit
language:
- en
library_name: diffusers
pipeline_tag: text-to-image
tags:
- watermark
- text-to-image
- diffusion
---

# SleeperMark Watermarked UNet Model

This is the watermarked UNet model from the SleeperMark project.

## Model Details
- **File**: diffusion_pytorch_model.safetensors
- **Size**: 3.2GB
- **Type**: Watermarked Diffusion UNet
- **Framework**: PyTorch/Diffusers

## Usage
See the [main repository](https://github.com/yifanwangchris-ui/SleeperMarkSrc) for usage instructions.
EOF
    
    # 提交并推送
    git add .
    git commit -m "Add watermarked UNet model"
    git push
    
    if [ $? -eq 0 ]; then
        echo "✅ Hugging Face上传成功！"
        
        local hf_url="https://huggingface.co/$(huggingface-cli whoami | grep -o '[^/]*$')/$repo_name"
        echo "🔗 模型仓库: $hf_url"
        
        # 国内镜像链接
        local mirror_url="https://hf-mirror.com/$(huggingface-cli whoami | grep -o '[^/]*$')/$repo_name/resolve/main/$model_path/diffusion_pytorch_model.safetensors"
        echo "🇨🇳 国内镜像: $mirror_url"
        
        update_download_script_hf "$mirror_url"
    else
        echo "❌ Hugging Face上传失败"
    fi
    
    # 清理临时目录
    cd "$OLDPWD"
    rm -rf "$temp_dir"
}

# 更新下载脚本中的链接
update_download_script_aliyun() {
    local url=$1
    local script_file="downloads/watermarked_unet_model/download_unet_china.sh"
    
    echo "📝 更新阿里云下载链接..."
    sed -i.bak "s|https://sleepermark.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/\$MODEL_FILE|$url|g" "$script_file"
}

update_download_script_tencent() {
    local url=$1
    local script_file="downloads/watermarked_unet_model/download_unet_china.sh"
    
    echo "📝 更新腾讯云下载链接..."
    sed -i.bak "s|https://sleepermark-1234567890.cos.ap-beijing.myqcloud.com/watermarked_unet_model/\$MODEL_FILE|$url|g" "$script_file"
}

update_download_script_hf() {
    local url=$1
    local script_file="downloads/watermarked_unet_model/download_unet_china.sh"
    
    echo "📝 更新Hugging Face下载链接..."
    sed -i.bak "s|https://hf-mirror.com/yifanwangchris-ui/SleeperMark-Models/resolve/main/\$MODEL_FILE|$url|g" "$script_file"
}

# 主程序
case "$PROVIDER" in
    aliyun)
        upload_to_aliyun
        ;;
    tencent)
        upload_to_tencent
        ;;
    huggingface)
        upload_to_huggingface
        ;;
    all)
        echo "🚀 上传到所有云服务商..."
        upload_to_aliyun
        echo ""
        upload_to_tencent
        echo ""
        upload_to_huggingface
        ;;
    *)
        echo "❌ 不支持的云服务商: $PROVIDER"
        echo "支持的服务商: aliyun, tencent, huggingface, all"
        exit 1
        ;;
esac

echo ""
echo "🎉 上传完成！"
echo ""
echo "📋 下一步："
echo "1. 测试下载链接是否正常工作"
echo "2. 更新项目文档中的下载说明"
echo "3. 在国内服务器测试下载速度"
