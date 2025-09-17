# 🤗 Hugging Face 上传指南

## 🚀 快速上传步骤

### 1. 获取Hugging Face Token
1. 访问 https://huggingface.co/settings/tokens
2. 点击 "New token"
3. 选择 "Write" 权限
4. 复制生成的token

### 2. 设置环境变量
```bash
# 设置你的HF token
export HF_TOKEN="hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 设置国内镜像 (可选)
export HF_ENDPOINT=https://hf-mirror.com
```

### 3. 执行上传
```bash
# 运行上传脚本
./scripts/upload_to_huggingface.sh
```

## 📋 完整操作流程

### 前置条件检查
```bash
# 1. 确保模型文件存在
ls -lh downloads/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 2. 安装必要工具
pip install huggingface_hub
pip install git-lfs

# 3. 检查Git配置
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 上传过程说明

脚本会自动完成以下步骤：

1. **验证环境** ✅
   - 检查HF token
   - 验证文件存在
   - 确认CLI工具安装

2. **创建仓库** 📦
   - 自动创建 `SleeperMark-Models` 仓库
   - 配置Git LFS处理大文件

3. **准备文件** 📁
   - 复制3.2GB模型文件
   - 生成详细的README文档
   - 创建模型配置文件

4. **上传到HF** 🚀
   - 使用Git LFS上传大文件
   - 自动处理版本控制
   - 生成访问链接

## 🇨🇳 国内加速访问

### 上传后的访问方式

```bash
# 方式1: 使用HF国内镜像
export HF_ENDPOINT=https://hf-mirror.com
huggingface-cli download your-username/SleeperMark-Models

# 方式2: 直接wget下载
wget https://hf-mirror.com/your-username/SleeperMark-Models/resolve/main/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 方式3: 使用Python API
from huggingface_hub import hf_hub_download
import os
os.environ["HF_ENDPOINT"] = "https://hf-mirror.com"

model_path = hf_hub_download(
    repo_id="your-username/SleeperMark-Models",
    filename="watermarked_unet_model/diffusion_pytorch_model.safetensors"
)
```

### 自动更新下载脚本

上传成功后，脚本会自动更新本地的下载脚本：
- `downloads/watermarked_unet_model/download_unet_china.sh`
- 添加你的HF仓库链接作为镜像源

## 🛠️ 故障排除

### 常见问题

**Q: Token权限错误？**
```bash
# 确保token有write权限
# 重新生成token时选择 "Write" 权限
export HF_TOKEN="hf_your_new_token_here"
```

**Q: 文件太大上传失败？**
```bash
# 检查Git LFS配置
git lfs ls-files
git lfs track "*.safetensors"

# 增加Git buffer大小
git config http.postBuffer 2147483648
```

**Q: 网络连接问题？**
```bash
# 使用代理 (如果需要)
export https_proxy=http://your-proxy:port
export http_proxy=http://your-proxy:port

# 或者增加超时时间
git config --global http.timeout 600
```

**Q: 克隆仓库失败？**
```bash
# 手动创建仓库
huggingface-cli repo create SleeperMark-Models --type model

# 或者使用不同的仓库名
# 修改脚本中的 REPO_NAME 变量
```

### 手动上传步骤 (如果脚本失败)

```bash
# 1. 手动创建仓库
huggingface-cli repo create SleeperMark-Models --type model

# 2. 克隆仓库
git clone https://huggingface.co/your-username/SleeperMark-Models
cd SleeperMark-Models

# 3. 配置LFS
git lfs install
git lfs track "*.safetensors"

# 4. 复制文件
mkdir watermarked_unet_model
cp ../downloads/watermarked_unet_model/diffusion_pytorch_model.safetensors watermarked_unet_model/

# 5. 提交上传
git add .
git commit -m "Add watermarked UNet model"
git push
```

## 📊 上传后验证

### 检查上传结果
```bash
# 1. 访问你的仓库页面
open https://huggingface.co/your-username/SleeperMark-Models

# 2. 测试下载
wget https://huggingface.co/your-username/SleeperMark-Models/resolve/main/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 3. 验证文件大小
ls -lh diffusion_pytorch_model.safetensors
# 应该显示约3.2GB
```

### 测试国内镜像速度
```bash
# 设置国内镜像
export HF_ENDPOINT=https://hf-mirror.com

# 测试下载速度
time wget https://hf-mirror.com/your-username/SleeperMark-Models/resolve/main/watermarked_unet_model/diffusion_pytorch_model.safetensors

# 期望速度: 20-50 MB/s (取决于网络环境)
```

## 🎯 使用建议

1. **首次上传**: 建议在网络稳定时进行，大文件上传需要时间
2. **命名规范**: 使用清晰的仓库名，便于团队找到
3. **文档完善**: README会影响模型的可发现性
4. **版本管理**: 可以创建不同分支管理模型版本
5. **访问控制**: 根据需要设置私有或公开仓库

## 🔗 相关链接

- **Hugging Face官网**: https://huggingface.co/
- **国内镜像**: https://hf-mirror.com/
- **Git LFS文档**: https://git-lfs.github.io/
- **HF Hub文档**: https://huggingface.co/docs/huggingface_hub/
