import 'package:flutter/material.dart';
import 'package:medinear_app/features/onboarding/presentation/widgets/onbaording_dots.dart';
import 'package:medinear_app/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:provider/provider.dart';

import '../provider/onboarding_provider.dart';

import '../widgets/onboarding_buttons.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: OnboardingPages()),
              SizedBox(height: 16),
              OnboardingDots(),
              SizedBox(height: 24),
              OnboardingButtons(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}