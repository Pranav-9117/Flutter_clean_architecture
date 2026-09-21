# Flutter Clean Architecture — Complete Learning Analysis
### Part 1 of 4: Phases 1–3 (Project Map, Learning Order, Master Roadmap)

> **How to use this document**: Study Part 1 first. Then read Part 2 (Files 1–13), Part 3 (Files 14–27), Part 4 (Phases 5–9). Each part builds on the previous.

---

# PHASE 1 — Complete Project Map

## Full Directory Tree

```text
Flutter_clean_architecture/
├── pubspec.yaml                          ← Project manifest: dependencies, assets, version
├── pubspec.lock                          ← Locked dependency versions (auto-generated)
├── analysis_options.yaml                 ← Dart linter/analyzer rules
├── README.md                             ← Project documentation
├── .gitignore                            ← Git ignore rules
├── .metadata                             ← Flutter tool metadata (auto-generated)
│
├── assets/
│   └── images/                          ← Image assets (currently empty)
│
├── test/
│   └── widget_test.dart                  ← Default Flutter widget test (stale/not updated)
│
├── lib/                                  ← ALL application source code lives here
│   ├── main.dart                         ← Application entry point
│   │
│   ├── app/                              ← App-level configuration (not feature-specific)
│   │   ├── app.dart                      ← Root widget (MyApp)
│   │   ├── router/
│   │   │   ├── route_names.dart          ← String constants for all URL paths
│   │   │   ├── app_router.dart           ← Route definitions + redirect logic
│   │   │   └── app_router_provider.dart  ← Riverpod provider that exposes the router
│   │   └── theme/                        ← (empty — theme not yet implemented)
│   │
│   ├── core/                             ← Shared infrastructure used by all features
│   │   ├── constants/                    ← (empty — constants not yet added)
│   │   ├── errors/                       ← (empty — error classes not yet added)
│   │   ├── network/
│   │   │   ├── dio_client.dart           ← Configured HTTP client (Dio)
│   │   │   ├── api_exception.dart        ← (empty placeholder file)
│   │   │   └── auth_interceptor.dart     ← (empty placeholder file)
│   │   ├── providers/
│   │   │   └── core_providers.dart       ← Riverpod providers for DioClient & TokenStorage
│   │   └── storage/
│   │       └── token_storage.dart        ← Secure token persistence (flutter_secure_storage)
│   │
│   └── features/                         ← One folder per app feature
│       ├── auth/                         ← Authentication feature (full clean architecture)
│       │   ├── data/                     ← Data layer: talks to network/storage
│       │   │   ├── datasources/
│       │   │   │   └── auth_remote_data_source.dart   ← Direct HTTP calls
│       │   │   ├── models/
│       │   │   │   ├── auth_response_model.dart        ← JSON → Dart object (response)
│       │   │   │   ├── login_request_model.dart        ← Dart object → JSON (login)
│       │   │   │   └── register_request_model.dart     ← Dart object → JSON (register)
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart       ← Concrete repository implementation
│       │   ├── domain/                   ← Business logic layer: framework-independent
│       │   │   ├── entities/
│       │   │   │   └── user.dart                       ← Pure business User object
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart            ← Abstract contract (interface)
│       │   │   └── usecases/
│       │   │       ├── login.dart                      ← Login use case
│       │   │       ├── register.dart                   ← Register use case
│       │   │       └── logout.dart                     ← Logout use case
│       │   └── presentation/             ← UI layer: widgets, screens, state
│       │       ├── providers/
│       │       │   ├── auth_notifier.dart              ← AuthState + AuthNotifier
│       │       │   └── auth_providers.dart             ← Wires together full DI chain
│       │       └── screens/
│       │           ├── login_screen.dart               ← Login UI
│       │           └── register_screen.dart            ← Register UI
│       │
│       ├── splash/                       ← Splash/loading feature
│       │   └── presentation/
│       │       ├── providers/            ← (empty — splash uses auth providers directly)
│       │       └── screens/
│       │           └── splash_screen.dart              ← Loading spinner / redirect UI
│       │
│       └── shell/                        ← Authenticated app shell (layout wrapper)
│           ├── presentation/
│           │   └── screens/
│           │       ├── shell_screen.dart               ← Sidebar + content layout
│           │       ├── dashboard_screen.dart           ← Placeholder screen
│           │       ├── users_screen.dart               ← Placeholder screen
│           │       ├── services_screen.dart            ← Placeholder screen
│           │       ├── equipment_screen.dart           ← Placeholder screen
│           │       └── settings_screen.dart            ← Placeholder screen
│           └── widgets/
│               └── app_side_bar.dart                  ← Navigation sidebar widget
```

---

## Architectural Role of Each Directory

| Directory | Architectural Role |
|---|---|
| `lib/` | All Dart source code. Flutter only compiles what is inside here. |
| `lib/app/` | App-wide configuration: root widget, routing, and theming. Nothing feature-specific. |
| `lib/core/` | Shared infrastructure. Any feature can import from `core/`. It has zero knowledge of any feature. |
| `lib/features/` | One sub-folder per product feature. Features do NOT import from each other. |
| `lib/features/auth/` | The only fully implemented feature — all three Clean Architecture layers present. |
| `lib/features/auth/data/` | Knows about HTTP, JSON, models. Communicates with the outside world. |
| `lib/features/auth/domain/` | Pure Dart. No Flutter, no HTTP, no Dio. Contains business rules and contracts. |
| `lib/features/auth/presentation/` | Flutter widgets and Riverpod state management. |
| `lib/features/splash/` | Simple loading screen that reacts to auth state. |
| `lib/features/shell/` | Authenticated-user layout shell (sidebar + dynamic content area). |
| `assets/images/` | Static images bundled with the app (currently empty). |
| `test/` | Automated tests (the existing test is a stale default — not valid for this project). |

---

# PHASE 2 — Correct Learning Order

The order below is derived from the **actual import/dependency graph** of this project.

**Key principle**: If File B imports File A, you must understand File A first.

```
Startup chain:    main.dart → app.dart → app_router_provider.dart → app_router.dart
Auth state chain: auth_notifier.dart → auth_providers.dart → auth_repository_impl.dart
                  → auth_remote_data_source.dart → dio_client.dart
Storage chain:    token_storage.dart ← core_providers.dart ← auth_providers.dart
Domain layer:     user.dart → auth_repository.dart → login.dart / register.dart / logout.dart
Models:           login_request_model.dart / register_request_model.dart → auth_response_model.dart
```

---

# PHASE 3 — Master Learning Roadmap

## File Learning Order Table

| Order | File | Layer | Why This Order | Depends On |
|---|---|---|---|---|
| 1 | `pubspec.yaml` | Config | Understand packages before any code | Nothing |
| 2 | `analysis_options.yaml` | Config | Understand linting rules | Nothing |
| 3 | `lib/main.dart` | Entry Point | Application starts here | pubspec.yaml |
| 4 | `lib/app/app.dart` | App | First widget Flutter builds | main.dart |
| 5 | `lib/app/router/route_names.dart` | Routing | All route strings, referenced everywhere | Nothing |
| 6 | `lib/core/network/dio_client.dart` | Core/Network | HTTP client — needed before any network code | dio package |
| 7 | `lib/core/storage/token_storage.dart` | Core/Storage | Secure token storage — needed before auth | flutter_secure_storage |
| 8 | `lib/core/providers/core_providers.dart` | Core/DI | Exposes DioClient & TokenStorage to Riverpod | Files 6, 7 |
| 9 | `lib/features/auth/domain/entities/user.dart` | Domain | Simplest data object — foundation of auth | Nothing |
| 10 | `lib/features/auth/domain/repositories/auth_repository.dart` | Domain | Abstract contract — must understand before impl | File 9 |
| 11 | `lib/features/auth/domain/usecases/login.dart` | Domain | Use case wrapping login contract | File 10 |
| 12 | `lib/features/auth/domain/usecases/register.dart` | Domain | Use case wrapping register contract | File 10 |
| 13 | `lib/features/auth/domain/usecases/logout.dart` | Domain | Use case wrapping logout contract | File 10 |
| 14 | `lib/features/auth/data/models/login_request_model.dart` | Data | Request serialization | Nothing |
| 15 | `lib/features/auth/data/models/register_request_model.dart` | Data | Request serialization | Nothing |
| 16 | `lib/features/auth/data/models/auth_response_model.dart` | Data | Response deserialization — maps JSON to User entity | File 9 |
| 17 | `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Data | Makes HTTP calls using Dio | Files 6, 14, 15, 16 |
| 18 | `lib/features/auth/data/repositories/auth_repository_impl.dart` | Data | Connects data source + storage → implements contract | Files 7, 10, 17 |
| 19 | `lib/features/auth/presentation/providers/auth_providers.dart` | Presentation/DI | Wires complete dependency chain via Riverpod | Files 8, 11, 12, 13, 18 |
| 20 | `lib/features/auth/presentation/providers/auth_notifier.dart` | Presentation/State | AuthState + state machine for auth lifecycle | Files 8, 19 |
| 21 | `lib/app/router/app_router.dart` | Routing | Route definitions + redirect logic based on auth state | Files 5, 20 |
| 22 | `lib/app/router/app_router_provider.dart` | Routing/DI | Riverpod provider that exposes GoRouter to the app | Files 20, 21 |
| 23 | `lib/features/splash/presentation/screens/splash_screen.dart` | Presentation | First screen shown — reacts to auth loading state | File 20 |
| 24 | `lib/features/auth/presentation/screens/login_screen.dart` | Presentation | Login form — reads/writes auth state | Files 5, 20 |
| 25 | `lib/features/auth/presentation/screens/register_screen.dart` | Presentation | Register form — reads/writes auth state | File 20 |
| 26 | `lib/features/shell/widgets/app_side_bar.dart` | Presentation | Navigation sidebar — triggers logout, navigates routes | Files 5, 20 |
| 27 | `lib/features/shell/presentation/screens/shell_screen.dart` | Presentation | Layout wrapper: sidebar + dynamic content | File 26 |
| 28 | `lib/features/shell/presentation/screens/dashboard_screen.dart` | Presentation | Placeholder screen inside shell | Flutter only |
| 29 | `lib/features/shell/presentation/screens/users_screen.dart` | Presentation | Placeholder screen inside shell | Flutter only |
| 30 | `lib/features/shell/presentation/screens/services_screen.dart` | Presentation | Placeholder screen inside shell | Flutter only |
| 31 | `lib/features/shell/presentation/screens/equipment_screen.dart` | Presentation | Placeholder screen inside shell | Flutter only |
| 32 | `lib/features/shell/presentation/screens/settings_screen.dart` | Presentation | Placeholder screen inside shell | Flutter only |
| 33 | `test/widget_test.dart` | Test | **SKIP / LOW PRIORITY** — stale default test, not updated | — |
| 34 | `lib/core/network/api_exception.dart` | Core | **SKIP / LOW PRIORITY** — empty placeholder file | — |
| 35 | `lib/core/network/auth_interceptor.dart` | Core | **SKIP / LOW PRIORITY** — empty placeholder file | — |
| 36 | `lib/app/theme/` | App | **SKIP / LOW PRIORITY** — empty directory | — |
| 37 | `lib/core/constants/` | Core | **SKIP / LOW PRIORITY** — empty directory | — |
| 38 | `lib/core/errors/` | Core | **SKIP / LOW PRIORITY** — empty directory | — |

---
**→ Continue to Part 2 for File-by-File Analysis (Files 1–13)**
