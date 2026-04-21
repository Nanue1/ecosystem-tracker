# GitHub Actions CI/CD 部署指南

## Workflow 概览

| Workflow | 触发条件 | 运行环境 | 产物 |
|----------|---------|---------|------|
| `android.yml` | push PR / main | Ubuntu | debug APK + release APK |
| `ios.yml` | push PR / main | macOS | iOS Simulator.app + iOS Release.app |
| `flutter.yml` | push PR / main | Ubuntu | flutter analyze + test |
| `deploy.yml` | tag v* / main push | Ubuntu | APK 上传到服务器 |

---

## 快速开始

### 1. 配置 GitHub Secrets & Variables

在 GitHub 仓库 → **Settings** → **Actions** → **Variables and Secrets** 中配置：

**Variables（变量）：**
```
SERVER_HOST   = 34.92.70.58
SERVER_USER   = manue1
```

**Secrets（密钥）：**
```
SERVER_SSH_KEY  = <你的 SSH 私钥>
```

> 生成 SSH 密钥对（如果还没有）：
> ```bash
> ssh-keygen -t ed25519 -C "github-actions@ecosystem-tracker"
> cat ~/.ssh/id_ed25519.pub  # 加到服务器的 ~/.ssh/authorized_keys
> ```

**Secrets（可选）：**
```
HERMES_WEBHOOK_URL = https://your-webhook-url/notify  # 通知回调
```

### 2. 创建 GitHub 仓库并推送代码

```bash
cd /home/manue1/hermes_project/projects/ecosystem-tracker
git init
git add .
git commit -m "feat: initial Flutter App project"

# 关联 GitHub 仓库（替换为你的仓库地址）
git remote add origin https://github.com/<username>/ecosystem-tracker.git
git branch -M main
git push -u origin main
```

### 3. 推送后自动构建

推送代码后，GitHub Actions 会自动：
1. 触发 `android.yml` — 构建 APK（~5-8 分钟）
2. 触发 `ios.yml` — 构建 iOS（~10-15 分钟，需 macOS）
3. 触发 `flutter.yml` — 代码检查（~2 分钟）

APK 产物在 **Actions** → 对应 Run → **Artifacts** 中下载。

---

## 手动触发构建

- **Android Debug APK：** Actions → "Build Android APK" → Run workflow
- **iOS Build：** Actions → "Build iOS App" → Run workflow
- **一键构建+部署：** 直接推送 tag：
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
  这会触发 `deploy.yml`，自动把 release APK 传到服务器 `/data/ecosystem-tracker/releases/`。

---

## 服务器部署路径

```
/data/ecosystem-tracker/releases/
├── app-debug.apk      # 调试版（可安装到手机测试）
└── app-release.apk    # 正式版（混淆优化）
```

---

## iOS 构建说明

iOS Release 构建需要 Apple 签名证书。当前 workflow 使用 `--no-codesign` 参数生成 **未签名** 的包，仅限：
- 模拟器运行（`flutter run -d <simulator>`）
- Ad-hoc 测试（需手动签名）

**真机发布 App Store（需额外配置）：**

1. 在 Apple Developer 创建 App ID 和 Provisioning Profile
2. 在 GitHub Secrets 添加：
   ```
   CERTIFICATE     = <base64 编码的 .p12 证书>
   CERTIFICATE_PWD = <证书密码>
   PROVISIONING_PROFILE = <base64 编码的 .mobileprovision>
   ```
3. 修改 `.github/workflows/ios.yml`，添加签名步骤

---

## 工作流详解

### android.yml
```yaml
runs-on: ubuntu-latest        # Linux 环境，可完全自动化
Flutter: 3.22.0              # 固定版本，避免 CI 不兼容
Java: 17                      # Android 构建要求
```

### deploy.yml
```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: true    # 防止重复部署
```
只在 tag push 或 main push 时运行，会把 APK scp 到服务器。

---

## 常见问题

**Q: Android 构建失败，提示 license accepted？**
> 在 `android.yml` 的 Accept Android licenses 步骤已自动处理，如果仍然失败，检查 `flutter-action` 版本。

**Q: iOS 构建报 `flutter: command not found`？**
> `subosito/flutter-action` 在 macOS 上需要几分钟初始化，确保 `flutter-version` 使用稳定版本。

**Q: APK 下载后无法安装？**
> release APK 需要先签名。debug APK 可直接安装到开启了"开发者模式"的手机。
