# SleeperMark资源下载说明

## 已完成下载的资源：
1. ✅ ArXiv论文: `arxiv_paper/SleeperMark_paper.pdf`
2. ✅ Diffusers项目: `diffusers_project/diffusers/`

## 需要手动下载的Google Drive资源：

### Stage1模型权重
- 链接: https://drive.google.com/drive/folders/1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F?usp=sharing
- 目标文件夹: `stage1_model_weights/`
- 说明: 包含秘密编码器和解码器的训练结果

### Stage2预训练水印模型
- 链接: https://drive.google.com/drive/folders/1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F?usp=sharing
- 目标文件夹: `stage2_pretrained_watermark/`
- 说明: 包含秘密消息和残差潜变量

### 水印扩散模型UNet
- 链接: https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw?usp=sharing
- 目标文件夹: `watermarked_unet_model/`
- 说明: 训练完成的水印扩散UNet模型

## 需要通过Hugging Face下载的资源：

### Stable-Diffusion-Prompts数据集
```bash
# 安装git-lfs（如果还没有）
git lfs install

# 克隆数据集
cd stable_diffusion_prompts/
git clone https://huggingface.co/datasets/Gustavosta/Stable-Diffusion-Prompts
```

## MS COCO2014数据集下载：
- 官方链接: https://cocodataset.org/#download
- 目标文件夹: `ms_coco2014_dataset/`
- 说明: 需要下载训练和验证图片

### 下载命令：
```bash
cd ms_coco2014_dataset/

# 下载训练集图片
wget http://images.cocodataset.org/zips/train2014.zip
unzip train2014.zip

# 下载验证集图片  
wget http://images.cocodataset.org/zips/val2014.zip
unzip val2014.zip
```

## PyTorch安装：
```bash
pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu124
```

