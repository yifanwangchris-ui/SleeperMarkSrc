# MS COCO2014 Dataset

## 下载说明

由于文件过大（>4GB），COCO数据集文件未包含在此仓库中。

### 手动下载：

```bash
# 训练集 (13GB)
wget http://images.cocodataset.org/zips/train2014.zip

# 验证集 (6GB) 
wget http://images.cocodataset.org/zips/val2014.zip

# 解压
unzip train2014.zip
unzip val2014.zip
```

### 官方链接：
- 官方网站: https://cocodataset.org/#download
- 直接下载链接:
  - 训练集: http://images.cocodataset.org/zips/train2014.zip
  - 验证集: http://images.cocodataset.org/zips/val2014.zip

### 使用说明：
根据SleeperMark项目README：
- 训练图片放到: `Stage1/dataset/train_coco`
- 验证图片放到: `Stage1/dataset/val_coco`
