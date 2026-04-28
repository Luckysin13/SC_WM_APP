import 'package:flutter/material.dart';

class ResponsiveToolbarConfig {
  final double toolbarHeight;
  final double titleFontSize;
  final double subtitleFontSize;
  final double mainIconSize;
  final double actionIconSize;
  final double spacing;

  const ResponsiveToolbarConfig({
    required this.toolbarHeight,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.mainIconSize,
    required this.actionIconSize,
    required this.spacing,
  });

  factory ResponsiveToolbarConfig.of(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = shortestSide >= 600;

    if (isTablet) {
      if (isLandscape) {
        return const ResponsiveToolbarConfig(
          toolbarHeight: 90,
          titleFontSize: 34,
          subtitleFontSize: 12,
          mainIconSize: 42,
          actionIconSize: 32,
          spacing: 20,
        );
      } else {
        return const ResponsiveToolbarConfig(
          toolbarHeight: 85,
          titleFontSize: 32,
          subtitleFontSize: 11,
          mainIconSize: 40,
          actionIconSize: 30,
          spacing: 18,
        );
      }
    } else {
      if (isLandscape) {
        return const ResponsiveToolbarConfig(
          toolbarHeight: 50,
          titleFontSize: 20,
          subtitleFontSize: 7,
          mainIconSize: 26,
          actionIconSize: 20,
          spacing: 12,
        );
      } else {
        return const ResponsiveToolbarConfig(
          toolbarHeight: 70,
          titleFontSize: 26,
          subtitleFontSize: 9,
          mainIconSize: 32,
          actionIconSize: 24,
          spacing: 16,
        );
      }
    }
  }
}
