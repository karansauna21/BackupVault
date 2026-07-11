import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/windows_settings_page.dart';
import 'widgets/android_settings_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return const AndroidSettingsPage();
    } else {
      return const WindowsSettingsPage();
    }
  }
}
