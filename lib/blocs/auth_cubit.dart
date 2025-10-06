import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// =====================
/// Auth States
/// =====================

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final String token;
  final String? profilePath; // optional local profile photo

  AuthAuthenticated({
    required this.username,
    required this.token,
    this.profilePath,
  });

  AuthAuthenticated copyWith({
    String? username,
    String? token,
    String? profilePath,
  }) {
    return AuthAuthenticated(
      username: username ?? this.username,
      token: token ?? this.token,
      profilePath: profilePath ?? this.profilePath,
    );
  }
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthGuest extends AuthState {}

/// =====================
///  Auth Cubit
/// =====================

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  AuthAuthenticated? _lastAuthenticated;

  /// Continue without authentication
  void continueAsGuest() {
    print(" continueAsGuest called");
    emit(AuthGuest());
  }

  final _storage = const FlutterSecureStorage();
  /// Login with email + password
  Future<void> login(String email, String password) async {
    print(" login() called with email=$email");
    emit(AuthLoading());

    try {
      final uri = Uri.parse("http://10.0.2.2:3333/login");

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final username = data["user"]?["userName"] ?? "User";
        final token = data["token"]?["token"];

        if (token != null) {
          print("✅ Login success for user=$username, saving token...");

          // 🔒 Save token securely
          await _storage.write(key: "auth_token", value: token);

          // Emit success state
          loginSuccess(username, token);
        } else {
          emit(AuthError("Invalid response: token missing"));
        }
      } else {
        print("❌ Login failed: ${response.body}");
        emit(AuthError("Login failed: ${response.body}"));
      }
    } catch (e, stack) {
      print("💥 Login exception: $e\n$stack");
      emit(AuthError("Login exception: $e"));
    }
  }


  ///  Shared handler for login + google login
  void loginSuccess(String username, String token) {
    print(" Auth success: $username | $token");
    final authState = AuthAuthenticated(username: username, token: token);
    _lastAuthenticated = authState;
    emit(authState);
  }


  /// Update profile photo locally (not server sync)
  Future<void> updateProfilePhoto(String filePath) async {
    print(" updateProfilePhoto called with $filePath");
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      emit(current.copyWith(profilePath: filePath));
    } else {
      print(" Tried to update profile photo without being authenticated");
    }
  }

  /// Update profile details (server + state)
  Future<void> updateProfile({
    String? userName,
    String? mobileNumber,
    String? oldPassword,
    String? newPassword,
  }) async {
    print(" updateProfile called");
    if (state is! AuthAuthenticated) {
      print("️ Not authenticated, skipping updateProfile");
      return;
    }

    final current = state as AuthAuthenticated;
    emit(AuthLoading());

    try {
      final url = Uri.parse("http://10.0.2.2:3333/profile");
      print(" Sending PATCH request to $url with token=${current.token}");

      final body = jsonEncode({
        if (userName != null) "userName": userName,
        if (mobileNumber != null) "mobileNumber": mobileNumber,
        if (oldPassword != null) "oldPassword": oldPassword,
        if (newPassword != null) "newPassword": newPassword,
      });

      print(" updateProfile body: $body");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${current.token}",
        },
        body: body,
      );

      print(" updateProfile response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedUserName = data['user']['userName'] ?? current.username;
        emit(current.copyWith(username: updatedUserName));
        print(" Profile updated successfully");
      } else {
        final err = jsonDecode(response.body);
        print("Profile update failed: ${err["error"] ?? "Unknown error"}");
        emit(AuthError(err["error"] ?? "Invalid request"));
        emit(current); // rollback
      }
    } catch (e) {
      print(" updateProfile exception: $e");
      emit(AuthError("Profile update failed: $e"));
      emit(current);
    }
  }


  Future<void> logout() async {
    print(" logout() called");

    if (_lastAuthenticated == null) {
      print(" Tried to log out but no authenticated user.");
      return;
    }

    final token = _lastAuthenticated!.token;

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:3333/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // send token
        },
      );

      if (response.statusCode == 200) {
        print("  Logout success (server confirmed).");
      } else {
        print("  Logout request failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print(" 💥 Logout request error: $e");
    }


    await _storage.delete(key: "auth_token");
    print(" Token removed from secure storage.");

    const storage = FlutterSecureStorage();
    await storage.delete(key: "auth_token");
    await storage.delete(key: "username");
    _lastAuthenticated = null;
    emit(AuthInitial());
    print(" Local auth state cleared.");
  }
  Future<void> googleLogin(String username, String token) async {
    print(" googleLogin() called with username=$username, token=$token");
    emit(AuthLoading());

    try {
      loginSuccess(username, token);
      print(" Google login success");
    } catch (e) {
      print(" Google login failed with exception: $e");
      emit(AuthError("Google login failed: $e"));
    }
  }

  static Future<bool> checkTokenWithBackend(String token) async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:3333/auth/check"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }


}
