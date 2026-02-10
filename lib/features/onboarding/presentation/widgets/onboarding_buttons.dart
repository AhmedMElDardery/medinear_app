import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/onboarding_provider.dart';

class OnboardingButtons extends StatelessWidget {
  const OnboardingButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            if (provider.isLastPage) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              provider.nextPage();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            provider.isLastPage
                ? 'Start Using MediNear'
                : 'Next',
          ),
        ),
      ),
    );
  }
}