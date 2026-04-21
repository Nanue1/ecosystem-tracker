// pages/catches/catches.js
const app = getApp();

Page({
  data: {
    tripId: null,
    speciesList: [],
    selectedSpecies: '',
    count: 1,
    length: '',
    weight: '',
    photoUrl: '',
    catches: []
  },

  onLoad(options) {
    this.setData({
      tripId: options.trip_id,
      apiBase: app.globalData.apiBase
    });
    this.loadSpecies();
    this.loadCatches();
  },

  // 加载鱼种列表
  loadSpecies() {
    wx.request({
      url: `${app.globalData.apiBase}/api/fish-species`,
      success: res => {
        if (Array.isArray(res.data)) {
          this.setData({ speciesList: res.data });
        }
      }
    });
  },

  // 加载已有鱼货记录
  loadCatches() {
    wx.request({
      url: `${app.globalData.apiBase}/api/catches/${this.data.tripId}`,
      success: res => {
        if (Array.isArray(res.data)) {
          this.setData({ catches: res.data });
        }
      }
    });
  },

  // 选择鱼种
  onSpeciesChange(e) {
    const index = e.detail.value;
    const species = this.data.speciesList[index];
    this.setData({ selectedSpecies: species.name });
  },

  onCountChange(e) {
    this.setData({ count: parseInt(e.detail.value) || 1 });
  },

  onLengthChange(e) {
    this.setData({ length: e.detail.value });
  },

  onWeightChange(e) {
    this.setData({ weight: e.detail.value });
  },

  // 拍照
  takePhoto() {
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      success: res => {
        const tempFilePath = res.tempFiles[0].tempFilePath;
        this.uploadPhoto(tempFilePath);
      }
    });
  },

  // 上传照片
  uploadPhoto(filePath) {
    wx.uploadFile({
      url: `${app.globalData.apiBase}/api/upload`,
      filePath: filePath,
      name: 'photo',
      success: res => {
        const data = JSON.parse(res.data);
        if (data.url) {
          this.setData({ photoUrl: data.url });
          wx.showToast({ title: '上传成功', icon: 'success' });
        }
      },
      fail: err => {
        wx.showToast({ title: '上传失败', icon: 'none' });
        console.error(err);
      }
    });
  },

  // 提交鱼货记录
  submitCatch() {
    if (!this.data.selectedSpecies) {
      wx.showToast({ title: '请选择鱼种', icon: 'none' });
      return;
    }

    wx.request({
      url: `${app.globalData.apiBase}/api/catches`,
      method: 'POST',
      data: {
        trip_id: this.data.tripId,
        fish_species: this.data.selectedSpecies,
        count: this.data.count,
        length: this.data.length || null,
        weight: this.data.weight || null,
        photo_url: this.data.photoUrl || null
      },
      success: res => {
        if (res.data.id) {
          wx.showToast({ title: '记录成功', icon: 'success' });
          this.loadCatches();
          // 清空表单
          this.setData({
            selectedSpecies: '',
            count: 1,
            length: '',
            weight: '',
            photoUrl: ''
          });
        }
      }
    });
  }
});
