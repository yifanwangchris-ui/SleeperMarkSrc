#!/bin/bash
# 一键部署到国内服务器的脚本

set -e

# 配置参数
DEFAULT_METHOD="aliyun"
DEFAULT_REGION="cn-hangzhou"
DOCKER_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="sleepermark"

show_usage() {
    echo "SleeperMark 国内服务器一键部署脚本"
    echo ""
    echo "用法: $0 [选项] <部署方式>"
    echo ""
    echo "部署方式:"
    echo "  cloud     - 云存储方式 (推荐)"
    echo "  docker    - Docker镜像方式"
    echo "  direct    - 直接传输方式"
    echo "  hybrid    - 混合方式"
    echo ""
    echo "选项:"
    echo "  -m, --method METHOD     云服务商: aliyun|tencent|baidu (默认: aliyun)"
    echo "  -r, --region REGION     区域 (默认: cn-hangzhou)"
    echo "  -t, --target TARGET     目标服务器 user@host"
    echo "  -p, --path PATH         目标路径 (默认: /data/sleepermark)"
    echo "  -s, --skip-build        跳过构建步骤"
    echo "  -h, --help              显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 cloud -m aliyun              # 阿里云OSS部署"
    echo "  $0 docker -t user@server.com    # Docker方式部署"
    echo "  $0 direct -t user@10.0.0.1      # 直接传输"
}

# 解析参数
METHOD="$DEFAULT_METHOD"
REGION="$DEFAULT_REGION"
TARGET_SERVER=""
TARGET_PATH="/data/sleepermark"
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
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
        -s|--skip-build)
            SKIP_BUILD=true
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
            DEPLOY_TYPE="$1"
            shift
            ;;
    esac
done

if [ -z "$DEPLOY_TYPE" ]; then
    echo "❌ 错误: 请指定部署方式"
    show_usage
    exit 1
fi

echo "=== SleeperMark 国内部署工具 ==="
echo "部署方式: $DEPLOY_TYPE"
echo "云服务商: $METHOD"
echo "区域: $REGION"
echo "目标服务器: ${TARGET_SERVER:-'云存储'}"
echo "目标路径: $TARGET_PATH"
echo ""

# 云存储部署
deploy_cloud() {
    echo "🌩️  云存储部署模式"
    
    case "$METHOD" in
        aliyun)
            echo "使用阿里云OSS..."
            if [ -f "./scripts/upload_to_aliyun.sh" ]; then
                ./scripts/upload_to_aliyun.sh
            else
                echo "❌ 阿里云上传脚本不存在"
                exit 1
            fi
            ;;
        tencent)
            echo "使用腾讯云COS..."
            if [ -f "./scripts/upload_to_tencent.sh" ]; then
                ./scripts/upload_to_tencent.sh
            else
                echo "❌ 腾讯云上传脚本不存在"
                exit 1
            fi
            ;;
        *)
            echo "❌ 不支持的云服务商: $METHOD"
            exit 1
            ;;
    esac
    
    echo ""
    echo "✅ 云存储部署完成！"
    echo "📋 在国内服务器执行以下命令下载:"
    
    case "$METHOD" in
        aliyun)
            echo "   curl -O https://your-bucket.oss-$REGION.aliyuncs.com/sleepermark/download_from_aliyun.sh"
            echo "   chmod +x download_from_aliyun.sh && ./download_from_aliyun.sh"
            ;;
        tencent)
            echo "   wget https://your-bucket.cos.$REGION.myqcloud.com/sleepermark/download_from_tencent.sh"
            echo "   chmod +x download_from_tencent.sh && ./download_from_tencent.sh"
            ;;
    esac
}

# Docker部署
deploy_docker() {
    echo "🐳 Docker部署模式"
    
    if [ -z "$TARGET_SERVER" ]; then
        echo "❌ Docker部署需要指定目标服务器"
        exit 1
    fi
    
    # 构建镜像
    if [ "$SKIP_BUILD" = false ]; then
        echo "🔨 构建Docker镜像..."
        docker build -t sleepermark:latest .
        
        # 推送到国内镜像仓库
        echo "📤 推送到阿里云容器镜像服务..."
        docker tag sleepermark:latest $DOCKER_REGISTRY/$NAMESPACE/sleepermark:latest
        docker push $DOCKER_REGISTRY/$NAMESPACE/sleepermark:latest
    fi
    
    # 生成部署脚本
    cat > deploy_docker_remote.sh << 'EOF'
#!/bin/bash
# 远程Docker部署脚本

REGISTRY="registry.cn-hangzhou.aliyuncs.com"
NAMESPACE="sleepermark"
IMAGE="$REGISTRY/$NAMESPACE/sleepermark:latest"

echo "=== SleeperMark Docker部署 ==="

# 安装Docker (如果需要)
if ! command -v docker &> /dev/null; then
    echo "安装Docker..."
    curl -fsSL https://get.docker.com | bash
    systemctl start docker
    systemctl enable docker
fi

# 安装docker-compose (如果需要)
if ! command -v docker-compose &> /dev/null; then
    echo "安装docker-compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 拉取镜像
echo "拉取镜像: $IMAGE"
docker pull $IMAGE

# 创建工作目录
mkdir -p /data/sleepermark/{data,downloads,outputs}
cd /data/sleepermark

# 运行容器
echo "启动SleeperMark容器..."
docker run -d \
    --name sleepermark \
    --gpus all \
    -v $(pwd)/data:/app/data \
    -v $(pwd)/downloads:/app/downloads \
    -v $(pwd)/outputs:/app/outputs \
    -p 8888:8888 \
    $IMAGE

echo "✅ 部署完成！"
echo "容器状态: $(docker ps --filter name=sleepermark --format 'table {{.Names}}\t{{.Status}}')"
echo ""
echo "进入容器: docker exec -it sleepermark bash"
echo "查看日志: docker logs sleepermark"
EOF

    # 传输并执行
    echo "📤 传输部署脚本到目标服务器..."
    scp deploy_docker_remote.sh "$TARGET_SERVER:/tmp/"
    
    echo "🚀 在目标服务器执行部署..."
    ssh "$TARGET_SERVER" "chmod +x /tmp/deploy_docker_remote.sh && /tmp/deploy_docker_remote.sh"
    
    echo "✅ Docker部署完成！"
    echo "🔗 连接: ssh $TARGET_SERVER"
    echo "📋 进入容器: docker exec -it sleepermark bash"
}

# 直接传输部署
deploy_direct() {
    echo "📦 直接传输部署模式"
    
    if [ -z "$TARGET_SERVER" ]; then
        echo "❌ 直接传输需要指定目标服务器"
        exit 1
    fi
    
    echo "📤 传输项目文件..."
    
    # 创建目标目录
    ssh "$TARGET_SERVER" "mkdir -p $TARGET_PATH"
    
    # 排除大文件传输小文件
    rsync -avz --progress \
        --exclude='downloads/ms_coco2014_dataset/*.zip' \
        --exclude='downloads/diffusers_project' \
        --exclude='downloads/stable_diffusion_prompts' \
        ./ "$TARGET_SERVER:$TARGET_PATH/"
    
    # 使用分片传输大文件
    for large_file in downloads/ms_coco2014_dataset/*.zip; do
        if [ -f "$large_file" ]; then
            echo "📦 分片传输: $large_file"
            ./scripts/split_and_upload.sh -m scp -t "$TARGET_SERVER" -p "$TARGET_PATH/downloads/ms_coco2014_dataset/" "$large_file"
        fi
    done
    
    # 传输环境设置脚本
    cat > setup_environment.sh << 'EOF'
#!/bin/bash
# 环境设置脚本

echo "=== SleeperMark环境设置 ==="

# 安装conda (如果需要)
if ! command -v conda &> /dev/null; then
    echo "安装Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b
    source ~/miniconda3/bin/activate
fi

# 创建环境
conda create -n SlpMark python=3.10 -y
source activate SlpMark

# 安装依赖
pip install --upgrade diffusers[torch] -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu124 \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip install transformers kornia wandb lpips scikit-image \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/

echo "✅ 环境设置完成！"
echo "激活环境: conda activate SlpMark"
EOF

    scp setup_environment.sh "$TARGET_SERVER:$TARGET_PATH/"
    ssh "$TARGET_SERVER" "cd $TARGET_PATH && chmod +x setup_environment.sh && ./setup_environment.sh"
    
    echo "✅ 直接传输部署完成！"
    echo "🔗 连接: ssh $TARGET_SERVER"
    echo "📋 项目路径: $TARGET_PATH"
}

# 混合部署
deploy_hybrid() {
    echo "🔄 混合部署模式"
    echo "小文件使用直接传输，大文件使用云存储..."
    
    # 先执行云存储上传大文件
    echo "1️⃣ 上传大文件到云存储..."
    deploy_cloud
    
    # 再直接传输小文件和脚本
    if [ -n "$TARGET_SERVER" ]; then
        echo "2️⃣ 直接传输项目文件..."
        
        # 只传输小文件
        rsync -avz --progress \
            --exclude='downloads/ms_coco2014_dataset/*.zip' \
            --exclude='downloads/**/diffusers' \
            --exclude='downloads/**/Stable-Diffusion-Prompts' \
            ./ "$TARGET_SERVER:$TARGET_PATH/"
        
        echo "✅ 混合部署完成！"
        echo "📋 在服务器上运行云存储下载脚本获取大文件"
    else
        echo "⚠️  未指定目标服务器，仅完成云存储上传"
    fi
}

# 执行部署
case "$DEPLOY_TYPE" in
    cloud)
        deploy_cloud
        ;;
    docker)
        deploy_docker
        ;;
    direct)
        deploy_direct
        ;;
    hybrid)
        deploy_hybrid
        ;;
    *)
        echo "❌ 不支持的部署方式: $DEPLOY_TYPE"
        echo "支持的方式: cloud, docker, direct, hybrid"
        exit 1
        ;;
esac

# 清理临时文件
rm -f deploy_docker_remote.sh setup_environment.sh

echo ""
echo "🎉 部署完成！"
echo "📖 查看完整部署指南: china_deployment_guide.md"
