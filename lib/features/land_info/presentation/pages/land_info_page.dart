import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

import '../../data/repositories/land_info_repository.dart';
import '../../data/models/land_info_model.dart';

class LandInfoPage extends StatefulWidget {
  const LandInfoPage({super.key});

  @override
  State<LandInfoPage> createState() => _LandInfoPageState();
}

class _LandInfoPageState extends State<LandInfoPage> {
  late Future<LandInfoData> _landInfoFuture;
  final LandInfoRepository _repository = LandInfoRepository();

  @override
  void initState() {
    super.initState();
    _landInfoFuture = _repository.loadLandInfo();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.infoPortal)),
      body: FutureBuilder<LandInfoData>(
        future: _landInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.topics.isEmpty) {
            return const Center(child: Text('No information available'));
          }

          final topics = snapshot.data!.topics;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _buildInfoCard(
                context,
                topic: topic,
                onTap: () => context.push('/land-info/detail', extra: topic),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required LandTopic topic,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (topic.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          topic.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
