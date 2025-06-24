import 'package:flutter/material.dart';
import 'package:p9_rgbridge/screen/colorRingControl.dart';
import 'package:p9_rgbridge/screen/mqtt_discovery.dart';
import 'package:p9_rgbridge/screen/smart_config.dart';
import 'package:p9_rgbridge/screen/udp_listen.dart';
import 'package:p9_rgbridge/services/mqtt_connection.dart';

class NavBar extends StatefulWidget {
  final String? deviceId; // Pass deviceId if needed
  const NavBar({Key? key, this.deviceId}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int currentPageIndex = 0;
  final MQTTConnection _mqttConnection = MQTTConnection();
  bool _isConnecting = true;
  String _connectionStatus = "🔄 Connecting to MQTT...";

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = "🔄 Connecting...";
    });

    try {
      await _mqttConnection.initialize();
      setState(() {
        _connectionStatus = _mqttConnection.isLocal
            ? "✅ Connected to LOCAL broker"
            : "☁️ Connected to CLOUD broker";
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Not connected";
      });
      debugPrint('MQTT Initialization failed: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  void dispose() {
    _mqttConnection.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ This AppBar shows connection status on all screens
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 139, 57),
        title: Text(
          _isConnecting ? '🔄 $_connectionStatus' : '🛰️ $_connectionStatus',
          style: const TextStyle(color: Colors.white, fontSize:16),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentPageIndex,
          children: [
            ColorRingControl(
              key: UniqueKey(), // ✅ Guaranteed unique
              mqttConnection: _mqttConnection,
            ),
            AddDevice(),
            UdpListenerPage(mqttConnection: _mqttConnection),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber.withOpacity(0.2),
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.lightbulb, color: Colors.amber),
            icon: Icon(Icons.lightbulb_outline),
            label: 'Device',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add_circle, color: Colors.amber),
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Device',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.network_check, color: Colors.amber),
            icon: Icon(Icons.network_check_outlined),
            label: 'Network',
          ),
        ],
      ),
    );
  }

}