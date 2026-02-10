import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medinear_app/app.dart';
import 'package:medinear_app/core/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main()  {
  

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

