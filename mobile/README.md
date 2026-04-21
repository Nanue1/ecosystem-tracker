# 路亚生态追踪 App — Flutter 构建指南

一份代码，同时构建 Android + iOS App。

---

## 🚀 GitHub Actions 云端构建（无需本地安装 Flutter）

项目已配置完整的 CI/CD流水线，推送代码后自动构建。

### 1. 将代码推送到 GitHub

```bash
cd ecosystem-tracker
git init
git add .
git commit -m "feat: initial Flutter App"
git remote add origin https://github.com/<你的用户名>/ecosystem-tracker.git
git push -u origin main
```

### 2. 配置 GitHub Secrets（在仓库 Settings → Actions Variables and Secrets）

**Variables（变量）：**
| 变量名 | 值 |
|--------|-----|
| `SERVER_HOST` | `34.92.70.58` |
| `SERVER_USER` | `manue1` |

**Secrets（密钥）：**
| 密钥名 | 值 |
|--------|-----|
| `SERVER_SSH_KEY` | 你的 SSH 私钥（用于 SCP 上传 APK 到服务器） |

> 生成 SSH 密钥：
> ```bash
> ssh-keygen -t ed25519 -C "github-actions"
> cat ~/.ssh/id_ed25519   # 复制到 SERVER_SSH_KEY
> cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys  # 加到服务器
> ```

### 3. 自动构建

推送代码后，GitHub Actions 自动运行：
- **android.yml** — Ubuntu 构建 Android APK（debug + release）
- **ios.yml** — macOS 构建 iOS App（simulator + release）
- **flutter.yml** — 代码检查（analyze + test）

APK 在 **Actions → Run → Artifacts** 中下载。

### 4. 一键构建并部署到服务器

打 tag 推送，自动构建 APK 并 SCP 到服务器 `/data/ecosystem-tracker/releases/`：
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 本地构建（可选）

### 安装 Flutter SDK

**macOS / Linux:**
```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:/path/to/flutter/bin"
flutter doctor
```

**Windows:** 下载 [Flutter SDK](https://docs.flutter.dev/get-started/install)

### 配置高德地图 Key

1. 去 [高德开放平台](https://console.amap.com/dev/key/app) 创建应用
2. 编辑 `android/app/src/main/AndroidManifest.xml`，替换：
   ```xml
   <meta-data
       android:name="com.amap.api.v2.apikey"
       android:value="你的高德Key"/>
   ```

### 修改后端地址

编辑 `lib/services/api_service.dart`：
```dart
static const String _baseUrl = 'http://34.92.70.58:5000/api';
```

### 构建命令

```bash
cd mobile
flutter pub get
flutter build apk --debug    # Android 调试版
flutter build apk --release  # Android 正式版
flutter build ios --simulator --no-codesign  # iOS 模拟器（需 Mac）
```

---

## 已有功能

| 功能 | 说明 |
|------|------|
| 🎣 出勤记录 | 一键开始/结束，自动记录时间+GPS |
| 📍 GPS 标记 | 在地图上标记标点位置 |
| 🐟 鱼货拍照 | 拍照记录鱼种、重量、长度 |
| 🌦 天气 | 自动获取当前位置天气 |
| 🌊 潮汐 | 显示当天潮汐信息 |
| 📱 离线缓存 | 无网络时也能记录，联网后自动同步 |
| 🔄 多平台 | Android + iOS 共用同一套代码 |

---

## 项目结构

```
mobile/
├── lib/
│   ├── main.dart              # App 入口
│   ├── models/models.dart     # 数据模型
│   ├── services/
│   │   ├── api_service.dart   # 后端 API
│   │   ├── location_service.dart  # GPS
│   │   └── storage_service.dart   # 本地缓存
│   └── screens/
│       ├── home_screen.dart
│       ├── active_trip_screen.dart
│       ├── catch_entry_screen.dart
│       └── trip_detail_screen.dart
├── android/app/src/main/AndroidManifest.xml  # 权限+高德Key
├── ios/Runner/Info.plist    # iOS 权限
├── pubspec.yaml              # Flutter 依赖
└── .gitignore
```

## CI/CD Workflow

```
.github/workflows/
├── android.yml    # Android 构建（Ubuntu）
├── ios.yml        # iOS 构建（macOS）
├── flutter.yml    # 代码检查（Ubuntu）
└── deploy.yml      # 构建+部署到服务器（tag push 或 main push）
```

---

## 已知问题 & TODO

- [ ] 微信登录：需要接入 `fluwx` 包，需在微信开放平台申请移动应用资质
- [ ] 潮汐 API：需接入真实潮汐数据源
- [ ] 离线同步：网络恢复后自动上传草稿
- [ ] iOS 真机发布：需配置 Apple Developer 签名证书
- [ ] 地图显示：标点尚未在地图上渲染
