import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verification_result.dart';

/// Compact badge widget to show verification status
class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final int? score;
  final bool showScore;

  const VerificationBadge({
    super.key,
    required this.status,
    this.score,
    this.showScore = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final label = status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.righteous(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showScore && score != null) ...[
            const SizedBox(width: 6),
            Text(
              '$score/100',
              style: GoogleFonts.righteous(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.authentic:
        return Colors.green;
      case VerificationStatus.suspicious:
        return Colors.orange;
      case VerificationStatus.likelyFake:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.authentic:
        return Icons.verified;
      case VerificationStatus.suspicious:
        return Icons.warning_amber_rounded;
      case VerificationStatus.likelyFake:
        return Icons.cancel;
    }
  }
}

/// Badge for when verification status is unknown/not verified
class UnverifiedBadge extends StatelessWidget {
  const UnverifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 16,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            'Not Verified',
            style: GoogleFonts.righteous(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

