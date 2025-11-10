import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/verification_result.dart';

/// Service for verifying image authenticity
class VerificationService {
  // Backend API URL - should be set via environment variable
  static const String _baseUrl = String.fromEnvironment(
    'VERIFICATION_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// Verify image authenticity by uploading to backend
  /// 
  /// Returns a [VerificationResult] with verification score and status
  Future<VerificationResult> verifyImageAuthenticity({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/verifyImage'),
      );

      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Add user ID
      request.fields['userId'] = userId;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return VerificationResult.fromJson(jsonData);
      } else {
        throw Exception(
          'Verification failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Return error result
      return VerificationResult(
        imageUrl: '',
        userId: userId,
        verificationScore: 0,
        status: VerificationStatus.suspicious,
        aiGeneratedProbability: 0.5,
        reverseImageMatchConfidence: 0.5,
        metadataStatus: MetadataStatus.missing,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Get verification history for a user
  Future<List<VerificationResult>> getVerificationHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/verificationHistory?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        return jsonData
            .map((item) => VerificationResult.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch verification history');
      }
    } catch (e) {
      return [];
    }
  }
}

