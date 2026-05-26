import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EdgeResult<T> {
  const EdgeResult.success(this.data) : error = null;

  const EdgeResult.failure(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
}

class EdgeFunctionClient {
  Future<EdgeResult<Map<String, dynamic>>> invoke(
    String functionName, {
    required Map<String, dynamic> payload,
    Map<String, String>? headers,
  }) async {
    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        functionName,
        body: payload,
        headers: headers,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return EdgeResult.success(data);
      }
      if (data is Map) {
        return EdgeResult.success(Map<String, dynamic>.from(data));
      }
      return const EdgeResult.failure('Unexpected edge function response.');
    } on Object catch (error) {
      debugPrint('Lumina edge function $functionName failed: $error');
      return EdgeResult.failure(error.toString());
    }
  }
}
