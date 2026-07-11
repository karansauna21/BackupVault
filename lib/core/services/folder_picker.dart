import 'package:flutter/material.dart';

abstract class FolderPicker {
  Future<String?> pickFolder(BuildContext context);
}
