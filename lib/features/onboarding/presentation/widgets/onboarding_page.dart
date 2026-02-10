import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/onboarding_data.dart';
import '../provider/onboarding_provider.dart';
import 'onboarding_content.dart';

class OnboardingPages extends StatelessWidget {
  const OnboardingPages({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return PageView.builder(
      controller: provider.pageController,
      onPageChanged: provider.onPageChanged,
      itemCount: onboardingList.length,
      itemBuilder: (_, index) {
        return OnboardingContent(
          model: onboardingList[index],
          isActive: index == provider.currentIndex,
        );
      },
    );
  }
}