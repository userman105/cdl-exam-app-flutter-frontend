import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'first_screen.dart';
import 'home_screen.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/exam_cubit.dart';
import 'repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Secure storage for token + username
  const storage = FlutterSecureStorage();
  final savedToken = await storage.read(key: "auth_token");
  final savedUsername = await storage.read(key: "username");

  // Initialize Dio + repository
  final dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:3333"));
  final authRepository = AuthRepository(dio);

  // Init cubit with repo
  final authCubit = AuthCubit();

  // Decide start screen
  Widget startScreen;
  if (savedToken != null) {
    final isValid = await AuthCubit.checkTokenWithBackend(savedToken);
    if (isValid) {
      authCubit.loginSuccess(savedUsername ?? "User", savedToken);
      startScreen = const HomeScreen();
    } else {
      await storage.delete(key: "auth_token");
      await storage.delete(key: "username");
      startScreen = const SplashScreen();
    }
  } else {
    startScreen = const SplashScreen();
  }

  runApp(AppRoot(startScreen: startScreen, authCubit: authCubit));
}

class AppRoot extends StatelessWidget {
  final Widget startScreen;
  final AuthCubit authCubit;

  const AppRoot({
    super.key,
    required this.startScreen,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<ExamCubit>(create: (_) => ExamCubit()),
      ],
      child: MyApp(startScreen: startScreen),
    );
  }
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: startScreen,
    );
  }
}
