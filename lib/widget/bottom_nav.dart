import 'package:flutter/material.dart';
import 'package:p9_rgbridge/notifiers/broker_status_notifier.dart';
import 'package:p9_rgbridge/screen/colorRingControl.dart';
import 'package:p9_rgbridge/screen/mqtt_discovery.dart';
import 'package:p9_rgbridge/screen/smart_config.dart';
import 'package:p9_rgbridge/screen/udp_listen.dart';
import 'package:p9_rgbridge/services/mqtt_connection.dart';
import 'package:p9_rgbridge/share/gradient_colour.dart';
import 'package:provider/provider.dart';

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
    final brokerNotifier = context.read<BrokerStatusNotifier>();
    brokerNotifier.updateStatus("🔄 Connecting...", connecting: true);

    try {
      await _mqttConnection.initialize();
      brokerNotifier.updateStatus(
        _mqttConnection.isLocal
            ? "✅ Connected to LOCAL broker"
            : "☁️ Connected to CLOUD broker",
        connecting: false,
      );
    } catch (e) {
      brokerNotifier.updateStatus("❌ Not connected", connecting: false);
      debugPrint('MQTT Initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _mqttConnection.disconnect();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerStatusNotifier>(
      builder: (context, brokerNotifier, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent, // make default background transparent
            flexibleSpace: Container(
              decoration: buildWarmGradient(),
            ),
            title: Text(
              brokerNotifier.isConnecting
                  ? '🔄 ${brokerNotifier.status}'
                  : '🛰️ ${brokerNotifier.status}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: SafeArea(
            child: IndexedStack(
              index: currentPageIndex,
              children: [
                ColorRingControl(
                  key: UniqueKey(),
                  mqttConnection: _mqttConnection,
                ),
                AddDevice(
                  onSmartConfigSuccess: () {
                    setState(() {
                      currentPageIndex = 0;
                    });
                  },
                ),
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
      },
    );
  }
}
