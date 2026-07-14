class DeviceInfoModel {
  const DeviceInfoModel({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.fcmToken,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String? fcmToken;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}
