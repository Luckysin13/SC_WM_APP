import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../app/theme/colors.dart';
import '../core/utils/ui_utils.dart';

class ShellLayout extends StatelessWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/options')) currentIndex = 1;
    if (location.startsWith('/history')) currentIndex = 2;
    if (location.startsWith('/configuration')) currentIndex = 3;
    if (location.startsWith('/wifi_setup')) currentIndex = 4;

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final navConfig = ResponsiveNavConfig.of(context);

    // Toggle system UI based on orientation
    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          if (isLandscape)
            Container(
              width: navConfig.railWidth,
              decoration: BoxDecoration(
                color: SmokerColors.secondaryBg.withValues(alpha: 0.8),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _customRailItem(
                    context,
                    Icons.thermostat,
                    'Status',
                    0,
                    currentIndex,
                  ),
                  _customRailItem(context, Icons.tune, 'Options', 1, currentIndex),
                  _customRailItem(
                    context,
                    Icons.show_chart,
                    'History',
                    2,
                    currentIndex,
                  ),
                  _customRailItem(
                    context,
                    Icons.settings,
                    'Config',
                    3,
                    currentIndex,
                  ),
                  _customRailItem(
                    context,
                    Icons.wifi,
                    'WiFi',
                    4,
                    currentIndex,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                // Fixed background mimicking the web radial-gradient
                Positioned.fill(
                  child: Container(
                    color: SmokerColors.primaryBg,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -100,
                          left: -100,
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF1E293B).withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -100,
                          right: -100,
                          child: Container(
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF0F172A).withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLandscape
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final isSelected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: navConfig.navLabelFontSize,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? SmokerColors.accentBlue : Colors.white60,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: navConfig.navBarHeight,
                  backgroundColor:
                      SmokerColors.secondaryBg.withValues(alpha: 0.8),
                  elevation: 0,
                  selectedIndex: currentIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  indicatorColor: SmokerColors.accentBlue.withValues(alpha: 0.2),
                  onDestinationSelected: (index) {
                    _navigateTo(context, index);
                  },
                  destinations: [
                    _navDestination(
                      context,
                      Icons.thermostat,
                      'Status',
                      currentIndex == 0,
                    ),
                    _navDestination(
                      context,
                      Icons.tune,
                      'Options',
                      currentIndex == 1,
                    ),
                    _navDestination(
                      context,
                      Icons.show_chart,
                      'History',
                      currentIndex == 2,
                    ),
                    _navDestination(
                      context,
                      Icons.settings,
                      'Config',
                      currentIndex == 3,
                    ),
                    _navDestination(
                      context,
                      Icons.wifi,
                      'WiFi',
                      currentIndex == 4,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _customRailItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final navConfig = ResponsiveNavConfig.of(context);
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () => _navigateTo(context, index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: navConfig.railWidth - 10,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? SmokerColors.accentBlue : Colors.white60,
              size: navConfig.railIconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? SmokerColors.accentBlue : Colors.white60,
                fontSize: navConfig.railLabelFontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/options');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/configuration');
        break;
      case 4:
        context.go('/wifi_setup');
        break;
    }
  }

  NavigationDestination _navDestination(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    final navConfig = ResponsiveNavConfig.of(context);
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected ? SmokerColors.accentBlue : Colors.white60,
        size: navConfig.navIconSize,
      ),
      label: label,
    );
  }
}
