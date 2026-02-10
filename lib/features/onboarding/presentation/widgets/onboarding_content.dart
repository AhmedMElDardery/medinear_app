import 'package:flutter/material.dart';
import '../../data/models/onboarding_model.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingModel model;
  final bool isActive;

  const OnboardingContent({
    super.key,
    required this.model,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            model.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            opacity: isActive ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 700),
              offset: isActive ? Offset.zero : const Offset(0, 0.2),
              child: Image.asset(
                model.image,
                height: 260,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            model.description,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}