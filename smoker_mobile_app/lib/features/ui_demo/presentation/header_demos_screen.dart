import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../shared/widgets/smoker_card.dart';

class HeaderDemosScreen extends StatefulWidget {
  const HeaderDemosScreen({super.key});

  @override
  State<HeaderDemosScreen> createState() => _HeaderDemosScreenState();
}

class _HeaderDemosScreenState extends State<HeaderDemosScreen> {
  int _demoIndex = 0;

  final List<String> _demoNames = [
    'Original (Current)',
    'Subtle Gradient Border',
    'Glassmorphism (Frosted)',
    'Branding (Logo + Subtitle)',
    'Collapsing Large Title',
    'Mesh Gradient Header',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _demoIndex == 2 || _demoIndex == 5,
      appBar: _buildAppBar(),
      body: _demoIndex == 4 ? _buildCollapsingBody() : _buildRegularBody(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: SmokerColors.secondaryBg,
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _demoIndex = (_demoIndex - 1) % _demoNames.length;
                if (_demoIndex < 0) _demoIndex = _demoNames.length - 1;
              }),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DEMO ${_demoIndex + 1}/${_demoNames.length}',
                    style: const TextStyle(
                      color: SmokerColors.accentCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _demoNames[_demoIndex].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _demoIndex = (_demoIndex + 1) % _demoNames.length;
              }),
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_demoIndex) {
      case 1: // Gradient Border
        return AppBar(
          title: const Text('O.S.S.C'),
          titleTextStyle: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: SmokerColors.primaryGradient,
              ),
            ),
          ),
        );

      case 2: // Glassmorphism
        return PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                title: const Text('O.S.S.C'),
                titleTextStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );

      case 3: // Logo + Subtitle
        return AppBar(
          title: Row(
            children: [
              Image.asset('assets/icon/icon.png', height: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O.S.S.C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Open Source Smoker Controller'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: SmokerColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 4: // Collapsing (Handled in body)
        return const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        );

      case 5: // Mesh Gradient
        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('O.S.S.C'),
          titleTextStyle: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        );

      default: // Original
        return AppBar(
          title: const Text('O.S.S.C'),
          titleTextStyle: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        );
    }
  }

  Widget _buildRegularBody() {
    return Stack(
      children: [
        if (_demoIndex == 5) // Mesh Gradient Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.5),
                  radius: 1.5,
                  colors: [
                    SmokerColors.accentBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ListView(
          padding: EdgeInsets.only(
            top: (_demoIndex == 2 || _demoIndex == 5) ? kToolbarHeight + 20 : 20,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          children: [
            _dummyContent('Pit Temperature', '225°F'),
            _dummyContent('Meat Temperature', '145°F'),
            _dummyContent('Fan Speed', '45%'),
            const SizedBox(height: 100),
          ],
        ),
      ],
    );
  }

  Widget _buildCollapsingBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          backgroundColor: SmokerColors.primaryBg,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
            title: const Text(
              'O.S.S.C',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _dummyContent('Pit Temperature', '225°F'),
              _dummyContent('Meat Temperature', '145°F'),
              _dummyContent('Fan Speed', '45%'),
              const SizedBox(height: 500),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _dummyContent(String title, String value) {
    return SmokerCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: SmokerColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
