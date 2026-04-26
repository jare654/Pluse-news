# PulseNews — Flutter News Reader App

> **Track B — NewsAPI | Mobile Application Development | Addis Ababa University**

---

## 1. Student Information

| Field | Details |
|---|---|
| **Name** | *(Your Full Name Here)* |
| **Student ID** | *(Your Student ID Here)* |
| **Track** | B — News Reader App (NewsAPI) |
| **Course** | Mobile Application Development — 4th Year, Semester 2 |
| **Instructor** | Abel Tadesse |

---

## 2. App Description

**PulseNews** is a production-grade Flutter news reader application. It has been expanded into a comprehensive 5-tab ecosystem:

- **Home Screen** — Top global headlines.
- **Explore Tab** — Staggered grid of 7+ news categories (Business, Tech, Science, etc.).
- **Search Tab** — Integrated debounced keyword search across all global sources.
- **Saved Tab** — Persistent article bookmarks using `shared_preferences`.
- **Settings Tab** — Regional configuration, Cache management, and Theme information.

**Key Enhancements:**
- **Persistent Bookmarks** — Save articles for later; bookmarks survive app restarts.
- **Category Feeds** — Deep-dive into specific news sectors.
- **Polished UI** — Staggered animations and improved tab navigation.
- **Centralized Settings** — Regional news filtering moved to a dedicated settings hub.

---

## 3. Architecture

The app follows a strict **3-layer clean architecture**:

```
Presentation (Screens / Widgets)
        ↓  reads state from
State Layer (NewsProvider — ChangeNotifier)
        ↓  calls typed methods on
Service Layer (NewsApiService — owns all HTTP logic)
        ↓  communicates with
External API (newsapi.org)
```

Key patterns:
- `NewsApiService` is the **only** file that imports `package:http`
- All async errors are caught in `NewsProvider` and surfaced as typed messages
- Screens use `Consumer<NewsProvider>` — never call async functions in `build()`

---

## 4. Running the App Locally

### Prerequisites
- Flutter SDK `>=3.0.0`
- A free NewsAPI developer key from [https://newsapi.org/register](https://newsapi.org/register)

### Setup Steps

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/flutter-news-reader.git
cd flutter-news-reader

# 2. Create your .env file from the template
cp assets/.env.example assets/.env

# 3. Open assets/.env and replace the placeholder with your real API key
#    NEWS_API_KEY=your_actual_key_here

# 4. Install dependencies
flutter pub get

# 5. Run the app
flutter run
```

> **⚠ Security:** The `assets/.env` file is excluded from version control via `.gitignore`.  
> **Never commit your actual API key.**

### Building a Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. API Endpoints Used

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 1 | `GET` | `/v2/top-headlines?country={cc}&pageSize=20&page={n}` | Fetch paginated top headlines by country |
| 2 | `GET` | `/v2/everything?q={query}&pageSize=20&sortBy=publishedAt` | Full-text keyword search |

**Base URL:** `https://newsapi.org`  
**Authentication:** `X-Api-Key` header (preferred over query parameter)  
**Timeout:** 10 seconds on all requests  
**URI construction:** `Uri.https()` — no string concatenation  

---

## 6. Known Limitations & Bugs

| # | Limitation | Details |
|---|---|---|
| 1 | **Free-tier article cap** | NewsAPI free tier truncates article content to ~200 characters. The full text is only available via the publisher's URL. |
| 2 | **Free-tier date restriction** | `/v2/everything` on the free tier only returns articles from the past 30 days. |
| 3 | **No `et` (Ethiopia) headlines** | The NewsAPI free tier has limited country support. Ethiopia may return zero results; the app handles this with an empty-state view. |
| 4 | **Image loading failures** | Some publishers serve images behind authentication walls. The app shows a placeholder icon gracefully. |
| 5 | **No dark↔light theme toggle** | Only the dark editorial theme is implemented in this version. |
| 6 | **Cache is in-memory only** | The cache does not survive app restarts. A production implementation would use `shared_preferences` or `hive` for disk persistence. |
| 7 | **Pagination on search** | Search results are limited to 20 articles (single page). Load-more pagination is implemented for headlines only. |

---

## 7. Packages Used

| Package | Version | Purpose |
|---|---|---|
| `http` | `^1.2.1` | All HTTP networking (required by assignment) |
| `flutter_dotenv` | `^5.1.0` | Secure API key management via `.env` |
| `url_launcher` | `^6.2.5` | Open full articles in the system browser |
| `provider` | `^6.1.2` | State management (`ChangeNotifier`) |
| `shimmer` | `^3.0.0` | Skeleton loading animations |
| `cached_network_image` | `^3.3.1` | Efficient article image loading and caching |
| `google_fonts` | `^6.2.1` | Playfair Display + DM Sans typography |
| `intl` | `^0.19.0` | Date formatting |

---

## 8. References & Citations

Any code patterns adapted from external sources are cited inline in the relevant file as `// Ref:` comments.

- [NewsAPI Documentation](https://newsapi.org/docs)
- [Flutter http package docs](https://pub.dev/packages/http)
- [flutter_dotenv usage](https://pub.dev/packages/flutter_dotenv)
- [url_launcher docs](https://pub.dev/packages/url_launcher)
- [AAU MAD Unit 4 lecture notes]

---

*PulseNews — Addis Ababa University · School of IT & Engineering*
