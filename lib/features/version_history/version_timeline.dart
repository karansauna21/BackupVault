import 'package:flutter/material.dart';
import 'version_history_provider.dart';
import 'package:intl/intl.dart';

class VersionTimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const VersionTimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
              const SizedBox(height: 12),
              Text(
                'No timeline events logged yet.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        Color dotColor;
        IconData icon;
        switch (event.eventType) {
          case 'created':
            dotColor = Colors.green;
            icon = Icons.add_circle_outline_rounded;
            break;
          case 'modified':
            dotColor = theme.colorScheme.primary;
            icon = Icons.edit_rounded;
            break;
          case 'restored':
            dotColor = Colors.orange;
            icon = Icons.restore_rounded;
            break;
          case 'verified':
            dotColor = Colors.teal;
            icon = Icons.verified_user_rounded;
            break;
          default:
            dotColor = theme.colorScheme.secondary;
            icon = Icons.info_outline_rounded;
            break;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicator Line and Dot
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: dotColor.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, size: 16, color: dotColor),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),

              // Event Details Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                event.title,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(event.timestamp),
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
