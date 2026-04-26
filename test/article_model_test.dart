// test/widget_test.dart

// Basic smoke test to verify the widget tree builds without errors.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/models/article.dart';

void main() {
  // ── Model unit tests ────────────────────────────────────────────────────

  group('Article model', () {
    const sampleJson = {
      'title': 'Test Article',
      'description': 'A test description.',
      'url': 'https://example.com/article',
      'urlToImage': 'https://example.com/image.jpg',
      'source': {'id': 'bbc', 'name': 'BBC News'},
      'author': 'Jane Doe',
      'publishedAt': '2026-04-22T10:30:00Z',
      'content': 'Full content here...',
    };

    test('fromJson parses all fields correctly', () {
      final article = Article.fromJson(sampleJson);
      expect(article.title, 'Test Article');
      expect(article.sourceName, 'BBC News');
      expect(article.author, 'Jane Doe');
      expect(article.url, 'https://example.com/article');
      expect(article.urlToImage, 'https://example.com/image.jpg');
      expect(article.description, 'A test description.');
      expect(article.publishedAt.year, 2026);
    });

    test('toJson round-trips correctly', () {
      final article = Article.fromJson(sampleJson);
      final json = article.toJson();
      expect(json['title'], article.title);
      expect(json['url'], article.url);
      expect((json['source'] as Map)['name'], article.sourceName);
      expect(json['publishedAt'], article.publishedAt.toIso8601String());
    });

    test('copyWith returns updated article without mutating original', () {
      final original = Article.fromJson(sampleJson);
      final updated = original.copyWith(title: 'Updated Title');
      expect(original.title, 'Test Article');
      expect(updated.title, 'Updated Title');
      expect(updated.url, original.url); // unchanged fields preserved
    });

    test('handles nullable fields gracefully', () {
      final noImageJson = Map<String, dynamic>.from(sampleJson)
        ..remove('urlToImage')
        ..remove('author')
        ..remove('description');

      final article = Article.fromJson(noImageJson);
      expect(article.urlToImage, isNull);
      expect(article.author, isNull);
      expect(article.description, isNull);
    });

    test('equality is based on url', () {
      final a1 = Article.fromJson(sampleJson);
      final a2 = Article.fromJson({
        ...sampleJson,
        'title': 'Different Title', // Different title, same url
      });
      expect(a1, equals(a2));
    });
  });
}
