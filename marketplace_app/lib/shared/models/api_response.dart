import 'package:json_annotation/json_annotation.dart';

// part 'api_response.g.dart';

/// Wrapper générique pour les réponses API
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => ApiResponse(
    success: json['success'] as bool, // Assuming 'success' field exists in JSON
    message: json['message'] as String?,
    data: json['data'] != null ? fromJsonT(json['data']) : null,
    errors: json['errors'] as Map<String, dynamic>?, // Assuming 'errors' field exists in JSON
  );

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'success': success,
    'message': message,
    'data': data != null ? toJsonT(data as T) : null,
    'errors': errors,
  };
}
