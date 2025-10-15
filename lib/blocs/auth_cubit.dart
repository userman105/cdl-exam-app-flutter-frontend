import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

/// =====================
/// Auth States
/// =====================

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final String token;
  final String? profilePath;

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

class AuthNeedsVerification extends AuthState {
  final String email;
  final String password; // add this

  AuthNeedsVerification({required this.email, required this.password});
}

/// =====================
/// Auth Cubit
/// =====================

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final _storage = const FlutterSecureStorage();
  AuthAuthenticated? _lastAuthenticated;


  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://10.0.2.2:3333",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  /// Continue as guest
  void continueAsGuest() => emit(AuthGuest());

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      final response = await _dio.post(
        "/login",
        data: {
          "email": email,
          "password": password,
        },
        options: Options(
          validateStatus: (status) {
            // Accept 200 and 403 (unverified)
            return status == 200 || status == 403;
          },
        ),
      );

      final data = response.data;

      if (response.statusCode == 403) {
        final errorMsg = (data["error"] ?? data["message"] ?? "").toString().toLowerCase();

        // redirect if the message indicates verification needed
        if (errorMsg.contains("verify") || errorMsg.contains("unverified")) {
          emit(AuthNeedsVerification(email: email, password: password));
          return;
        }

        // fallback for other 403s
        emit(AuthError(errorMsg.isNotEmpty ? errorMsg : "Forbidden"));
        return;
      }


      if (response.statusCode == 200) {
        final username = data["user"]?["userName"] ?? "User";
        final token = data["token"]?["token"];

        if (token != null) {
          await _storage.write(key: "auth_token", value: token);
          loginSuccess(username, token);
        } else {
          emit(AuthError("Invalid response: token missing"));
        }
        return;
      }

      emit(AuthError(data["error"] ?? "Login failed"));
    } on DioException catch (e) {
      final msg = e.response?.data?["error"] ?? e.message;
      emit(AuthError("Login failed: $msg"));
    } catch (e) {
      emit(AuthError("Login exception: $e"));
    }
  }






  void loginSuccess(String username, String token) {
    final authState = AuthAuthenticated(username: username, token: token);
    _lastAuthenticated = authState;
    emit(authState);
  }


  void updateProfilePhoto(String filePath) {
    if (state is AuthAuthenticated) {
      emit((state as AuthAuthenticated).copyWith(profilePath: filePath));
    }
  }


  Future<void> updateProfile({
    String? userName,
    String? mobileNumber,
    String? oldPassword,
    String? newPassword,
  }) async {
    if (state is! AuthAuthenticated) return;

    final current = state as AuthAuthenticated;
    emit(AuthLoading());

    try {
      final response = await _dio.patch(
        "/profile",
        data: {
          if (userName != null) "userName": userName,
          if (mobileNumber != null) "mobileNumber": mobileNumber,
          if (oldPassword != null) "oldPassword": oldPassword,
          if (newPassword != null) "newPassword": newPassword,
        },
        options: Options(
          headers: {"Authorization": "Bearer ${current.token}"},
        ),
      );

      final updatedUserName =
          response.data['user']['userName'] ?? current.username;
      emit(current.copyWith(username: updatedUserName));
    } catch (e) {
      emit(AuthError("Profile update failed: $e"));
      emit(current); // rollback
    }
  }

  /// Logout
  Future<void> logout() async {
    if (_lastAuthenticated == null) return;

    final token = _lastAuthenticated!.token;

    try {
      await _dio.post(
        "/logout",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } catch (_) {}

    await _storage.delete(key: "auth_token");
    await _storage.delete(key: "username");
    _lastAuthenticated = null;
    emit(AuthInitial());
  }


  void googleLogin(String username, String token) {
    emit(AuthLoading());
    loginSuccess(username, token);
  }


  static Future<bool> checkTokenWithBackend(String token) async {
    final dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:3333"));
    try {
      final response = await dio.get(
        "/auth/check",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  Future<Map<String, dynamic>> registerUser({
    required String fName,
    required String lName,
    required String userName,
    required String email,
    required String password,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dio.post("/register", data: {
        "fName": fName,
        "lName": lName,
        "userName": userName,
        "email": email,
        "password": password,
        "mobileNumber": mobileNumber ?? "",
      });
      return response.data;
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }


  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response =
      await _dio.post("/auth/verify", data: {"email": email, "otp": otp});
      return {"success": true, "message": response.data["message"]};
    } on DioException catch (e) {
      final error = e.response?.data ?? {};
      return {
        "success": false,
        "error": error["error"] ?? "Verification failed",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }


  Future<Map<String, dynamic>> requestOtp({
    required String oldEmail,
    String? newEmail,
  }) async {
    try {
      final response = await _dio.post("/auth/resend-otp", data: {
        "oldEmail": oldEmail,
        "newEmail": newEmail ?? oldEmail,
      });
      return response.data;
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? e.message,
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateEmail({
    required String oldEmail,
    required String newEmail,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/update-email",
        data: {
          "old_email": oldEmail,
          "new_email": newEmail,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? e.message,
      };
    }
  }

  ///=============
  ///password recovery
  ///=============

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        "/auth/request-password-reset",
        data: {"email": email},
      );
      return {"success": true, "message": response.data["message"]};
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? "Failed to send OTP",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  /// Step 2: Verify OTP
  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/verify-reset-otp",
        data: {"email": email, "otp": otp},
      );
      return {"success": true, "message": response.data["message"]};
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? "Invalid OTP",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  /// Step 3: Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/reset-password",
        data: {"email": email, "otp": otp, "newPassword": newPassword},
      );
      return {"success": true, "message": response.data["message"]};
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data["error"] ?? "Failed to reset password",
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }



}
