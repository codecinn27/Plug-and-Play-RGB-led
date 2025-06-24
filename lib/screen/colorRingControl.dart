import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:p9_rgbridge/db/db_helper.dart';
import 'package:p9_rgbridge/models/device.dart';
import 'package:p9_rgbridge/services/mqtt_connection.dart';

class ColorRingControl extends StatefulWidget {
  final MQTTConnection mqttConnection;
  final String? deviceId;

  const ColorRingControl({
    super.key,
    required this.mqttConnection,
    this.deviceId,
  });

  @override
  State<ColorRingControl> createState() => _ColorRingControlState();
}

class _ColorRingControlState extends State<ColorRingControl> {
  Color selectedColor = Colors.green;
  bool isOn = true;
  String? currentUdpId = 'DL8_00008F50E2'; // ✅ Default value
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('Loading saved Device ID from DB');
    // Load saved device ID from DB on startup
    DBHelper.getSavedDeviceId().then((savedId) {
      if (savedId != null && mounted) {
        setState(() {
          currentUdpId = savedId;
        });
        debugPrint('📥 Loaded saved Device ID: $savedId');
      }
    });

    // Start periodic check for live updates from UDP listener, if you have one
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (latestDeviceId != null && latestDeviceId != currentUdpId) {
        setState(() {
          currentUdpId = latestDeviceId;
        });
      }
    });
  }


  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }


  void _toggleLight() {
    setState(() {
      isOn = !isOn;
    });

    final topic = 'rgb/DL8_9A8F8F50E2/dfd34';
    final client = widget.mqttConnection.client;

    String payload = isOn
        ? '${selectedColor.red},${selectedColor.green},${selectedColor.blue}'
        : '0,0,0';

    print('💡 Light ${isOn ? "ON" : "OFF"} - Publishing: $payload');

    if (client != null && client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    } else {
      print('❌ MQTT client not connected');
    }
  }

  void _onColorChanged(Color color) {
    setState(() {
      selectedColor = color;
    });

    if (isOn) {
      _toggleLight(); // re-publish updated color
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        final navbarHeight = 80.0;
        final totalBottomSpace = bottomPadding + navbarHeight;
        final maxDiameter = constraints.maxWidth;
        final availableHeight = constraints.maxHeight - totalBottomSpace;
        final diameter = maxDiameter < availableHeight ? maxDiameter : availableHeight;
        final colorPickerHeight = diameter + 80;

        return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color.fromARGB(255, 222, 139, 57), // ✅ Highlight background
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '🌐 Device ID: ${currentUdpId ?? "Waiting..."}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: diameter,
                      height: colorPickerHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ColorPicker(
                            pickerColor: selectedColor,
                            onColorChanged: _onColorChanged,
                            colorPickerWidth: diameter,
                            pickerAreaHeightPercent: 1.0,
                            enableAlpha: false,
                            displayThumbColor: true,
                            paletteType: PaletteType.hsvWithHue,
                            labelTypes: const [],
                            portraitOnly: false,
                          ),
                          GestureDetector(
                            onTap: _toggleLight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: diameter * 0.35,
                              height: diameter * 0.35,
                              decoration: BoxDecoration(
                                color: isOn ? selectedColor : Colors.grey[800],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isOn
                                        ? selectedColor.withOpacity(0.5)
                                        : Colors.transparent,
                                    blurRadius: 15,
                                    spreadRadius: 8,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.lightbulb,
                                size: diameter * 0.175,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: totalBottomSpace),
              ],
            ),
          ),
        );
      },
    );
  }
}
