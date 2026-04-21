"""
生态研究追踪 - 后端 API 服务
Flask + SQLite + 高德地图 + 潮汐数据
"""
import os
import json
import requests
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# ========================
# 数据库配置
# ========================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'records.db')}"
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

engine = create_engine(DATABASE_URL, echo=False)
Session = sessionmaker(bind=engine)

# 导入数据模型
from models import Base, Trip, Waypoint, Catch, FishSpecies


# ========================
# 工具函数
# ========================
def get_db():
    return Session()


# 高德地图 API 配置
AMAP_API_KEY = os.getenv('AMAP_API_KEY', '')
AMAP_GEOCODE_URL = "https://restapi.amap.com/v3/geocode/regeo"
OPENWEATHER_KEY = os.getenv('OPENWEATHER_KEY', '')
OPENWEATHER_URL = "https://api.openweathermap.org/data/2.5/weather"


def get_weather_ow(lat, lon):
    """获取 OpenWeatherMap 实时天气"""
    if not OPENWEATHER_KEY:
        return {"error": "OpenWeatherMap API Key 未配置"}

    try:
        params = {
            'lat': lat,
            'lon': lon,
            'appid': OPENWEATHER_KEY,
            'units': 'metric'
        }
        resp = requests.get(OPENWEATHER_URL, params=params, timeout=5)
        data = resp.json()
        if data.get('cod') == 200:
            w = data.get('weather', [{}])[0]
            main = data.get('main', {})
            wind = data.get('wind', {})
            return {
                'weather': w.get('description'),
                'temperature': main.get('temp'),
                'wind': wind.get('deg'),
                'humidity': main.get('humidity'),
                'feelsLike': main.get('feels_like'),
            }
        return {"error": data.get('message', '未知错误')}
    except Exception as e:
        return {"error": str(e)}


def get_address_amap(lat, lon):
    """获取高德地图逆地理编码（经纬度 -> 地址）"""
    if not AMAP_API_KEY:
        return None

    try:
        params = {
            'key': AMAP_API_KEY,
            'location': f"{lon},{lat}",
            'extensions': 'base'
        }
        resp = requests.get(AMAP_GEOCODE_URL, params=params, timeout=5)
        data = resp.json()
        if data.get('status') == '1':
            regeocode = data.get('regeocode', {})
            return regeocode.get('formatted_address')
    except:
        pass
    return None


# 潮汐 API（示例使用国家海洋信息中心格式，需根据实际API调整）
def get_tide_info(lat, lon):
    """获取潮汐信息（预留接口，后续接入真实API）"""
    # TODO: 接入真实潮汐 API
    # 目前返回模拟数据
    return {
        'high_tide': '06:30',
        'low_tide': '13:45',
        'current_level': 1.8,
        'unit': '米',
        'note': '数据来源待接入'
    }


# ========================
# 微信登录
# ========================
WX_APP_ID = os.getenv('WX_APP_ID', '')
WX_APP_SECRET = os.getenv('WX_APP_SECRET', '')


def get_openid_from_wx(code):
    """用微信 code 换取 openid"""
    if not WX_APP_ID or not WX_APP_SECRET:
        return None, "微信 AppID 或 AppSecret 未配置"

    try:
        url = "https://api.weixin.qq.com/sns/jscode2session"
        params = {
            'appid': WX_APP_ID,
            'secret': WX_APP_SECRET,
            'js_code': code,
            'grant_type': 'authorization_code'
        }
        resp = requests.get(url, params=params, timeout=5)
        data = resp.json()
        if 'openid' in data:
            return data['openid'], None
        return None, data.get('errmsg', '获取 openid 失败')
    except Exception as e:
        return None, str(e)


# ========================
# API 路由
# ========================

@app.route('/')
def index():
    return jsonify({
        'name': '生态研究追踪 API',
        'version': '0.1.0',
        'status': 'running'
    })


@app.route('/api/health')
def health():
    """健康检查"""
    return jsonify({'status': 'ok', 'service': 'ecosystem-tracker'})


# ---------- 出勤记录 ----------

@app.route('/api/trips', methods=['POST'])
def create_trip():
    """创建出勤记录"""
    data = request.get_json()
    openid = data.get('openid')
    lat = data.get('latitude')
    lon = data.get('longitude')

    if not all([openid, lat, lon]):
        return jsonify({'error': '缺少必要参数'}), 400

    db = get_db()
    try:
        # 获取地址
        address = get_address_amap(lat, lon)
        # 获取天气
        weather = get_weather_ow(lat, lon)
        # 获取潮汐
        tide = get_tide_info(lat, lon)

        trip = Trip(
            openid=openid,
            latitude=lat,
            longitude=lon,
            address=address,
            weather=json.dumps(weather, ensure_ascii=False),
            tide=json.dumps(tide, ensure_ascii=False),
            remark=data.get('remark', '')
        )
        db.add(trip)
        db.commit()
        db.refresh(trip)

        return jsonify({
            'id': trip.id,
            'address': address,
            'weather': weather,
            'tide': tide,
            'created_at': (trip.created_at or datetime.utcnow()).isoformat()
        })
    finally:
        db.close()


@app.route('/api/trips', methods=['GET'])
def list_trips():
    """获取出勤记录列表"""
    openid = request.args.get('openid')
    db = get_db()
    try:
        query = db.query(Trip)
        if openid:
            query = query.filter(Trip.openid == openid)
        trips = query.order_by(Trip.created_at.desc()).limit(50).all()
        result = []
        for t in trips:
            result.append({
                'id': t.id,
                'latitude': t.latitude,
                'longitude': t.longitude,
                'address': t.address,
                'weather': json.loads(t.weather) if t.weather else None,
                'tide': json.loads(t.tide) if t.tide else None,
                'created_at': (t.created_at or datetime.utcnow()).isoformat(),
                'remark': t.remark,
                'catch_count': len(t.catches)
            })
        return jsonify(result)
    finally:
        db.close()


# ---------- 标点管理 ----------

@app.route('/api/waypoints', methods=['POST'])
def create_waypoint():
    """创建标点"""
    data = request.get_json()
    for field in ['openid', 'name', 'latitude', 'longitude']:
        if not data.get(field):
            return jsonify({'error': f'缺少参数: {field}'}), 400

    db = get_db()
    try:
        wp = Waypoint(
            openid=data['openid'],
            name=data['name'],
            latitude=data['latitude'],
            longitude=data['longitude'],
            remark=data.get('remark', '')
        )
        db.add(wp)
        db.commit()
        db.refresh(wp)
        return jsonify({'id': wp.id, 'created_at': (wp.created_at or datetime.utcnow()).isoformat()})
    finally:
        db.close()


@app.route('/api/waypoints', methods=['GET'])
def list_waypoints():
    """获取标点列表"""
    openid = request.args.get('openid')
    db = get_db()
    try:
        query = db.query(Waypoint)
        if openid:
            query = query.filter(Waypoint.openid == openid)
        wps = query.order_by(Waypoint.created_at.desc()).all()
        return jsonify([{
            'id': w.id,
            'name': w.name,
            'latitude': w.latitude,
            'longitude': w.longitude,
            'remark': w.remark,
            'created_at': (w.created_at or datetime.utcnow()).isoformat()
        } for w in wps])
    finally:
        db.close()


# ---------- 鱼货记录 ----------

@app.route('/api/catches', methods=['POST'])
def create_catch():
    """创建鱼货记录"""
    data = request.get_json()
    required = ['trip_id', 'fish_species']
    for f in required:
        if not data.get(f):
            return jsonify({'error': f'缺少参数: {f}'}), 400

    db = get_db()
    try:
        catch = Catch(
            trip_id=data['trip_id'],
            fish_species=data['fish_species'],
            count=data.get('count', 1),
            length=data.get('length'),
            weight=data.get('weight'),
            photo_url=data.get('photo_url')
        )
        db.add(catch)
        db.commit()
        db.refresh(catch)
        return jsonify({'id': catch.id, 'created_at': (catch.created_at or datetime.utcnow()).isoformat()})
    finally:
        db.close()


@app.route('/api/catches/<int:trip_id>', methods=['GET'])
def list_catches(trip_id):
    """获取某个出勤的鱼货记录"""
    db = get_db()
    try:
        catches = db.query(Catch).filter(Catch.trip_id == trip_id).all()
        return jsonify([{
            'id': c.id,
            'fish_species': c.fish_species,
            'count': c.count,
            'length': c.length,
            'weight': c.weight,
            'photo_url': c.photo_url,
            'created_at': (c.created_at or datetime.utcnow()).isoformat()
        } for c in catches])
    finally:
        db.close()


# ---------- 图片上传 ----------

@app.route('/api/upload', methods=['POST'])
def upload_photo():
    """上传鱼货照片"""
    if 'photo' not in request.files:
        return jsonify({'error': '没有文件'}), 400

    file = request.files['photo']
    if file.filename == '':
        return jsonify({'error': '文件名为空'}), 400

    # 生成唯一文件名
    ext = os.path.splitext(file.filename)[1] or '.jpg'
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{os.urandom(4).hex()}{ext}"
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)

    # 返回访问URL（后续通过 Nginx 静态托管）
    photo_url = f"/uploads/{filename}"
    return jsonify({'url': photo_url})


@app.route('/uploads/<filename>')
def serve_upload(filename):
    """提供上传文件访问"""
    return send_from_directory(UPLOAD_FOLDER, filename)


# ---------- 鱼种库 ----------

@app.route('/api/fish-species', methods=['GET'])
def list_fish_species():
    """获取鱼种列表"""
    db = get_db()
    try:
        species = db.query(FishSpecies).order_by(FishSpecies.name).all()
        return jsonify([{
            'id': s.id,
            'name': s.name,
            'name_cn': s.name_cn,
            'family': s.family
        } for s in species])
    finally:
        db.close()


@app.route('/api/fish-species', methods=['POST'])
def add_fish_species():
    """添加鱼种"""
    data = request.get_json()
    if not data.get('name'):
        return jsonify({'error': '缺少鱼种名称'}), 400

    db = get_db()
    try:
        existing = db.query(FishSpecies).filter(FishSpecies.name == data['name']).first()
        if existing:
            return jsonify({'error': '鱼种已存在'}), 409

        fish = FishSpecies(
            name=data['name'],
            name_cn=data.get('name_cn'),
            family=data.get('family')
        )
        db.add(fish)
        db.commit()
        db.refresh(fish)
        return jsonify({'id': fish.id})
    finally:
        db.close()


# ---------- 外部数据 ----------

@app.route('/api/weather', methods=['GET'])
def get_weather():
    """手动获取天气（用于调试）"""
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    if not lat or not lon:
        return jsonify({'error': '需要 lat 和 lon 参数'}), 400
    return jsonify(get_weather_ow(lat, lon))


@app.route('/api/tide', methods=['GET'])
def get_tide():
    """手动获取潮汐（用于调试）"""
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    if not lat or not lon:
        return jsonify({'error': '需要 lat 和 lon 参数'}), 400
    return jsonify(get_tide_info(lat, lon))


# ---------- 微信登录 ----------

@app.route('/api/login', methods=['POST'])
def wx_login():
    """微信小程序登录：用 code 换取 openid"""
    data = request.get_json()
    code = data.get('code')
    if not code:
        return jsonify({'error': '缺少 code 参数'}), 400

    openid, err = get_openid_from_wx(code)
    if err:
        return jsonify({'error': err}), 400
    return jsonify({'openid': openid})


# ========================
# 启动
# ========================
if __name__ == '__main__':
    # 创建表（如不存在）
    Base.metadata.create_all(engine)
    print("数据库初始化完成")

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )