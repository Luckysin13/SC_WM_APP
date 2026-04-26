import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/networking/device_session_manager.dart';
import '../../../core/models/history_point.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/smoker_card.dart';
import '../../../app/theme/colors.dart';
import '../../../core/models/live_state.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use connection status instead of connectivity provider to avoid null check on first load
      final status = ref.read(connectionStatusProvider);
      final manager = ref.read(deviceSessionManagerProvider);

      manager.changeView('history');

      if (status == ConnectionStatus.connected) {
        manager.sendCommand('getHistory');
      }
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SmokerColors.secondaryBg,
        title: const Text(
          'Clear History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear the temperature history for this session?',
          style: TextStyle(color: SmokerColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(deviceSessionManagerProvider)
                  .sendCommand('ClearHistory');
              ref.read(historyProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: SmokerColors.accentOrange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final history = historyState.points;
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;
    final liveState = ref.watch(deviceStateProvider);

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              toolbarHeight: isLandscape && !isTablet ? 40 : 56,
              centerTitle: false,
              title: Row(
                children: [
                  const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HISTORY',
                          style: TextStyle(
                            fontSize: isLandscape && !isTablet ? 20 : 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Session data and temperature charts'.toUpperCase(),
                            style: TextStyle(
                              fontSize: isLandscape && !isTablet ? 7 : 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: SmokerColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: SmokerColors.primaryGradient,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white60),
                  onPressed: _clearHistory,
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (!isConnected) const ConnectionBanner(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.0 : 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    _buildLiveIndicator(
                      'SETPOINT',
                      liveState.pitSetpoint.toDouble(),
                      const Color(0xFFF09647),
                      isTablet,
                      isLandscape,
                    ),
                    const SizedBox(width: 12),
                    _buildLiveIndicator(
                      'PIT',
                      double.tryParse(liveState.pitTemp) ?? -999.0,
                      SmokerColors.accentOrange,
                      isTablet,
                      isLandscape,
                    ),
                    const SizedBox(width: 12),
                    _buildLiveIndicator(
                      'MEAT',
                      double.tryParse(liveState.meatTemp) ?? -999.0,
                      SmokerColors.accentBlue,
                      isTablet,
                      isLandscape,
                    ),
                    const SizedBox(width: 12),
                    _buildLiveIndicator(
                      'FAN',
                      double.tryParse(liveState.fanSpeedPercent) ?? 0.0,
                      SmokerColors.accentGreen,
                      isTablet,
                      isLandscape,
                    ),
                  ],
                ),
              ),
              _buildHistoryContent(
                context,
                history,
                isConnected,
                liveState,
                isTablet,
                screenWidth,
                historyState.isLoading,
                historyState.progress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent(
    BuildContext context,
    List<HistoryPoint> history,
    bool isConnected,
    LiveState liveState,
    bool isTablet,
    double screenWidth,
    bool isLoading,
    double progress,
  ) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    double chartHeight;
    if (isTablet) {
      chartHeight = 600.0;
    } else if (isLandscape) {
      chartHeight = 280.0;
    } else {
      chartHeight = 400.0;
    }

    if (isLoading && history.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                color: SmokerColors.accentBlue,
              ),
              const SizedBox(height: 16),
              Text(
                progress > 0
                    ? 'Downloading: ${(progress * 100).toInt()}%'
                    : 'Fetching history...',
                style: const TextStyle(color: SmokerColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data recorded yet.',
            style: TextStyle(color: SmokerColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 8,
        0,
        isTablet ? 32 : 16,
        isTablet ? 32 : 16,
      ),
      child: Column(
        children: [
          if (isLoading && history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: Colors.white10,
                  color: SmokerColors.accentBlue,
                  minHeight: 4,
                ),
              ),
            ),
          SmokerCard(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, right: 10),
              child: SizedBox(
                height: chartHeight,
                child: _buildChart(history, screenWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator(
    String label,
    double val,
    Color color,
    bool isTablet,
    bool isLandscape,
  ) {
    final bool isFan = label.toLowerCase().contains('fan');
    final String unit = isFan ? '%' : '°F';
    final displayVal = val <= -900 ? '---' : '${val.toInt()}$unit';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: isTablet ? 24 : (isLandscape ? 14 : 10),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayVal,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 24 : (isLandscape ? 20 : 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<HistoryPoint> points, double screenWidth) {
    final List<FlSpot> pitSpots = [];
    final List<FlSpot> meatSpots = [];
    final List<FlSpot> setpointSpots = [];
    final List<FlSpot> fanSpots = [];

    double maxY = 100;

    for (var p in points) {
      final x = p.timestamp.toDouble();
      final pitV = p.pitTemp.toDouble();
      final meatV = p.meatTemp.toDouble();
      final spV = p.setpoint.toDouble();
      final fanV = p.fanPercent.toDouble();

      pitSpots.add(pitV <= -900 ? FlSpot.nullSpot : FlSpot(x, pitV));
      meatSpots.add(meatV <= -900 ? FlSpot.nullSpot : FlSpot(x, meatV));
      setpointSpots.add(FlSpot(x, spV));
      fanSpots.add(FlSpot(x, fanV));

      if (pitV > -900 && pitV > maxY) maxY = pitV;
      if (meatV > -900 && meatV > maxY) maxY = meatV;
      if (spV > maxY) maxY = spV;
    }

    final double minX = points.first.timestamp.toDouble();
    final double maxX = points.last.timestamp.toDouble();

    // Ensure minX and maxX are different to avoid fl_chart calculation errors
    final double actualMinX = minX;
    final double actualMaxX = maxX == minX
        ? maxX + 60
        : maxX; // Add 1 minute if same

    final double chartMaxY = (((maxY / 10).ceil()) * 10) + 10;

    const seriesColors = [
      SmokerColors.accentOrange,
      SmokerColors.accentBlue,
      Color.fromARGB(255, 240, 150, 71),
      SmokerColors.accentGreen,
    ];

    final double duration = actualMaxX - actualMinX;
    const double eightHours = 8 * 3600;

    // Calculate chart width based on 8-hour viewport
    final double chartWidth = duration > eightHours
        ? screenWidth * (duration / eightHours)
        : screenWidth;

    // Adjust target labels based on actual chart width
    final double targetLabels = chartWidth / 80;
    double dynamicInterval = duration / targetLabels;

    if (dynamicInterval < 60) {
      dynamicInterval = 60;
    } else if (dynamicInterval < 300) {
      dynamicInterval = 300;
    } else if (dynamicInterval < 600) {
      dynamicInterval = 600;
    } else if (dynamicInterval < 1200) {
      dynamicInterval = 1200;
    } else if (dynamicInterval < 1800) {
      dynamicInterval = 1800;
    } else if (dynamicInterval < 3600) {
      dynamicInterval = 3600;
    } else {
      dynamicInterval = (dynamicInterval / 3600).ceil() * 3600.0;
    }

    final chartData = LineChartData(
      minX: actualMinX,
      maxX: actualMaxX,
      minY: 0,
      maxY: chartMaxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) =>
              SmokerColors.secondaryBg.withValues(alpha: 0.9),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipHorizontalAlignment: FLHorizontalAlignment.left,
          tooltipMargin: 12,
          tooltipRoundedRadius: 8,
          tooltipBorder: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final color = seriesColors[spot.barIndex];
              final val = spot.y.isFinite ? spot.y.toInt() : 0;
              final label = switch (spot.barIndex) {
                0 => "Pit: ",
                1 => "Meat: ",
                2 => "Setpoint: ",
                3 => "Fan: ",
                _ => "",
              };

              final time = DateTime.fromMillisecondsSinceEpoch(
                spot.x.toInt() * 1000,
              );
              final timeStr = DateFormat('h:mm a').format(time);

              if (touchedSpots.indexOf(spot) == 0) {
                return LineTooltipItem(
                  '$timeStr\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                  children: [
                    TextSpan(
                      text: '$label$val${spot.barIndex == 3 ? '%' : '°F'}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                );
              }

              return LineTooltipItem(
                '$label$val${spot.barIndex == 3 ? '%' : '°F'}',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.05),
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => const SizedBox(),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: dynamicInterval,
            getTitlesWidget: (value, meta) {
              final valInt = value.isFinite ? value.toInt() : 0;
              final date = DateTime.fromMillisecondsSinceEpoch(valInt * 1000);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                angle: -0.785, // 45 degrees
                space: 12,
                child: Text(
                  DateFormat('h:mm a').format(date),
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: 30),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: pitSpots,
          isCurved: false,
          color: SmokerColors.accentOrange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: meatSpots,
          isCurved: false,
          color: SmokerColors.accentBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: setpointSpots,
          isCurved: false,
          color: seriesColors[2],
          barWidth: 1.5,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: fanSpots,
          isCurved: false,
          color: SmokerColors.accentGreen,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Vertical Y-Axis Name
              RotatedBox(
                quarterTurns: 3,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'TEMP (°F) / FAN (%)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              // Static Y-Axis Numbers
              SizedBox(
                width: 30,
                child: ExcludeSemantics(
                  child: LineChart(
                    LineChartData(
                      minX: actualMinX,
                      maxX: actualMaxX,
                      minY: 0,
                      maxY: chartMaxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 0,
                            getTitlesWidget: (value, meta) => const SizedBox(),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => const SizedBox(),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.isFinite ? value.toInt() : 0}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [FlSpot(actualMinX, 0), FlSpot(actualMaxX, 0)],
                          show: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Chart Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: chartWidth,
                    child: ExcludeSemantics(child: LineChart(chartData)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'TIME',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}
