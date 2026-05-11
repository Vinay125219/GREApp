import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/lesson_action_bar_widget.dart';
import './widgets/lesson_content_widget.dart';
import './widgets/lesson_header_widget.dart';
import './widgets/lesson_sidebar_widget.dart';

// Re-export LessonItem so widgets can import it from this file
export '../../services/supabase_service.dart' show LessonItem;

class CourseLessonScreen extends StatefulWidget {
  const CourseLessonScreen({super.key});

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen>
    with SingleTickerProviderStateMixin {
  int _selectedLessonIndex = 0;
  bool _isBookmarked = false;
  double _videoProgress = 0.0;
  bool _showSidebar = false;
  late AnimationController _sidebarController;
  late Animation<Offset> _sidebarSlide;

  // Supabase state
  bool _isLoading = true;
  String? _loadError;
  List<LessonItem> _lessons = [];
  String? _courseId;
  String? _courseTitle;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sidebarSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _sidebarController,
            curve: Curves.easeOutCubic,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLessons());
  }

  Future<void> _loadLessons() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? courseId;
    String? courseTitle;
    if (args is Map<String, dynamic>) {
      courseId = args['courseId'] as String?;
      courseTitle = args['courseTitle'] as String?;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
      _courseId = courseId;
      _courseTitle = courseTitle ?? 'Course Lessons';
    });

    try {
      List<LessonItem> lessons = [];
      if (courseId != null) {
        lessons = await SupabaseService.instance.fetchCourseLessons(courseId);
      }

      if (mounted) {
        setState(() {
          _lessons = lessons;
          _isLoading = false;
          _selectedLessonIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _lessons = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _showSidebar = !_showSidebar);
    if (_showSidebar) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _selectLesson(int index) {
    if (_lessons[index].isLocked) return;
    setState(() {
      _selectedLessonIndex = index;
      _videoProgress = 0.0;
      _isBookmarked = false;
      _showSidebar = false;
    });
    _sidebarController.reverse();
  }

  Future<void> _markComplete() async {
    final lesson = _lessons[_selectedLessonIndex];
    if (lesson.isCompleted) return;

    if (_courseId != null) {
      try {
        await SupabaseService.instance.markLessonComplete(
          _courseId!,
          lesson.id,
        );
      } catch (e) {
        debugPrint('[CourseLessonScreen] markLessonComplete error: $e');
      }
    }

    setState(() {
      _lessons[_selectedLessonIndex] = LessonItem(
        id: lesson.id,
        title: lesson.title,
        type: lesson.type,
        contentUrl: lesson.contentUrl,
        durationMins: lesson.durationMins,
        isCompleted: true,
        isLocked: lesson.isLocked,
        sortOrder: lesson.sortOrder,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_courseTitle ?? 'Course'),
          backgroundColor: AppTheme.surface,
          elevation: 0,
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
                  'Failed to load lessons',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadLessons,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

    if (_lessons.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_courseTitle ?? 'Course'),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: AppTheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'No lessons available yet',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lessons will appear here once the admin publishes them.',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isTablet = context.isWide;
    final currentLesson = _lessons[_selectedLessonIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout(currentLesson)
            : _buildPhoneLayout(currentLesson),
      ),
    );
  }

  Widget _buildPhoneLayout(LessonItem lesson) {
    final sidebarWidth = (MediaQuery.sizeOf(context).width * 0.86)
        .clamp(300.0, 380.0)
        .toDouble();
    return Stack(
      children: [
        Column(
          children: [
            LessonHeaderWidget(
              lesson: lesson,
              isBookmarked: _isBookmarked,
              onBookmark: () => setState(() => _isBookmarked = !_isBookmarked),
              onOpenSidebar: _toggleSidebar,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LessonContentWidget(
                      lesson: lesson,
                      videoProgress: _videoProgress,
                      onVideoProgressChanged: (val) =>
                          setState(() => _videoProgress = val),
                    ),
                    const SizedBox(height: 16),
                    LessonActionBarWidget(
                      currentIndex: _selectedLessonIndex,
                      totalLessons: _lessons.length,
                      onPrevious: _selectedLessonIndex > 0
                          ? () => _selectLesson(_selectedLessonIndex - 1)
                          : null,
                      onNext: _selectedLessonIndex < _lessons.length - 1
                          ? () => _selectLesson(_selectedLessonIndex + 1)
                          : null,
                      onMarkComplete: _markComplete,
                      isCompleted: _lessons[_selectedLessonIndex].isCompleted,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showSidebar)
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: sidebarWidth,
          child: SlideTransition(
            position: _sidebarSlide,
            child: LessonSidebarWidget(
              lessons: _lessons,
              selectedIndex: _selectedLessonIndex,
              onSelectLesson: _selectLesson,
              onClose: _toggleSidebar,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(LessonItem lesson) {
    final sidebarWidth = context.isDesktop ? 340.0 : 300.0;
    return Row(
      children: [
        SizedBox(
          width: sidebarWidth,
          child: LessonSidebarWidget(
            lessons: _lessons,
            selectedIndex: _selectedLessonIndex,
            onSelectLesson: _selectLesson,
            onClose: null,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              LessonHeaderWidget(
                lesson: lesson,
                isBookmarked: _isBookmarked,
                onBookmark: () =>
                    setState(() => _isBookmarked = !_isBookmarked),
                onOpenSidebar: null,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: AdaptivePageBody(
                    maxWidth: AppBreakpoints.maxReading,
                    padding: context.adaptivePagePadding(bottom: 32),
                    child: Column(
                      children: [
                        LessonContentWidget(
                          lesson: lesson,
                          videoProgress: _videoProgress,
                          onVideoProgressChanged: (val) =>
                              setState(() => _videoProgress = val),
                        ),
                        const SizedBox(height: 20),
                        LessonActionBarWidget(
                          currentIndex: _selectedLessonIndex,
                          totalLessons: _lessons.length,
                          onPrevious: _selectedLessonIndex > 0
                              ? () => _selectLesson(_selectedLessonIndex - 1)
                              : null,
                          onNext: _selectedLessonIndex < _lessons.length - 1
                              ? () => _selectLesson(_selectedLessonIndex + 1)
                              : null,
                          onMarkComplete: _markComplete,
                          isCompleted:
                              _lessons[_selectedLessonIndex].isCompleted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
