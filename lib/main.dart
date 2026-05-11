import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth/auth_provider.dart';
import 'logic/attendance/attendance_provider.dart';
import 'logic/notifications/notification_service.dart';
import 'logic/timetable/timetable_provider.dart';
import 'data/models/subject_stats.dart';
import 'firebase_options.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/attendance/daily_attendance_screen.dart';
import 'presentation/screens/calendar/calendar_screen.dart';
import 'presentation/screens/timetable/timetable_management_screen.dart';
import 'presentation/screens/alerts/low_attendance_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/ai_assistant/ai_assistant_screen.dart';
import 'presentation/widgets/glass_loading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Force instant local cache load before connecting to websocket to bypass Web delay
  try {
    await FirebaseFirestore.instance.disableNetwork();
    Future.delayed(const Duration(milliseconds: 500), () {
      FirebaseFirestore.instance.enableNetwork();
    });
  } catch (e) {
    // Ignore if not supported on platform
  }

  await NotificationService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: true,
        builder: (context) => const AttendXApp(),
      ),
    ),
  );
}

class AttendXApp extends ConsumerWidget {
  const AttendXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'AttendX',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}

/// Listens to auth state and routes to login or home
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
      loading: () => Scaffold(
        body: Center(child: GlassLoading(message: "Authenticating...")),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}

/// Splash screen shown while checking auth state
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkBgGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'AttendX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Attendance Tracker',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main navigation with 6-tab bottom nav bar
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Schedule notifications after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNotifications();
    });
  }

  Future<void> _scheduleNotifications() async {
    final lectures = ref.read(todayLecturesProvider).value;
    final stats = ref.read(subjectStatsProvider).value;
    final minutesBefore = await ref.read(settingsRepositoryProvider).getNotificationMinutes();

    if (lectures != null && stats != null) {
      final List<Map<String, dynamic>> mappedLectures = lectures.map((l) {
        final stat = stats.firstWhere(
          (s) => s.subjectName == l.subjectName,
          orElse: () => SubjectStats(subjectName: l.subjectName, totalLectures: 0, attendedLectures: 0),
        );
        return {
          'subjectName': l.subjectName,
          'startTime': l.startTime,
          'currentPct': stat.percentage,
        };
      }).toList();

      await NotificationService().scheduleAllTodayReminders(
        lectures: mappedLectures,
        minutesBefore: minutesBefore,
      );
    }
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    DailyAttendanceScreen(),
    CalendarScreen(),
    TimetableManagementScreen(),
    LowAttendanceScreen(),
    SettingsScreen(),
  ];

  void _openAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // AI FAB — visible on Dashboard only
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: 90,
              child: _AiFab(onTap: _openAiAssistant),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 70,
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_calendar_outlined),
                selectedIcon: Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
                label: 'Mark',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule_rounded, color: AppColors.primary),
                label: 'Timetable',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_rounded, color: AppColors.primary),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated AI Assistant FAB
class _AiFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AiFab({required this.onTap});

  @override
  State<_AiFab> createState() => _AiFabState();
}

class _AiFabState extends State<_AiFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 8, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: _glowAnimation.value,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// AI Assistant as a full-screen bottom sheet
class _AiAssistantSheet extends StatelessWidget {
  const _AiAssistantSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: const AiAssistantScreen(),
      ),
    );
  }
}
