// pages/history/history.js
const app = getApp();

Page({
  data: {
    trips: [],
    loading: false,
    empty: false
  },

  onLoad() {
    this.setData({ apiBase: app.globalData.apiBase });
    this.loadTrips();
  },

  onShow() {
    this.loadTrips();
  },

  loadTrips() {
    this.setData({ loading: true });
    const openid = app.globalData.openid || wx.getStorageSync('openid');
    wx.request({
      url: `${app.globalData.apiBase}/api/trips`,
      data: { openid },
      success: res => {
        if (Array.isArray(res.data)) {
          this.setData({
            trips: res.data,
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

  viewCatch(e) {
    const tripId = e.currentTarget.dataset.tripId;
    wx.navigateTo({
      url: `/pages/catches/catches?trip_id=${tripId}`
    });
  }
});
