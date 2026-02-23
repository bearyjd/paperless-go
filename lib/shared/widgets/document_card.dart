import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/thumbnail_cache.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document.dart';
import '../../core/models/document_type.dart';
import '../../core/models/tag.dart';
import 'tag_chip.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? thumbnailUrl;
  final String? authToken;

  static const int _maxVisibleTags = 3;

  const DocumentCard({
    super.key,
    required this.document,
    required this.tags,
    required this.correspondents,
    required this.documentTypes,
    this.onTap,
    this.onLongPress,
    this.thumbnailUrl,
    this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    final correspondent = document.correspondent != null
        ? correspondents[document.correspondent]
        : null;
    final docType = document.documentType != null
        ? documentTypes[document.documentType]
        : null;
    final docTags = document.tags
        .map((id) => tags[id])
        .whereType<Tag>()
        .toList();

    final subtitle = [
      if (correspondent != null) correspondent.name,
      if (docType != null) docType.name,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (thumbnailUrl != null && authToken != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      httpHeaders: {'Authorization': authToken!},
                      cacheManager: ThumbnailCacheManager.instance,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 64,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.description_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 64,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 4),
                    Text(
                      _formatDate(document.created),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Tags
                    if (docTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...docTags.take(_maxVisibleTags).map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: TagChip(tag: tag),
                            ),
                          ),
                          if (docTags.length > _maxVisibleTags)
                            TagOverflowChip(count: docTags.length - _maxVisibleTags),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
