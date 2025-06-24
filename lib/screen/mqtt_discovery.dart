import 'package:flutter/material.dart';
import 'package:multicast_dns/multicast_dns.dart';

class MqttMdnsDiscoveryPage extends StatefulWidget {
  const MqttMdnsDiscoveryPage({super.key});

  @override
  State<MqttMdnsDiscoveryPage> createState() => _MqttMdnsDiscoveryPageState();
}

class _MqttMdnsDiscoveryPageState extends State<MqttMdnsDiscoveryPage> {
  String status = "🔍 Searching for MQTT broker via mDNS...";
  String? discoveredHost;
  int? discoveredPort;

  @override
  void initState() {
    super.initState();
    _discoverMqttBroker();
  }

  Future<void> _discoverMqttBroker() async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();

      // Browse for _mqtt._tcp services
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_mqtt._tcp.local'),
      )) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            setState(() {
              discoveredHost = ip.address.address;
              discoveredPort = srv.port;
              status = "✅ MQTT Broker found: $discoveredHost:$discoveredPort";
            });
            client.stop();
            return;
          }
        }
      }

      setState(() {
        status = "❌ No MQTT broker found via mDNS.";
      });
    } catch (e) {
      setState(() {
        status = "⚠️ mDNS discovery failed: $e";
      });
    } finally {
      client.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mDNS MQTT Discovery')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(status, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}