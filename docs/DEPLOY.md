# 部署手册

## 服务器环境

- **服务器**: 34.92.70.58 (CentOS Stream 10)
- **用户**: manue1
- **代码目录**: `/home/manue1/hermes_project/projects/ecosystem-tracker`

---

## 后端部署（systemd 服务）

### 1. 创建 systemd 服务文件

`/etc/systemd/system/ecosystem-tracker.service`

```ini
[Unit]
Description=Ecosystem Tracker Flask API
After=network.target

[Service]
User=manue1
WorkingDirectory=/home/manue1/hermes_project/projects/ecosystem-tracker/backend
Environment="PATH=/home/manue1/.pyenv/shims:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/home/manue1/hermes_project/projects/ecosystem-tracker/backend/.env
ExecStart=/home/manue1/.pyenv/shims/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 2. 启用服务

```bash
sudo systemctl daemon-reload
sudo systemctl enable ecosystem-tracker
sudo systemctl start ecosystem-tracker
sudo systemctl status ecosystem-tracker
```

### 3. 查看日志

```bash
sudo journalctl -u ecosystem-tracker -f
```

---

## Nginx 反向代理

`/etc/nginx/conf.d/ecosystem-tracker.conf`

```nginx
server {
    listen 80;
    server_name api.042138.xyz;  # 后续申请此域名

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /uploads/ {
        alias /home/manue1/hermes_project/projects/ecosystem-tracker/backend/uploads/;
        expires 30d;
    }
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## HTTPS（Let's Encrypt）

```bash
sudo certbot --nginx -d api.042138.xyz
```

---

## 微信小程序域名配置

在微信公众平台 → 开发管理 → 开发设置 中添加：

- 服务器域名: `https://api.042138.xyz`（request 合法域名）
- 下载域名: `https://api.042138.xyz`（downloadFile 合法域名）

---

## 数据库备份

```bash
# 每日备份脚本
BACKUP_DIR="/data/backups/ecosystem-tracker"
DATE=$(date +%Y%m%d)
mkdir -p $BACKUP_DIR
cp /home/manue1/hermes_project/projects/ecosystem-tracker/backend/records.db $BACKUP_DIR/records_$DATE.db
# 保留最近 30 天
find $BACKUP_DIR -name "records_*.db" -mtime +30 -delete
```
