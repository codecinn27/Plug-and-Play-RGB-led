import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:p9_rgbridge/db/db_helper.dart';
import 'package:p9_rgbridge/services/device_discovery.dart';
import 'package:p9_rgbridge/services/mqtt_service.dart';
import 'package:p9_rgbridge/share/styled_text.dart'; // Contains discoverMqttBrokerViaMdns()
import 'package:p9_rgbridge/models/device.dart';

class UdpListenerPage extends StatefulWidget {
  const UdpListenerPage({super.key});

  @override
  State<UdpListenerPage> createState() => _UdpListenerPageState();
}

class _UdpListenerPageState extends State<UdpListenerPage> {
  static const int listenPort = 4210;
  List<String> receivedMessages = [];
  RawDatagramSocket? socket;
  String brokerStatus = "No broker discovered.";
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startListening();
  }

  Future<void> _loadMessages() async {
    final messages = await DBHelper.getMessages();
    setState(() {
      receivedMessages = messages;
    });
  }

  void _startListening() async {
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        listenPort,
        reuseAddress: true,
      );
      socket?.broadcastEnabled = true;

      socket?.listen((RawSocketEvent event) async {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            final address = datagram.address.address;
            final displayMessage = '📨 $address → $message';

            await DBHelper.insertMessage(displayMessage);
            setState(() {
              receivedMessages.insert(0, displayMessage);
            });
            final match = RegExp(r'DL8_[A-F0-9]+').firstMatch(message);
            if (match != null) {
              latestDeviceId = match.group(0); // ✅ Update global variable
              debugPrint('🌐 New Device ID received: $latestDeviceId');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('UDP Listen error: $e');
    }
  }

  void _discoverLocalBroker() async {
    if (isDiscovering) return;

    setState(() {
      isDiscovering = true;
      brokerStatus = "🔍 Searching for MQTT broker via mDNS...";
    });

    final mdnsResult = await discoverMqttBrokerViaMdns();

    if (mdnsResult != null) {
      setState(() {
        brokerStatus = "✅ MQTT Broker found via mDNS at: $mdnsResult";
        isDiscovering = false;
      });
      return;
    }

    setState(() {
      brokerStatus = "🔍 mDNS not found, trying UDP...";
    });

    final udpResult = await DeviceDiscovery.discoverViaUDP();

    setState(() {
      brokerStatus = udpResult != null
          ? "✅ MQTT Broker found via UDP at: $udpResult"
          : "❌ No MQTT broker found on local network.";
      isDiscovering = false;
    });
  }
  void _clearMessages() async {
    await DBHelper.clearMessages(); // Make sure this function exists
    setState(() {
      receivedMessages.clear();
    });
  }


  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('UDP Device Discovery', style: boldWhiteText,),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white,),
            tooltip: 'Clear messages',
            onPressed: _clearMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // 📨 Message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: receivedMessages.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(receivedMessages[index]),
                  ),
                );
              },
            ),
          ),

          // 🚀 Broker Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              brokerStatus,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),

          // 🔘 Discover Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDiscovering ? null : _discoverLocalBroker,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.deepPurple,
                  ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, color: Colors.white),
                    SizedBox(width: 8), // spacing between icon and text
                    Text(
                      "Discover Local Broker",
                      style: boldWhiteText,
                    ),
                  ],
                ),

                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
