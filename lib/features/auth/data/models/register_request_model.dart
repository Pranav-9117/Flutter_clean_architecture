class RegisterRequestModel {
  final String email;
  final String password;

  const RegisterRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': email, 'email': email, 'password': password};
  }
}
