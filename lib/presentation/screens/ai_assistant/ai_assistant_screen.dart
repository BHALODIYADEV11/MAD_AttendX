import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/subject_stats.dart';
import '../../../logic/attendance/attendance_provider.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<Map<String, String>> _quickQuestions = [
    {'icon': '🤔', 'text': 'Can I bunk tomorrow?'},
    {'icon': '📊', 'text': 'How is my attendance?'},
    {'icon': '⚠️', 'text': 'Which subjects need attention?'},
    {'icon': '🎯', 'text': 'How many classes can I miss?'},
    {'icon': '📅', 'text': 'How many classes must I attend?'},
    {'icon': '🏆', 'text': 'What is my best subject?'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addBotMessage(
        "👋 Hey! I'm your **AttendX AI Assistant**.\n\nI can help you understand your attendance, plan your bunks wisely, and keep you on track. What would you like to know?",
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
  }

  Future<void> _handleQuestion(String question) async {
    _addUserMessage(question);
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final subjectStatsAsync = ref.read(subjectStatsProvider);
    final overallAsync = ref.read(overallStatsProvider);
    final criteria = ref.read(criteriaProvider);

    final subjectStats = subjectStatsAsync.valueOrNull ?? [];
    final overall = overallAsync.valueOrNull;

    String response = '';

    final q = question.toLowerCase();

    if (q.contains('bunk') || q.contains('miss') || q.contains('skip')) {
      response = _buildBunkResponse(subjectStats, criteria);
    } else if (q.contains('how is') || q.contains('attendance') && q.contains('status')) {
      response = _buildStatusResponse(overall, subjectStats, criteria);
    } else if (q.contains('attention') || q.contains('low') || q.contains('below')) {
      response = _buildLowSubjectsResponse(subjectStats, criteria);
    } else if (q.contains('attend') && q.contains('must')) {
      response = _buildMustAttendResponse(subjectStats, criteria);
    } else if (q.contains('best') || q.contains('top')) {
      response = _buildBestSubjectResponse(subjectStats);
    } else if (q.contains('overall') || q.contains('total') || q.contains('how is')) {
      response = _buildStatusResponse(overall, subjectStats, criteria);
    } else {
      response = _buildDefaultResponse(overall, subjectStats, criteria);
    }

    setState(() => _isTyping = false);
    _addBotMessage(response);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildBunkResponse(List<SubjectStats> stats, int criteria) {
    if (stats.isEmpty) {
      return "📭 No attendance data yet! Set up your timetable and mark some attendance first.";
    }

    final safeSubs = stats.where((s) => s.lecturesCanMiss(criteria) > 0).toList()
      ..sort((a, b) => b.lecturesCanMiss(criteria).compareTo(a.lecturesCanMiss(criteria)));

    final dangerSubs = stats.where((s) => s.lecturesCanMiss(criteria) == 0 && s.isBelowCriteria(criteria)).toList();

    if (safeSubs.isEmpty) {
      return "🚫 **No bunks allowed right now!**\n\nYou're at or below the $criteria% criteria in most subjects. You need to attend consistently to recover.\n\n${dangerSubs.isNotEmpty ? "⚠️ **Critical subjects:**\n${dangerSubs.map((s) => '• ${s.subjectName}: ${s.percentage.toStringAsFixed(1)}% — Need ${s.lecturesNeededToMeetCriteria(criteria)} more classes').join('\n')}" : ""}";
    }

    final safeLines = safeSubs.take(3).map((s) {
      final canMiss = s.lecturesCanMiss(criteria);
      return '✅ **${s.subjectName}**: can miss **$canMiss** more ${canMiss == 1 ? "class" : "classes"} (currently ${s.percentage.toStringAsFixed(1)}%)';
    }).join('\n');

    String warning = '';
    if (dangerSubs.isNotEmpty) {
      warning = "\n\n⚠️ **Do NOT bunk:**\n${dangerSubs.map((s) => '• ${s.subjectName}: only ${s.percentage.toStringAsFixed(1)}%').join('\n')}";
    }

    return "🎯 **Bunk Budget Analysis:**\n\n$safeLines$warning";
  }

  String _buildStatusResponse(SubjectStats? overall, List<SubjectStats> stats, int criteria) {
    if (overall == null || overall.totalLectures == 0) {
      return "📭 No attendance recorded yet. Start marking your lectures!";
    }

    final pct = overall.percentage.toStringAsFixed(1);
    final status = overall.percentage >= criteria ? "✅ Above criteria" : "⚠️ Below criteria";
    final lowCount = stats.where((s) => s.isBelowCriteria(criteria)).length;

    return "📊 **Overall Attendance: $pct%**\n\n$status ($criteria% required)\n• Attended: ${overall.attendedLectures}/${overall.totalLectures} lectures\n${lowCount > 0 ? "• ⚠️ $lowCount subject${lowCount > 1 ? 's' : ''} below criteria" : "• All subjects on track! 🎉"}";
  }

  String _buildLowSubjectsResponse(List<SubjectStats> stats, int criteria) {
    final low = stats.where((s) => s.isBelowCriteria(criteria)).toList();
    if (low.isEmpty) {
      return "🎉 **All Good!** All your subjects are above the $criteria% attendance criteria. Keep it up!";
    }

    final lines = low.map((s) {
      final needed = s.lecturesNeededToMeetCriteria(criteria);
      return '🔴 **${s.subjectName}**: ${s.percentage.toStringAsFixed(1)}% — attend **$needed** more to recover';
    }).join('\n');

    return "⚠️ **${low.length} subject${low.length > 1 ? 's' : ''} need attention:**\n\n$lines";
  }

  String _buildMustAttendResponse(List<SubjectStats> stats, int criteria) {
    if (stats.isEmpty) {
      return "📭 No attendance data yet. Set up your timetable first!";
    }

    final low = stats.where((s) => s.isBelowCriteria(criteria)).toList();
    if (low.isEmpty) {
      return "🎉 You're above $criteria% in all subjects! You're doing great — just maintain your attendance.";
    }

    final lines = low.map((s) {
      final needed = s.lecturesNeededToMeetCriteria(criteria);
      return '📚 **${s.subjectName}**: attend **$needed** consecutive classes to reach $criteria%';
    }).join('\n');

    return "📅 **Must-attend classes:**\n\n$lines\n\n💡 Tip: These are *minimum* numbers assuming perfect attendance from now on.";
  }

  String _buildBestSubjectResponse(List<SubjectStats> stats) {
    if (stats.isEmpty) {
      return "📭 No attendance data yet!";
    }

    final sorted = List<SubjectStats>.from(stats)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    final best = sorted.first;
    final worst = sorted.last;

    return "🏆 **Best**: ${best.subjectName} — ${best.percentage.toStringAsFixed(1)}%\n📉 **Needs Work**: ${worst.subjectName} — ${worst.percentage.toStringAsFixed(1)}%\n\n${sorted.length > 2 ? "📊 **All subjects:**\n${sorted.map((s) => '• ${s.subjectName}: ${s.percentage.toStringAsFixed(1)}%').join('\n')}" : ""}";
  }

  String _buildDefaultResponse(SubjectStats? overall, List<SubjectStats> stats, int criteria) {
    if (overall == null || overall.totalLectures == 0) {
      return "👆 I can help you plan your attendance! Try one of the quick questions above to get started.";
    }
    return _buildStatusResponse(overall, stats, criteria);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimary : AppColors.textLight,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Opacity(
                            opacity: _pulseAnimation.value,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'Always available',
                                  style: TextStyle(fontSize: 11, color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded, 
                        color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isTyping && i == _messages.length) {
                      return _TypingIndicator(isDark: isDark);
                    }
                    return _MessageBubble(message: _messages[i], isDark: isDark);
                  },
                ),
              ),

              // Suggestions
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final q = _quickQuestions[i];
                    return GestureDetector(
                      onTap: () {
                        _handleQuestion(q['text']!);
                        _scrollToBottom();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${q['icon']} ${q['text']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimary : AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Text Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.textLight),
                          decoration: InputDecoration(
                            hintText: 'Ask AttendX...',
                            hintStyle: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _handleQuestion(val.trim());
                              _textController.clear();
                              _scrollToBottom();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (_textController.text.trim().isNotEmpty) {
                          _handleQuestion(_textController.text.trim());
                          _textController.clear();
                          _scrollToBottom();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser ? AppColors.primaryGradient : null,
                color: message.isUser
                    ? null
                    : isDark
                        ? AppColors.darkCard
                        : AppColors.lightSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: _parseMarkdown(message.text, message.isUser, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parseMarkdown(String text, bool isUser, bool isDark) {
    final parts = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts.map((line) {
        // Bold text between **
        if (line.contains('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildRichLine(line, isUser, isDark),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isUser
                  ? Colors.white
                  : isDark
                      ? AppColors.textPrimary
                      : AppColors.textLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRichLine(String line, bool isUser, bool isDark) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: isUser
              ? Colors.white
              : isDark
                  ? AppColors.textPrimary
                  : AppColors.textLight,
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controllers[i],
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6 + (_controllers[i].value * 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6 + _controllers[i].value * 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
