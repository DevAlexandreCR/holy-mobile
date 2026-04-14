import 'package:flutter_test/flutter_test.dart';
import 'package:holyverso/domain/devotionals/devotional_feed_header.dart';

void main() {
  group('DevotionalFeedHeader.fromMap', () {
    test('parses daily featured devotional payload', () {
      final header = DevotionalFeedHeader.fromMap({
        'streak': {
          'current_streak': 5,
          'longest_streak': 8,
          'streak_freeze_count': 1,
        },
        'completed_today': false,
        'daily_featured': {
          'id': 'featured-1',
          'title': 'Dios sigue obrando',
          'estimated_read_time': 3,
          'preview_text': 'Aunque hoy parezca lento...',
          'preview_image_url': 'https://example.com/featured.jpg',
        },
        'primary_cta': {
          'type': 'OPEN_DAILY_FEATURED',
          'label': 'Completa tu día',
          'devotional_id': 'featured-1',
        },
      });

      expect(header.currentStreak, 5);
      expect(header.longestStreak, 8);
      expect(header.streakFreezeCount, 1);
      expect(header.completedToday, isFalse);
      expect(header.dailyFeatured?.id, 'featured-1');
      expect(header.dailyFeatured?.title, 'Dios sigue obrando');
      expect(header.dailyFeatured?.estimatedReadTime, 3);
      expect(header.dailyFeatured?.previewText, 'Aunque hoy parezca lento...');
      expect(
        header.dailyFeatured?.previewImageUrl,
        'https://example.com/featured.jpg',
      );
      expect(header.primaryCtaType, 'OPEN_DAILY_FEATURED');
      expect(header.primaryCtaLabel, 'Completa tu día');
      expect(header.primaryCtaDevotionalId, 'featured-1');
    });

    test('defaults to null daily featured when inventory is empty', () {
      final header = DevotionalFeedHeader.fromMap({
        'streak': {'current_streak': 0},
        'completed_today': true,
        'daily_featured': null,
        'primary_cta': {'type': 'BROWSE_FEED', 'label': 'Seguir explorando'},
      });

      expect(header.dailyFeatured, isNull);
      expect(header.primaryCtaType, 'BROWSE_FEED');
      expect(header.primaryCtaLabel, 'Seguir explorando');
      expect(header.primaryCtaDevotionalId, isNull);
    });
  });
}
