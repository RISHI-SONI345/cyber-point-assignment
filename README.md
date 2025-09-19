Products Explorer – Flutter Take-Home

A small Flutter 3.x / Dart 3.x app that lists products from the dummyjson.com API
 with pagination, search, and two modes: Future and Stream.
Supports infinite scroll, pull-to-refresh, product details, error/empty states, theming, shimmer loaders, and basic testing.

🚀 Run Steps

Clone the repository:

git clone https://github.com/RISHI-SONI345/cyber-point-assignment
cd products_explorer


Install dependencies:

flutter pub get


Run the app:

flutter run


Run tests:

flutter test

🏗️ Architecture Notes

The project follows a layered architecture with light modularity:

data/ → API client (ProductsApi) and repository (ProductsRepository)

domain/ → Models/entities (Product)

presentation/ → Screens (ProductsScreen, ProductDetailScreen, AboutScreen), widgets, and state management

State is managed using Provider:

FutureProductsProvider (for Future mode, ChangeNotifier-based)

StreamProductsController (for Stream mode, StreamController-based)

All network + business logic stays out of widgets.
UI consumes state via context.watch() (Future) or StreamBuilder (Stream).
Infinite scroll is implemented by listening to ScrollController and triggering loadMore() when extentAfter < 300.
Search is client-side filtering with debounce, applied to loaded items only.
Shimmer loaders improve perceived performance, and error/empty states are explicitly handled.
Theming (light/dark) uses ThemeMode.system with ColorScheme.fromSeed.

✅ What’s Done / Not Done
Done

Future mode with pagination, refresh, search, and error handling

Stream mode with StreamController, pagination, refresh, search

Product details screen with hero image and metadata

Empty/loading/error states with retry buttons

Shimmer skeleton loader while loading

Light/Dark theme support

About screen with SHA-256 submission token

Unit test: JSON → model mapping

Widget test: ProductRow renders product data

Not Done

Persistent storage (mode selection not saved between launches)

Advanced pagination edge-cases (e.g., very large dataset stress test)

Integration tests beyond the sample widget test

⏱️ Time Spent

Setup & architecture scaffolding: ~1.5 hrs

Future mode implementation: ~2 hrs

Stream mode implementation: ~2 hrs

Search, pull-to-refresh, infinite scroll: ~1 hr

Error/empty states, shimmer loader, theming: ~1 hr

Tests + README + polish: ~0.5–1 hr

Total: ~7–8 hours (within the 6–8 hr timebox).
