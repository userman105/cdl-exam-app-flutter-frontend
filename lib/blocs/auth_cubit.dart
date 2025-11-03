import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// =====================
/// Auth States
/// =====================

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String username;
  final String token;
  final String? profilePath; // local image (from gallery)
  final String? photoUrl; // remote image (from backend or Google)
  final bool? isExistingUser;
  final bool? subscribed; //
  final String? typeOfSubscription;
  final bool isSubscriptionActive;

  AuthAuthenticated({
    required this.username,
    required this.token,
    this.profilePath,
    this.photoUrl,
    this.isExistingUser,
    this.subscribed = false,
    this.typeOfSubscription,
    this.isSubscriptionActive = false,

  });

  AuthAuthenticated copyWith({
    String? username,
    String? token,
    String? profilePath,
    String? photoUrl,
    bool? isExistingUser,
    bool? subscribed,
  }) {
    return AuthAuthenticated(
      username: username ?? this.username,
      token: token ?? this.token,
      profilePath: profilePath ?? this.profilePath,
      photoUrl: photoUrl ?? this.photoUrl,
      isExistingUser: isExistingUser ?? this.isExistingUser,
      subscribed: subscribed ?? this.subscribed, // ✅ keep when copying
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
  final String ?password; // add this

  AuthNeedsVerification({required this.email, this.password});
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
    required String ?password,
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
          await fetchUserProfile();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // or selectively delete dashboard_* and exam_* keys

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
      final response = await _dio.post(
        "/register",
        data: {
          "fName": fName,
          "lName": lName,
          "userName": userName,
          "email": email,
          "password": password,
          "mobileNumber": mobileNumber ?? "",
        },
      );

      return response.data;
    } on DioException catch (e) {
      String message = "Registration failed. Please try again.";

      if (e.response != null) {
        if (e.response?.statusCode == 400) {
          message = e.response?.data["message"] ??
              "This email is already registered. Please use another one.";
        } else if (e.response?.statusCode == 409) {
          message = "This email is already registered. Please use another one.";
        } else {
          message = e.response?.data["message"] ??
              "An error occurred: ${e.response?.statusMessage}";
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = "Connection timed out. Please try again.";
      } else if (e.type == DioExceptionType.connectionError) {
        message = "No internet connection. Please check your network.";
      }

      return {"success": false, "error": message};
    } catch (e) {
      return {"success": false, "error": "Unexpected error occurred."};
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


  Future<void> registerWithGoogle() async {
    emit(AuthLoading());

    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthError("Google sign-in cancelled"));
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        emit(AuthError("Failed to get Google ID token"));
        return;
      }

      final email = googleUser.email;
      final fName = email.split('@').first;
      const lName = '';
      final userName = fName;

      final response = await _dio.post(
        "/auth/google/callback",
        data: {"id_token": idToken},
        options: Options(validateStatus: (status) => true),
      );

      final data = response.data;

      // ✅ Existing user (already registered)
      if (response.statusCode == 200 && data["token"] != null) {
        final token = data["token"]["token"];
        await _storage.write(key: "auth_token", value: token);

        final profileResult = await fetchUserProfile();

        if (profileResult["success"] == true) {
          final user = profileResult["user"];
          final username = user["userName"] ?? fName;
          final photoUrl = user["googlePhotoUrl"];

          emit(AuthAuthenticated(
            username: username,
            token: token,
            photoUrl: photoUrl,
            isExistingUser: true, // ⚠️ Existing user
          ));
        } else {
          emit(AuthError("Failed to fetch user profile after Google login"));
        }
        return;
      }

      // ✅ New user (registered now via Google)
      if (response.statusCode == 201 ||
          (data["message"] ?? "").toString().toLowerCase().contains("created")) {
        final token = data["token"]?["token"];
        if (token != null) await _storage.write(key: "auth_token", value: token);

        final profileResult = await fetchUserProfile();
        if (profileResult["success"] == true) {
          final user = profileResult["user"];
          final username = user["userName"] ?? fName;
          final photoUrl = user["googlePhotoUrl"];

          emit(AuthAuthenticated(
            username: username,
            token: token ?? "",
            photoUrl: photoUrl,
            isExistingUser: false, // ✅ New user
          ));
        } else {
          emit(AuthError("Failed to fetch user profile after registration"));
        }
        return;
      }

      // Needs verification or similar backend hints
      if (response.statusCode == 202 ||
          data["needs_verification"] == true ||
          (data["message"] ?? "")
              .toString()
              .toLowerCase()
              .contains("verify")) {
        emit(AuthNeedsVerification(email: email, password: ""));
        return;
      }

      //  Unauthorized → try manual registration fallback
      if (response.statusCode == 401) {
        final registerResult = await registerUser(
          fName: fName,
          lName: lName,
          userName: userName,
          email: email,
          password: '',
        );

        if (registerResult["success"] == true) {
          emit(AuthNeedsVerification(email: email, password: ""));
        } else {
          emit(AuthError(
            registerResult["message"] ?? "Google registration failed",
          ));
        }
        return;
      }

      emit(AuthError("Google login failed: ${response.data}"));
    } catch (e) {
      emit(AuthError("Google sign-in error: $e"));
    } finally {
      await googleSignIn.signOut();
    }
  }



  /// =====================
  /// Fetch current user info (from /me endpoint)
  /// =====================
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) {
        emit(AuthError("No token found. Please log in again."));
        return {"success": false, "error": "Token missing"};
      }

      emit(AuthLoading());

      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = data["user"];

        final username = user["userName"] ?? "User";
        final photoUrl = user["photoUrl"] ?? user["googlePhotoUrl"];
        final subscribed = user["subscribed"] ?? false;
        final typeOfSubscription = user["typeOfSubscription"];
        final isSubscriptionActive = user["isSubscriptionActive"] ?? false;

        print("✅ Loaded user photo URL: $photoUrl");
        print("✅ Subscribed: $subscribed");

        final updatedState = AuthAuthenticated(
          username: username,
          token: token,
          photoUrl: photoUrl,
          subscribed: subscribed,
          typeOfSubscription: typeOfSubscription,
          isSubscriptionActive: isSubscriptionActive,
        );

        _lastAuthenticated = updatedState;
        emit(updatedState);

        return {
          "success": true,
          "user": user,
          "requestedAt": data["requestedAt"],
        };
      } else {
        emit(AuthError(response.data["error"] ?? "Failed to fetch user"));
        return {
          "success": false,
          "error": response.data["error"] ?? "Unknown error",
        };
      }
    } on DioException catch (e) {
      final msg = e.response?.data?["error"] ?? e.message;
      emit(AuthError("Fetch user failed: $msg"));
      return {"success": false, "error": msg};
    } catch (e) {
      emit(AuthError("Unexpected error: $e"));
      return {"success": false, "error": e.toString()};
    }
  }





}
