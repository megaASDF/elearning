import 'package:flutter/material.dart';
import '../../../core/models/announcement_model.dart';
import '../../announcement/screens/announcement_detail_screen.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementCard({super.key, required this.announcement});

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcementId: announcement.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias, // Ensures ink splash is contained
      child: InkWell(
        onTap: () => _navigateToDetail(context), // Make whole card clickable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(announcement.authorName.isNotEmpty 
                        ? announcement.authorName[0].toUpperCase() 
                        : '?'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          announcement.timeAgo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Keep menu for specific actions if needed, or remove if redundant
                  PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'view') _navigateToDetail(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View details & comments'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                maxLines: 3, // Limit lines in preview
                overflow: TextOverflow.ellipsis,
              ),
              if (announcement.attachmentUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: announcement.attachmentUrls.take(2).map((url) {
                    return Chip(
                      avatar: const Icon(Icons.attachment, size: 16),
                      label: Text(
                        url.split('/').last.length > 20 
                            ? '${url.split('/').last.substring(0, 20)}...' 
                            : url.split('/').last
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                if (announcement.attachmentUrls.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${announcement.attachmentUrls.length - 2} more files',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${announcement.viewCount}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${announcement.commentCount}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Text(
                    'Tap to view more',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}