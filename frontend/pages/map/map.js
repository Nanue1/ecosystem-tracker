// pages/map/map.js
const app = getApp();

Page({
  data: {
    waypoints: [],
    loading: false,
    empty: false,
    creating: false,
    name: '',
    latitude: null,
    longitude: null
  },

  onLoad() {
    this.setData({ apiBase: app.globalData.apiBase });
    this.loadWaypoints();
  },

  onShow() {
    this.loadWaypoints();
  },

  loadWaypoints() {
    this.setData({ loading: true });
    const openid = app.globalData.openid || wx.getStorageSync('openid');
    wx.request({
      url: `${app.globalData.apiBase}/api/waypoints`,
      data: { openid },
      success: res => {
        if (Array.isArray(res.data)) {
          this.setData({
            waypoints: res.data,
            empty: res.data.length === 0
          });
        }
      },
      fail: err => {
        console.error(err);
        wx.showToast({ title: '加载失败', icon: 'none' });
      },
      complete: () => {
        this.setData({ loading: false });
      }
    });
  },

  // 获取当前位置作为标点
  getLocationAndSet() {
    wx.getLocation({
      type: 'gcj02',
      success: res => {
        this.setData({
          latitude: res.latitude,
          longitude: res.longitude
        });
        wx.showToast({ title: '已获取位置', icon: 'success' });
      },
      fail: err => {
        wx.showToast({ title: '获取位置失败', icon: 'none' });
        console.error(err);
      }
    });
  },

  onNameInput(e) {
    this.setData({ name: e.detail.value });
  },

  // 创建标点
  createWaypoint() {
    const { name, latitude, longitude } = this.data;
    if (!name || !latitude || !longitude) {
      wx.showToast({ title: '请填写名称并获取位置', icon: 'none' });
      return;
    }

    this.setData({ creating: true });
    const openid = app.globalData.openid || wx.getStorageSync('openid');

    wx.request({
      url: `${app.globalData.apiBase}/api/waypoints`,
      method: 'POST',
      data: { openid, name, latitude, longitude },
      success: res => {
        if (res.data && res.data.id) {
          wx.showToast({ title: '标点已创建', icon: 'success' });
          this.setData({ name: '', latitude: null, longitude: null });
          this.loadWaypoints();
        } else {
          wx.showToast({ title: '创建失败', icon: 'none' });
        }
      },
      fail: err => {
        wx.showToast({ title: '网络错误', icon: 'none' });
        console.error(err);
      },
      complete: () => {
        this.setData({ creating: false });
      }
    });
  }
});
