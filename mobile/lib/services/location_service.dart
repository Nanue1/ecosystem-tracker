import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// GPS 定位服务
class LocationService {
  /// 请求定位权限并获取当前位置
  Future<Position> getCurrentPosition() async {
    // 请求权限
    var status = await Permission.location.request();
    if (status.isDenied) {
      // 再次请求
      status = await Permission.location.request();
    }
    if (status.isPermanentlyDenied) {
      throw LocationException('定位权限被永久拒绝，请在系统设置中开启');
    }

    // 检查定位服务是否开启
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('定位服务未开启');
    }

    // 获取当前位置
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// 持续监听位置变化（用于导航/记录轨迹）
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  /// 计算两点间距离（米）
  double distanceBetween(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
