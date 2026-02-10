import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_model.dart';

final List<OnboardingModel> onboardingList = [
  OnboardingModel(
    title: 'Welcome to MediNear',
    description:
        'Your trusted health partner for easy and fast medication delivery.',
    image: 'assets/images/onboarding_1.jpg',
  ),
   OnboardingModel(
    title: 'Manage Your Health',
    description:
        'Keep track of your medications with smart reminders and easy access.',
    image: 'assets/images/onboarding_2.jpg',
  ),
   OnboardingModel(
    title: 'Care for Your Family',
    description:
        'Easily manage your family’s medications and nearby pharmacies.',
    image: 'assets/images/onboarding_3.jpg',
  ),
];

class OnboardingDataSource{
  final SharedPreferences prefs;
  OnboardingDataSource(this.prefs);
  bool isSeen() => prefs.getBool('seenOnboarding') ?? false;
  Future<void> saveSeen() async => await prefs.setBool('seenOnboarding', true);
}