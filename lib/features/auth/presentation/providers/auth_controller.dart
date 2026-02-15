import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    await _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    // state is already AsyncLoading during build if we await? 
    // Actually in build(), we just return the value. 
    // But here we want to side-effect? 
    // Ideally, we shouldn't side-effect in build. but for anonymous auth on start it's ok.
    
    // However, to keep it simple and creating a minimal change:
    try {
      final repository = ref.read(authRepositoryProvider);
      if (repository.currentUser == null) {
        await repository.signInAnonymously();
      }
    } catch (e) {
      // If build fails, the provider state becomes error
      rethrow; 
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);
