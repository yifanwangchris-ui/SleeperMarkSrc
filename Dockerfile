FROM pytorch/pytorch:2.4.1-cuda12.4-cudnn9-devel

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    git-lfs \
    unzip \
    parallel \
    rsync \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 安装Python依赖
RUN pip install --no-cache-dir \
    diffusers[torch] \
    transformers \
    kornia \
    wandb \
    lpips \
    scikit-image \
    coscmd \
    && pip install --no-cache-dir torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu124

# 安装阿里云CLI
RUN curl -O https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz \
    && tar -xzf aliyun-cli-linux-*.tgz \
    && mv aliyun /usr/local/bin/ \
    && rm aliyun-cli-linux-*.tgz

# 复制项目文件
COPY . /app/

# 设置权限
RUN chmod +x /app/scripts/*.sh \
    && chmod +x /app/downloads/*.sh

# 创建数据目录
RUN mkdir -p /app/data/Stage1/dataset/{train_coco,val_coco} \
    && mkdir -p /app/data/Stage2/{pretrainedWM,Output}

# 设置环境变量
ENV PYTHONPATH=/app
ENV HF_ENDPOINT=https://hf-mirror.com
ENV TORCH_HOME=/app/data/.torch

# 创建启动脚本
RUN cat > /app/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "=== SleeperMark Docker环境 ==="
echo "PyTorch版本: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA可用: $(python -c 'import torch; print(torch.cuda.is_available())')"
echo "GPU数量: $(python -c 'import torch; print(torch.cuda.device_count())')"
echo ""

# 检查数据
if [ ! -f "/app/data/Stage1/dataset/train_coco/COCO_train2014_000000000009.jpg" ]; then
    echo "⚠️  未检测到COCO数据集，请先下载数据"
    echo "执行: docker run -it <image> bash"
    echo "然后运行: ./scripts/download_data.sh"
fi

# 执行传入的命令
exec "$@"
EOF

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bash"]
