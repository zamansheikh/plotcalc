import 'package:flutter/material.dart';
import '../../../../../../core/localization/app_localizations.dart';

class ResizeModeBanner extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const ResizeModeBanner({
    super.key,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade100,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.aspect_ratio, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.resizeMode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      loc.resizeInstruction,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: Text(loc.cancel)),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onApply, child: Text(loc.apply)),
            ],
          ),
        ],
      ),
    );
  }
}
