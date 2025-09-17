#!/bin/bash

# Google Drive下载脚本
# 注意：Google Drive的大文件需要确认下载，可能需要手动操作

echo "=== Google Drive资源下载脚本 ==="

# 函数：下载Google Drive文件夹
download_gdrive_folder() {
    local folder_id=$1
    local output_dir=$2
    local description=$3
    
    echo "正在下载: $description"
    echo "文件夹ID: $folder_id"
    echo "目标目录: $output_dir"
    echo "手动下载链接: https://drive.google.com/drive/folders/$folder_id"
    echo ""
}

# Stage1模型权重
download_gdrive_folder "1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F" "stage1_model_weights" "Stage1 秘密编码器和解码器权重"

# Stage2预训练水印模型 (与Stage1相同的链接)
download_gdrive_folder "1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F" "stage2_pretrained_watermark" "Stage2 预训练水印模型、秘密消息和残差潜变量"

# 水印扩散模型UNet
download_gdrive_folder "1OnpVaXC6r1014oOambHETAPcF3-PILlw" "watermarked_unet_model" "训练完成的水印扩散UNet模型"

echo "=== 下载说明 ==="
echo "1. 由于Google Drive的限制，需要手动下载大文件"
echo "2. 请访问上面的链接，手动下载文件到相应目录"
echo "3. 或者使用gdown工具："
echo "   pip install gdown"
echo "   gdown --folder https://drive.google.com/drive/folders/FOLDER_ID"
echo ""

# 尝试使用gdown下载（如果已安装）
if command -v gdown &> /dev/null; then
    echo "检测到gdown工具，尝试自动下载..."
    
    cd stage1_model_weights
    echo "下载Stage1模型权重..."
    gdown --folder "https://drive.google.com/drive/folders/1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F"
    cd ..
    
    cd watermarked_unet_model  
    echo "下载水印UNet模型..."
    gdown --folder "https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw"
    cd ..
else
    echo "未检测到gdown工具。请先安装: pip install gdown"
fi

