import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_provider.dart';
import '../../../logic/attendance/attendance_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double? _localCriteria;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkMode = ref.watch(isDarkModeProvider);
    final criteria = _localCriteria ?? ref.watch(criteriaProvider).toDouble();
    final userNameAsync = ref.watch(userNameProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            userNameAsync.when(
                              data: (name) => Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70)),
                              error: (_, __) => const Text('Student', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ref.read(authRepositoryProvider).currentUser?.email ?? '',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Attendance Criteria
                _SectionHeader(title: 'Attendance Criteria', isDark: isDark),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Minimum Attendance',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimary : AppColors.textLight,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${criteria.toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withValues(alpha: 0.1),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: criteria,
                          min: 50,
                          max: 100,
                          divisions: 50,
                          onChanged: (value) {
                            setState(() => _localCriteria = value);
                          },
                          onChangeEnd: (value) {
                            ref.read(criteriaProvider.notifier).setCriteria(value.toInt());
                            _localCriteria = null;
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('50%', style: TextStyle(fontSize: 12,
                            color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary)),
                          Text('100%', style: TextStyle(fontSize: 12,
                            color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Appearance
                _SectionHeader(title: 'Appearance', isDark: isDark),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  isDark: isDark,
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) => ref.read(isDarkModeProvider.notifier).toggle(),
                  ),
                ),
                const SizedBox(height: 28),

                // About
                _SectionHeader(title: 'About', isDark: isDark),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  isDark: isDark,
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.school_outlined,
                  title: 'AttendX',
                  isDark: isDark,
                  trailing: Text(
                    'Smart Attendance',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Logout
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text('Sign Out',
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.textLight)),
                          content: Text('Are you sure you want to sign out?',
                            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(authControllerProvider.notifier).signOut();
                              },
                              child: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDark ? AppColors.textPrimary : AppColors.textLight,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
