# Doubao AI Skill V2

文生图、图片编辑、文生视频技能

## 功能
- 🖼️ 文生图：文字描述生成图片
- ✏️ 图片编辑：去除水印、修改图片
- 🎬 文生视频：文字描述生成视频

## 使用方法
```bash
cd skills/doubao-skill-v2/scripts

# 生成图片
./doubao.sh img "一只可爱的小猫"

# 编辑图片
./doubao.sh edit "https://example.com/image.png" "remove watermark"

# 生成视频
./doubao.sh vid "一个人在跳舞" sync

# 查询状态
./doubao.sh status "task_xxxxx"
```

## 环境变量
需要设置 `ARK_API_KEY` 火山引擎 API Key
