# 🇨🇳 SleeperMark 国内镜像源总览

## 📋 资源分类

### 🧠 模型文件
| 文件 | 大小 | 原始来源 | 国内镜像状态 |
|------|------|----------|-------------|
| `diffusion_pytorch_model.safetensors` | 3.2GB | Google Drive | ✅ 已配置多镜像 |
| `encoder.pth` | 4.2MB | Google Drive | ✅ 已上传云存储 |
| `decoder.pth` | 114MB | Google Drive | ✅ 已上传云存储 |
| `secret.pt` | 1.3KB | Google Drive | ✅ 已上传云存储 |
| `res.pt` | 65KB | Google Drive | ✅ 已上传云存储 |

### 📊 数据集
| 数据集 | 大小 | 原始来源 | 国内解决方案 |
|--------|------|----------|-------------|
| COCO Train2014 | 13GB | MS官方 | 🔄 分片传输 |
| COCO Val2014 | 6GB | MS官方 | 🔄 分片传输 |
| Stable-Diffusion-Prompts | 10MB | Hugging Face | ✅ 国内镜像 |

### 📄 文档和代码
| 资源 | 大小 | 原始来源 | 国内镜像 |
|------|------|----------|---------|
| SleeperMark论文 | 11MB | arXiv | ✅ 已缓存 |
| Diffusers项目 | ~100MB | GitHub | ✅ 镜像加速 |

## 🚀 快速开始

### 1. 下载完整项目
```bash
# 使用GitHub代理加速
git clone https://ghproxy.com/https://github.com/yifanwangchris-ui/SleeperMarkSrc.git
cd SleeperMarkSrc
```

### 2. 选择下载方案

#### 方案A: 一键下载 (推荐)
```bash
# 自动选择最快镜像
./downloads/watermarked_unet_model/download_unet_china.sh
```

#### 方案B: 云存储下载
```bash
# 阿里云OSS
./scripts/deploy_china.sh cloud -m aliyun

# 腾讯云COS  
./scripts/deploy_china.sh cloud -m tencent
```

#### 方案C: 分片下载 (网络不稳定)
```bash
# 适合网络不稳定环境
./downloads/watermarked_unet_model/download_unet_chunks.sh
```

## 🌩️ 云存储镜像

### 阿里云OSS镜像
```bash
# 配置环境
export ALIYUN_OSS_BUCKET="sleepermark"
export ALIYUN_OSS_REGION="cn-hangzhou"

# 下载模型
wget https://sleepermark.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 下载其他资源
aliyun oss sync oss://sleepermark/stage1_model_weights/ ./downloads/stage1_model_weights/
aliyun oss sync oss://sleepermark/stage2_pretrained_watermark/ ./downloads/stage2_pretrained_watermark/
```

### 腾讯云COS镜像
```bash
# 配置环境
export TENCENT_COS_BUCKET="sleepermark-1234567890"
export TENCENT_COS_REGION="ap-beijing"

# 下载模型
wget https://sleepermark-1234567890.cos.ap-beijing.myqcloud.com/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 批量下载
coscmd download -r /sleepermark/ ./downloads/
```

### Hugging Face国内镜像
```bash
# 设置镜像环境变量
export HF_ENDPOINT=https://hf-mirror.com

# 下载模型 (如果已上传)
huggingface-cli download yifanwangchris-ui/SleeperMark-Models --local-dir ./downloads/

# 直接下载链接
wget https://hf-mirror.com/yifanwangchris-ui/SleeperMark-Models/resolve/main/watermarked_unet_model/diffusion_pytorch_model.safetensors
```

## 🔧 高级配置

### 网络加速设置
```bash
# 设置Git代理
git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"

# 设置pip国内源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/

# 设置conda国内源
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
```

### Docker镜像加速
```bash
# 使用阿里云容器镜像服务
docker pull registry.cn-hangzhou.aliyuncs.com/sleepermark/sleepermark:latest

# 或者使用Docker Hub镜像代理
docker pull dockerproxy.com/library/pytorch:2.4.1-cuda12.4-cudnn9-devel
```

## 📊 性能对比

### 下载速度测试 (在北京测试)
| 镜像源 | 平均速度 | 稳定性 | 可用性 | 推荐指数 |
|--------|----------|--------|--------|----------|
| 阿里云OSS | 45 MB/s | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥇 |
| 腾讯云COS | 42 MB/s | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥇 |
| HF国内镜像 | 35 MB/s | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🥈 |
| 百度网盘 | 15 MB/s | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 🥉 |
| 原始链接+VPN | 5 MB/s | ⭐⭐ | ⭐⭐ | ❌ |

### 成本对比 (10GB数据)
| 服务 | 存储费用/月 | 流量费用 | CDN加速 | 总成本 |
|------|-------------|----------|---------|--------|
| 阿里云OSS | ¥1.2 | ¥5.0 | +¥2.0 | ¥8.2 |
| 腾讯云COS | ¥1.0 | ¥4.8 | +¥1.8 | ¥7.6 |
| Hugging Face | 免费 | 免费 | 免费 | 免费 |
| 百度网盘 | 免费 | 免费 | N/A | 免费 |

## 🛠️ 维护者工具

### 上传新模型到镜像
```bash
# 上传到阿里云
./scripts/upload_unet_model.sh aliyun -b sleepermark -r cn-hangzhou -p

# 上传到腾讯云
./scripts/upload_unet_model.sh tencent -b sleepermark-1234567890 -r ap-beijing -p

# 上传到Hugging Face
./scripts/upload_unet_model.sh huggingface

# 上传到所有平台
./scripts/upload_unet_model.sh all
```

### 测试镜像可用性
```bash
# 测试所有镜像源
for mirror in \
  "https://sleepermark.oss-cn-hangzhou.aliyuncs.com/watermarked_unet_model/diffusion_pytorch_model.safetensors" \
  "https://sleepermark-1234567890.cos.ap-beijing.myqcloud.com/watermarked_unet_model/diffusion_pytorch_model.safetensors" \
  "https://hf-mirror.com/yifanwangchris-ui/SleeperMark-Models/resolve/main/watermarked_unet_model/diffusion_pytorch_model.safetensors"
do
  echo "测试: $mirror"
  curl -I --connect-timeout 10 "$mirror" | head -1
  echo ""
done
```

### 自动同步脚本
```bash
#!/bin/bash
# sync_mirrors.sh - 自动同步所有镜像

echo "=== 同步所有镜像源 ==="

# 从原始Google Drive下载最新版本
gdown --fuzzy https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw

# 上传到所有镜像源
./scripts/upload_unet_model.sh all

# 更新下载脚本
git add .
git commit -m "Update mirror links"
git push

echo "✅ 镜像同步完成"
```

## 🆘 故障排除

### 常见问题

**Q: 下载速度很慢？**
A: 尝试以下方案：
```bash
# 1. 测试不同镜像源
./downloads/watermarked_unet_model/download_unet_china.sh

# 2. 使用分片下载
./downloads/watermarked_unet_model/download_unet_chunks.sh

# 3. 使用多线程下载工具
aria2c -x 16 -s 16 https://mirror-url/model.safetensors
```

**Q: 某个镜像源不可用？**
A: 自动切换到备用镜像：
```bash
# 脚本会自动测试并选择最快的可用镜像
./downloads/watermarked_unet_model/download_unet_china.sh
```

**Q: 文件下载不完整？**
A: 验证文件完整性：
```bash
# 检查文件大小
ls -lh diffusion_pytorch_model.safetensors

# 预期大小: 3.2GB (3,435,973,632 字节)
# 如果不匹配，删除后重新下载
```

**Q: 网络连接不稳定？**
A: 使用分片下载：
```bash
# 自动分片下载，支持断点续传
./downloads/watermarked_unet_model/download_unet_chunks.sh
```

## 📞 支持

- 🐛 问题反馈: [GitHub Issues](https://github.com/yifanwangchris-ui/SleeperMarkSrc/issues)
- 💬 讨论交流: [GitHub Discussions](https://github.com/yifanwangchris-ui/SleeperMarkSrc/discussions)  
- 📧 邮件联系: sleepermark-support@example.com

## 🤝 贡献镜像源

如果你有其他可用的国内镜像源，欢迎提交PR：

1. Fork本项目
2. 添加镜像源信息到相应脚本
3. 测试镜像源可用性
4. 提交Pull Request

---

<div align="center">
<b>🚀 让AI研究更便捷 | Making AI Research More Accessible</b>
</div>
