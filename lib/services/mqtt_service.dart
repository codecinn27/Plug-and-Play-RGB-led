import 'package:multicast_dns/multicast_dns.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<String?> discoverMqttBrokerViaMdns() async {
  final MDnsClient client = MDnsClient();
  try {
    await client.start();

    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer('_mqtt._tcp.local'),
    )) {
      await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )) {
        await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
        )) {
          client.stop();
          return "${ip.address.address}:${srv.port}";
        }
      }
    }

    client.stop();
    return null;
  } catch (e) {
    client.stop();
    return null;
  }
}


class MqttService {
  static final MqttService instance = MqttService._internal();
  late MqttServerClient client;

  MqttService._internal() {
    client = MqttServerClient('152.42.241.179', 'flutter_client');
    client.port = 1883; // your MQTT port
    client.logging(on: false);
    client.keepAlivePeriod = 20;
  }

  Future<void> connect() async {
    try {
      await client.connect();
      print("MQTT connected");
    } catch (e) {
      print("MQTT connect error: $e");
      client.disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
    print("MQTT disconnected");
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}