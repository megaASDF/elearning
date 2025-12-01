import 'package:elearning_app/core/providers/submission_provider.dart';
import 'package:elearning_app/core/services/offline_database_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/semester_provider.dart';
import 'core/providers/course_provider.dart';
import 'core/providers/group_provider.dart';
import 'core/providers/student_provider.dart';
import 'core/providers/assignment_provider.dart'; // ADD
import 'core/providers/material_provider.dart'; // ADD
import 'core/providers/announcement_provider.dart'; // ADD
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add this to catch and log all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(' FLUTTER ERROR ');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint(' END ERROR \n');
  };
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OfflineDatabaseService.initialize();

  // Initialize default semester if none exists
  await _initializeDefaultData();

  // Initialize notification service (non-web only)
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  // Initialize connectivity service
  await ConnectivityService.instance.initialize();

  runApp(const MyApp());
}

Future<void> _initializeDefaultData() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Check if default semester exists
    final semesterQuery =
        await firestore.collection('semesters').limit(1).get();

    if (semesterQuery.docs.isEmpty) {
      // Create default semester
      await firestore.collection('semesters').add({
        'code': 'HK1-2024',
        'name': 'Semester 1, 2024-2025',
        'startDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
        'isCurrent': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Default semester created');
    }
  } catch (e) {
    debugPrint('Error initializing default data: $e');
  }
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
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()), // ADD
        ChangeNotifierProvider(create: (_) => MaterialProvider()), // ADD
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => SubmissionProvider()), // ADD
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
