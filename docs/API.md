# API 接口文档

基础 URL: `http://localhost:5000`（开发环境）
生产 URL: `https://api.042138.xyz`（待配置）

---

## 出勤记录

### 创建出勤记录
```
POST /api/trips
Content-Type: application/json

{
  "openid": "用户openid",
  "latitude": 23.1291,
  "longitude": 113.2644,
  "remark": "今天口很好"  // 可选
}

响应 200:
{
  "id": 1,
  "address": "广东省广州市...",
  "weather": {
    "weather": "晴",
    "temperature": "28",
    "wind": "东南风3级",
    "humidity": "65"
  },
  "tide": {
    "high_tide": "06:30",
    "low_tide": "13:45",
    "current_level": 1.8
  },
  "created_at": "2026-04-20T06:30:00"
}
```

### 获取出勤记录列表
```
GET /api/trips?openid=xxx

响应 200:
[
  {
    "id": 1,
    "latitude": 23.1291,
    "longitude": 113.2644,
    "address": "...",
    "weather": {...},
    "tide": {...},
    "created_at": "2026-04-20T06:30:00",
    "catch_count": 3
  }
]
```

---

## 标点管理

### 创建标点
```
POST /api/waypoints
Content-Type: application/json

{
  "openid": "用户openid",
  "name": "A1标点",
  "latitude": 23.1291,
  "longitude": 113.2644,
  "remark": "大嘴黑鲈"  // 可选
}

响应 200:
{
  "id": 1,
  "created_at": "2026-04-20T06:30:00"
}
```

### 获取标点列表
```
GET /api/waypoints?openid=xxx

响应 200:
[
  {
    "id": 1,
    "name": "A1标点",
    "latitude": 23.1291,
    "longitude": 113.2644,
    "remark": "大嘴黑鲈",
    "created_at": "2026-04-20T06:30:00"
  }
]
```

---

## 鱼货记录

### 创建鱼货记录
```
POST /api/catches
Content-Type: application/json

{
  "trip_id": 1,
  "fish_species": "Micropterus salmoides",
  "count": 2,
  "length": 35.5,    // 可选 cm
  "weight": 0.8,    // 可选 kg
  "photo_url": "/uploads/20260420123456.jpg"  // 可选
}

响应 200:
{
  "id": 1,
  "created_at": "2026-04-20T06:35:00"
}
```

### 获取某出勤的鱼货记录
```
GET /api/catches/{trip_id}

响应 200:
[
  {
    "id": 1,
    "fish_species": "Micropterus salmoides",
    "count": 2,
    "length": 35.5,
    "weight": 0.8,
    "photo_url": "/uploads/20260420123456.jpg",
    "created_at": "2026-04-20T06:35:00"
  }
]
```

---

## 图片上传

### 上传鱼货照片
```
POST /api/upload
Content-Type: multipart/form-data

file: <binary>

响应 200:
{
  "url": "/uploads/20260420123456.jpg"
}
```

---

## 鱼种库

### 获取鱼种列表
```
GET /api/fish-species

响应 200:
[
  {
    "id": 1,
    "name": "Micropterus salmoides",
    "name_cn": "大口黑鲈",
    "family": "太阳鱼科"
  }
]
```

### 添加鱼种
```
POST /api/fish-species
Content-Type: application/json

{
  "name": "New Species",
  "name_cn": "新鱼种",
  "family": "科"
}

响应 200:
{
  "id": 100
}
```

---

## 天气与潮汐

### 获取天气（调试用）
```
GET /api/weather?lat=23.1291&lon=113.2644

响应 200:
{
  "weather": "晴",
  "temperature": "28",
  "wind": "东南风3级",
  "humidity": "65"
}
```

### 获取潮汐（调试用）
```
GET /api/tide?lat=23.1291&lon=113.2644

响应 200:
{
  "high_tide": "06:30",
  "low_tide": "13:45",
  "current_level": 1.8,
  "unit": "米"
}
```

---

## 错误响应

```json
{
  "error": "错误描述"
}
```

HTTP 状态码:
- `400` - 请求参数错误
- `404` - 资源不存在
- `409` - 资源冲突（如重复添加）
- `500` - 服务器内部错误
