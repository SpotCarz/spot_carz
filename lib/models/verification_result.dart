/// Model representing the result of image authenticity verification
class VerificationResult {
  final String imageUrl;
  final String userId;
  final int verificationScore; // 0-100
  final VerificationStatus status;
  final double aiGeneratedProbability; // 0.0-1.0
  final double reverseImageMatchConfidence; // 0.0-1.0
  final MetadataStatus metadataStatus;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // EXIF data
  final String? errorMessage;

  VerificationResult({
    required this.imageUrl,
    required this.userId,
    required this.verificationScore,
    required this.status,
    required this.aiGeneratedProbability,
    required this.reverseImageMatchConfidence,
    required this.metadataStatus,
    required this.timestamp,
    this.metadata,
    this.errorMessage,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      imageUrl: json['imageUrl'] as String,
      userId: json['userId'] as String,
      verificationScore: json['verificationScore'] as int,
      status: VerificationStatusExtension.fromString(json['status'] as String),
      aiGeneratedProbability: (json['aiGeneratedProbability'] as num).toDouble(),
      reverseImageMatchConfidence: (json['reverseImageMatchConfidence'] as num).toDouble(),
      metadataStatus: MetadataStatusExtension.fromString(json['metadataStatus'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'userId': userId,
      'verificationScore': verificationScore,
      'status': status.toValueString(),
      'aiGeneratedProbability': aiGeneratedProbability,
      'reverseImageMatchConfidence': reverseImageMatchConfidence,
      'metadataStatus': metadataStatus.toValueString(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'errorMessage': errorMessage,
    };
  }
}

/// Verification status based on score
enum VerificationStatus {
  authentic, // score > 80
  suspicious, // score 50-80
  likelyFake, // score < 50
}

/// Extension for VerificationStatus
extension VerificationStatusExtension on VerificationStatus {
  static VerificationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'authentic':
        return VerificationStatus.authentic;
      case 'suspicious':
        return VerificationStatus.suspicious;
      case 'likelyfake':
      case 'likely_fake':
        return VerificationStatus.likelyFake;
      default:
        return VerificationStatus.suspicious;
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.authentic:
        return 'Authentic';
      case VerificationStatus.suspicious:
        return 'Suspicious';
      case VerificationStatus.likelyFake:
        return 'Likely Fake';
    }
  }

  String toValueString() {
    switch (this) {
      case VerificationStatus.authentic:
        return 'authentic';
      case VerificationStatus.suspicious:
        return 'suspicious';
      case VerificationStatus.likelyFake:
        return 'likelyFake';
    }
  }
}

/// Metadata extraction status
enum MetadataStatus {
  complete, // Has camera model, timestamp, GPS
  partial, // Has some metadata
  missing, // No metadata found
}

/// Extension for MetadataStatus
extension MetadataStatusExtension on MetadataStatus {
  static MetadataStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'complete':
        return MetadataStatus.complete;
      case 'partial':
        return MetadataStatus.partial;
      case 'missing':
        return MetadataStatus.missing;
      default:
        return MetadataStatus.missing;
    }
  }

  String toValueString() {
    switch (this) {
      case MetadataStatus.complete:
        return 'complete';
      case MetadataStatus.partial:
        return 'partial';
      case MetadataStatus.missing:
        return 'missing';
    }
  }
}

