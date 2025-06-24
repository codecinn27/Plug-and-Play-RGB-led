//save the mqtt broker ipaddress, device id and device ipaddress

class Device {
  final String id;
  final String ip;
  final String name;
  
  Device({required this.id, required this.ip, required this.name});
}

String? latestDeviceId;