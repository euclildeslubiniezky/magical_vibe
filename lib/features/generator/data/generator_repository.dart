import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneratorRepository {
  final FirebaseFunctions _functions;

  GeneratorRepository(this._functions);

  Future<Map<String, dynamic>> generateVideo(String attribute) async {
    try {
      final callable = _functions.httpsCallable('generateTransformationVideo');
      final result = await callable.call({'attribute': attribute});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Failed to generate video: $e');
    }
  }
}

final generatorRepositoryProvider = Provider<GeneratorRepository>((ref) {
  return GeneratorRepository(FirebaseFunctions.instance);
});
