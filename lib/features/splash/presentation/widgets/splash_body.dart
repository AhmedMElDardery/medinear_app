import 'package:flutter/material.dart';
import 'package:medinear_app/features/splash/presentation/provider/splash_provider.dart';
import 'package:provider/provider.dart';

class SplashBody extends StatelessWidget {
  const SplashBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplashProvider>();

    return Center(
      child: AnimatedBuilder(
        animation: provider.controller,
        builder: (_, __) {
          return Opacity(
            opacity: provider.opacityAnimation.value,
            child: Transform.scale(
              scale: provider.scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MediNear',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}