import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  // Private constructor
  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  // Expose the client
  SupabaseClient get client => Supabase.instance.client;
}
