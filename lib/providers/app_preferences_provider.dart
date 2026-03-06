import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_preferences.dart';

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences();
});
