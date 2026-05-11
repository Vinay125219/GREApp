import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../test_engine_screen.dart';

class TestQuestionWidget extends StatelessWidget {
  final TestQuestion question;
  final int? selectedAnswer;
  final bool hasSubmitted;
  final bool showExplanation;
  final ValueChanged<int> onSelectAnswer;

  const TestQuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.hasSubmitted,
    required this.showExplanation,
    required this.onSelectAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question metadata
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Q ${question.questionNumber}',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if ((question.subject ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  question.subject ?? '',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            StatusBadgeWidget(
              status: _difficultyStatus(question.difficulty),
              customLabel:
                  question.difficulty[0].toUpperCase() +
                  question.difficulty.substring(1),
            ),
            if (question.hasLatex) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentContainer,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.functions_rounded,
                      size: 11,
                      color: AppTheme.accent,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Math',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Question text + image
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MathTextRenderer(
                text: question.questionText,
                hasLatex: question.hasLatex,
              ),
              if ((question.questionImageUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    question.questionImageUrl!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Options
        Text(
          'Select one answer:',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...question.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final optionImageUrl = idx < question.optionImageUrls.length
              ? question.optionImageUrls[idx]
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              index: idx,
              text: option,
              imageUrl: optionImageUrl,
              isSelected: selectedAnswer == idx,
              hasSubmitted: hasSubmitted,
              isCorrect: idx == question.correctOptionIndex,
              hasLatex: question.hasLatex,
              onTap: () => onSelectAnswer(idx),
            ),
          );
        }),
        // Explanation
        if (showExplanation && hasSubmitted) ...[
          const SizedBox(height: 16),
          _ExplanationWidget(
            explanation: question.explanation ?? '',
            isCorrect: selectedAnswer == question.correctOptionIndex,
            hasLatex: question.hasLatex,
          ),
        ],
      ],
    );
  }

  BadgeStatus _difficultyStatus(String diff) {
    switch (diff) {
      case 'easy':
        return BadgeStatus.easy;
      case 'hard':
        return BadgeStatus.hard;
      default:
        return BadgeStatus.medium;
    }
  }
}

// ─── Math Text Renderer ───────────────────────────────────────

class _MathTextRenderer extends StatelessWidget {
  final String text;
  final bool hasLatex;

  const _MathTextRenderer({required this.text, required this.hasLatex});

  @override
  Widget build(BuildContext context) {
    // Auto-detect math even if hasLatex flag is false
    final hasMathDelimiters = text.contains(r'$');
    if (!hasLatex && !hasMathDelimiters) {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppTheme.textPrimary,
          height: 1.6,
        ),
      );
    }

    // Parse and render mixed text + LaTeX
    final segments = _parseLatexSegments(text);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 6,
      children: segments.map((seg) {
        if (seg.isLatex) {
          final processedLatex = _preprocessLatex(seg.content);
          return Math.tex(
            processedLatex,
            textStyle: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
            onErrorFallback: (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                seg.content,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 13,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        }
        return Text(
          seg.content,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
        );
      }).toList(),
    );
  }

  /// Pre-process LaTeX string to convert common math notation to proper LaTeX
  String _preprocessLatex(String latex) {
    String result = latex.trim();

    // Convert sqrt(...) → \sqrt{...}  (handles nested parens)
    result = _convertFunctionToLatex(result, 'sqrt', r'\sqrt');

    // Convert cbrt(...) → \sqrt[3]{...}
    result = result.replaceAllMapped(
      RegExp(r'cbrt\(([^)]+)\)'),
      (m) => r'\sqrt[3]{' + m.group(1)! + '}',
    );

    // Convert frac(a,b) → \frac{a}{b}
    result = result.replaceAllMapped(
      RegExp(r'frac\(([^,]+),([^)]+)\)'),
      (m) => r'\frac{' + m.group(1)!.trim() + '}{' + m.group(2)!.trim() + '}',
    );

    // Convert log_a(b) → \log_{a}(b)
    result = result.replaceAllMapped(
      RegExp(r'log_(\w+)'),
      (m) => r'\log_{' + m.group(1)! + '}',
    );

    // Convert sin/cos/tan/log/ln without backslash → add backslash
    for (final fn in [
      'sin',
      'cos',
      'tan',
      'cot',
      'sec',
      'csc',
      'log',
      'ln',
      'lim',
      'max',
      'min',
      'exp',
    ]) {
      result = result.replaceAllMapped(
        RegExp('(?<!\\\\)\\b$fn\\b'),
        (m) => '\\$fn',
      );
    }

    // Convert ** → ^ (Python-style power)
    result = result.replaceAll('**', '^');

    // Convert >= → \geq, <= → \leq, != → \neq
    result = result
        .replaceAll('>=', r'\geq ')
        .replaceAll('<=', r'\leq ')
        .replaceAll('!=', r'\neq ')
        .replaceAll('<>', r'\neq ');

    // Convert * between terms → \cdot (only when surrounded by alphanumeric)
    result = result.replaceAllMapped(
      RegExp(r'(\w)\s*\*\s*(\w)'),
      (m) => '${m.group(1)!}\\cdot ${m.group(2)!}',
    );

    return result;
  }

  /// Convert function(expr) → \function{expr} handling nested parentheses
  String _convertFunctionToLatex(String input, String fnName, String latexCmd) {
    final buffer = StringBuffer();
    int i = 0;
    while (i < input.length) {
      final idx = input.indexOf('$fnName(', i);
      if (idx == -1) {
        buffer.write(input.substring(i));
        break;
      }
      // Check it's not already prefixed with backslash
      if (idx > 0 && input[idx - 1] == '\\') {
        buffer.write(input.substring(i, idx + fnName.length + 1));
        i = idx + fnName.length + 1;
        continue;
      }
      buffer.write(input.substring(i, idx));
      // Find matching closing paren
      int depth = 0;
      int start = idx + fnName.length;
      int end = start;
      while (end < input.length) {
        if (input[end] == '(') {
          depth++;
        } else if (input[end] == ')') {
          depth--;
          if (depth == 0) break;
        }
        end++;
      }
      if (depth == 0 && end < input.length) {
        final inner = input.substring(start + 1, end);
        // Recursively process inner content
        final processedInner = _convertFunctionToLatex(inner, fnName, latexCmd);
        buffer.write('$latexCmd{$processedInner}');
        i = end + 1;
      } else {
        // Unmatched paren — write as-is
        buffer.write('$fnName(');
        i = idx + fnName.length + 1;
      }
    }
    return buffer.toString();
  }

  List<_TextSegment> _parseLatexSegments(String text) {
    final segments = <_TextSegment>[];
    // Match $$...$$ (block) first, then $...$ (inline)
    final pattern = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final plain = text.substring(lastEnd, match.start);
        if (plain.isNotEmpty) segments.add(_TextSegment(plain, false));
      }
      final latexContent = match.group(1) ?? match.group(2) ?? '';
      if (latexContent.isNotEmpty) {
        segments.add(_TextSegment(latexContent, true));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.isNotEmpty) segments.add(_TextSegment(remaining, false));
    }
    if (segments.isEmpty) segments.add(_TextSegment(text, false));
    return segments;
  }
}

class _TextSegment {
  final String content;
  final bool isLatex;
  const _TextSegment(this.content, this.isLatex);
}

// ─── Option Tile ──────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final String? imageUrl;
  final bool isSelected;
  final bool hasSubmitted;
  final bool isCorrect;
  final bool hasLatex;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    this.imageUrl,
    required this.isSelected,
    required this.hasSubmitted,
    required this.isCorrect,
    required this.hasLatex,
    required this.onTap,
  });

  static const _labels = ['A', 'B', 'C', 'D', 'E'];

  Color _getBorderColor() {
    if (!hasSubmitted) {
      return isSelected ? AppTheme.primary : AppTheme.outlineVariant;
    }
    if (isCorrect) return AppTheme.success;
    if (isSelected && !isCorrect) return AppTheme.error;
    return AppTheme.outlineVariant;
  }

  Color _getBgColor() {
    if (!hasSubmitted) {
      return isSelected
          ? AppTheme.primaryContainer.withValues(alpha: 0.5)
          : AppTheme.surface;
    }
    if (isCorrect) return AppTheme.successContainer;
    if (isSelected && !isCorrect) return AppTheme.errorContainer;
    return AppTheme.surface;
  }

  Color _getLabelColor() {
    if (!hasSubmitted) {
      return isSelected ? AppTheme.primary : AppTheme.textMuted;
    }
    if (isCorrect) return AppTheme.success;
    if (isSelected && !isCorrect) return AppTheme.error;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: hasSubmitted ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: AppTheme.primary.withValues(alpha: 0.06),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _getBgColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getLabelColor().withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getLabelColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option text (with math rendering if needed)
                  _MathTextRenderer(text: text, hasLatex: hasLatex),
                  // Option image
                  if ((imageUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasSubmitted) ...[
              const SizedBox(width: 8),
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : isSelected
                    ? Icons.cancel_rounded
                    : Icons.circle_outlined,
                size: 20,
                color: isCorrect
                    ? AppTheme.success
                    : isSelected
                    ? AppTheme.error
                    : AppTheme.outlineVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Explanation Widget ───────────────────────────────────────

class _ExplanationWidget extends StatelessWidget {
  final String explanation;
  final bool isCorrect;
  final bool hasLatex;

  const _ExplanationWidget({
    required this.explanation,
    required this.isCorrect,
    required this.hasLatex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppTheme.successContainer : AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isCorrect ? AppTheme.success : AppTheme.error).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: isCorrect ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct! Well done.' : 'Incorrect Answer',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCorrect ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MathTextRenderer(
                    text: explanation,
                    hasLatex: hasLatex,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
