import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:p9_rgbridge/db/db_helper.dart';
import 'package:p9_rgbridge/models/device.dart';
import 'package:p9_rgbridge/services/device_discovery.dart';
import 'package:p9_rgbridge/services/mqtt_connection.dart';
import 'package:p9_rgbridge/services/mqtt_service.dart';
import 'package:p9_rgbridge/share/styled_text.dart'; // Contains discoverMqttBrokerViaMdns()

class UdpListenerPage extends StatefulWidget {
  final MQTTConnection mqttConnection;
  const UdpListenerPage({super.key, required this.mqttConnection});

  @override
  State<UdpListenerPage> createState() => _UdpListenerPageState();
}

class _UdpListenerPageState extends State<UdpListenerPage> {
  static const int listenPort = 4210;
  List<String> receivedMessages = [];
  RawDatagramSocket? socket;
  String brokerStatus = "Initializing...";
  bool isDiscovering = false;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startListening();
    _updateBrokerStatus();
  }

  void _updateBrokerStatus() {
    setState(() {
      if (widget.mqttConnection.isConnected) {
        brokerStatus = widget.mqttConnection.isLocal
            ? "✅ Connected to LOCAL broker"
            : "☁️ Connected to CLOUD broker";
      } else {
        brokerStatus = "❌ Not connected to any broker";
      }
    });
  }
  void _discoverLocalBroker() async {
    if (isDiscovering) return;

    setState(() {
      isDiscovering = true;
      brokerStatus = "🔍 Searching for MQTT broker...";
    });

    try {
      if (widget.mqttConnection.isConnected && widget.mqttConnection.isLocal) {
        // Switch to cloud
        await widget.mqttConnection.disconnect();
        await widget.mqttConnection.connect('152.42.241.179', isLocal: false); // Using public method
        setState(() {
          brokerStatus = "☁️ Connected to CLOUD broker";
        });
      } else {
        // Try to discover local broker
        final mdnsResult = await discoverMqttBrokerViaMdns();
        if (mdnsResult != null) {
          await widget.mqttConnection.disconnect();
          await widget.mqttConnection.connect(mdnsResult, isLocal: true); // Using public method
          setState(() {
            brokerStatus = "✅ Connected to LOCAL broker at: $mdnsResult";
          });
        } else {
          // Fall back to cloud if local not found
          await widget.mqttConnection.disconnect();
          await widget.mqttConnection.connect('152.42.241.179', isLocal: false); // Using public method
          setState(() {
            brokerStatus = "☁️ Connected to CLOUD broker (local not found)";
          });
        }
      }
    } catch (e) {
      setState(() {
        brokerStatus = "❌ Connection error: ${e.toString()}";
      });
    } finally {
      setState(() => isDiscovering = false);
    }
  }

  void _checkBrokerStatus() async {
    setState(() {
      brokerStatus = "🔄 Checking broker connection...";
    });

    try {
      final mdnsResult = await discoverMqttBrokerViaMdns();

      if (mdnsResult != null) {
        await widget.mqttConnection.disconnect();
        await widget.mqttConnection.connect(mdnsResult, isLocal: true);
        setState(() {
          brokerStatus = "✅ Connected to LOCAL broker at: $mdnsResult";
        });
      } else {
        await widget.mqttConnection.disconnect();
        await widget.mqttConnection.connect('152.42.241.179', isLocal: false);
        setState(() {
          brokerStatus = "☁️ Connected to CLOUD broker (local not found)";
        });
      }
    } catch (e) {
      setState(() {
        brokerStatus = "❌ Connection error: ${e.toString()}";
      });
    }
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
              if (latestDeviceId != null) {
                await DBHelper.saveDeviceId(latestDeviceId!); // ✅ use ! to assert non-null
                debugPrint('🌐 New Device ID received: $latestDeviceId');
              }
              debugPrint('🌐 New Device ID received: $latestDeviceId');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('UDP Listen error: $e');
    }
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

           Container(
            color: Colors.deepPurple,
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title text
                const Text(
                  'UDP Device Discovery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                // Clear messages button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'Clear messages',
                  onPressed: _clearMessages,
                ),
              ],
            ),
          ),

           // Connection status display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              brokerStatus,
              style: TextStyle(
                fontSize: 16,
                color: widget.mqttConnection.isConnected ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Connection toggle button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 🔘 Discover Button (already existing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isDiscovering ? null : _discoverLocalBroker,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: widget.mqttConnection.isConnected
                            ? (widget.mqttConnection.isLocal ? Colors.green : Colors.blue)
                            : Colors.deepPurple,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.mqttConnection.isConnected
                                ? (widget.mqttConnection.isLocal
                                    ? Icons.network_wifi
                                    : Icons.cloud)
                                : Icons.search,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.mqttConnection.isConnected
                                ? (widget.mqttConnection.isLocal
                                    ? "Switch to Cloud"
                                    : "Switch to Local")
                                : "Discover Broker",
                            style: boldWhiteText,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ New: Check Broker Status Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkBrokerStatus,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.orange,
                      ),
                      icon: const Icon(Icons.wifi_tethering, color: Colors.white),
                      label: const Text(
                        "Check Broker Connection",
                        style: boldWhiteText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
