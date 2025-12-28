import 'package:flutter/material.dart';
import '../../data/models/land_info_model.dart';

class TopicDetailPage extends StatelessWidget {
  final LandTopic topic;

  const TopicDetailPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: topic.content.length,
        itemBuilder: (context, index) {
          final block = topic.content[index];
          return _buildContentBlock(context, block);
        },
      ),
    );
  }

  Widget _buildContentBlock(BuildContext context, ContentBlock block) {
    switch (block.type) {
      case 'header':
        return Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
          child: Text(
            block.text ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        );
      case 'sub_header':
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            block.text ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        );
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            block.text ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        );
      case 'bullet_point':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              children: [
                const WidgetSpan(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.circle, size: 8, color: Colors.black54),
                  ),
                  alignment: PlaceholderAlignment.middle,
                ),
                if (block.title != null)
                  TextSpan(
                    text: '${block.title}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                TextSpan(text: block.text ?? ''),
              ],
            ),
          ),
        );
      case 'bullet_list':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (block.items ?? []).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, right: 8.0),
                    child: Icon(Icons.circle, size: 6, color: Colors.black54),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: block.source == 'asset'
                    ? Image.asset(
                        block.url ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50),
                            ),
                          );
                        },
                      )
                    : Image.network(
                        block.url ?? '',
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50),
                            ),
                          );
                        },
                      ),
              ),
              if (block.caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    block.caption!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
