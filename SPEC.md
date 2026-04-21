# 生态研究追踪 - 路亚出勤记录小程序

## 1. 项目概述

**项目名称**: 生态研究追踪 (Ecosystem Tracker)
**类型**: 微信小程序 + 后端 API
**核心功能**: 记录路亚出勤、标点、天气、潮汛、鱼货拍照上传、鱼种记录
**技术栈**: 微信小程序 + Flask/SQLite + 高德地图 API

---

## 2. 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                      微信小程序前端                          │
│  (位置获取 · 天气潮讯 · 拍照上传 · 记录鱼货)                  │
└──────────────────┬──────────────────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    后端 API 服务器                           │
│            34.92.70.58:5000                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ 出勤记录API  │  │ 标点管理API  │  │ 天气/潮讯聚合API     │ │
│  └─────────────┘  └──────────────┘  └──────────────────────┘ │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │ 图片存储API  │  │ 鱼种数据库API │  │ 用户管理API          │ │
│  └─────────────┘  └──────────────┘  └──────────────────────┘ │
└──────────────────┬──────────────────────────────────────────┘
                   │
         ┌─────────┴──────────┐
         ▼                    ▼
┌─────────────────┐  ┌─────────────────────────────────────────┐
│   SQLite 本地   │  │              外部 API                    │
│   数据库文件     │  │  高德地图天气 · 高德地图地理编码          │
│  (records.db)   │  │  国家海洋信息中心潮汐 API               │
└─────────────────┘  └─────────────────────────────────────────┘
```

---

## 3. 功能模块

### 3.1 出勤记录（核心）
- 获取当前 GPS 坐标（微信 `wx.getLocation`）
- 一键记录出勤：位置 + 时间 + 天气 + 潮讯
- 自动生成唯一出勤 ID

### 3.2 标点管理
- 在地图上标记钓点（高德地图小程序 SDK）
- 支持给标点命名、添加备注
- 查看所有已保存的标点

### 3.3 天气获取
- 调用高德地图天气 API 获取实时天气
- 记录时自动附带：温度、湿度、风力、天气状况

### 3.4 潮讯信息
- 调用国家海洋信息中心或第三方潮汐 API
- 显示当日潮汐曲线（高潮/低潮时间）
- 记录时附带当前潮位

### 3.5 鱼货记录
- 拍照上传鱼货照片
- 选择/搜索鱼种（预设鱼种库）
- 记录数量、长度（可选）、重量（可选）
- 关联到当前出勤记录

### 3.6 数据导出
- 按日期范围导出出勤记录
- 支持生成分享图片

---

## 4. 技术方案

### 4.1 前端 - 微信小程序
- **框架**: 原生 WXML/WXSS + JavaScript（初版快速落地）
- **地图**: 高德地图小程序 SDK（`amap-wx.js`）
- **UI 组件**: Vant Weapp（有赞出品的小程序 UI 库）
- **图片上传**: 微信 `wx.chooseImage` + `wx.uploadFile`

### 4.2 后端 - Flask API
- **语言**: Python 3
- **框架**: Flask + Flask-CORS
- **数据库**: SQLite（初版简单，后续可升级 PostgreSQL）
- **ORM**: SQLAlchemy
- **图片存储**: 本地文件系统（`/data/ecosystem-tracker/uploads/`）
- **端口**: 5000

### 4.3 外部 API
| 数据 | 来源 | 说明 |
|------|------|------|
| 地理位置 | 微信 `wx.getLocation` | 获取 GCJ-02 坐标 |
| 地图展示 | 高德地图小程序 SDK | 在小程序内展示地图 |
| 天气数据 | 高德地图 Weather API | `https://restapi.amap.com/v3/weather` |
| 地理编码 | 高德地图 Geocoding API | 经纬度→地址文字 |
| 潮汐数据 | 国家海洋信息中心 / 第三方 | 根据坐标返回潮汐预报 |

### 4.4 数据模型

```sql
-- 出勤记录
CREATE TABLE trips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    openid TEXT NOT NULL,           -- 微信用户 openid
    latitude REAL NOT NULL,         -- 纬度
    longitude REAL NOT NULL,        -- 经度
    address TEXT,                    -- 地址文字
    weather TEXT,                    -- 天气 JSON
    tide TEXT,                       -- 潮讯 JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remark TEXT
);

-- 标点
CREATE TABLE waypoints (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    openid TEXT NOT NULL,
    name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 鱼货记录
CREATE TABLE catches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id INTEGER NOT NULL,       -- 关联出勤
    fish_species TEXT NOT NULL,      -- 鱼种
    count INTEGER DEFAULT 1,
    length REAL,                     -- 长度 cm
    weight REAL,                     -- 重量 kg
    photo_url TEXT,                  -- 图片路径
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES trips(id)
);

-- 鱼种库
CREATE TABLE fish_species (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    name_cn TEXT,
    family TEXT
);
```

---

## 5. 项目结构

```
ecosystem-tracker/
├── SPEC.md                          # 本规格文档
├── README.md                        # 项目说明
│
├── backend/                         # 后端服务
│   ├── app.py                       # Flask 主程序
│   ├── models.py                    # 数据库模型
│   ├── config.py                    # 配置文件
│   ├── requirements.txt             # Python 依赖
│   ├── init_db.py                   # 初始化数据库
│   ├── fish_species_seed.py         # 鱼种库初始数据
│   └── uploads/                     # 图片存储目录
│
├── frontend/                        # 微信小程序前端
│   ├── project.config.json          # 小程序项目配置
│   ├── app.js                       # 小程序入口
│   ├── app.json                     # 小程序配置
│   ├── app.wxss                     # 全局样式
│   ├── pages/
│   │   ├── index/                   # 首页 - 出勤记录
│   │   ├── map/                     # 地图页 - 标点管理
│   │   ├── catches/                # 鱼货记录页
│   │   ├── history/                # 历史记录页
│   │   └── fish species/            # 鱼种选择页
│   ├── components/                  # 公共组件
│   └── utils/                      # 工具函数
│
├── .github/
│   └── workflows/
│       └── deploy.yml               # CI/CD 部署流程
│
└── docs/
    ├── API.md                       # API 接口文档
    ├── DEPLOY.md                    # 部署手册
    └── UPDATE_FLOW.md               # 更新迭代流程
```

---

## 6. 部署方案

### 6.1 服务器部署（当前 34.92.70.58）
- 后端使用 `systemd` 管理服务
- Nginx 反向代理到 `127.0.0.1:5000`
- 子域名: `api.042138.xyz`（后续申请）

### 6.2 小程序发布流程
1. 本地开发调试（微信开发者工具）
2. 提交代码到 Git
3. GitHub Actions 自动构建 + 部署后端
4. 手动上传小程序到微信公众平台（需要 AppID）

---

## 7. 开发迭代流程

```
┌──────────────────────────────────────────────────────────┐
│                     开发迭代流程                          │
│                                                          │
│  需求收集 → 设计评审 → 开发 → 自测 → 提交PR               │
│     ↑                                        ↓           │
│  用户反馈 ← 发布内测 ← 合并主分支 ← Code Review          │
│     ↑                                        ↓           │
│  小程序审核(微信) ← 上传版本 ← 构建 + 部署后端           │
└──────────────────────────────────────────────────────────┘
```

### 迭代周期建议：每 2 周一个版本

| 版本 | 周期 | 目标 |
|------|------|------|
| v0.1 | 第 1-2 周 | 出勤记录 + 天气获取 + 本地存储，跑通全流程 |
| v0.2 | 第 3-4 周 | 标点管理 + 地图展示 |
| v0.3 | 第 5-6 周 | 鱼货拍照上传 + 鱼种选择 |
| v0.4 | 第 7-8 周 | 潮讯接入 + 历史记录查看 |
| v1.0 | 第 9-10 周 | 正式版发布 + 用户反馈收集 |

---

## 8. 下一步行动

### 立即执行（今天）
1. [ ] 确认微信小程序 AppID（如没有需申请）
2. [ ] 申请高德地图 API Key（天气 + 地理编码）
3. [ ] 创建 GitHub 仓库
4. [ ] 搭建后端服务（Flask + SQLite）
5. [ ] 初始化数据库和鱼种库

### 待办
- [ ] 开发小程序首页（获取位置 + 记录出勤）
- [ ] 开发天气/潮讯获取功能
- [ ] 开发鱼货拍照上传功能
- [ ] 配置 GitHub Actions CI/CD
- [ ] 配置 Nginx + 域名

---

## 9. 已知约束与注意事项

1. **微信小程序要求 HTTPS**：生产环境必须使用有效 SSL 证书，后端需部署在 HTTPS 下
2. **高德地图 API 配额**：免费版有日调用上限，注意用量
3. **潮汐 API**：中国潮汐数据由国家海洋信息中心提供，需申请或使用第三方数据源
4. **用户 openid**：需通过微信服务器获取，不能在前端直接使用
5. **图片存储**：初版用本地文件系统，生产环境建议用 OSS/COS
