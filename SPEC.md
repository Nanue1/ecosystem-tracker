# 生态研究追踪 - 路亚出勤记录 App

## 1. 项目概述

**项目名称**: 生态研究追踪 (Ecosystem Tracker)
**类型**: 跨平台原生 App + 后端 API
**核心功能**: 记录路亚出勤、标点、天气、潮汛、鱼货拍照上传、鱼种记录
**技术栈**: Flutter (Android + iOS) + Flask/SQLite + 高德地图 API
**版本**: 从微信小程序改为 Flutter App（一套代码同时输出 Android + iOS）

---

## 2. 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App 前端                         │
│         (Android + iOS 同一套代码原生 App)                   │
│  (GPS定位 · 高德地图 · 天气潮讯 · 拍照上传 · 记录鱼货)        │
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

### 4.1 前端 - Flutter App
- **框架**: Flutter 3.x + Dart（一套代码输出 Android + iOS）
- **地图**: 高德地图 Flutter SDK（`amap_flutter_map`）
- **定位**: `geolocator` + `amap_flutter_location`
- **状态管理**: `provider`
- **图片**: `image_picker`
- **离线存储**: `shared_preferences` + `sqflite`
- **微信登录**: `fluwx`（需要微信开放平台移动应用资质）

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
├── backend/                         # 后端服务（Flask API）
│   ├── app.py                       # Flask 主程序
│   ├── models.py                    # 数据库模型
│   ├── config.py                    # 配置文件
│   ├── requirements.txt             # Python 依赖
│   ├── init_db.py                   # 初始化数据库
│   ├── fish_species_seed.py         # 鱼种库初始数据
│   └── uploads/                     # 图片存储目录
│
├── mobile/                          # Flutter App（一套代码 Android + iOS）
│   ├── lib/
│   │   ├── main.dart                # App 入口
│   │   ├── models/
│   │   │   └── models.dart          # 数据模型（Trip/Catch/Waypoint/FishSpecies/Weather/Tide）
│   │   ├── services/
│   │   │   ├── api_service.dart     # 后端 API 调用
│   │   │   ├── location_service.dart # GPS 定位
│   │   │   └── storage_service.dart  # 本地缓存
│   │   └── screens/
│   │       ├── home_screen.dart     # 首页 - 出勤列表
│   │       ├── active_trip_screen.dart  # 进行中出勤（地图+天气+鱼货）
│   │       ├── catch_entry_screen.dart   # 鱼货记录（拍照+选鱼种）
│   │       └── trip_detail_screen.dart  # 历史出勤详情
│   ├── android/                     # Android 配置（权限、高德 Key）
│   ├── ios/                         # iOS 配置（权限）
│   └── pubspec.yaml                 # Flutter 依赖
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

### 6.2 Flutter App 发布流程

**Android:**
1. 本地开发调试（`flutter run`）
2. 构建 APK（`flutter build apk --release`）
3. 直接分发 APK 或上传到应用市场

**iOS:**
1. 本地开发调试（`flutter run` + Xcode 模拟器）
2. Xcode 配置签名 + Bundle ID
3. Archive + 上传到 App Store Connect

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
1. [x] 创建 Flutter 项目结构（mobile/ 目录）
2. [x] 实现数据模型和服务层
3. [x] 实现核心页面（首页、出勤页、鱼货记录页、历史详情页）
4. [x] 生成 Android 权限配置
5. [x] 生成 iOS 权限配置
6. [ ] 在本地安装 Flutter SDK（https://docs.flutter.dev/get-started/install）
7. [ ] 申请高德地图 API Key（Android + iOS 各一个）
8. [ ] 配置 `lib/services/api_service.dart` 中的服务器地址
9. [ ] 在本地构建 Android APK 测试
10. [ ] 在 macOS + Xcode 构建 iOS App（需 Mac 电脑）

---

## 9. 已知约束与注意事项

1. **Flutter SDK**：需本地安装（服务器不编译 App，仅存放代码）
2. **高德地图 API**：需要申请 Web API Key（Android + iOS 各一个）
3. **微信登录**：需在微信开放平台申请移动应用资质（AppID）
4. **iOS 构建**：必须在 macOS + Xcode 环境下进行
5. **Android 调试**：可在任意系统进行，真机调试需要配置 USB 调试
