# ecosystem-tracker 后端配置
# 复制为 .env 并填写实际值

# 高德地图 API Key（申请地址：https://console.amap.com/dev/key/app）
AMAP_API_KEY = "YOUR_AMAP_KEY_HERE"

# Flask 配置
FLASK_ENV = development
FLASK_DEBUG = 1
SECRET_KEY = "change-me-in-production"

# 数据库
DATABASE_URL = "sqlite:///records.db"

# 文件上传
UPLOAD_FOLDER = "uploads"
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
