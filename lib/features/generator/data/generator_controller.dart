import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magical_vibe/features/auth/data/auth_repository.dart';
import '../../monetization/presentation/providers/monetization_controller.dart';
import '../../monetization/data/usage_repository.dart';
import 'generator_repository.dart';

class GeneratorController extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null; // Initial state
  }

  Future<void> generateVideo(String attribute) async {
    // Set loading
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(generatorRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final usageRepository = ref.read(usageRepositoryProvider);

      final user = authRepository.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final count = await usageRepository.getGenerationCount(user.uid);
      if (count >= 1) {
        // Use a specific exception message that UI listens for
        throw Exception('Free limit reached. Please purchase premium.');
      }

      final result = await repository.generateVideo(attribute);
      
      if (result['success'] == true) {
        await usageRepository.incrementGenerationCount(user.uid);
      }
      
      return result;
    });
  }
}

final generatorControllerProvider = AsyncNotifierProvider<GeneratorController, Map<String, dynamic>?>(GeneratorController.new);
