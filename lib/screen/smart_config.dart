import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:p9_rgbridge/share/styled_text.dart';

class AddDevice extends StatefulWidget {
  final VoidCallback? onSmartConfigSuccess;

  const AddDevice({super.key, this.onSmartConfigSuccess});

  @override
  State<AddDevice> createState() => _AddDeviceState();
}

class _AddDeviceState extends State<AddDevice> {
  bool? _isWifi;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _checkWifiStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool connected = connectivityResult == ConnectivityResult.wifi;

    setState(() {
      _isWifi = connected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(connected ? 'Connected to WiFi' : 'Not connected to WiFi')),
    );
  }
  void _onDeviceProvisioned(ProvisioningResponse response) {
    final ip = response.ipAddressText ?? 'Unknown IP';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Device added successfully\n🛰️ IP Address: $ip'),
        duration: const Duration(seconds: 3),
      ),
    );

    widget.onSmartConfigSuccess?.call(); // ✅ Switch to tab index 0
  }

  Future<void> startSmartConfig() async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter SSID and password')),
      );
      return;
    }

    final provisioner = Provisioner.espTouch();
    ProvisioningResponse? smartConfigResponse;
    provisioner.listen((response) {
      smartConfigResponse = response; // ✅ Save the result
      Navigator.of(context, rootNavigator: true).pop(); // ✅ Close dialog
    });

    provisioner.start(ProvisioningRequest.fromStrings(
      ssid: _ssidController.text,
      bssid: '00:00:00:00:00:00',
      password: _passwordController.text,
    ));

    ProvisioningResponse? response = await showDialog<ProvisioningResponse>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Provisioning'),
          content: const Text('Provisioning started. Please wait...'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );

    if(provisioner.running) {
      provisioner.stop();
    }

    // Handle result
    if (smartConfigResponse != null) {
      _onDeviceProvisioned(smartConfigResponse!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ SmartConfig failed or was cancelled')),
      );
    }
  }


  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                children: [
                  const SizedBox(height: 70),
                  SvgPicture.asset(
                    'assets/light-bulb-svgrepo-com.svg',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),
                  const StyledText('RGBridge'),
                ],
              ),
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: StyledTextRegular('SSID:', 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ssidController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: StyledTextRegular('Password:', 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkWifiStatus,
                child: const Text('Check WiFi Connection'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: startSmartConfig,
                child: const Text('Add Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}