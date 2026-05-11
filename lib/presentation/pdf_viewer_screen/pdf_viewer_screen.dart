import 'dart:html' as html show window;

import 'package:flutter/foundation.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// ignore: avoid_web_libraries_in_flutter

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  String? _error;
  String? _pdfUrl;
  String? _lessonTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPdf());
  }

  Future<void> _loadPdf() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? url;
    String? title;

    if (args is Map<String, dynamic>) {
      url = args['pdfUrl'] as String?;
      title = args['title'] as String?;
      final lessonId = args['lessonId'] as String?;

      // Resolve storage path → public/signed URL
      if (url != null && url.isNotEmpty && !url.startsWith('http')) {
        try {
          final resolved = await SupabaseService.instance.getSignedPdfUrl(
            lessonId ?? '',
          );
          if (resolved != null && resolved.isNotEmpty) {
            url = resolved;
          } else {
            url = SupabaseService.instance.client.storage
                .from('course-materials')
                .getPublicUrl(url);
          }
        } catch (e) {
          debugPrint('[PdfViewerScreen] resolve path error: $e');
        }
      }

      // If still no URL, try signed URL by lessonId
      if ((url == null || url.isEmpty) && lessonId != null) {
        try {
          url = await SupabaseService.instance.getSignedPdfUrl(lessonId);
        } catch (e) {
          debugPrint('[PdfViewerScreen] getSignedPdfUrl error: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _pdfUrl = url;
        _lessonTitle = title ?? 'PDF Document';
        _isLoading = false;
        _error = (url == null || url.isEmpty)
            ? 'No PDF URL available for this lesson.'
            : null;
      });

      // Auto-open on web immediately
      if (kIsWeb && url != null && url.isNotEmpty) {
        _openInBrowser(url);
      }
    }
  }

  void _openInBrowser(String url) {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _lessonTitle ?? 'PDF Document',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _error != null
          ? _buildError()
          : _buildOpenCard(),
    );
  }

  Widget _buildOpenCard() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 48,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _lessonTitle ?? 'PDF Document',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'The PDF has been opened in a new browser tab.\nTap the button below if it did not open.'
                  : 'Tap the button below to open this PDF.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_pdfUrl != null) {
                    _openInBrowser(_pdfUrl!);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  kIsWeb ? 'Open PDF in New Tab' : 'Open PDF',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load PDF',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
