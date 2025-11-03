import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PlotCalc')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Header
              const Icon(
                Icons.terrain,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'PlotCalc',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Measure land area with ease',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // Main Actions
              ElevatedButton.icon(
                onPressed: () => context.push('/drawing'),
                icon: const Icon(Icons.add, size: 28),
                label: const Text('Start New Measurement'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history, size: 28),
                label: const Text('View Past Calculations'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings, size: 28),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
