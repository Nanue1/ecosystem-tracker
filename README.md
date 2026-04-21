# 生态研究追踪 - 路亚出勤记录小程序

微信小程序 + Flask 后端，用于记录路亚出勤、天气、潮讯和鱼货。

## 项目结构

```
ecosystem-tracker/
├── backend/              # Flask API 后端
│   ├── app.py           # 主程序
│   ├── models.py        # 数据模型
│   ├── init_db.py       # 数据库初始化
│   └── uploads/         # 图片存储
├── frontend/            # 微信小程序前端
│   ├── app.js          # 小程序入口
│   ├── pages/          # 页面
│   └── ...
├── docs/               # 文档
└── .github/workflows/  # CI/CD
```

## 快速开始

### 后端

```bash
cd backend
pip install -r requirements.txt
cp config.py .env  # 填写 AMAP_API_KEY
python init_db.py
python app.py
```

### 前端（微信开发者工具）

1. 下载 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
2. 导入 `frontend/` 目录
3. 在 `app.js` 中填写高德地图 Key
4. 编译预览

## 部署到服务器

```bash
# 在服务器上
cd /home/manue1/hermes_project/projects/ecosystem-tracker
git pull

# 配置 systemd 服务（参考 docs/DEPLOY.md）
sudo systemctl restart ecosystem-tracker
```

## 更新迭代流程

详见 [docs/UPDATE_FLOW.md](docs/UPDATE_FLOW.md)

## 环境变量

| 变量 | 说明 |
|------|------|
| `AMAP_API_KEY` | 高德地图 API Key |
| `FLASK_ENV` | development / production |
| `DATABASE_URL` | SQLite 数据库路径 |
