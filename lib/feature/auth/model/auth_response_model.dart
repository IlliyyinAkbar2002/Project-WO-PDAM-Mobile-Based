import 'dart:convert';

class AuthResponseModel {
  final bool? success;
  final String? type;
  final String? message;
  final String? token;
  final Map<String, dynamic>? user;

  const AuthResponseModel({
    this.success,
    this.type,
    this.message,
    this.token,
    this.user,
  });

  factory AuthResponseModel.fromJson(String source) =>
      AuthResponseModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  factory AuthResponseModel.fromMap(Map<String, dynamic> map) {
    return AuthResponseModel(
      success: map['success'],
      type: map['type'],
      message: map['message'],
      // Laravel returns 'access_token', not 'token'
      token: map['access_token'] ?? map['token'],
      user: map['user'] != null ? Map<String, dynamic>.from(map['user']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'type': type,
      'message': message,
      'token': token,
      'user': user,
    };
  }
}
