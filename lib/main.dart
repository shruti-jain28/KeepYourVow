// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/isar/isar_service.dart';
import 'features/today/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await IsarService.instance.init();
  runApp(const ProviderScope(child: KYVApp()));

  // Defer non-critical init until after first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.instance.init();
  });
}
