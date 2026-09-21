# Flutter Clean Architecture — Complete Learning Analysis
### Part 4 of 4: Phases 5–9 (Architecture, Patterns, Redundancies, Final Checklist)

---

# PHASE 5 — Connect the Files (Complete Architecture as One System)

## Application Startup Flow

```
Device starts app
     ↓
main() runs
     ↓
runApp(ProviderScope(child: MyApp()))
     ↓
ProviderScope initializes the Riverpod container
     ↓
MyApp.build() runs
     ↓
ref.watch(appRouterProvider) evaluated
     ↓
authProvider created → AuthNotifier.build() called
     ↓
Initial AuthState: { isLoading: true, isAuthenticated: false }
     ↓
_checkInitialAuth() fires in background (unawaited)
     ↓
GoRouter starts at '/' (splash route)
     ↓
Redirect: isLoading=true → stay on splash (return null)
     ↓
SplashScreen renders: CircularProgressIndicator
     ↓
_checkInitialAuth() reads token from secure storage
     ↓
Token found?   YES → isAuthenticated: true
               NO  → isAuthenticated: false
     ↓
AuthState updates: { isLoading: false, isAuthenticated: true/false }
     ↓
authProvider change → appRouterProvider rebuilds → router.refresh()
     ↓
Redirect re-runs:
  isAuthenticated: true  → navigate to /dashboard
  isAuthenticated: false → navigate to /login
```

---

## Authentication Flow (Login)

```
User fills login form
     ↓
"Sign in" button pressed
     ↓
ref.read(authProvider.notifier).login(email, password)
     ↓
AuthNotifier.login():
  state = { isLoading: true }            ← spinner appears, button disabled
     ↓
ref.read(loginUseCaseProvider)(email, password)
     ↓
Login.call(email, password)
     ↓
AuthRepository.login(email, password)   ← abstract contract
     ↓
AuthRepositoryImpl.login(email, password)
  → Creates LoginRequestModel(email, password)
     ↓
AuthRemoteDataSourceImpl.login(LoginRequestModel)
     ↓
DioClient.dio.post(
  '/auth/login',
  data: { "username": email, "password": password }
)
     ↓
HTTP POST → https://dummyjson.com/auth/login
     ↓
Server returns JSON:
  { "accessToken": "...", "refreshToken": "...", "id": 1, "firstName": "Emily", ... }
     ↓
AuthResponseModel.fromJson(json):
  → Constructs User(id, name, email)
  → Constructs AuthResponseModel(accessToken, refreshToken, user)
     ↓
AuthRepositoryImpl._saveTokens():
  tokenStorage.saveAccessToken("...")   ← writes to device keychain
  tokenStorage.saveRefreshToken("...")
     ↓
AuthNotifier:
  state = { isLoading: false, isAuthenticated: true }
     ↓
All ref.watch(authProvider) listeners notified
     ↓
appRouterProvider rebuilds → router.refresh()
     ↓
Redirect: authenticated user on /login page → navigate to /dashboard
     ↓
ShellRoute + ShellScreen + DashboardScreen rendered
     ↓
User sees the dashboard with sidebar
```

---

## Logout Flow

```
User taps "Logout" in sidebar (app_side_bar.dart)
     ↓
ref.read(authProvider.notifier).logout()
     ↓
AuthNotifier.logout():
  state = { isLoading: true, isAuthenticated: true }
     ↓
ref.read(logoutUseCaseProvider)()
     ↓
Logout.call()
     ↓
AuthRepositoryImpl.logout():
  remoteDataSource.logout()       ← HTTP POST /auth/logout (errors silently ignored)
  tokenStorage.clear()            ← DELETES tokens from keychain
     ↓
AuthNotifier:
  state = { isLoading: false, isAuthenticated: false }
     ↓
appRouterProvider rebuilds → router.refresh()
     ↓
Redirect: not authenticated → navigate to /login
     ↓
LoginScreen rendered
```

---

## Navigation Flow (within authenticated shell)

```
User taps "Users" in sidebar
     ↓
context.go(RouteNames.users)   → navigate to '/users'
     ↓
GoRouter evaluates redirect:
  isLoading: false, isAuthenticated: true
  not on splash or auth page
  → return null (proceed as requested)
     ↓
ShellRoute matches → ShellScreen persists in the widget tree
     ↓
GoRoute('/users') matches → UsersScreen() injected as child
     ↓
ShellScreen renders:
  Row(AppSideBar(), Expanded(UsersScreen()))
     ↓
AppSideBar re-reads GoRouterState:
  curLocation = '/users'
  "Users" ListTile → selected = true (highlighted)
```

---

## Data Flow (API Response → UI)

```
HTTP Response (raw bytes)
     ↓
Dio parses JSON → Map<String, dynamic>
     ↓
AuthResponseModel.fromJson(map)
  → Constructs User entity (id, name, email)
  → Creates AuthResponseModel (accessToken, refreshToken, user)
     ↓
AuthRepositoryImpl
  → Extracts tokens → saves to secure storage
  → Returns void (no data passed up to domain)
     ↓
Login use case
  → Returns void to AuthNotifier
     ↓
AuthNotifier
  → Sets state = { isAuthenticated: true }
     ↓
Riverpod notifies all ref.watch(authProvider) listeners
     ↓
UI widgets rebuild with new state
     ↓
Router redirect fires → user sees dashboard
```

> **Note**: The `User` entity is constructed but NOT passed to the presentation layer in this project.
> The `AuthRepositoryImpl` only saves the tokens; the user data is discarded.
> This is a known gap — see Phase 8 (Observation 4).

---

# PHASE 6 — Concept Dependency Map

```
Level 1: Dart Fundamentals
  Variables, types, null safety (String?)
  Functions, classes, constructors
  abstract classes (used as interfaces)
  static const members
         ↓

Level 2: Async Dart
  Future<T>
  async / await
  unawaited()
  try / catch / on SomeException
         ↓

Level 3: JSON / Serialization
  Map<String, dynamic>
  factory constructor pattern (fromJson)
  toJson() method
  null-coalescing (??, ?., !)
         ↓

Level 4: Flutter Widgets
  StatelessWidget / build()
  StatefulWidget / State / dispose()
  Scaffold, Column, Row, Expanded
  TextEditingController
  Material widgets (TextField, FilledButton, ListTile)
  Spacer, ConstrainedBox
         ↓

Level 5: Riverpod
  ProviderScope (root container)
  Provider<T> (simple value provider)
  Notifier<State> + NotifierProvider
  ref.watch() vs ref.read()
  ConsumerWidget / ConsumerStatefulWidget
         ↓

Level 6: Navigation (GoRouter)
  GoRouter, GoRoute
  ShellRoute (persistent layout)
  context.go()
  redirect logic (auth guard)
  GoRouterState (current location)
         ↓

Level 7: Architecture Patterns
  Repository Pattern (abstract + impl)
  Data Source Pattern
  Use Case Pattern (callable objects)
  Dependency Injection via Riverpod
  Clean Architecture layers (domain / data / presentation)
         ↓

Level 8: Networking
  HTTP (POST, request body, response)
  REST API (endpoints, JSON)
  Dio (client, BaseOptions, DioException)
  JSON serialization / deserialization cycle
         ↓

Level 9: Secure Storage
  Why secure storage vs plain storage
  Key-value storage pattern
  Token-based authentication flow
  Token persistence → auth state on startup
```

---

# PHASE 7 — Architecture Patterns Identified

## Pattern 1: Clean Architecture (Layered Architecture)

```
Pattern:        Clean Architecture (3 layers)
Where used:     features/auth/ — all three layers fully implemented
Files involved: domain/ (entities, repositories, usecases)
                data/ (datasources, models, repository impl)
                presentation/ (providers, screens)
Why used:       Each layer has one responsibility.
                Lower layers cannot know about higher layers.
                Business logic is framework-independent.
How it works:   Domain defines contracts (abstract classes).
                Data implements them (concrete HTTP/storage).
                Presentation consumes domain contracts via DI.
```

## Pattern 2: Repository Pattern

```
Pattern:        Repository Pattern
Where used:     auth/domain/repositories/ + auth/data/repositories/
Files involved: auth_repository.dart (abstract contract)
                auth_repository_impl.dart (concrete implementation)
Why used:       Domain never knows if data comes from HTTP, DB, or a mock.
                Business logic is decoupled from data access.
How it works:   Abstract class defines the interface.
                Concrete class implements it.
                Riverpod injects the concrete class where the abstract is expected.
```

## Pattern 3: Data Source Pattern

```
Pattern:        Data Source Pattern
Where used:     auth/data/datasources/
Files involved: auth_remote_data_source.dart (abstract + impl)
Why used:       Isolates HTTP communication from repository logic.
                Repository orchestrates; data source just fetches.
How it works:   Same abstract + implementation as repository.
                Repository delegates HTTP calls to the data source.
```

## Pattern 4: Use Case Pattern (Interactor)

```
Pattern:        Use Case Pattern
Where used:     auth/domain/usecases/
Files involved: login.dart, register.dart, logout.dart
Why used:       Encapsulates single business operations.
                Presentation never calls repository directly.
                Single Responsibility Principle: one class, one action.
How it works:   Each class has a call() method.
                Dart lets you invoke the object directly: useCase(params).
```

## Pattern 5: Dependency Injection via Riverpod

```
Pattern:        Dependency Injection (DI)
Where used:     core/providers/, auth/presentation/providers/
Files involved: core_providers.dart, auth_providers.dart
Why used:       Objects don't create their own dependencies.
                Enables testability (swap implementations without code changes).
                Enables single instances (singleton by default in ProviderScope).
How it works:   Provider<T> creates and caches objects.
                Consumers use ref.watch() or ref.read() to get them.
                Providers are composed: A reads B reads C.
```

## Pattern 6: State Machine (AuthState)

```
Pattern:        State Machine
Where used:     auth/presentation/providers/auth_notifier.dart
Files involved: auth_notifier.dart
Why used:       Auth has clearly defined states with well-defined transitions.
                Prevents invalid states (e.g., isLoading + isAuthenticated both true on login).
How it works:   AuthState holds isLoading + isAuthenticated + error.
                AuthNotifier transitions between states via its methods.
                Router and UI react to state changes declaratively.
```

## Pattern 7: Declarative Navigation with Route Guards

```
Pattern:        Declarative Navigation + Route Guards
Where used:     app/router/app_router.dart + app_router_provider.dart
Files involved: app_router.dart, app_router_provider.dart
Why used:       Navigation is driven by application state, not imperative push/pop calls.
                Auth guard prevents unauthorized access automatically.
How it works:   GoRouter redirect() runs on every navigation.
                Inspects authState and returns a new path or null.
                Auth state change → router refresh → redirect re-evaluates.
```

## Pattern 8: Feature-Based Directory Structure

```
Pattern:        Feature-Based Architecture
Where used:     lib/features/
Files involved: features/auth/, features/splash/, features/shell/
Why used:       Groups related code by feature, not by technical layer.
                Scaling: teams can work on separate features independently.
                Encapsulation: each feature contains data/domain/presentation.
How it works:   Adding a new feature = adding a new folder under features/.
                Features don't import from each other.
                Shared infrastructure lives in core/.
```

## Pattern 9: Callable Objects (Functor-like pattern)

```
Pattern:        Callable Objects
Where used:     auth/domain/usecases/
Files involved: login.dart, register.dart, logout.dart
Why used:       Allows use case objects to be invoked with function syntax.
                Cleaner call site: useCase(email, password) vs useCase.execute(email, password).
How it works:   Define a call() method on the class.
                Dart automatically invokes it when the object is called as a function.
```

---

# PHASE 8 — Observations, Redundancies, and Confusions

```
File:        test/widget_test.dart
Observation: Default counter app test — not updated for this project.
Why confusing: Running `flutter test` will fail, misleading you into
               thinking the app is broken when it's the test that's stale.
```

```
File:        core/network/api_exception.dart
Observation: File exists (1 byte of whitespace) but contains no code.
Why confusing: Suggests an error-handling system that doesn't exist yet.
               DioException is currently caught raw without custom wrapping.
```

```
File:        core/network/auth_interceptor.dart
Observation: Completely empty file.
Why confusing: Suggests token refresh interceptor logic that is not implemented.
               Without it, access tokens are never refreshed automatically.
               After token expiry, the app will make failing API calls.
```

```
File:        auth_notifier.dart (AuthState)
Observation: The User entity is constructed in auth_response_model.dart
             but discarded — it is never passed to the presentation layer.
Why confusing: The User entity exists and is constructed, but there's no way
               for a screen to display the logged-in user's name without
               re-fetching. The AuthState only has isAuthenticated, not the user.
```

```
File:        login_screen.dart
Observation: TextEditingController pre-filled with test credentials:
             email='emilys', password='emilyspass'
Why confusing: Development convenience for testing with dummyjson.com.
               Looks like a bug or security issue to a new reader.
               Must be removed before any production use.
```

```
File:        auth_remote_data_source.dart (logout method)
Observation: DioException is caught and silently ignored on logout.
Why confusing: Intentional design (client-side logout always succeeds),
               but no comment explains this decision. Could look like a bug.
```

```
File:        app_router_provider.dart
Observation: Both ref.watch() AND ref.listen() are used on authProvider.
Why confusing: ref.watch() causes the provider to rebuild (creates new router).
               ref.listen() also calls router.refresh() on the new router.
               It can seem redundant. The listen is needed because GoRouter
               needs an explicit refresh() call to re-run redirect logic.
```

```
Files:       splash/presentation/providers/ (empty directory)
Observation: The splash feature has an empty providers/ directory.
Why confusing: Suggests splash will have its own providers, but currently
               it uses authProvider directly. The directory may be for
               consistency or future use.
```

---

# PHASE 9 — Final Learning Checklist

Use this checklist to study the project systematically. For each file, understand the four dimensions shown.

```
[ ] 1. pubspec.yaml
        Concepts:      package dependencies, semantic versioning, asset registration
        Architecture:  project manifest — 4 key packages identified
        Dependencies:  nothing depends on it; everything requires it
        Runtime flow:  Flutter tool reads this before any code runs

[ ] 2. analysis_options.yaml
        Concepts:      static analysis, linting, code quality
        Architecture:  development tooling only — no runtime effect
        Dependencies:  flutter_lints package
        Runtime flow:  no runtime effect

[ ] 3. lib/main.dart
        Concepts:      void main(), runApp(), ProviderScope, const
        Architecture:  application entry point
        Dependencies:  flutter_riverpod, app.dart
        Runtime flow:  Dart runtime → main() → runApp() → ProviderScope → MyApp

[ ] 4. lib/app/app.dart
        Concepts:      ConsumerWidget, MaterialApp.router(), ref.watch(), ThemeData
        Architecture:  root widget — connects routing and state management
        Dependencies:  appRouterProvider, GoRouter
        Runtime flow:  First widget built → reads router → renders first route

[ ] 5. lib/app/router/route_names.dart
        Concepts:      abstract class as namespace, static const
        Architecture:  centralized route constants (single source of truth)
        Dependencies:  nothing
        Runtime flow:  String constants used at navigation time

[ ] 6. lib/core/network/dio_client.dart
        Concepts:      Dio, BaseOptions, baseUrl, timeouts, headers, initializer list
        Architecture:  core network infrastructure
        Dependencies:  dio package
        Runtime flow:  Created once via provider, reused for all HTTP requests

[ ] 7. lib/core/storage/token_storage.dart
        Concepts:      FlutterSecureStorage, Future<String?>, async/await, nullable types
        Architecture:  core secure storage infrastructure
        Dependencies:  flutter_secure_storage package
        Runtime flow:  Reads/writes tokens to device keychain (async I/O)

[ ] 8. lib/core/providers/core_providers.dart
        Concepts:      Provider<T>, Riverpod DI, lazy initialization, singleton
        Architecture:  DI layer for core infrastructure
        Dependencies:  DioClient, TokenStorage
        Runtime flow:  Providers created lazily on first access; shared thereafter

[ ] 9. lib/features/auth/domain/entities/user.dart
        Concepts:      plain Dart class, final fields, immutability, named parameters
        Architecture:  domain entity — framework-independent business object
        Dependencies:  nothing
        Runtime flow:  Created when parsing API response (in auth_response_model.dart)

[ ] 10. lib/features/auth/domain/repositories/auth_repository.dart
         Concepts:      abstract class, interface contract, Future<void>
         Architecture:  Repository Pattern — domain defines the contract
         Dependencies:  nothing
         Runtime flow:  Never instantiated directly — always used through its implementation

[ ] 11. lib/features/auth/domain/usecases/login.dart
[ ] 12. lib/features/auth/domain/usecases/register.dart
[ ] 13. lib/features/auth/domain/usecases/logout.dart
         Concepts:      use case class, call() method (callable objects), delegation
         Architecture:  Use Case Pattern — single-action business objects
         Dependencies:  AuthRepository (abstract)
         Runtime flow:  Invoked like functions: loginUseCase(email, password)

[ ] 14. lib/features/auth/data/models/login_request_model.dart
[ ] 15. lib/features/auth/data/models/register_request_model.dart
         Concepts:      toJson(), Map<String, dynamic>, const constructor, serialization
         Architecture:  DTO pattern — outbound JSON serialization
         Dependencies:  nothing
         Runtime flow:  Created before HTTP request → serialized to JSON body by Dio

[ ] 16. lib/features/auth/data/models/auth_response_model.dart
         Concepts:      factory fromJson, ?? operator, whereType, join, nullable casting
         Architecture:  DTO pattern — inbound JSON deserialization, constructs User entity
         Dependencies:  User entity (user.dart)
         Runtime flow:  Created from API response JSON → constructs and contains User object

[ ] 17. lib/features/auth/data/datasources/auth_remote_data_source.dart
         Concepts:      abstract + implementation, DioException, HTTP POST, await
         Architecture:  Data Source Pattern — isolated HTTP communication
         Dependencies:  DioClient, request/response models
         Runtime flow:  Makes actual HTTP calls; returns model objects

[ ] 18. lib/features/auth/data/repositories/auth_repository_impl.dart
         Concepts:      implements, private helpers, ! operator, null check
         Architecture:  Repository implementation — orchestrates data source + storage
         Dependencies:  AuthRemoteDataSource, TokenStorage, AuthRepository (contract)
         Runtime flow:  Called by use cases → calls data source → saves tokens

[ ] 19. lib/features/auth/presentation/providers/auth_providers.dart
         Concepts:      Provider<T>, DI composition, ref.watch() in providers
         Architecture:  Dependency wiring — connects all layers via Riverpod
         Dependencies:  core_providers, all auth layer classes
         Runtime flow:  Full DI chain assembled lazily on first access

[ ] 20. lib/features/auth/presentation/providers/auth_notifier.dart
         Concepts:      Notifier<State>, NotifierProvider, unawaited, state machine, ref.read
         Architecture:  State management — auth lifecycle (central source of truth)
         Dependencies:  tokenStorageProvider, loginUseCaseProvider, etc.
         Runtime flow:  Created on startup → checks token → drives all navigation decisions

[ ] 21. lib/app/router/app_router.dart
         Concepts:      GoRouter, GoRoute, ShellRoute, redirect, initialLocation
         Architecture:  Declarative navigation + route guards (auth protection)
         Dependencies:  AuthState, all screen widgets, route names
         Runtime flow:  Evaluated on every navigation; redirect runs auth-check logic

[ ] 22. lib/app/router/app_router_provider.dart
         Concepts:      ref.watch + ref.listen combination, router.refresh()
         Architecture:  Bridge between Riverpod state and GoRouter navigation
         Dependencies:  authProvider, AppRouter
         Runtime flow:  Auth state change → provider rebuilds → router refreshes → redirect fires

[ ] 23. lib/features/splash/presentation/screens/splash_screen.dart
         Concepts:      ConsumerWidget, CircularProgressIndicator, conditional rendering
         Architecture:  Passive UI — only reflects state, never drives navigation
         Dependencies:  authProvider
         Runtime flow:  Shows spinner while isLoading=true; router redirect replaces it automatically

[ ] 24. lib/features/auth/presentation/screens/login_screen.dart
[ ] 25. lib/features/auth/presentation/screens/register_screen.dart
         Concepts:      ConsumerStatefulWidget, TextEditingController, dispose(), ref.watch vs ref.read
         Architecture:  Presentation — UI + reactive state subscription
         Dependencies:  authProvider, route names, GoRouter
         Runtime flow:  User enters credentials → notifier method called → state transitions → redirect

[ ] 26. lib/features/shell/widgets/app_side_bar.dart
         Concepts:      GoRouterState.of(context), context.go(), Spacer, selected state
         Architecture:  Reusable navigation widget inside ShellScreen
         Dependencies:  authProvider (logout), route names, GoRouter
         Runtime flow:  Reads current URL to highlight active route; navigates on tap; triggers logout

[ ] 27. lib/features/shell/presentation/screens/shell_screen.dart
         Concepts:      StatelessWidget, Row, Expanded, child parameter injection
         Architecture:  Layout shell for authenticated section (used by ShellRoute)
         Dependencies:  AppSideBar
         Runtime flow:  GoRouter injects current page as child; sidebar stays persistent across navigations

[ ] 28-32. Dashboard / Users / Services / Equipment / Settings Screens
         Concepts:      StatelessWidget, Scaffold, placeholder pattern
         Architecture:  Feature screens — ready for implementation following auth pattern
         Runtime flow:  Rendered as ShellScreen's child when their route is matched
```

---

# Final Answers to All 16 Questions

**1. What happens when the Flutter application starts?**
`main()` runs → `ProviderScope` + `MyApp` initialize → `AuthNotifier` checks for a saved token asynchronously → router shows splash (loading spinner) → when the check completes, router redirects to `/login` or `/dashboard`.

**2. Where does the application begin?**
`lib/main.dart` — specifically, the `void main()` function.

**3. How does navigation work?**
GoRouter (`go_router` package) manages all navigation declaratively. Routes are defined in `app_router.dart`. A `redirect` function guards routes based on `AuthState`. `context.go()` triggers navigation. `ShellRoute` provides persistent layout for authenticated routes.

**4. How is authentication handled?**
Login → `AuthNotifier.login()` → `Login` use case → `AuthRepositoryImpl.login()` → HTTP POST → `AuthResponseModel.fromJson()` → save tokens to secure storage → set `isAuthenticated: true` → router redirects to dashboard.

**5. How is state managed?**
Riverpod. `AuthNotifier extends Notifier<AuthState>` holds auth state. Widgets read state via `ref.watch(authProvider)`. Actions are called via `ref.read(authProvider.notifier).login(...)`.

**6. How does the UI communicate with the backend?**
`LoginScreen` → `ref.read(authProvider.notifier).login()` → `AuthNotifier` → `Login` use case → `AuthRepositoryImpl` → `AuthRemoteDataSourceImpl` → `DioClient.dio.post(...)` → `https://dummyjson.com`.

**7. How does data travel from API → Flutter → UI?**
JSON response → `AuthResponseModel.fromJson()` (creates `User`) → `AuthRepositoryImpl` saves tokens → `AuthNotifier` sets `isAuthenticated: true` → all `ref.watch(authProvider)` listeners rebuild → router redirects.

**8. Why are repositories used?**
To decouple the domain layer from data sources. Domain code depends only on the abstract `AuthRepository`. The concrete HTTP implementation can be swapped or mocked without changing domain or UI code.

**9. Why are models/entities used?**
Models (data layer) handle JSON serialization — they know about API field names and parsing. Entities (domain layer) are pure business objects — they know nothing about JSON. API changes only affect models, not business logic.

**10. Where does each responsibility belong?**
| Responsibility | Location |
|---|---|
| HTTP calls | `data/datasources/` |
| Token storage | `core/storage/` |
| Business contracts | `domain/repositories/` |
| Business actions | `domain/usecases/` |
| JSON parsing | `data/models/` |
| State management | `presentation/providers/` |
| UI | `presentation/screens/` + `widgets/` |
| Navigation | `app/router/` |
| Shared infrastructure | `core/` |

**11. How do all files connect?**
See Phase 5 — the complete runtime flow diagrams trace every connection from startup through login through navigation.

**12. What Dart concepts are being used?**
`abstract class`, `implements`, `final` fields, `static const`, `async`/`await`, `Future<T>`, `Map<String, dynamic>`, factory constructors, `call()` method, null safety (`?`, `??`, `!`, `?.`), initializer lists, `unawaited()`.

**13. What Flutter concepts are being used?**
`StatelessWidget`, `StatefulWidget`, `ConsumerWidget`, `ConsumerStatefulWidget`, `BuildContext`, `WidgetRef`, `TextEditingController`, `dispose()`, `MaterialApp.router()`, `Scaffold`, `Row`, `Column`, `Expanded`, `Spacer`, `ConstrainedBox`, `ThemeData`.

**14. What Riverpod concepts are being used?**
`ProviderScope`, `Provider<T>`, `Notifier<State>`, `NotifierProvider`, `ref.watch()`, `ref.read()`, `ref.listen()`, `authProvider.notifier`, provider composition.

**15. What architecture patterns are being used?**
Clean Architecture, Repository Pattern, Data Source Pattern, Use Case Pattern, Dependency Injection (Riverpod), State Machine (AuthState), Declarative Navigation with Route Guards, Feature-Based Directory Structure, Callable Objects.

**16. Why was the project structured this way?**
Feature-based Clean Architecture: each feature is self-contained (data/domain/presentation), shared infrastructure lives in `core/`, and the `app/` layer ties it together. This structure supports:
- **Scalability**: teams work on separate features independently
- **Testability**: each layer can be tested in isolation (mock repositories, mock data sources)
- **Maintainability**: changing one layer (e.g., switching HTTP library from Dio to http) doesn't break other layers
- **Separation of Concerns**: business logic never knows about Flutter; UI never knows about HTTP
