# SleeperMark 国内服务器部署指南

## 🚀 推荐方案

### 方案1: 阿里云OSS + 直接传输（推荐）
**优点**: 速度快，稳定，成本低
**适用**: 有阿里云账号，文件需要长期存储

```bash
# 1. 安装阿里云CLI
curl -O https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
tar -xzf aliyun-cli-linux-*.tgz
sudo mv aliyun /usr/local/bin/

# 2. 配置OSS
aliyun configure
# 输入AccessKey ID, AccessKey Secret, 区域(cn-hangzhou等)

# 3. 上传大文件
aliyun oss cp downloads/ms_coco2014_dataset/train2014.zip oss://your-bucket/sleepermark/
aliyun oss cp downloads/ms_coco2014_dataset/val2014.zip oss://your-bucket/sleepermark/

# 4. 在服务器下载
aliyun oss cp oss://your-bucket/sleepermark/ ./downloads/ --recursive
```

### 方案2: 腾讯云COS + 传输（备选）
**优点**: 国内速度快，与腾讯云服务集成好

```bash
# 安装COSCMD
pip install coscmd

# 配置
coscmd config -a <SecretId> -s <SecretKey> -b <BucketName> -r <Region>

# 上传
coscmd upload downloads/ms_coco2014_dataset/train2014.zip /sleepermark/
coscmd upload downloads/ms_coco2014_dataset/val2014.zip /sleepermark/

# 下载到服务器
coscmd download /sleepermark/ ./downloads/ -r
```

### 方案3: 百度网盘API + 自动传输
**优点**: 免费，容量大
**缺点**: 速度较慢，需要开发者账号

### 方案4: rsync + VPN/专线
**优点**: 直接传输，支持断点续传
**适用**: 有稳定的VPN或专线连接

```bash
# 压缩后传输
tar -czf sleepermark_data.tar.gz downloads/
rsync -avz --progress sleepermark_data.tar.gz user@your-china-server:/path/to/destination/
```

### 方案5: 分片上传 + 多线程
**优点**: 绕过单文件大小限制，提高稳定性

```bash
# 分割大文件
split -b 1GB downloads/ms_coco2014_dataset/train2014.zip train2014_part_
split -b 1GB downloads/ms_coco2014_dataset/val2014.zip val2014_part_

# 多线程传输
parallel -j 4 scp {} user@server:/path/ ::: train2014_part_*
parallel -j 4 scp {} user@server:/path/ ::: val2014_part_*

# 服务器端合并
cat train2014_part_* > train2014.zip
cat val2014_part_* > val2014.zip
```

## 📦 Docker化部署方案

### 创建Docker镜像
```dockerfile
FROM pytorch/pytorch:2.4.1-cuda12.4-cudnn9-devel

WORKDIR /app
COPY . /app/

# 安装依赖
RUN pip install -r requirements.txt

# 下载脚本
COPY download_china.sh /app/
RUN chmod +x /app/download_china.sh

CMD ["/bin/bash"]
```

### 使用Docker Registry
```bash
# 构建镜像
docker build -t sleepermark:latest .

# 推送到阿里云容器镜像服务
docker tag sleepermark:latest registry.cn-hangzhou.aliyuncs.com/your-namespace/sleepermark:latest
docker push registry.cn-hangzhou.aliyuncs.com/your-namespace/sleepermark:latest

# 在国内服务器拉取
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/sleepermark:latest
```

## 🛠️ 自动化脚本

### 智能下载脚本
会自动选择最快的下载源：

```bash
#!/bin/bash
# download_intelligent.sh

# 测试网络连接
test_connection() {
    local url=$1
    timeout 10 curl -s --head "$url" > /dev/null
    return $?
}

# 选择下载源
if test_connection "https://aliyuncs.com"; then
    echo "使用阿里云OSS下载..."
    source download_aliyun.sh
elif test_connection "https://cloud.tencent.com"; then
    echo "使用腾讯云COS下载..."
    source download_tencent.sh
else
    echo "使用原始链接下载..."
    source download_original.sh
fi
```

## 📊 传输监控

### 进度监控脚本
```bash
#!/bin/bash
# monitor_transfer.sh

while true; do
    echo "=== 传输进度 $(date) ==="
    du -sh downloads/
    ls -la downloads/*/
    echo "网络速度: $(speedtest-cli --simple)"
    sleep 300  # 每5分钟检查一次
done
```

## 🔧 国内环境优化

### 替换下载源
```bash
# PyTorch 使用清华源
pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple/

# 替换GitHub为镜像
git clone https://ghproxy.com/https://github.com/huggingface/diffusers.git

# 使用国内Hugging Face镜像
export HF_ENDPOINT=https://hf-mirror.com
```

### 网络加速
```bash
# 安装BBR加速
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p

# 优化TCP参数
echo 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> /etc/sysctl.conf
```

## 💰 成本估算

| 方案 | 存储成本/月 | 流量成本 | 总成本(10GB) |
|------|------------|----------|-------------|
| 阿里云OSS | ¥1.2 | ¥5 | ~¥6.2 |
| 腾讯云COS | ¥1.0 | ¥4.8 | ~¥5.8 |
| 百度网盘 | 免费 | 免费 | 免费 |
| 专线传输 | - | 带宽费用 | 取决于带宽 |

## 📝 建议

1. **小文件**: 直接使用GitHub + Git LFS
2. **中等文件(<2GB)**: 阿里云OSS或腾讯云COS
3. **大文件(>2GB)**: 分片上传或百度网盘
4. **完整部署**: Docker + 云原生方案

选择建议：
- **开发测试**: 方案1 (阿里云OSS)
- **生产环境**: 方案4 (Docker + 云原生)
- **成本敏感**: 方案3 (百度网盘)
- **速度优先**: 方案1 + CDN加速
