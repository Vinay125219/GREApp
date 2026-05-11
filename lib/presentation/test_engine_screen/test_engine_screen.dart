import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/test_bottom_bar_widget.dart';
import './widgets/test_header_widget.dart';
import './widgets/test_palette_widget.dart';
import './widgets/test_question_widget.dart';

// Re-export TestQuestion so widgets can import it from this file
export '../../services/supabase_service.dart' show TestQuestion;

class TestEngineScreen extends StatefulWidget {
  const TestEngineScreen({super.key});

  @override
  State<TestEngineScreen> createState() => _TestEngineScreenState();
}

class _TestEngineScreenState extends State<TestEngineScreen>
    with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  final Map<int, int?> _selectedAnswers = {};
  final Set<int> _markedForReview = {};
  bool _showPalette = false;
  bool _isSubmitting = false;
  int _remainingSeconds = 3600;
  Timer? _timer;
  int _appMinimizeCount = 0;

  // Supabase state
  bool _isLoading = true;
  String? _loadError;
  List<TestQuestion> _questions = [];
  String? _testId;
  String? _testTitle;
  String? _attemptId;

  bool _showExplanation = false;
  bool _hasSubmittedQuestion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTest());
  }

  Future<void> _loadTest() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? testId;
    if (args is Map<String, dynamic>) {
      testId = args['testId'] as String?;
    } else if (args is String) {
      testId = args;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      List<TestQuestion> questions = [];
      String title = 'Test';
      int durationMins = 60;

      if (testId != null) {
        _testId = testId;
        final testData = await SupabaseService.instance.fetchTestById(testId);
        title = testData?['title'] as String? ?? 'Test';
        durationMins = (testData?['duration_mins'] as int?) ?? 60;
        questions = await SupabaseService.instance.fetchTestQuestions(testId);
      }

      // Start attempt in Supabase if we have a real test with questions
      String? attemptId;
      if (_testId != null && questions.isNotEmpty) {
        try {
          attemptId = await SupabaseService.instance.startTestAttempt(_testId!);
        } catch (e) {
          debugPrint('[TestEngine] Could not start attempt: $e');
        }
      }

      if (mounted) {
        setState(() {
          _questions = questions;
          _testTitle = title;
          _remainingSeconds = durationMins * 60;
          _attemptId = attemptId;
          _isLoading = false;
        });
        if (questions.isNotEmpty) _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      setState(() => _appMinimizeCount++);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showAntiCheatWarning(),
        );
      }
    }
  }

  void _showAntiCheatWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.warning),
            const SizedBox(width: 8),
            const Text('Anti-Cheat Warning'),
          ],
        ),
        content: Text(
          'You left the test screen $_appMinimizeCount time(s). This has been logged.',
          style: const TextStyle(fontFamily: 'IBM Plex Sans', fontSize: 14),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!kIsWeb) {
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.immersiveSticky,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Return to Test'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitTest();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _togglePalette() => setState(() => _showPalette = !_showPalette);

  void _selectAnswer(int optionIndex) {
    if (_hasSubmittedQuestion) return;
    setState(() => _selectedAnswers[_currentQuestionIndex] = optionIndex);
  }

  void _toggleMarkForReview() {
    setState(() {
      if (_markedForReview.contains(_currentQuestionIndex)) {
        _markedForReview.remove(_currentQuestionIndex);
      } else {
        _markedForReview.add(_currentQuestionIndex);
      }
    });
  }

  void _navigateToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _showPalette = false;
      _hasSubmittedQuestion = false;
      _showExplanation = false;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasSubmittedQuestion = false;
        _showExplanation = false;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _hasSubmittedQuestion = false;
        _showExplanation = false;
      });
    }
  }

  void _submitQuestion() {
    if (_selectedAnswers[_currentQuestionIndex] == null) return;
    setState(() {
      _hasSubmittedQuestion = true;
      _showExplanation = true;
    });
  }

  void _submitTest() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SubmitDialog(
        answeredCount: _selectedAnswers.length,
        totalQuestions: _questions.length,
        markedCount: _markedForReview.length,
        onConfirm: () {
          Navigator.pop(ctx);
          _performSubmit();
        },
        onCancel: () {
          Navigator.pop(ctx);
          _startTimer();
        },
      ),
    );
  }

  Future<void> _performSubmit() async {
    setState(() => _isSubmitting = true);

    TestAttemptResult? result;

    try {
      if (_attemptId != null && _testId != null) {
        result = await SupabaseService.instance.submitTestAttempt(
          attemptId: _attemptId!,
          testId: _testId!,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          antiCheatViolations: _appMinimizeCount,
        );
      } else {
        // Calculate result locally when no attempt was started
        int correct = 0, incorrect = 0, skipped = 0;
        double score = 0, totalMarks = 0;
        final answersStr = <String, int>{};

        for (int i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          totalMarks += q.marks;
          final selected = _selectedAnswers[i];
          if (selected == null) {
            skipped++;
          } else {
            answersStr[q.id] = selected;
            if (selected == q.correctOptionIndex) {
              correct++;
              score += q.marks;
            } else {
              incorrect++;
              score -= q.negativeMarks;
            }
          }
        }
        if (score < 0) score = 0;

        result = TestAttemptResult(
          attemptId: 'local',
          testId: _testId ?? 'local',
          testTitle: _testTitle ?? 'Test',
          score: score,
          totalMarks: totalMarks,
          totalQuestions: _questions.length,
          attempted: correct + incorrect,
          correct: correct,
          incorrect: incorrect,
          skipped: skipped,
          selectedAnswers: answersStr,
          questions: _questions,
          submittedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[TestEngine] Submit error: $e');
    }

    if (!mounted) return;

    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    if (result != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.testResultScreen,
        arguments: result,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.studentDashboardScreen,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'Loading test questions...',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Test'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load test',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadTest,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Submitting Test...',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Calculating your score',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppTheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_testTitle ?? 'Test'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: AppTheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No questions available',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This test has no questions yet.\nPlease contact your instructor.',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isTablet = context.isWide;
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TestHeaderWidget(
                  sectionName: currentQuestion.sectionName,
                  currentIndex: _currentQuestionIndex,
                  totalQuestions: _questions.length,
                  markedCount: _markedForReview.length,
                  answeredCount: _selectedAnswers.length,
                  isMarked: _markedForReview.contains(_currentQuestionIndex),
                  remainingSeconds: _remainingSeconds,
                  onToggleMark: _toggleMarkForReview,
                  onOpenPalette: isTablet ? null : _togglePalette,
                  onSubmit: _submitTest,
                ),
                Expanded(
                  child: isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: AdaptivePageBody(
                                  maxWidth: AppBreakpoints.maxReading,
                                  padding: context.adaptivePagePadding(
                                    bottom: 32,
                                  ),
                                  child: TestQuestionWidget(
                                    question: currentQuestion,
                                    selectedAnswer:
                                        _selectedAnswers[_currentQuestionIndex],
                                    hasSubmitted: _hasSubmittedQuestion,
                                    showExplanation: _showExplanation,
                                    onSelectAnswer: _selectAnswer,
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: context.isDesktop ? 340.0 : 300.0,
                              child: TestPaletteWidget(
                                questions: _questions,
                                selectedAnswers: _selectedAnswers,
                                markedForReview: _markedForReview,
                                currentIndex: _currentQuestionIndex,
                                onSelectQuestion: _navigateToQuestion,
                                onClose: null,
                                onSubmit: _submitTest,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: TestQuestionWidget(
                            question: currentQuestion,
                            selectedAnswer:
                                _selectedAnswers[_currentQuestionIndex],
                            hasSubmitted: _hasSubmittedQuestion,
                            showExplanation: _showExplanation,
                            onSelectAnswer: _selectAnswer,
                          ),
                        ),
                ),
                TestBottomBarWidget(
                  currentIndex: _currentQuestionIndex,
                  totalQuestions: _questions.length,
                  hasAnswer: _selectedAnswers[_currentQuestionIndex] != null,
                  hasSubmitted: _hasSubmittedQuestion,
                  onPrevious: _currentQuestionIndex > 0
                      ? _previousQuestion
                      : null,
                  onNext: _currentQuestionIndex < _questions.length - 1
                      ? _nextQuestion
                      : null,
                  onSubmitQuestion: _submitQuestion,
                ),
              ],
            ),
            if (_showPalette && !isTablet)
              GestureDetector(
                onTap: _togglePalette,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            if (_showPalette && !isTablet)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.78,
                child: TestPaletteWidget(
                  questions: _questions,
                  selectedAnswers: _selectedAnswers,
                  markedForReview: _markedForReview,
                  currentIndex: _currentQuestionIndex,
                  onSelectQuestion: _navigateToQuestion,
                  onClose: _togglePalette,
                  onSubmit: _submitTest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmitDialog extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final int markedCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SubmitDialog({
    required this.answeredCount,
    required this.totalQuestions,
    required this.markedCount,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final unanswered = totalQuestions - answeredCount;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.assignment_turned_in_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text(
            'Submit Test?',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatRow(
            label: 'Answered',
            value: '$answeredCount',
            color: AppTheme.success,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Unanswered',
            value: '$unanswered',
            color: AppTheme.error,
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Marked for Review',
            value: '$markedCount',
            color: AppTheme.warning,
          ),
          const SizedBox(height: 16),
          const Text(
            'Once submitted, you cannot change your answers.',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Continue Test')),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Submit Now'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
