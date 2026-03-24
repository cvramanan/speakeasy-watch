import 'package:flutter/material.dart';

class PttButton extends StatelessWidget {
  final bool isRecording;
  final bool isDisabled;
  final VoidCallback onTap;

  const PttButton({
    super.key,
    required this.isRecording,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Enable iPhone hotspot first',
                    style: TextStyle(fontSize: 11),
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDisabled
              ? Colors.grey.shade800
              : isRecording
                  ? Colors.red.shade700
                  : Colors.blueGrey.shade700,
          boxShadow: isRecording
              ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 6,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDisabled
                  ? Icons.mic_off
                  : isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic,
              color: isDisabled ? Colors.grey.shade600 : Colors.white,
              size: 32,
            ),
            const SizedBox(height: 2),
            Text(
              isDisabled
                  ? 'No mic'
                  : isRecording
                      ? 'Stop'
                      : 'Record',
              style: TextStyle(
                fontSize: 9,
                color: isDisabled ? Colors.grey.shade600 : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
