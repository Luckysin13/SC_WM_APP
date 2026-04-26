import 'package:flutter/material.dart';

class ProbeNoticeBanner extends StatelessWidget {
  final String meatTemp;
  final String pitTemp;

  const ProbeNoticeBanner({
    super.key,
    required this.meatTemp,
    required this.pitTemp,
  });

  @override
  Widget build(BuildContext context) {
    final pitDisconnected = pitTemp == 'No Probe' || pitTemp == '---';
    final meatDisconnected = meatTemp == 'No Probe' || meatTemp == '---';

    if (!pitDisconnected && !meatDisconnected) {
      return const SizedBox.shrink();
    }

    String noticeText = '';
    if (pitDisconnected && meatDisconnected) {
      noticeText = 'Pit and Meat probes disconnected — Fan Stopped';
    } else if (pitDisconnected) {
      noticeText = 'Pit probe disconnected — Fan Stopped';
    } else if (meatDisconnected) {
      noticeText = 'Meat probe disconnected';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x1AF59E0B), // rgba(245, 158, 11, 0.1)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66F59E0B)), // rgba(245, 158, 11, 0.4)
      ),
      child: Text(
        noticeText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFBBF24),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
