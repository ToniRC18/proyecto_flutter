import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_client.dart';

const _kOnboardingKey = 'onboarding_completed';
const _kMonthlyGoalKey = 'monthly_goal';

class OnboardingService extends ChangeNotifier {
  bool _completed = false;
  bool get isCompleted => _completed;

  /// Llama esto en main() antes de runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_kOnboardingKey) ?? false;

    // Si no está en prefs, consulta Supabase para cubrir cambio de dispositivo.
    if (!_completed) {
      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          final row = await supabase
              .from('user_settings')
              .select('onboarding_completed_at, tenant_id')
              .not('onboarding_completed_at', 'is', null)
              .maybeSingle();
          if (row != null) {
            await prefs.setBool(_kOnboardingKey, true);
            _completed = true;
          }
        }
      } catch (_) {}
    }
  }

  /// Llama esto justo después de un signIn o signUp exitoso.
  /// Re-consulta Supabase ahora que sí hay sesión activa.
  Future<void> syncFromServer() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final prefs = await SharedPreferences.getInstance();

      final row = await supabase
          .from('user_settings')
          .select('onboarding_completed_at')
          .not('onboarding_completed_at', 'is', null)
          .maybeSingle();

      if (row != null) {
        // Ya completó onboarding en otro dispositivo.
        await prefs.setBool(_kOnboardingKey, true);
        _completed = true;
        notifyListeners();
      } else {
        await prefs.remove(_kOnboardingKey);
        _completed = false;
        notifyListeners();
      }
      // Si row == null: usuario nuevo, _completed se queda en false y ve onboarding.
    } catch (_) {
      // Si falla la consulta, no bloquear: el router ya tiene el estado actual.
    }
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboardingKey);
    _completed = false;
    notifyListeners();
  }

  Future<void> markCompleted(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    _completed = true;

    try {
      await supabase.from('user_settings').upsert({
        'tenant_id': tenantId,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'tenant_id');
    } catch (_) {}

    notifyListeners();
  }

  Future<void> saveMonthlySavingsGoal(String tenantId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMonthlyGoalKey, amount);
    try {
      await supabase.from('user_settings').upsert({
        'tenant_id': tenantId,
        'monthly_savings_goal': amount,
      }, onConflict: 'tenant_id');
    } catch (_) {}
  }
}

final onboardingService = OnboardingService();

final onboardingServiceProvider = Provider<OnboardingService>((_) {
  return onboardingService;
});
