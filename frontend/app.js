App({
  globalData: {
    // API 基础地址（开发时用本地，发布时用实际域名）
    apiBase: 'https://api.042138.xyz',

    // 微信小程序 AppID
    appId: 'wxe6c1c6c304a028d8',

    // 地图 key
    amapKey: 'd185bf2bbab4f569ee1ba0f66e406dd4',

    // 当前用户 openid（登录后设置）
    openid: null,

    // 当前位置
    location: null
  },

  onLaunch() {
    // 获取用户 openid
    this.login();
  },

  login() {
    wx.login({
      success: res => {
        if (res.code) {
          // 将 code 发送到后端换取 openid
          wx.request({
            url: `${this.globalData.apiBase}/api/login`,
            method: 'POST',
            data: { code: res.code },
            success: resp => {
              if (resp.data && resp.data.openid) {
                this.globalData.openid = resp.data.openid;
                wx.setStorageSync('openid', resp.data.openid);
                console.log('openid 获取成功:', resp.data.openid);
              }
            },
            fail: err => {
              console.error('login API failed:', err);
            }
          });
        }
      }
    });

    // 监听用户信息（需用户授权）
    wx.getSetting({
      success: res => {
        if (res.authSetting['scope.userInfo']) {
          wx.getUserInfo({
            success: data => {
              this.globalData.userInfo = data.userInfo;
            }
          });
        }
      }
    });
  }
});
