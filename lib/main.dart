import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/semester_provider.dart';
import 'core/providers/course_provider.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding. ensureInitialized();
  
  // Initialize local database only on non-web platforms
  if (!kIsWeb) {
    await DatabaseService.instance.database;
    // Initialize notification service on mobile
    await NotificationService(). initialize();
  }
  
  // Initialize connectivity service
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
        ChangeNotifierProvider. value(value: ConnectivityService.instance),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp. router(
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