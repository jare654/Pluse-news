# Flutter News Reader App — Architecture & Design Document
### Track B · NewsAPI · Mobile Application Development · Addis Ababa University

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Philosophy](#2-architecture-philosophy)
3. [System Architecture Diagram](#3-system-architecture-diagram)
4. [Folder & File Structure](#4-folder--file-structure)
5. [Layer-by-Layer Design](#5-layer-by-layer-design)
   - 5.1 [Data Layer — Models](#51-data-layer--models)
   - 5.2 [Service Layer — API & Networking](#52-service-layer--api--networking)
   - 5.3 [State Management Layer — Providers](#53-state-management-layer--providers)
   - 5.4 [Presentation Layer — Screens & Widgets](#54-presentation-layer--screens--widgets)
6. [API Contract & Endpoint Specification](#6-api-contract--endpoint-specification)
7. [Error Handling Strategy](#7-error-handling-strategy)
8. [Security Design — API Key Management](#8-security-design--api-key-management)
9. [High-Level UI/UX Design](#9-high-level-uiux-design)
   - 9.1 [Design System & Tokens](#91-design-system--tokens)
   - 9.2 [Screen-by-Screen Wireframes (ASCII)](#92-screen-by-screen-wireframes-ascii)
   - 9.3 [Navigation Flow](#93-navigation-flow)
   - 9.4 [Component Library](#94-component-library)
10. [Async & Lifecycle Patterns](#10-async--lifecycle-patterns)
11. [Dependency Map & pubspec.yaml](#11-dependency-map--pubspecyaml)
12. [Environment Configuration](#12-environment-configuration)
13. [Bonus Feature Designs](#13-bonus-feature-designs)
14. [Git Strategy & Commit Plan](#14-git-strategy--commit-plan)
15. [Testing Strategy](#15-testing-strategy)
16. [Implementation Checklist](#16-implementation-checklist)

---

## 1. Project Overview

| Property | Value |
|---|---|
| **App Name** | PulseNews |
| **Track** | B — News Reader App |
| **API** | [NewsAPI](https://newsapi.org) (Developer Free Tier) |
| **Framework** | Flutter (Dart) |
| **Architecture Pattern** | Layered Clean Architecture (Service + Provider + Presentation) |
| **State Management** | `ChangeNotifier` + `Provider` (with `FutureBuilder` for one-shot fetches) |
| **Min SDK** | Android 21 / iOS 13 |

**Core User Stories:**
- As a user, I can browse top headlines filtered by country so I can read news relevant to me.
- As a user, I can search for any topic across all news sources so I can find specific news quickly.
- As a user, I can read an article's full details and open the original source in a browser.
- As a user, I receive clear feedback when the network is unavailable or slow.

---

## 2. Architecture Philosophy

The application follows a **strict three-layer separation** inspired by Clean Architecture principles, adapted for a Flutter mobile assignment context. The core rule is:

> **Data flows DOWN. Dependencies point INWARD.**

```
Presentation Layer   →   State/Provider Layer   →   Service Layer   →   External API
(knows nothing             (knows service,             (knows only
 about services)            not UI)                     HTTP & models)
```

### Why This Structure?

| Principle | Benefit in This Project |
|---|---|
| **Separation of Concerns** | Screens never import `http`. Services never import Flutter widgets. |
| **Testability** | The service layer can be tested independently by mocking HTTP. |
| **Maintainability** | Changing the API endpoint only touches `lib/services/`. |
| **Assignment Compliance** | Directly satisfies the rubric's "API Service Layer Architecture" (20 marks). |

---

## 3. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APPLICATION                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   PRESENTATION LAYER                          │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐   │  │
│  │  │ HomeScreen  │  │ SearchScreen │  │ ArticleDetail     │   │  │
│  │  │             │  │              │  │ Screen            │   │  │
│  │  │ FutureBuilder│  │ SearchBar +  │  │ Full metadata +   │   │  │
│  │  │ CountryDrop │  │ FutureBuilder│  │ url_launcher      │   │  │
│  │  └──────┬──────┘  └──────┬───────┘  └────────┬──────────┘   │  │
│  └─────────┼───────────────┼──────────────────┼───────────────┘  │
│            │               │                  │                    │
│  ┌─────────▼───────────────▼──────────────────▼───────────────┐  │
│  │                  STATE / PROVIDER LAYER                      │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │              NewsProvider (ChangeNotifier)            │   │  │
│  │  │                                                       │   │  │
│  │  │  selectedCountry: String                              │   │  │
│  │  │  headlines: List<Article>                             │   │  │
│  │  │  searchResults: List<Article>                         │   │  │
│  │  │  isLoading: bool                                      │   │  │
│  │  │  errorMessage: String?                                │   │  │
│  │  │  fetchHeadlines(country) → calls service              │   │  │
│  │  │  searchArticles(query)  → calls service               │   │  │
│  │  └───────────────────────┬──────────────────────────────┘   │  │
│  └──────────────────────────┼───────────────────────────────────┘  │
│                             │                                       │
│  ┌──────────────────────────▼───────────────────────────────────┐  │
│  │                    SERVICE LAYER                              │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │              NewsApiService                           │   │  │
│  │  │                                                       │   │  │
│  │  │  _baseUrl: 'https://newsapi.org'                      │   │  │
│  │  │  _apiKey: loaded from .env                            │   │  │
│  │  │  _timeout: Duration(seconds: 10)                      │   │  │
│  │  │  _headers: {Content-Type, Accept, X-Api-Key}         │   │  │
│  │  │                                                       │   │  │
│  │  │  fetchTopHeadlines(country) → Future<List<Article>>   │   │  │
│  │  │  searchEverything(query)    → Future<List<Article>>   │   │  │
│  │  │  _checkResponse(response)  → throws ApiException      │   │  │
│  │  └───────────────────────┬──────────────────────────────┘   │  │
│  │                          │                                    │  │
│  │  ┌───────────────────────▼──────────────────────────────┐   │  │
│  │  │              api_exception.dart                       │   │  │
│  │  │  class ApiException implements Exception              │   │  │
│  │  │  final int statusCode                                 │   │  │
│  │  │  final String message                                 │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                             │                                       │
│  ┌──────────────────────────▼───────────────────────────────────┐  │
│  │                    DATA / MODEL LAYER                         │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │  Article  (lib/models/article.dart)                   │   │  │
│  │  │  ├── title: String                                    │   │  │
│  │  │  ├── description: String?                             │   │  │
│  │  │  ├── url: String                                      │   │  │
│  │  │  ├── urlToImage: String?                              │   │  │
│  │  │  ├── sourceName: String                               │   │  │
│  │  │  ├── author: String?                                  │   │  │
│  │  │  ├── publishedAt: DateTime                            │   │  │
│  │  │  ├── factory fromJson(Map<String, dynamic>)           │   │  │
│  │  │  ├── Map<String, dynamic> toJson()                    │   │  │
│  │  │  └── Article copyWith({...})                          │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                             │
              ┌──────────────▼──────────────┐
              │       EXTERNAL LAYER        │
              │   NewsAPI  (newsapi.org)     │
              │  ┌──────────────────────┐   │
              │  │ GET /v2/top-headlines │   │
              │  │ GET /v2/everything   │   │
              │  └──────────────────────┘   │
              └─────────────────────────────┘
```

---

## 4. Folder & File Structure

```
flutter_news_reader/
│
├── .env                          ← API key (NEVER commit; in .gitignore)
├── .gitignore
├── pubspec.yaml
├── README.md
│
├── assets/
│   └── .env                      ← Alternative location if using flutter_dotenv asset
│
└── lib/
    ├── main.dart                 ← App entry point, Provider setup, theme config
    │
    ├── config/
    │   ├── app_theme.dart        ← ThemeData, color constants, text styles
    │   └── app_constants.dart    ← Country codes, page sizes, TTL constants
    │
    ├── models/
    │   └── article.dart          ← Article model: fromJson, toJson, copyWith
    │
    ├── services/
    │   ├── api_exception.dart    ← Custom ApiException class
    │   └── news_api_service.dart ← All HTTP logic, no widget imports
    │
    ├── providers/
    │   └── news_provider.dart    ← ChangeNotifier: state, fetchHeadlines, search
    │
    ├── screens/
    │   ├── home_screen.dart      ← Top headlines + country dropdown
    │   ├── search_screen.dart    ← Search bar + results list
    │   └── article_detail_screen.dart ← Full article view + url_launcher
    │
    └── widgets/
        ├── article_card.dart     ← Reusable headline card widget
        ├── error_view.dart       ← Reusable error display + Retry button
        ├── loading_shimmer.dart  ← Shimmer placeholder skeleton
        ├── country_dropdown.dart ← Styled dropdown for country selection
        └── cached_badge.dart     ← (Bonus) 'Cached' indicator chip
```

---

## 5. Layer-by-Layer Design

### 5.1 Data Layer — Models

#### `lib/models/article.dart`

**Responsibility:** Pure Dart class. Represents a single news article. No Flutter imports. No business logic.

```
Article
├── Properties (all final)
│   ├── title        : String           ← required, non-nullable
│   ├── description  : String?          ← nullable — API often returns null
│   ├── url          : String           ← required, used by url_launcher
│   ├── urlToImage   : String?          ← nullable — not all articles have images
│   ├── sourceName   : String           ← extracted from json['source']['name']
│   ├── author       : String?          ← nullable — API sometimes omits
│   └── publishedAt  : DateTime         ← parsed from ISO-8601 string
│
├── factory Article.fromJson(Map<String, dynamic> json)
│   ├── Cast title   : json['title'] as String
│   ├── Cast url     : json['url'] as String
│   ├── Cast source  : (json['source'] as Map<String, dynamic>)['name'] as String
│   ├── Null-safe    : json['description'] as String?
│   ├── Null-safe    : json['urlToImage'] as String?
│   ├── Null-safe    : json['author'] as String?
│   └── DateTime     : DateTime.parse(json['publishedAt'] as String)
│
├── Map<String, dynamic> toJson()
│   └── Returns all fields as a Map (publishedAt → .toIso8601String())
│
└── Article copyWith({String? title, String? description, ...})
    └── Returns new Article with overridden fields
```

**JSON Mapping Reference (NewsAPI response structure):**

```json
{
  "source": { "id": "bbc-news", "name": "BBC News" },
  "author": "Jane Doe",
  "title": "Breaking: Flutter 4 Released",
  "description": "The Flutter team announced...",
  "url": "https://bbc.com/article/123",
  "urlToImage": "https://bbc.com/image.jpg",
  "publishedAt": "2026-04-22T10:30:00Z",
  "content": "Full text (truncated at 200 chars in free tier)"
}
```

**Dart Model Implementation Blueprint:**

```dart
// lib/models/article.dart

class Article {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final String sourceName;
  final String? author;
  final DateTime publishedAt;

  const Article({
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.sourceName,
    this.author,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>;
    return Article(
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String,
      urlToImage: json['urlToImage'] as String?,
      sourceName: source['name'] as String? ?? 'Unknown Source',
      author: json['author'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'url': url,
    'urlToImage': urlToImage,
    'source': {'name': sourceName},
    'author': author,
    'publishedAt': publishedAt.toIso8601String(),
  };

  Article copyWith({
    String? title,
    String? description,
    String? url,
    String? urlToImage,
    String? sourceName,
    String? author,
    DateTime? publishedAt,
  }) => Article(
    title: title ?? this.title,
    description: description ?? this.description,
    url: url ?? this.url,
    urlToImage: urlToImage ?? this.urlToImage,
    sourceName: sourceName ?? this.sourceName,
    author: author ?? this.author,
    publishedAt: publishedAt ?? this.publishedAt,
  );
}
```

---

### 5.2 Service Layer — API & Networking

#### `lib/services/api_exception.dart`

```dart
// lib/services/api_exception.dart

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

#### `lib/services/news_api_service.dart`

**Responsibility:** Owns 100% of HTTP logic. Returns typed Dart objects. Never imported by widgets.

```
NewsApiService
│
├── Private Fields
│   ├── _baseUrl    : 'https://newsapi.org'
│   ├── _apiKey     : loaded from dotenv.env['NEWS_API_KEY']!
│   ├── _timeout    : const Duration(seconds: 10)
│   └── _headers    : Map<String, String> {
│                       'Content-Type': 'application/json',
│                       'Accept': 'application/json',
│                       'X-Api-Key': _apiKey,        ← preferred over query param
│                     }
│
├── Private Methods
│   └── _checkResponse(http.Response response) → void
│       ├── if statusCode == 200 → return (ok)
│       ├── if statusCode == 401 → throw ApiException(401, 'Invalid API Key')
│       ├── if statusCode == 429 → throw ApiException(429, 'Rate limit exceeded')
│       └── else                → throw ApiException(statusCode, 'Server error')
│
├── Public Methods
│   │
│   ├── fetchTopHeadlines(String countryCode) → Future<List<Article>>
│   │   ├── Build URI: Uri.https('newsapi.org', '/v2/top-headlines',
│   │   │              {'country': countryCode, 'pageSize': '20'})
│   │   ├── Call: http.get(uri, headers: _headers)
│   │   │       .timeout(_timeout)
│   │   ├── _checkResponse(response)
│   │   ├── final body = jsonDecode(response.body) as Map<String, dynamic>
│   │   ├── final articles = body['articles'] as List<dynamic>
│   │   └── return articles.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList()
│   │
│   └── searchEverything(String query) → Future<List<Article>>
│       ├── Build URI: Uri.https('newsapi.org', '/v2/everything',
│       │              {'q': query, 'pageSize': '20', 'sortBy': 'publishedAt'})
│       ├── Call: http.get(uri, headers: _headers)
│       │       .timeout(_timeout)
│       ├── _checkResponse(response)
│       └── [same parsing logic]
│
└── Error propagation (NOT caught here — bubbles up to provider)
    ├── SocketException   → no internet
    ├── TimeoutException  → .timeout() triggers this
    ├── ApiException      → from _checkResponse()
    └── FormatException   → from jsonDecode() on malformed body
```

**Full Implementation Blueprint:**

```dart
// lib/services/news_api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/article.dart';
import 'api_exception.dart';

class NewsApiService {
  static const String _baseUrl = 'newsapi.org';
  final String _apiKey = dotenv.env['NEWS_API_KEY']!;
  static const Duration _timeout = Duration(seconds: 10);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Api-Key': _apiKey,
  };

  void _checkResponse(http.Response response) {
    if (response.statusCode == 200) return;
    final Map<String, dynamic>? body =
        jsonDecode(response.body) as Map<String, dynamic>?;
    final apiMessage = body?['message'] as String? ?? 'An error occurred';
    throw ApiException(
      statusCode: response.statusCode,
      message: apiMessage,
    );
  }

  Future<List<Article>> fetchTopHeadlines(String countryCode) async {
    final uri = Uri.https(_baseUrl, '/v2/top-headlines', {
      'country': countryCode,
      'pageSize': '20',
    });
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final articles = body['articles'] as List<dynamic>;
    return articles
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Article>> searchEverything(String query) async {
    final uri = Uri.https(_baseUrl, '/v2/everything', {
      'q': query,
      'pageSize': '20',
      'sortBy': 'publishedAt',
    });
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final articles = body['articles'] as List<dynamic>;
    return articles
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

---

### 5.3 State Management Layer — Providers

#### `lib/providers/news_provider.dart`

**Responsibility:** Business logic, state ownership, error translation. Sits between service and UI.

```
NewsProvider extends ChangeNotifier
│
├── State Fields
│   ├── _service       : NewsApiService (final, injected or internal)
│   ├── _headlines     : List<Article>     (private — exposed via getter)
│   ├── _searchResults : List<Article>     (private — exposed via getter)
│   ├── _isLoading     : bool = false
│   ├── _errorMessage  : String? = null
│   └── _selectedCountry : String = 'us'
│
├── Getters (public read-only view of state)
│   ├── List<Article> get headlines     → _headlines
│   ├── List<Article> get searchResults → _searchResults
│   ├── bool get isLoading              → _isLoading
│   ├── String? get errorMessage        → _errorMessage
│   └── String get selectedCountry     → _selectedCountry
│
├── fetchTopHeadlines(String countryCode) async
│   ├── _isLoading = true; _errorMessage = null; notifyListeners();
│   ├── try:
│   │   ├── _headlines = await _service.fetchTopHeadlines(countryCode)
│   │   └── _selectedCountry = countryCode
│   ├── catch SocketException:
│   │   └── _errorMessage = 'No internet connection. Check your network.'
│   ├── catch TimeoutException:
│   │   └── _errorMessage = 'Request timed out. Please try again.'
│   ├── catch ApiException e:
│   │   └── _errorMessage = 'Server error (${e.statusCode}): ${e.message}'
│   ├── catch FormatException:
│   │   └── _errorMessage = 'Unexpected data format received.'
│   ├── catch Exception e:
│   │   └── _errorMessage = 'An unexpected error occurred: ${e.toString()}'
│   └── finally:
│       └── _isLoading = false; notifyListeners();
│
├── searchArticles(String query) async
│   └── [same pattern as fetchTopHeadlines, writes to _searchResults]
│
└── clearError()
    └── _errorMessage = null; notifyListeners();
```

**Provider Registration in `main.dart`:**

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    ChangeNotifierProvider(
      create: (_) => NewsProvider(NewsApiService()),
      child: const PulseNewsApp(),
    ),
  );
}
```

---

### 5.4 Presentation Layer — Screens & Widgets

#### Screen Responsibilities Summary

| Screen | Data Source | Key Widgets | User Actions |
|---|---|---|---|
| `HomeScreen` | `NewsProvider` via `Consumer` | `CountryDropdown`, `ArticleCard`, `ErrorView`, `LoadingShimmer` | Select country, tap article, pull-to-refresh |
| `SearchScreen` | `FutureBuilder<List<Article>>` | `TextField`, `ArticleCard`, `ErrorView` | Type query, tap result |
| `ArticleDetailScreen` | Passed via `Navigator` route args | `NetworkImage`, `url_launcher` button | Read, open full URL |

#### `lib/screens/home_screen.dart` Design

```
HomeScreen (StatefulWidget)
│
├── initState()
│   └── WidgetsBinding.instance.addPostFrameCallback((_) {
│         context.read<NewsProvider>().fetchTopHeadlines('us');
│       });
│
├── build() → Scaffold
│   ├── AppBar
│   │   ├── Title: 'Top Headlines'
│   │   └── Actions: [SearchIcon → Navigator.push(SearchScreen)]
│   │
│   ├── Body → Consumer<NewsProvider>(
│   │   └── builder: (context, provider, _) {
│   │       if (provider.isLoading) → LoadingShimmer()
│   │       if (provider.errorMessage != null) → ErrorView(
│   │           message: provider.errorMessage!,
│   │           onRetry: () => provider.fetchTopHeadlines(
│   │               provider.selectedCountry))
│   │       if (provider.headlines.isEmpty) → EmptyStateView()
│   │       else → RefreshIndicator(
│   │           onRefresh: () => provider.fetchTopHeadlines(...),
│   │           child: Column(children: [
│   │             CountryDropdown(...),
│   │             Expanded(ListView.builder(
│   │               itemCount: provider.headlines.length,
│   │               itemBuilder: (_, i) => ArticleCard(
│   │                   article: provider.headlines[i],
│   │                   onTap: () → Navigator.push(ArticleDetailScreen)
│   │               ),
│   │             ))
│   │           ])
│   │       )
│   │   }
│   └── )
│
└── No async in build() ✓  |  Provider handles all state ✓
```

#### `lib/screens/search_screen.dart` Design

```
SearchScreen (StatefulWidget)
│
├── State
│   ├── _controller  : TextEditingController
│   ├── _searchFuture: Future<List<Article>>?
│   └── _debounceTimer: Timer?         ← (Bonus: debounce)
│
├── _onQueryChanged(String query)
│   ├── _debounceTimer?.cancel()
│   └── _debounceTimer = Timer(Duration(milliseconds: 400), () {
│         if (query.trim().length >= 2) {
│           setState(() {
│             _searchFuture = context.read<NewsApiService>()
│                               .searchEverything(query.trim());
│           });
│         }
│       });
│
├── build() → Scaffold
│   ├── AppBar with embedded TextField (search UI)
│   │
│   └── Body → FutureBuilder<List<Article>>(
│       future: _searchFuture,
│       builder: (context, snapshot) {
│         // ConnectionState.none → EmptySearchPrompt ('Search for any topic')
│         // ConnectionState.waiting → CircularProgressIndicator (centre)
│         // snapshot.hasError → ErrorView(message, onRetry: re-search)
│         // snapshot.data!.isEmpty → NoResultsView()
│         // snapshot.hasData → ListView of ArticleCard widgets
│       }
│     )
└── )
```

#### `lib/screens/article_detail_screen.dart` Design

```
ArticleDetailScreen (StatelessWidget)
│
├── Route argument: Article article (passed via Navigator)
│
└── build() → Scaffold
    ├── AppBar: article.sourceName
    └── Body → SingleChildScrollView
        ├── Hero image (urlToImage) or placeholder
        ├── Padding → Column
        │   ├── Source chip + date formatted (e.g. '22 Apr 2026')
        │   ├── Title (large, bold)
        │   ├── Author (if not null)
        │   ├── Divider
        │   ├── Description (if not null)
        │   └── ElevatedButton.icon(
        │           icon: Icon(Icons.open_in_new),
        │           label: Text('Read Full Article'),
        │           onPressed: () async {
        │             final uri = Uri.parse(article.url);
        │             if (await canLaunchUrl(uri)) launchUrl(uri,
        │                 mode: LaunchMode.externalApplication);
        │           }
        │       )
        └── )
```

---

## 6. API Contract & Endpoint Specification

### Base URL
```
https://newsapi.org
```

### Authentication
```
Header: X-Api-Key: <YOUR_KEY>
```
> ⚠ Never pass the key as a query parameter (`?apiKey=`) in production — it exposes the key in server logs and browser history. Use the `X-Api-Key` header.

### Endpoint 1 — Top Headlines

```
GET /v2/top-headlines

Query Parameters:
  country   : string  (required) — ISO 3166-1 alpha-2 code e.g. 'us', 'gb'
  pageSize  : int     (optional) — max 100; use 20 for free tier

Response shape:
{
  "status": "ok",
  "totalResults": 38,
  "articles": [ <Article>, ... ]
}

Error shapes:
  401 → { "status": "error", "code": "apiKeyInvalid", "message": "..." }
  429 → { "status": "error", "code": "rateLimited", "message": "..." }
```

### Endpoint 2 — Search Everything

```
GET /v2/everything

Query Parameters:
  q        : string  (required) — keyword(s)
  pageSize : int     — max 100; use 20
  sortBy   : string  — 'publishedAt' | 'relevancy' | 'popularity'

Response shape: same as top-headlines

Notes:
  - Free tier restricts to articles from last 30 days
  - Minimum q length: 2 characters
```

### Country Codes Reference (minimum 5 required)

| Display Name | Code |
|---|---|
| United States | `us` |
| United Kingdom | `gb` |
| Germany | `de` |
| France | `fr` |
| Australia | `au` |
| India | `in` |
| Canada | `ca` |
| Ethiopia | `et` |

---

## 7. Error Handling Strategy

### Error Flow Diagram

```
           User Action
               │
        ┌──────▼──────┐
        │  Provider   │
        │  calls      │
        │  Service    │
        └──────┬──────┘
               │
        ┌──────▼──────────────────────────────────────────────────────┐
        │                    try { await service.fetch() }            │
        │                                                             │
        │  catch (SocketException)   → 'No internet connection'       │
        │  catch (TimeoutException)  → 'Request timed out'            │
        │  catch (ApiException e)    → 'Server error (${e.statusCode})│
        │  catch (FormatException)   → 'Unexpected data format'       │
        │  catch (Exception e)       → 'Unexpected error: ${e}'       │
        │                                                             │
        │  finally: _isLoading = false; notifyListeners()             │
        └──────┬──────────────────────────────────────────────────────┘
               │
        ┌──────▼──────┐
        │  Provider   │
        │  sets       │
        │  _error     │
        │  Message    │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  Consumer   │
        │  in Screen  │
        │  renders    │
        │  ErrorView  │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  User taps  │
        │  Retry btn  │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  Provider   │
        │  clears err │
        │  & re-fetch │
        └─────────────┘
```

### Complete Error Matrix

| Exception Class | When Thrown | User Message | Retry Available |
|---|---|---|---|
| `SocketException` | Device has no network | "No internet connection. Check your network and try again." | ✅ Yes |
| `TimeoutException` | Request took > 10 seconds | "Request timed out. The server may be busy. Please try again." | ✅ Yes |
| `ApiException(401)` | Bad API key | "API key invalid. Please check your configuration." | ❌ No |
| `ApiException(429)` | Rate limited | "Too many requests. Please wait a moment and try again." | ✅ Yes |
| `ApiException(5xx)` | Server error | "Server error (${code}). Please try again later." | ✅ Yes |
| `FormatException` | Malformed JSON | "Unexpected data format received from server." | ✅ Yes |
| `Exception` | Catch-all | "An unexpected error occurred: ${e.message}" | ✅ Yes |

### `ErrorView` Widget Specification

```
ErrorView (StatelessWidget)
├── Parameters
│   ├── message   : String
│   ├── onRetry   : VoidCallback?   ← null = no retry button shown
│   └── icon      : IconData?       ← defaults to Icons.wifi_off
│
└── Layout
    └── Center → Column(mainAxisSize: min)
        ├── Icon(icon, size: 64, color: theme.error)
        ├── SizedBox(height: 16)
        ├── Text(message, textAlign: center, style: bodyLarge)
        ├── SizedBox(height: 24)
        └── if onRetry != null:
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                onPressed: onRetry,
              )
```

---

## 8. Security Design — API Key Management

### Setup Steps

```
Step 1: Create assets/.env  (never commit this file)
─────────────────────────────────────────────────
NEWS_API_KEY=your_actual_key_here

Step 2: Add to .gitignore
─────────────────────────────────────────────────
.env
assets/.env
*.env

Step 3: Register in pubspec.yaml
─────────────────────────────────────────────────
flutter:
  assets:
    - assets/.env

Step 4: Load in main.dart BEFORE runApp()
─────────────────────────────────────────────────
await dotenv.load(fileName: 'assets/.env');

Step 5: Access in service
─────────────────────────────────────────────────
final String _apiKey = dotenv.env['NEWS_API_KEY']!;
// The ! will throw a StateError on startup if key is missing
// This is intentional — fail fast, fail loud.
```

### Key Exposure Prevention Checklist

```
☐  .env is in .gitignore BEFORE first commit
☐  GitHub repo scanned with: git log --all --full-history -- "*.env"
☐  Key is NOT in any Dart string literal
☐  Key is NOT in pubspec.yaml
☐  Key is NOT in any test files
☐  README.md instructs how to set up .env (not what the key is)
☐  CI/CD (if any) uses environment secrets, not the file
```

---

## 9. High-Level UI/UX Design

### 9.1 Design System & Tokens

#### Color Palette

```
Primary:     #0A0F1E  (Deep Navy — AppBar, key elements)
Accent:      #E63946  (Signal Red — error states, CTAs)
Surface:     #1A2035  (Card backgrounds in dark mode)
Background:  #F8F9FA  (Light mode background)
TextPrimary: #0D1117  (Headlines, primary text)
TextSecondary: #6C757D (Captions, metadata)
Success:     #2DC653  (Cached badge)
Border:      #DEE2E6  (Dividers, card outlines)
```

#### Typography Scale

```
Display/Headline (H1): 28sp, FontWeight.w700, letterSpacing: -0.5
Card Title        (H2): 18sp, FontWeight.w600, letterSpacing: -0.2
Section Label     (H3): 14sp, FontWeight.w600, letterSpacing: 0.5, UPPERCASE
Body Text              : 15sp, FontWeight.w400, height: 1.6
Caption/Metadata       : 12sp, FontWeight.w400, TextSecondary color
Button Text            : 14sp, FontWeight.w600, letterSpacing: 0.3
```

#### Spacing System (8pt grid)

```
xs  =  4dp
sm  =  8dp
md  = 16dp
lg  = 24dp
xl  = 32dp
xxl = 48dp
```

#### Border Radius

```
Card     : 12dp
Button   : 8dp
Chip     : 20dp (pill)
Image    : 8dp (top corners only on card)
```

---

### 9.2 Screen-by-Screen Wireframes (ASCII)

#### Screen 1 — Home Screen

```
┌─────────────────────────────────────┐
│  ●●●  9:41 AM              ▲ ● ■   │  ← Status bar
├─────────────────────────────────────┤
│ ██ PulseNews          [🔍]  [⋮]    │  ← AppBar (navy)
├─────────────────────────────────────┤
│                                     │
│  ┌─ Country ────────────────────┐   │
│  │  🌍 United States        ▼   │   │  ← CountryDropdown (5+ options)
│  └──────────────────────────────┘   │
│                                     │
│  TOP HEADLINES  •  38 articles      │  ← Section label + count
│                                     │
│  ┌──────────────────────────────┐   │
│  │ ████████████  [Image 16:9]   │   │
│  │                              │   │
│  │ BBC News  •  2 hours ago     │   │  ← ArticleCard
│  │ Flutter 4 Released with Major│   │
│  │ Performance Improvements...  │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ ████████████  [Image 16:9]   │   │
│  │                              │   │
│  │ Reuters  •  4 hours ago      │   │  ← ArticleCard
│  │ Global Tech Summit Opens     │   │
│  │ in Addis Ababa This Week...  │   │
│  └──────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ [No image placeholder]  📰  │   │
│  │                              │   │
│  │ TechCrunch  •  6 hours ago   │   │  ← Card without image
│  │ AI Startup Raises $200M in   │   │
│  │ Series B Funding Round       │   │
│  └──────────────────────────────┘   │
│                                     │
│         ↕ Scrollable list           │
└─────────────────────────────────────┘

LOADING STATE:
┌─────────────────────────────────────┐
│ ██ PulseNews          [🔍]  [⋮]    │
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐   │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   │
│  │ ░░░░░░░░░░   SHIMMER     ░░░│   │  ← LoadingShimmer skeleton cards
│  │ ░░░░░  ░░░░░░░░░░░░░░░░░░░░░│   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘

ERROR STATE:
┌─────────────────────────────────────┐
│ ██ PulseNews          [🔍]  [⋮]    │
├─────────────────────────────────────┤
│                                     │
│              📡                     │
│                                     │
│       No internet connection.       │  ← ErrorView widget
│    Check your network and try       │
│              again.                 │
│                                     │
│         ┌─────────────┐             │
│         │  ↺  Retry   │             │  ← Retry button (accent red)
│         └─────────────┘             │
│                                     │
└─────────────────────────────────────┘
```

#### Screen 2 — Search Screen

```
┌─────────────────────────────────────┐
│  ●●●  9:41 AM              ▲ ● ■   │
├─────────────────────────────────────┤
│ ← │ 🔍 Search news...      │  [✕]  │  ← Embedded TextField in AppBar
├─────────────────────────────────────┤
│                                     │

INITIAL STATE (no query typed):
│          🔍                         │
│                                     │
│       Search for any topic          │  ← Empty prompt illustration
│    across all global sources        │
│                                     │

TYPING STATE (debounce active):
│  ┌──────────────────────────────┐   │
│  │  ◌  Searching...            │   │  ← Centred CircularProgressIndicator
│  └──────────────────────────────┘   │

RESULTS STATE:
│  Results for "flutter"  •  20       │
│                                     │
│  ┌──────────────────────────────┐   │
│  │ [Img]  Medium  •  1 day ago  │   │
│  │ Building Apps with Flutter   │   │  ← Compact card layout for search
│  │ and Dart — A Practical...    │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ [Img]  Dev.to  •  3 days ago │   │
│  │ Flutter State Management     │   │
│  │ Guide for 2026...            │   │
│  └──────────────────────────────┘   │
│                                     │

NO RESULTS STATE:
│            🔎                       │
│     No results found for            │
│       "xyznonexistent"              │
│   Try a different search term       │
└─────────────────────────────────────┘
```

#### Screen 3 — Article Detail Screen

```
┌─────────────────────────────────────┐
│  ●●●  9:41 AM              ▲ ● ■   │
├─────────────────────────────────────┤
│ ←   BBC News                   [↗] │  ← AppBar: source name + share icon
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  │     HERO IMAGE (16:9)        │   │  ← NetworkImage with shimmer fallback
│  │     CachedNetworkImage       │   │
│  │                              │   │
│  └──────────────────────────────┘   │
│                                     │
│  Padding(16dp)                      │
│  ┌──────────────────────────────┐   │
│  │ [BBC News]  •  22 Apr 2026   │   │  ← Source chip + formatted date
│  │                              │   │
│  │ Flutter 4 Released with      │   │
│  │ Major Performance and        │   │  ← Title (large, bold, multiline)
│  │ Developer Experience Gains   │   │
│  │                              │   │
│  │ By John Smith                │   │  ← Author (if available)
│  │ ─────────────────────────── │   │  ← Divider
│  │                              │   │
│  │ The Flutter team today       │   │
│  │ announced the release of     │   │  ← Description paragraph
│  │ Flutter 4, bringing major    │   │
│  │ improvements to performance  │   │
│  │ and the developer toolchain. │   │
│  │ The new version introduces...│   │
│  │                              │   │
│  │ ┌──────────────────────────┐ │   │
│  │ │ ↗  Read Full Article     │ │   │  ← Primary CTA button (accent red)
│  │ └──────────────────────────┘ │   │
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

### 9.3 Navigation Flow

```
                    ┌─────────────────┐
                    │   HomeScreen    │ ← App entry point
                    │  (Top Headlines)│
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │                             │
              ▼                             ▼
   [Tap article card]              [Tap 🔍 in AppBar]
              │                             │
   ┌──────────────────┐         ┌──────────────────────┐
   │ ArticleDetail    │         │   SearchScreen        │
   │ Screen           │         │   (Search Everything) │
   │                  │         └──────────┬────────────┘
   │ [Read Full       │                    │
   │  Article] →      │         [Tap result card]
   │ External Browser │                    │
   └──────────────────┘         ┌──────────▼────────────┐
                                 │ ArticleDetail Screen  │
                                 │ (from search result)  │
                                 └───────────────────────┘

Navigation method: Navigator.push (material page route)
Back navigation: Android back button + AppBar leading ← arrow
Route passing: Article object passed as constructor argument
```

---

### 9.4 Component Library

#### `ArticleCard` Widget

```
ArticleCard (StatelessWidget)
├── Parameters
│   ├── article : Article
│   └── onTap   : VoidCallback
│
└── Layout: Card → InkWell(onTap)
    └── Column
        ├── if article.urlToImage != null:
        │     ClipRRect(borderRadius top 12dp)
        │     → Image.network(urlToImage,
        │         height: 200, fit: BoxFit.cover,
        │         loadingBuilder: shimmer,
        │         errorBuilder: placeholder icon)
        │
        └── Padding(12dp) → Column
            ├── Row
            │   ├── Text(sourceName, style: caption, color: accent)
            │   ├── Spacer
            │   └── Text(timeAgo(publishedAt), style: caption)
            ├── SizedBox(8)
            ├── Text(title, style: cardTitle, maxLines: 3,
            │         overflow: TextOverflow.ellipsis)
            └── if description != null:
                  SizedBox(6)
                  Text(description!, style: body, maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       color: textSecondary)
```

#### `LoadingShimmer` Widget

```
LoadingShimmer (StatelessWidget)
└── ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) → ShimmerCard()
    )

ShimmerCard:
└── Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column [
        Container(height: 200, color: white),  ← image placeholder
        Padding → Column [
          Container(height: 12, width: 80),    ← source placeholder
          Container(height: 18, width: double.infinity),  ← title line 1
          Container(height: 18, width: 200),   ← title line 2
        ]
      ]
    )
```

#### `CountryDropdown` Widget

```
CountryDropdown (StatelessWidget)
├── Parameters
│   ├── selected : String (country code)
│   └── onChanged: ValueChanged<String>
│
├── Data: const List<({String code, String name, String flag})> _countries
│   e.g. (code: 'us', name: 'United States', flag: '🇺🇸')
│
└── Layout: DropdownButtonFormField<String>
    ├── value: selected
    ├── decoration: InputDecoration(prefixIcon: 🌍, border: OutlineInputBorder)
    ├── items: _countries.map((c) →
    │     DropdownMenuItem(value: c.code, child: Text('${c.flag} ${c.name}'))
    │   ).toList()
    └── onChanged: (val) { if (val != null) onChanged(val); }
```

---

## 10. Async & Lifecycle Patterns

### Rule: No async in `build()`

```dart
// ❌ WRONG — DO NOT DO THIS
Widget build(BuildContext context) {
  fetchData(); // async call inside build — called on every rebuild
  return ...;
}

// ✅ CORRECT — Call in initState via postFrameCallback
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<NewsProvider>().fetchTopHeadlines('us');
  });
}
```

### Rule: `mounted` check after every `await`

```dart
// In any StatefulWidget method:
Future<void> _loadData() async {
  final result = await someAsyncOperation();
  if (!mounted) return;  // ← REQUIRED: widget may have been disposed
  setState(() { _data = result; });
}
```

### `FutureBuilder` — All 4 States (SearchScreen)

```dart
FutureBuilder<List<Article>>(
  future: _searchFuture,
  builder: (context, snapshot) {
    // State 1: No future yet (initial state — user hasn't searched)
    if (snapshot.connectionState == ConnectionState.none) {
      return const EmptySearchPromptView();
    }

    // State 2: Waiting (loading)
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    // State 3: Error
    if (snapshot.hasError) {
      return ErrorView(
        message: _friendlyError(snapshot.error!),
        onRetry: () => setState(() {
          _searchFuture = _service.searchEverything(_controller.text);
        }),
      );
    }

    // State 4: Data (may be empty list)
    final articles = snapshot.data ?? [];
    if (articles.isEmpty) return const NoResultsView();
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (_, i) => ArticleCard(
        article: articles[i],
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(article: articles[i]),
        )),
      ),
    );
  },
)
```

---

## 11. Dependency Map & pubspec.yaml

```yaml
# pubspec.yaml

name: flutter_news_reader
description: PulseNews — A News Reader App using NewsAPI

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Networking
  http: ^1.2.1                    # REQUIRED by assignment — all HTTP calls

  # Environment / Security
  flutter_dotenv: ^5.1.0          # Load .env for API key

  # External URLs
  url_launcher: ^6.2.5            # Open full article in browser

  # State Management
  provider: ^6.1.2                # ChangeNotifier + Consumer

  # UI / UX
  shimmer: ^3.0.0                 # Loading skeleton animations
  cached_network_image: ^3.3.1    # Cache article images

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  assets:
    - assets/.env                 # Loaded by flutter_dotenv
```

### Dependency Justification

| Package | Reason | Required? |
|---|---|---|
| `http` | Assignment mandates this package | ✅ Mandatory |
| `flutter_dotenv` | Secure API key loading — required by rubric | ✅ Mandatory |
| `url_launcher` | 'Read Full Article' button — required by spec | ✅ Mandatory |
| `provider` | Clean state management for `NewsProvider` | ✅ Recommended |
| `shimmer` | Professional loading skeleton (UI marks) | 🔵 Strongly advised |
| `cached_network_image` | Performance for image-heavy list | 🔵 Strongly advised |

---

## 12. Environment Configuration

### `.env` file (in `.gitignore`)
```
NEWS_API_KEY=abc123youractualkeyhere
```

### `.gitignore` (critical entries)
```
# Flutter
.dart_tool/
build/
*.iml

# Environment — CRITICAL
.env
assets/.env
*.env
```

### `lib/config/app_constants.dart`
```dart
class AppConstants {
  // Country options for dropdown (minimum 5 required)
  static const List<({String code, String name, String flag})> countries = [
    (code: 'us', name: 'United States', flag: '🇺🇸'),
    (code: 'gb', name: 'United Kingdom', flag: '🇬🇧'),
    (code: 'de', name: 'Germany',        flag: '🇩🇪'),
    (code: 'fr', name: 'France',         flag: '🇫🇷'),
    (code: 'au', name: 'Australia',      flag: '🇦🇺'),
    (code: 'in', name: 'India',          flag: '🇮🇳'),
    (code: 'ca', name: 'Canada',         flag: '🇨🇦'),
    (code: 'et', name: 'Ethiopia',       flag: '🇪🇹'),
  ];

  // API
  static const int pageSize = 20;

  // Bonus: Cache TTL
  static const Duration cacheTtl = Duration(minutes: 5);

  // Bonus: Search debounce delay
  static const Duration debounceDelay = Duration(milliseconds: 400);
}
```

---

## 13. Bonus Feature Designs

### Bonus 1: Search Debouncing (+5 marks)

```
Pattern: Timer-based debounce in SearchScreen

State:
  Timer? _debounceTimer;

_onSearchChanged(String query):
  1. _debounceTimer?.cancel()
  2. if query.length < 2: clear results, return
  3. _debounceTimer = Timer(AppConstants.debounceDelay, () {
       setState(() {
         _searchFuture = _service.searchEverything(query.trim());
       });
     });

UI indication:
  Show small CircularProgressIndicator in TextField suffix
  while timer is active (use separate _isDebouncing bool state)
```

### Bonus 2: In-Memory Caching with TTL (+5 marks)

```
Cache model (in NewsApiService or separate CacheService):

class _CacheEntry {
  final List<Article> data;
  final DateTime expiresAt;
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

Map<String, _CacheEntry> _cache = {};

fetchTopHeadlines(countryCode):
  1. Check _cache[countryCode]?.isValid
  2. If valid: return cached data (instant), then refresh in background
  3. If invalid: fetch from API, store in cache with TTL, return fresh data

UI badge: Show 'CACHED' chip in AppBar when data is from cache
Chip: Container(color: Colors.green, child: Text('● CACHED', style: caption))
Background refresh: Future.microtask(() => _refreshInBackground(code))
```

### Bonus 3: Pagination / Load More (+5 marks)

```
State additions in NewsProvider:
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalResults = 0;

fetchMoreHeadlines(String countryCode):
  URI adds: 'page': (_currentPage + 1).toString()
  Appends to _headlines (not replaces)
  _hasMore = _headlines.length < _totalResults

UI: Add at bottom of ListView:
  if (_hasMore):
    ElevatedButton('Load More', onPressed: provider.fetchMoreHeadlines)
  else:
    Text('You've reached the end', style: caption)
```

---

## 14. Git Strategy & Commit Plan

### Repository Setup

```bash
# Repository name: flutter-news-reader  (or: pulse-news-flutter)
# Visibility: PUBLIC

git init
echo "assets/.env" >> .gitignore
echo ".env" >> .gitignore
git add .gitignore
git commit -m "chore: initialise project and add .gitignore with .env exclusion"
```

### Recommended Commit Sequence (minimum 5 meaningful commits)

| # | Commit Message | Files Changed |
|---|---|---|
| 1 | `chore: initialise Flutter project and configure .gitignore` | `.gitignore`, `pubspec.yaml` |
| 2 | `feat: add Article model with fromJson, toJson, and copyWith` | `lib/models/article.dart` |
| 3 | `feat: implement NewsApiService with all endpoints and error handling` | `lib/services/news_api_service.dart`, `lib/services/api_exception.dart` |
| 4 | `feat: add NewsProvider with ChangeNotifier and full error handling` | `lib/providers/news_provider.dart` |
| 5 | `feat: implement HomeScreen with FutureBuilder and country dropdown` | `lib/screens/home_screen.dart`, `lib/widgets/` |
| 6 | `feat: implement SearchScreen with FutureBuilder and all 4 states` | `lib/screens/search_screen.dart` |
| 7 | `feat: implement ArticleDetailScreen with url_launcher integration` | `lib/screens/article_detail_screen.dart` |
| 8 | `feat: add ErrorView and LoadingShimmer reusable widgets` | `lib/widgets/error_view.dart`, `lib/widgets/loading_shimmer.dart` |
| 9 | `feat(bonus): add search debouncing with 400ms timer` | `lib/screens/search_screen.dart` |
| 10 | `docs: complete README with setup instructions and endpoint list` | `README.md` |

---

## 15. Testing Strategy

> Testing is not required by the rubric but demonstrates professionalism.

### Manual Test Scenarios

| Test | Steps | Expected Result |
|---|---|---|
| **Happy path — Headlines** | Open app, select 'United States' | Articles load within 10 seconds |
| **Country switch** | Change dropdown to 'Germany' | New headlines load for Germany |
| **Search — results** | Tap 🔍, type 'technology' | List of articles appears |
| **Search — no results** | Search for 'zzzzzz123xyz' | "No results" message shown |
| **Detail navigation** | Tap any article card | Detail screen opens with correct data |
| **External link** | Tap 'Read Full Article' | Browser opens article URL |
| **No internet** | Enable Airplane Mode, tap Retry | Error message + Retry button shown |
| **Retry works** | Enable internet, tap Retry | Data loads successfully |
| **Timeout** | Throttle network to 2G, open app | Timeout error after 10 seconds |
| **Back navigation** | Press back from detail → from search | Returns to correct previous screen |

---

## 16. Implementation Checklist

### Phase 1 — Foundation

```
☐  Flutter project created (flutter create flutter_news_reader)
☐  pubspec.yaml updated with all dependencies
☐  flutter pub get executed successfully
☐  assets/.env created and populated with API key
☐  .gitignore includes *.env and assets/.env
☐  First commit made
```

### Phase 2 — Data & Service Layer

```
☐  lib/models/article.dart — Article class with all 7 fields final
☐  Article.fromJson() casts all fields explicitly (no dynamic)
☐  Article.toJson() returns complete Map<String, dynamic>
☐  Article.copyWith() returns new instance with overrides
☐  lib/services/api_exception.dart — ApiException with statusCode + message
☐  lib/services/news_api_service.dart — NewsApiService class
☐  _baseUrl, _apiKey, _timeout, _headers all declared as private fields
☐  _checkResponse() throws ApiException for non-200
☐  fetchTopHeadlines() uses Uri.https() (no string concat)
☐  searchEverything() uses Uri.https() (no string concat)
☐  Both methods have .timeout(_timeout) applied
☐  Both methods return typed Future<List<Article>> (not dynamic)
☐  NO widget imports in news_api_service.dart
```

### Phase 3 — State Layer

```
☐  lib/providers/news_provider.dart — NewsProvider extends ChangeNotifier
☐  All 5 error types caught (Socket, Timeout, Api, Format, generic)
☐  Each catch sets a user-friendly _errorMessage string
☐  finally block: _isLoading = false + notifyListeners()
☐  Provider registered in main.dart with ChangeNotifierProvider
☐  dotenv.load() called before runApp() in main()
```

### Phase 4 — Presentation Layer

```
☐  lib/screens/home_screen.dart — StatefulWidget
☐  HomeScreen uses initState() + postFrameCallback (no async in build)
☐  HomeScreen uses Consumer<NewsProvider> (not read/watch in build body)
☐  Loading state shows LoadingShimmer (not just CircularProgressIndicator)
☐  Error state shows ErrorView with Retry button
☐  Retry button calls provider.fetchTopHeadlines(selectedCountry)
☐  CountryDropdown has minimum 5 countries
☐  lib/screens/search_screen.dart — FutureBuilder with ALL 4 states
☐  FutureBuilder handles: none, waiting, error, empty data, data
☐  lib/screens/article_detail_screen.dart — url_launcher integrated
☐  url_launcher canLaunchUrl() checked before launchUrl()
☐  lib/widgets/article_card.dart — reusable, handles null urlToImage
☐  lib/widgets/error_view.dart — reusable, Retry is optional parameter
☐  lib/widgets/loading_shimmer.dart — uses shimmer package
```

### Phase 5 — Quality & Submission

```
☐  No http imports in any screen or widget file
☐  All model fields are final
☐  const used on all possible widgets and constructors
☐  All files named in snake_case
☐  Folder structure matches spec exactly
☐  GitHub repo is PUBLIC
☐  At least 5 meaningful commits with descriptive messages
☐  No API key in any committed file (check with git log)
☐  README.md contains all 6 required items
☐  Screen recording: loading ✓, search ✓, detail ✓, error ✓, retry ✓
☐  Google Classroom submission submitted
```

---

*Document prepared for: Mobile Application Development — Unit 4 Assignment, Track B*
*Addis Ababa University · School of IT & Engineering · 4th Year, Semester 2*
*Architecture Author: Student Implementation Reference*
