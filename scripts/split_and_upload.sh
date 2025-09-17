#!/bin/bash
# 分片上传大文件的通用脚本

set -e

CHUNK_SIZE="1GB"
UPLOAD_METHOD="scp"  # scp, rsync, aliyun, tencent
TARGET_SERVER=""
TARGET_PATH=""

show_usage() {
    echo "用法: $0 [选项] <文件路径>"
    echo ""
    echo "选项:"
    echo "  -s, --chunk-size SIZE   分片大小 (默认: 1GB)"
    echo "  -m, --method METHOD     上传方式: scp|rsync|aliyun|tencent (默认: scp)"
    echo "  -t, --target TARGET     目标服务器 (格式: user@host)"
    echo "  -p, --path PATH         目标路径"
    echo "  -h, --help              显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 -m scp -t user@server.com -p /data/ large_file.zip"
    echo "  $0 -m aliyun -s 500MB dataset.tar.gz"
    echo "  $0 -m rsync -t user@10.0.0.1 -p /backup/ backup.tar"
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--chunk-size)
            CHUNK_SIZE="$2"
            shift 2
            ;;
        -m|--method)
            UPLOAD_METHOD="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_SERVER="$2"
            shift 2
            ;;
        -p|--path)
            TARGET_PATH="$2"
            shift 2
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
            FILE_PATH="$1"
            shift
            ;;
    esac
done

# 检查必需参数
if [ -z "$FILE_PATH" ]; then
    echo "❌ 错误: 请指定文件路径"
    show_usage
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "❌ 错误: 文件不存在: $FILE_PATH"
    exit 1
fi

if [[ "$UPLOAD_METHOD" == "scp" || "$UPLOAD_METHOD" == "rsync" ]] && [ -z "$TARGET_SERVER" ]; then
    echo "❌ 错误: SCP/RSYNC方式需要指定目标服务器"
    show_usage
    exit 1
fi

# 获取文件信息
FILENAME=$(basename "$FILE_PATH")
FILESIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH")
FILESIZE_MB=$((FILESIZE / 1024 / 1024))

echo "=== 分片上传工具 ==="
echo "文件: $FILE_PATH"
echo "大小: ${FILESIZE_MB}MB"
echo "分片: $CHUNK_SIZE"
echo "方式: $UPLOAD_METHOD"
echo ""

# 创建临时目录
TEMP_DIR="/tmp/split_upload_$$"
mkdir -p "$TEMP_DIR"

# 清理函数
cleanup() {
    echo "🧹 清理临时文件..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# 分割文件
echo "📦 分割文件..."
cd "$TEMP_DIR"
split -b "$CHUNK_SIZE" "$FILE_PATH" "${FILENAME}.part."

# 计算分片数量
PARTS=$(ls ${FILENAME}.part.* | wc -l)
echo "✅ 文件已分割为 $PARTS 个分片"

# 生成重组脚本
cat > reassemble.sh << EOF
#!/bin/bash
# 重组脚本: $FILENAME

echo "🔗 重组文件: $FILENAME"
cat ${FILENAME}.part.* > $FILENAME

# 验证文件完整性
ORIGINAL_SIZE=$FILESIZE
ASSEMBLED_SIZE=\$(stat -f%z "$FILENAME" 2>/dev/null || stat -c%s "$FILENAME")

if [ "\$ORIGINAL_SIZE" -eq "\$ASSEMBLED_SIZE" ]; then
    echo "✅ 文件重组成功，大小匹配"
    rm ${FILENAME}.part.*
    echo "🧹 已清理分片文件"
else
    echo "❌ 文件大小不匹配: 原始=\$ORIGINAL_SIZE, 重组=\$ASSEMBLED_SIZE"
    exit 1
fi
EOF

chmod +x reassemble.sh

# 上传函数
upload_scp() {
    echo "📤 使用SCP上传到: $TARGET_SERVER"
    
    # 创建目标目录
    ssh "$TARGET_SERVER" "mkdir -p $TARGET_PATH"
    
    # 并行上传分片
    echo "🚀 并行上传 $PARTS 个分片..."
    for part in ${FILENAME}.part.*; do
        echo "  上传: $part"
        scp "$part" "$TARGET_SERVER:$TARGET_PATH/" &
        
        # 限制并发数
        (($(jobs -r | wc -l) >= 4)) && wait
    done
    wait
    
    # 上传重组脚本
    scp reassemble.sh "$TARGET_SERVER:$TARGET_PATH/"
    
    echo "✅ SCP上传完成"
    echo "📋 在目标服务器执行:"
    echo "   cd $TARGET_PATH && chmod +x reassemble.sh && ./reassemble.sh"
}

upload_rsync() {
    echo "📤 使用RSYNC上传到: $TARGET_SERVER"
    
    # 使用rsync上传所有文件
    rsync -avz --progress ./ "$TARGET_SERVER:$TARGET_PATH/"
    
    echo "✅ RSYNC上传完成"
    echo "📋 在目标服务器执行:"
    echo "   cd $TARGET_PATH && ./reassemble.sh"
}

upload_aliyun() {
    echo "📤 使用阿里云OSS上传..."
    
    if ! command -v aliyun &> /dev/null; then
        echo "❌ 阿里云CLI未安装"
        exit 1
    fi
    
    BUCKET=${TARGET_SERVER:-"your-bucket"}
    OSS_PATH=${TARGET_PATH:-"split-uploads"}
    
    for part in ${FILENAME}.part.*; do
        echo "  上传: $part"
        aliyun oss cp "$part" "oss://$BUCKET/$OSS_PATH/$part"
    done
    
    aliyun oss cp reassemble.sh "oss://$BUCKET/$OSS_PATH/reassemble.sh"
    
    echo "✅ 阿里云OSS上传完成"
    echo "📋 下载和重组:"
    echo "   aliyun oss sync oss://$BUCKET/$OSS_PATH/ ./"
    echo "   chmod +x reassemble.sh && ./reassemble.sh"
}

upload_tencent() {
    echo "📤 使用腾讯云COS上传..."
    
    if ! command -v coscmd &> /dev/null; then
        echo "❌ COSCMD未安装"
        exit 1
    fi
    
    COS_PATH=${TARGET_PATH:-"split-uploads"}
    
    for part in ${FILENAME}.part.*; do
        echo "  上传: $part"
        coscmd upload "$part" "/$COS_PATH/$part"
    done
    
    coscmd upload reassemble.sh "/$COS_PATH/reassemble.sh"
    
    echo "✅ 腾讯云COS上传完成"
    echo "📋 下载和重组:"
    echo "   coscmd download -r /$COS_PATH/ ./"
    echo "   chmod +x reassemble.sh && ./reassemble.sh"
}

# 执行上传
case "$UPLOAD_METHOD" in
    scp)
        upload_scp
        ;;
    rsync)
        upload_rsync
        ;;
    aliyun)
        upload_aliyun
        ;;
    tencent)
        upload_tencent
        ;;
    *)
        echo "❌ 不支持的上传方式: $UPLOAD_METHOD"
        echo "支持的方式: scp, rsync, aliyun, tencent"
        exit 1
        ;;
esac

echo ""
echo "🎉 分片上传完成！"
echo "📊 统计信息:"
echo "  原始文件: $FILENAME (${FILESIZE_MB}MB)"
echo "  分片数量: $PARTS"
echo "  分片大小: $CHUNK_SIZE"
