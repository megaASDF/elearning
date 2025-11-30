import 'dart:io'; // For Platform check
import 'package:flutter/foundation.dart' show kIsWeb; // For Web check
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Windows/Desktop DB support
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Web DB support
import 'package:sqflite/sqflite.dart'; // Core DB package

import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/semester_provider.dart';
import 'core/providers/course_provider.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the Database Factory based on the platform
  if (kIsWeb) {
    // --- WEB SETUP ---
    // Use the Web implementation of sqflite
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // --- DESKTOP (WINDOWS) SETUP ---
    // Initialize FFI loader and set the factory
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Note: Android and iOS work automatically without extra setup here.

  // 3. Initialize Services (Wrapped in try-catch to prevent app crash on startup)
  
  // Initialize Database
  try {
    // This forces the database to open/create immediately
    await DatabaseService.instance.database;
  } catch (e) {
    debugPrint('Error initializing database: $e');
  }

  // Initialize Notifications (Skip on Web as it requires different setup)
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }
  
  // Initialize Connectivity
  await ConnectivityService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'E-Learning App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
              ),
            ),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}