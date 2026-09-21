import '../../domain/entities/user.dart';

class AuthResponseModel {
  final String? accessToken;
  final String? refreshToken;
  final User user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  //named factory constructor converts json to AuthResponseModel object
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] as Map<String, dynamic>?) ?? json;
    final firstName = userJson['firstName'] as String?;
    final lastName = userJson['lastName'] as String?;

    return AuthResponseModel(
      accessToken: (json['accessToken'] ?? json['access_token']) as String?,
      refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String?,
      user: User(
        id: userJson['id'].toString(),
        name:
            userJson['name'] as String? ??
            [firstName, lastName].whereType<String>().join(' '),
        email: userJson['email'] as String? ?? '',
      ),
    );
  }
}
