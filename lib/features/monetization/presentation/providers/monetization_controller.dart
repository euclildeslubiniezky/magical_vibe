import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../monetization/data/monetization_repository.dart';

class MonetizationState {
  final bool isPremium;
  final bool hasAdReward;

  MonetizationState({this.isPremium = false, this.hasAdReward = false});

  MonetizationState copyWith({bool? isPremium, bool? hasAdReward}) {
    return MonetizationState(
      isPremium: isPremium ?? this.isPremium,
      hasAdReward: hasAdReward ?? this.hasAdReward,
    );
  }
}

class MonetizationController extends StateNotifier<MonetizationState> {
  final MonetizationRepository _repository;

  MonetizationController(this._repository) : super(MonetizationState()) {
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final isPremium = await _repository.checkPremiumStatus();
    state = state.copyWith(isPremium: isPremium);
  }

  Future<bool> purchasePremium() async {
    final success = await _repository.purchasePremium();
    if (success) {
      state = state.copyWith(isPremium: true);
    }
    return success;
  }

  Future<bool> watchAdForReward() async {
    final success = await _repository.showRewardedAd();
    if (success) {
      state = state.copyWith(hasAdReward: true);
    }
    return success;
  }

  void consumeReward() {
    state = state.copyWith(hasAdReward: false);
  }
}

final monetizationControllerProvider = StateNotifierProvider<MonetizationController, MonetizationState>((ref) {
  final repository = ref.watch(monetizationRepositoryProvider);
  return MonetizationController(repository);
});
