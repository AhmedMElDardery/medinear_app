import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/onboarding_data.dart';
import '../provider/onboarding_provider.dart';

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingList.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: provider.currentIndex == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: provider.currentIndex == index
                ? Theme.of(context).primaryColor
                : Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}