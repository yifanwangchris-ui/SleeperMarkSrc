# SleeperMark 资源下载状态

## 文件夹结构
```
downloads/
├── arxiv_paper/                    # ✅ ArXiv论文
│   └── SleeperMark_paper.pdf      
├── diffusers_project/              # ✅ Diffusers项目
│   └── diffusers/                 
├── stable_diffusion_prompts/       # ✅ SD提示词数据集
│   └── Stable-Diffusion-Prompts/  
├── ms_coco2014_dataset/           # ✅ COCO数据集（正在下载）
│   ├── train2014.zip              
│   └── val2014.zip                
├── stage1_model_weights/          # ⏳ 需要手动下载
├── stage2_pretrained_watermark/   # ⏳ 需要手动下载  
├── watermarked_unet_model/        # ⏳ 需要手动下载
└── pytorch_wheels/                # 📝 PyTorch安装说明
```

## 下载状态

### ✅ 已完成
1. **ArXiv论文**: SleeperMark_paper.pdf (11MB)
2. **Diffusers项目**: 完整的GitHub仓库
3. **Stable-Diffusion-Prompts**: Hugging Face数据集
4. **MS COCO2014**: 训练集和验证集（大文件，正在下载中）

### ⏳ 需要手动下载 (Google Drive)
这些资源存储在Google Drive上，需要手动下载：

1. **Stage1模型权重**
   - 链接: https://drive.google.com/drive/folders/1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F
   - 目标: `stage1_model_weights/`

2. **Stage2预训练水印模型** 
   - 链接: https://drive.google.com/drive/folders/1q-CQiqhSkYESqgfRAQC43-Z-CXsXqI2F
   - 目标: `stage2_pretrained_watermark/`

3. **水印扩散模型UNet**
   - 链接: https://drive.google.com/drive/folders/1OnpVaXC6r1014oOambHETAPcF3-PILlw  
   - 目标: `watermarked_unet_model/`

### 🔧 自动下载脚本
运行以下脚本进行自动下载：
```bash
cd downloads
./download_google_drive.sh
```

### 📦 PyTorch安装
```bash
pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu124
```

## 使用说明
1. 首先手动下载Google Drive中的模型权重
2. 解压COCO数据集: `unzip train2014.zip && unzip val2014.zip`
3. 按照原项目README的指示使用这些资源

## 文件大小参考
- ArXiv论文: ~11MB
- COCO训练集: ~13GB (压缩后)
- COCO验证集: ~6GB (压缩后)  
- 各个模型权重: 大小待确认

