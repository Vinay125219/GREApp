import '../../../core/app_export.dart';

class TestTimerWidget extends StatefulWidget {
  final int remainingSeconds;

  const TestTimerWidget({super.key, required this.remainingSeconds});

  @override
  State<TestTimerWidget> createState() => _TestTimerWidgetState();
}

class _TestTimerWidgetState extends State<TestTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TestTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingSeconds <= 300 && oldWidget.remainingSeconds > 300) {
      _pulseController.repeat(reverse: true);
    }
    if (widget.remainingSeconds > 300) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isCritical => widget.remainingSeconds <= 300;
  bool get _isWarning => widget.remainingSeconds <= 900;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isCritical ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _isCritical
              ? AppTheme.errorContainer
              : _isWarning
              ? AppTheme.warningContainer
              : AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_rounded,
              size: 15,
              color: _isCritical
                  ? AppTheme.error
                  : _isWarning
                  ? AppTheme.warning
                  : AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _format(widget.remainingSeconds),
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _isCritical
                    ? AppTheme.error
                    : _isWarning
                    ? AppTheme.warning
                    : AppTheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
