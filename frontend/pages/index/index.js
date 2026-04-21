// pages/index/index.js
const app = getApp();

Page({
  data: {
    loading: false,
    location: null,
    address: null,
    weather: null,
    tide: null,
    tripResult: null,
    remark: ''
  },

  onLoad() {
    this.setData({ apiBase: app.globalData.apiBase });
  },

  // 获取当前位置
  getLocation() {
    wx.getLocation({
      type: 'gcj02',
      success: res => {
        this.setData({ location: res });
        this.fetchAddress(res.latitude, res.longitude);
        this.fetchWeather(res.latitude, res.longitude);
        this.fetchTide(res.latitude, res.longitude);
      },
      fail: err => {
        wx.showToast({ title: '获取位置失败', icon: 'none' });
        console.error(err);
      }
    });
  },

  // 获取地址
  fetchAddress(lat, lon) {
    // 实际应调用后端逆地理编码
    // 这里前端直接调用高德（需配置合法域名）
    wx.request({
      url: `https://restapi.amap.com/v3/geocode/regeo`,
      data: {
        key: app.globalData.amapKey,
        location: `${lon},${lat}`
      },
      success: res => {
        if (res.data.status === '1') {
          this.setData({ address: res.data.regeocode.formatted_address });
        }
      }
    });
  },

  // 获取天气（通过后端）
  fetchWeather(lat, lon) {
    const apiBase = app.globalData.apiBase;
    wx.request({
      url: `${apiBase}/api/weather`,
      data: { lat, lon },
      success: res => {
        if (res.data && !res.data.error) {
          this.setData({ weather: res.data });
        }
      }
    });
  },

  // 获取潮汐（通过后端）
  fetchTide(lat, lon) {
    const apiBase = app.globalData.apiBase;
    wx.request({
      url: `${apiBase}/api/tide`,
      data: { lat, lon },
      success: res => {
        if (res.data) {
          this.setData({ tide: res.data });
        }
      }
    });
  },

  // 输入备注
  onRemarkChange(e) {
    this.setData({ remark: e.detail.value });
  },

  // 一键记录出勤
  recordTrip() {
    if (!this.data.location) {
      wx.showToast({ title: '请先获取位置', icon: 'none' });
      return;
    }

    this.setData({ loading: true });

    // 从全局获取 openid
    const openid = app.globalData.openid || wx.getStorageSync('openid');
    const { latitude, longitude } = this.data.location;

    wx.request({
      url: `${app.globalData.apiBase}/api/trips`,
      method: 'POST',
      data: {
        openid,
        latitude,
        longitude,
        remark: this.data.remark
      },
      success: res => {
        if (res.data.id) {
          this.setData({
            tripResult: res.data,
            tripId: res.data.id
          });
          wx.showToast({ title: '出勤记录成功', icon: 'success' });
        } else {
          wx.showToast({ title: '记录失败', icon: 'none' });
        }
      },
      fail: err => {
        wx.showToast({ title: '网络请求失败', icon: 'none' });
        console.error(err);
      },
      complete: () => {
        this.setData({ loading: false });
      }
    });
  },

  // 去拍照记录鱼货
  goToCatch() {
    if (!this.data.tripId) {
      wx.showToast({ title: '请先记录出勤', icon: 'none' });
      return;
    }
    wx.navigateTo({
      url: `/pages/catches/catches?trip_id=${this.data.tripId}`
    });
  }
});
