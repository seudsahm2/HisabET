import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Legacy backend provider kept only to avoid breaking old imports.
///
/// The app now uses Firebase as its backend.
final supabaseClientProvider = Provider<Object?>((ref) {
  return null;
});

/// Legacy initializer kept only for compatibility.
class SupabaseService {
  static Future<void> initialize({required String url, required String anonKey}) async {}
}
