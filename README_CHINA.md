# SleeperMark 国内部署版本

<div align=center><img src=method.png  width="80%" height="40%"></div>

## 🚀 一键部署到国内服务器

本版本针对国内网络环境优化，提供多种部署方案：

### 🌩️ 推荐方案：云存储 + 自动化

```bash
# 方案1: 阿里云OSS (推荐)
./scripts/deploy_china.sh cloud -m aliyun

# 方案2: 腾讯云COS
./scripts/deploy_china.sh cloud -m tencent

# 方案3: Docker容器化
./scripts/deploy_china.sh docker -t user@your-server.com

# 方案4: 直接传输
./scripts/deploy_china.sh direct -t user@your-server.com
```

### 📦 快速开始

1. **选择部署方式** (推荐云存储):
   ```bash
   ./scripts/deploy_china.sh cloud -m aliyun
   ```

2. **在国内服务器下载**:
   ```bash
   curl -O https://your-bucket.oss-cn-hangzhou.aliyuncs.com/sleepermark/download_from_aliyun.sh
   chmod +x download_from_aliyun.sh && ./download_from_aliyun.sh
   ```

3. **运行项目**:
   ```bash
   conda activate SlpMark
   cd Stage1 && sh train.sh
   ```

## 📁 项目结构

```
SleeperMarkSrc/
├── README.md                 # 原始项目说明
├── china_deployment_guide.md # 🇨🇳 国内部署详细指南
├── links.txt                 # 📋 所有资源链接
├── downloads/                # 📦 下载的资源
│   ├── arxiv_paper/         # 📄 论文PDF
│   ├── stage1_model_weights/ # 🧠 Stage1模型权重
│   ├── stage2_pretrained_watermark/ # 🔒 Stage2水印模型
│   ├── ms_coco2014_dataset/ # 🖼️ COCO数据集
│   ├── diffusers_project/   # 🔧 Diffusers项目
│   └── stable_diffusion_prompts/ # 💬 SD提示词
├── scripts/                  # 🛠️ 部署和传输脚本
│   ├── deploy_china.sh      # 🚀 一键部署脚本
│   ├── upload_to_aliyun.sh  # ☁️ 阿里云上传
│   ├── upload_to_tencent.sh # ☁️ 腾讯云上传
│   └── split_and_upload.sh  # 📦 分片上传工具
├── Dockerfile               # 🐳 Docker镜像
└── docker-compose.yml       # 🐳 Docker编排
```

## 🛠️ 部署方案对比

| 方案 | 速度 | 稳定性 | 成本 | 复杂度 | 推荐场景 |
|------|------|--------|------|--------|----------|
| 阿里云OSS | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | 🥇 生产环境 |
| 腾讯云COS | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | 生产环境 |
| Docker | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 标准化部署 |
| 直接传输 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | 简单测试 |

## 🎯 针对国内优化

### 网络加速
- 使用国内PyPI镜像源 (清华大学)
- Hugging Face模型使用国内镜像
- GitHub代码使用代理加速
- 启用BBR网络加速

### 云服务集成
- 阿里云OSS对象存储
- 腾讯云COS对象存储  
- 阿里云容器镜像服务
- 百度网盘API支持

### 分片传输
- 自动分割大文件 (>2GB)
- 多线程并行上传
- 断点续传支持
- 自动重组验证

## 💰 成本估算 (10GB数据)

| 服务商 | 存储费用/月 | 流量费用 | 总成本 |
|--------|-------------|----------|--------|
| 阿里云OSS | ¥1.2 | ¥5.0 | ~¥6.2 |
| 腾讯云COS | ¥1.0 | ¥4.8 | ~¥5.8 |
| 百度网盘 | 免费 | 免费 | 免费 |

## 🔧 环境要求

### 最低配置
- **GPU**: NVIDIA RTX 3060+ (8GB显存)
- **内存**: 16GB RAM
- **存储**: 50GB可用空间
- **网络**: 10Mbps带宽

### 推荐配置  
- **GPU**: NVIDIA RTX 4090 (24GB显存)
- **内存**: 32GB RAM
- **存储**: 100GB SSD
- **网络**: 100Mbps带宽

## 📚 详细文档

- [📖 完整部署指南](china_deployment_guide.md) - 详细的部署说明
- [🔗 资源链接汇总](links.txt) - 所有下载链接
- [📄 原始项目README](README.md) - 原始项目文档

## 🆘 常见问题

### Q: 下载速度慢怎么办？
A: 使用云存储方案，在国内服务器下载速度可达50MB/s+

### Q: 如何处理大文件上传失败？
A: 使用分片上传工具：
```bash
./scripts/split_and_upload.sh -m aliyun large_file.zip
```

### Q: Docker部署时GPU不可用？
A: 确保安装nvidia-docker：
```bash
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
sudo apt-get install nvidia-docker2
sudo systemctl restart docker
```

### Q: 如何更换下载源？
A: 修改环境变量：
```bash
export HF_ENDPOINT=https://hf-mirror.com
export PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple/
```

## 🤝 支持

- 🐛 问题反馈: [GitHub Issues](https://github.com/yifanwangchris-ui/SleeperMarkSrc/issues)
- 💬 讨论交流: [GitHub Discussions](https://github.com/yifanwangchris-ui/SleeperMarkSrc/discussions)
- 📧 邮件联系: [作者邮箱](mailto:your-email@example.com)

## 📄 License

本项目遵循原始SleeperMark项目的开源协议。

---

<div align="center">
<b>🚀 为中国AI研究者优化 | Made for Chinese AI Researchers</b>
</div>
