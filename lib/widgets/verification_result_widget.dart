import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verification_result.dart';

/// Widget to display image verification result with color-coded status
class VerificationResultWidget extends StatelessWidget {
  final VerificationResult result;

  const VerificationResultWidget({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(result.status);
    final statusIcon = _getStatusIcon(result.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        
        color: statusColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.status.displayName,
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Verification Score: ${result.verificationScore}/100',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 117, 117, 117),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Score Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.verificationScore / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 12,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Detailed Metrics
          _buildMetricRow(
            'AI Generated Probability',
            '${(result.aiGeneratedProbability * 100).toStringAsFixed(1)}%',
            result.aiGeneratedProbability < 0.3
                ? Colors.green
                : result.aiGeneratedProbability < 0.7
                    ? const Color.fromARGB(255, 216, 130, 0)
                    : Colors.red,
          ),
          
          const SizedBox(height: 12),
          
          _buildMetricRow(
            'Reverse Image Match',
            '${(result.reverseImageMatchConfidence * 100).toStringAsFixed(1)}%',
            result.reverseImageMatchConfidence < 0.1
                ? Colors.green
                : const Color.fromARGB(255, 216, 130, 0),
          ),
          
          const SizedBox(height: 12),
          
          _buildMetricRow(
            'Metadata Status',
            _getMetadataStatusText(result.metadataStatus),
            _getMetadataStatusColor(result.metadataStatus),
          ),
          
          if (result.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${result.errorMessage}',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (result.metadata != null && result.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(
                'EXIF Metadata',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.metadata!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
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
        return Icons.check_circle;
      case VerificationStatus.suspicious:
        return Icons.warning;
      case VerificationStatus.likelyFake:
        return Icons.cancel;
    }
  }

  String _getMetadataStatusText(MetadataStatus status) {
    switch (status) {
      case MetadataStatus.complete:
        return 'Complete';
      case MetadataStatus.partial:
        return 'Partial';
      case MetadataStatus.missing:
        return 'Missing';
    }
  }

  Color _getMetadataStatusColor(MetadataStatus status) {
    switch (status) {
      case MetadataStatus.complete:
        return Colors.green;
      case MetadataStatus.partial:
        return const Color.fromARGB(255, 156, 94, 0);
      case MetadataStatus.missing:
        return Colors.red;
    }
  }
}

/// Widget to show verification progress
class VerificationProgressWidget extends StatelessWidget {
  final String message;

  const VerificationProgressWidget({
    super.key,
    this.message = 'Verifying image authenticity...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

