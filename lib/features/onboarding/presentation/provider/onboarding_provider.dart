import 'package:flutter/material.dart';
import '../../data/models/onboarding_data.dart';

class OnboardingProvider extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentIndex = 0;

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (currentIndex < onboardingList.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get isLastPage => currentIndex == onboardingList.length - 1;
}