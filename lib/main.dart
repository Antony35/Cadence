import 'package:cadence/ui/home_page.dart';
import 'package:cadence/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CadenceApp());

class CadenceApp extends StatelessWidget {
  const CadenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
