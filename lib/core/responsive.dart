import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double compact = 600;
  static const double wide = 900;
  static const double desktop = 1200;
  static const double maxContent = 1180;
  static const double maxReading = 920;
  static const double maxList = 980;

  const AppBreakpoints._();
}

extension AdaptiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < AppBreakpoints.compact;
  bool get isWide => screenWidth >= AppBreakpoints.wide;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;

  EdgeInsets adaptivePagePadding({double bottom = 24}) {
    if (isDesktop) {
      return EdgeInsets.fromLTRB(32, 28, 32, bottom);
    }
    if (isWide) {
      return EdgeInsets.fromLTRB(24, 24, 24, bottom);
    }
    return EdgeInsets.fromLTRB(16, 16, 16, bottom);
  }
}

class AdaptiveScaffoldBody extends StatelessWidget {
  final Widget child;
  final Widget? navigationRail;

  const AdaptiveScaffoldBody({
    super.key,
    required this.child,
    this.navigationRail,
  });

  @override
  Widget build(BuildContext context) {
    if (navigationRail == null || !context.isWide) {
      return child;
    }

    return Row(
      children: [
        SafeArea(right: false, bottom: false, child: navigationRail!),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}

class AdaptivePageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const AdaptivePageBody({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContent,
    required this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AdaptiveListItem extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdaptiveListItem({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxList,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
