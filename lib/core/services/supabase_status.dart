import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStatus {
  const SupabaseStatus._();

  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } on Object {
      return false;
    }
  }
}
