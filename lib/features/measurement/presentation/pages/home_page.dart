import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.appTitle)),
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
              Text(
                loc.appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                loc.homeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // Main Actions
              ElevatedButton.icon(
                onPressed: () => context.push('/drawing'),
                icon: const Icon(Icons.add, size: 28),
                label: Text(loc.drawingTitle),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => context.push('/calculator'),
                icon: const Icon(Icons.calculate, size: 28),
                label: Text(loc.calculator),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => context.push('/converter'),
                icon: const Icon(Icons.swap_horiz, size: 28),
                label: Text(loc.unitConverter),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => context.push('/land-calculator'),
                icon: const Icon(Icons.landscape, size: 28),
                label: Text(loc.landCalculator),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history, size: 28),
                label: Text(loc.historyTitle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings, size: 28),
                label: Text(loc.settings),
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
