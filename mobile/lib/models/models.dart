// ===========================
// 数据模型
// ===========================

/// 出勤记录
class Trip {
  final int? id;
  final String openid;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? weather;
  final String? tide;
  final String? note;

  Trip({
    this.id,
    required this.openid,
    required this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    this.weather,
    this.tide,
    this.note,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int?,
      openid: json['openid'] as String? ?? '',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      weather: json['weather'] as String?,
      tide: json['tide'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'openid': openid,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'weather': weather,
        'tide': tide,
        'note': note,
      };

  Trip copyWith({
    int? id,
    String? openid,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    String? weather,
    String? tide,
    String? note,
  }) {
    return Trip(
      id: id ?? this.id,
      openid: openid ?? this.openid,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      weather: weather ?? this.weather,
      tide: tide ?? this.tide,
      note: note ?? this.note,
    );
  }
}

/// GPS 标记点
class Waypoint {
  final int? id;
  final int tripId;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  Waypoint({
    this.id,
    required this.tripId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as int?,
      tripId: json['trip_id'] as int,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };
}

/// 鱼货记录
class Catch {
  final int? id;
  final int tripId;
  final int? fishSpeciesId;
  final String? fishSpeciesName;
  final int? weight; // 克
  final int? length; // 厘米
  final String? photoPath;
  final String? photoUrl;
  final DateTime caughtAt;
  final String? note;

  Catch({
    this.id,
    required this.tripId,
    this.fishSpeciesId,
    this.fishSpeciesName,
    this.weight,
    this.length,
    this.photoPath,
    this.photoUrl,
    required this.caughtAt,
    this.note,
  });

  factory Catch.fromJson(Map<String, dynamic> json) {
    return Catch(
      id: json['id'] as int?,
      tripId: json['trip_id'] as int,
      fishSpeciesId: json['fish_species_id'] as int?,
      fishSpeciesName: json['fish_species_name'] as String?,
      weight: json['weight'] as int?,
      length: json['length'] as int?,
      photoPath: json['photo_path'] as String?,
      photoUrl: json['photo_url'] as String?,
      caughtAt: DateTime.parse(json['caught_at'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'fish_species_id': fishSpeciesId,
        'fish_species_name': fishSpeciesName,
        'weight': weight,
        'length': length,
        'photo_path': photoPath,
        'caught_at': caughtAt.toIso8601String(),
        'note': note,
      };
}

/// 鱼种
class FishSpecies {
  final int id;
  final String name;
  final String? chineseName;
  final String? category;
  final String? description;

  FishSpecies({
    required this.id,
    required this.name,
    this.chineseName,
    this.category,
    this.description,
  });

  factory FishSpecies.fromJson(Map<String, dynamic> json) {
    return FishSpecies(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      chineseName: json['chinese_name'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }

  String get displayName => chineseName ?? name;
}

/// 天气信息
class Weather {
  final String condition;
  final double temperature;
  final double? windSpeed;
  final String? windDirection;
  final int humidity;
  final String location;

  Weather({
    required this.condition,
    required this.temperature,
    this.windSpeed,
    this.windDirection,
    required this.humidity,
    required this.location,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      condition: json['condition'] as String? ?? '未知',
      temperature: (json['temperature'] as num).toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      windDirection: json['wind_direction'] as String?,
      humidity: (json['humidity'] as int?) ?? 0,
      location: json['location'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      '$condition ${temperature.toStringAsFixed(1)}°C 风${windSpeed?.toStringAsFixed(1)}m/s';
}

/// 潮汐信息
class Tide {
  final DateTime time;
  final String type; // 'high' 或 'low'
  final double height;

  Tide({required this.time, required this.type, required this.height});

  factory Tide.fromJson(Map<String, dynamic> json) {
    return Tide(
      time: DateTime.parse(json['time'] as String),
      type: json['type'] as String? ?? 'unknown',
      height: (json['height'] as num).toDouble(),
    );
  }
}
