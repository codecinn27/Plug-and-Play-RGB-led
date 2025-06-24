import 'package:flutter/material.dart';
import 'package:p9_rgbridge/notifiers/broker_status_notifier.dart';
import 'package:p9_rgbridge/share/theme.dart';
import 'package:p9_rgbridge/widget/bottom_nav.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BrokerStatusNotifier(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NavBar(),
        debugShowCheckedModeBanner: false,
      )
      
    )
  );
}
