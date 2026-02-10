
import 'package:flutter/material.dart';
import 'package:medinear_app/features/splash/presentation/provider/splash_provider.dart';
import 'package:medinear_app/features/splash/presentation/widgets/splash_body.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late SplashProvider provider;

  @override
  void initState() {
    super.initState();
    provider = SplashProvider();
    provider.init(this);

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    provider.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const Scaffold(
        body: SplashBody(),
      ),
    );
  }
}