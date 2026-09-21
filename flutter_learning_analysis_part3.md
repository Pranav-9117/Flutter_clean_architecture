# Flutter Clean Architecture — Complete Learning Analysis
### Part 3 of 4: Phase 4 — File Analysis (Files 14–32)

---

## Files 14 & 15 — `login_request_model.dart` / `register_request_model.dart`

### 1. Purpose of These Files

**Request models** — Dart objects representing data sent TO the server. Their job: take Dart-friendly values and serialize them into JSON for HTTP requests.

### 2. Where They Fit in the Architecture

```
Presentation
    ↓
Domain
    ↓
Data  ← YOU ARE HERE
    models/
        login_request_model.dart
        register_request_model.dart
    ↓
Network → HTTP POST body (JSON)
```

### 3. Explain the Code

```dart
class LoginRequestModel {
  final String email;
  final String password;
  const LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': email, 'password': password};
  }
}
```

**Note the field name mismatch**: The Dart field is `email`, but the JSON key is `'username'`. The `dummyjson.com` API expects `username` for its login endpoint, but the app uses `email` internally. The model handles this translation silently.

```dart
class RegisterRequestModel {
  Map<String, dynamic> toJson() {
    return {'username': email, 'email': email, 'password': password};
  }
}
```
Register sends both `username` AND `email` because the API might require both.

`Map<String, dynamic>` — A Dart map (dictionary) with string keys and values of any type. This is the Dart representation of JSON before it's serialized to a string by Dio.

### 4. Key Takeaways

1. Request models convert Dart objects → JSON for outgoing HTTP requests
2. `toJson()` does the serialization
3. Field name differences between Dart code and JSON are handled inside the model
4. `const` constructor means the object can be created at compile-time
5. `dynamic` in `Map<String, dynamic>` means the value can be any type (String, int, bool, etc.)

---

## File 16 — `lib/features/auth/data/models/auth_response_model.dart`

### 1. Purpose of the File

The **response model** — takes raw JSON from the server and converts it into structured Dart objects. It is the mirror of request models but works in the opposite direction: JSON → Dart.

### 2. Where It Fits in the Architecture

```
Network → JSON response
    ↓
Data  ← YOU ARE HERE
    models/
        auth_response_model.dart
    ↓
Domain
    entities/
        user.dart  ← The User entity is CONSTRUCTED here
```

### 3. Concepts Used

**Dart Concepts**:
- `factory constructor` — A constructor that can do work before returning an instance. Standard Dart pattern for JSON deserialization.
- `??` (null-coalescing operator) — `a ?? b` means "use `a` if not null, otherwise `b`"
- `as String?` — Casting with a nullable type
- `whereType<String>()` — Filters a list to only elements of type `String`
- `join(' ')` — Joins list items into a string with a separator

### 4. Explain the Code

```dart
factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
  final userJson = (json['user'] as Map<String, dynamic>?) ?? json;
```
The API might return user data nested under a `'user'` key OR at the top level (login vs register APIs differ). `?? json` means: "if `json['user']` is null, use the whole `json` map."

```dart
  return AuthResponseModel(
    accessToken: (json['accessToken'] ?? json['access_token']) as String?,
    refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String?,
```
API might use either `accessToken` (camelCase) or `access_token` (snake_case). The `??` handles both.

```dart
    user: User(
      id: userJson['id'].toString(),
      name: userJson['name'] as String? ??
            [firstName, lastName].whereType<String>().join(' '),
      email: userJson['email'] as String? ?? '',
    ),
```
- `id` → `.toString()` because API might return it as an integer
- `name` → either a direct `name` field OR `firstName + ' ' + lastName`
- `[firstName, lastName].whereType<String>().join(' ')` — creates a list of name parts, filters nulls, joins with a space

### 5. Key Takeaways

1. `factory` constructors are the standard Dart pattern for JSON deserialization
2. `??` is essential for APIs that use different field names or structures
3. This is where the `User` entity is actually constructed — domain entity created in the data layer
4. The model absorbs all the messiness of the real API; the rest of the code sees only clean data
5. The `fromJson` pattern is universal in Flutter development — master it

---

## File 17 — `lib/features/auth/data/datasources/auth_remote_data_source.dart`

### 1. Purpose of the File

Contains the code that **directly makes HTTP calls to the server**. The boundary between the Flutter app and the internet. Has two parts: an abstract contract and a concrete implementation.

### 2. Where It Fits in the Architecture

```
Data  ← YOU ARE HERE
    datasources/
        auth_remote_data_source.dart
    ↓
Network
    DioClient → https://dummyjson.com
```

### 3. Concepts Used

**Networking Concepts**:
- `client.dio.post(path, data: ...)` — HTTP POST request with a JSON body
- `response.data` — Response body as a Dart object (Dio auto-parses JSON)
- `DioException` — Exception thrown by Dio when an HTTP error occurs
- `on DioException { }` — Catches only Dio-specific errors

**Architecture Concepts**:
- **Data Source Pattern** — Responsible for one thing: talking to one external source (HTTP). No business logic.

### 4. Explain the Code

```dart
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<void> logout();
}
```
Same abstract + implementation pattern as `AuthRepository`.

```dart
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this.client);
  final DioClient client;
```
`DioClient` is injected via constructor — dependency injection. Doesn't create its own HTTP client; receives one.

```dart
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await client.dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }
```
Three steps:
1. `request.toJson()` — Dart object → JSON map
2. `client.dio.post('/auth/login', data: ...)` — HTTP POST to `https://dummyjson.com/auth/login`
3. `AuthResponseModel.fromJson(response.data)` — JSON response → Dart object

```dart
  Future<void> logout() async {
    try {
      await client.dio.post('/auth/logout');
    } on DioException {
    }
  }
```
Logout silently catches `DioException`. Intentional — even if server logout fails, the client should still clear tokens. Error handling is a design decision.

### 5. Input → Processing → Output

```
INPUT:  LoginRequestModel(email, password)
         ↓
PROCESSING:
  1. request.toJson() → {'username': '...', 'password': '...'}
  2. HTTP POST → https://dummyjson.com/auth/login
  3. Server returns JSON: {"accessToken": "...", "user": {...}}
  4. AuthResponseModel.fromJson(json)
         ↓
OUTPUT: AuthResponseModel(accessToken, refreshToken, user)
```

### 6. Key Takeaways

1. Data source is the ONLY place in the app where HTTP calls are made
2. Returns model objects (not entities) — model objects live at this boundary
3. Constructor injection makes it testable (inject a mock `DioClient`)
4. `on DioException { }` catches only HTTP-specific errors, not all exceptions
5. The abstract + implementation pattern mirrors the repository pattern

---

## File 18 — `lib/features/auth/data/repositories/auth_repository_impl.dart`

### 1. Purpose of the File

The **concrete implementation of the domain's `AuthRepository` contract**. The orchestrator: calls the data source (HTTP) and token storage (secure storage) together to fulfill each auth operation.

### 2. Where It Fits in the Architecture

```
Domain
    AuthRepository (abstract contract)
    ↓
Data  ← YOU ARE HERE
    auth_repository_impl.dart (concrete implementation)
    ↓ calls both:
    auth_remote_data_source.dart (HTTP)
    token_storage.dart (secure storage)
```

### 3. Explain the Code

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  AuthRepositoryImpl(this.remoteDataSource, this.tokenStorage);
```
`implements AuthRepository` — compiler enforces that ALL abstract methods are provided.

Two dependencies injected: data source (for HTTP) and token storage (for persisting tokens).

```dart
  Future<void> login(String email, String password) async {
    final response = await remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );
    await _saveTokens(response);
  }
```
Login flow:
1. Converts `(email, password)` → `LoginRequestModel`
2. Calls data source (HTTP call)
3. Saves returned tokens to secure storage

```dart
  Future<void> _saveTokens(AuthResponseModel response) async {
    if (response.accessToken != null) {
      await tokenStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null) {
      await tokenStorage.saveRefreshToken(response.refreshToken!);
    }
  }
```
`_saveTokens` is private (underscore). The `!` (bang/null assertion) operator is used AFTER an explicit null check — safe here.

```dart
  Future<void> logout() async {
    await remoteDataSource.logout();
    await tokenStorage.clear();
  }
```
Logout calls the server (invalidate server-side session) AND clears local tokens. Both steps required.

### 4. Input → Processing → Output

```
INPUT:  email: String, password: String
         ↓
PROCESSING:
  1. Create LoginRequestModel
  2. remoteDataSource.login() → HTTP call → AuthResponseModel
  3. tokenStorage.saveAccessToken() → writes to device keychain
         ↓
OUTPUT: void (tokens are saved, app considers user authenticated)
```

### 5. Key Takeaways

1. `implements` enforces all abstract methods — compiler error if any are missing
2. Only layer that combines HTTP + local storage into coherent auth operations
3. `_saveTokens` is a private helper to avoid repetition (login and register both need it)
4. `!` operator should only be used after explicit null check — as done here
5. Bridges the abstract domain contract and the concrete data layer

---

## File 19 — `lib/features/auth/presentation/providers/auth_providers.dart`

### 1. Purpose of the File

**Wires together the entire dependency chain** for the auth feature using Riverpod providers. This is the dependency injection file that connects all layers.

### 2. Explain the Code (reading in dependency order)

```dart
// Step 1: Create the data source (needs DioClient)
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
```

```dart
// Step 2: Create the repository (needs data source + token storage)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  );
});
```
Note: return type is `Provider<AuthRepository>` (abstract), not `Provider<AuthRepositoryImpl>`. Enforces the dependency inversion principle.

```dart
// Step 3: Create each use case
final loginUseCaseProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<Register>((ref) {
  return Register(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});
```

### 3. The Full Dependency Chain

```
dioClientProvider          tokenStorageProvider
       ↓                          ↓
authRemoteDataSourceProvider      ↓
       ↓                          ↓
       └────── authRepositoryProvider ──────┘
                       ↓
       ┌───────────────┼───────────────┐
       ↓               ↓               ↓
loginUseCaseProvider  registerUseCaseProvider  logoutUseCaseProvider
       ↓               ↓               ↓
              authProvider (auth_notifier.dart)
```

### 4. Key Takeaways

1. `ref.watch()` inside a provider creates a dependency — if the watched provider changes, this one re-creates itself
2. Return type `Provider<AuthRepository>` enforces the dependency inversion principle
3. This file is purely wiring — no business logic, no UI code
4. The entire chain is lazy — nothing created until first accessed
5. This is the Riverpod version of a dependency injection container

---

## File 20 — `lib/features/auth/presentation/providers/auth_notifier.dart`

### 1. Purpose of the File

**The central state management file of the entire application.** Defines:
1. `AuthState` — what auth-related data the app holds
2. `AuthNotifier` — the class that manages state transitions
3. `authProvider` — the Riverpod provider that exposes state to the whole app

### 2. Where It Fits in the Architecture

```
Presentation  ← YOU ARE HERE
    providers/
        auth_notifier.dart
             ↓
        auth_providers.dart (use cases)
             ↓
        Domain → Data → Network
```

### 3. Concepts Used

**Riverpod Concepts**:
- `Notifier<AuthState>` — Holds and manages state. Override `build()` to set initial state. Change state by assigning to `state`.
- `NotifierProvider<AuthNotifier, AuthState>` — Exposes a `Notifier`. Allows reading state (`ref.watch(authProvider)`) and calling methods (`ref.read(authProvider.notifier).login(...)`).
- `ref.read()` inside async methods — Used (not `ref.watch()`) because you only need the value once, not a subscription.

**Dart Concepts**:
- `unawaited()` — Starts an async operation without waiting. Used to kick off `_checkInitialAuth()` without blocking the synchronous `build()` method.

### 4. Explain `AuthState`

```dart
class AuthState {
  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.error,
  });
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
}
```

Three possible situations:
- `{ isLoading: true, isAuthenticated: false }` → App is checking (startup or mid-operation)
- `{ isLoading: false, isAuthenticated: true }` → User is logged in
- `{ isLoading: false, isAuthenticated: false }` → User is logged out
- `{ isLoading: false, isAuthenticated: false, error: '...' }` → An error occurred

### 5. Explain `AuthNotifier`

```dart
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_checkInitialAuth());
    return const AuthState(isLoading: true, isAuthenticated: false);
  }
```
`build()` is synchronous — it must return immediately. It fires `_checkInitialAuth()` WITHOUT awaiting (fires-and-forgets), then returns the loading state.

```dart
  Future<void> _checkInitialAuth() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    state = AuthState(
      isLoading: false,
      isAuthenticated: token != null && token.isNotEmpty,
    );
  }
```
Checks for a saved token. If yes → authenticated. If no → redirect to login. Assigning `state` notifies all `ref.watch(authProvider)` listeners.

```dart
  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true, isAuthenticated: false);
    try {
      await ref.read(loginUseCaseProvider)(email, password);
      state = const AuthState(isLoading: false, isAuthenticated: true);
    } catch (error) {
      state = AuthState(isLoading: false, isAuthenticated: false, error: error.toString());
    }
  }
```
State transitions during login:
1. Set loading → UI shows spinner, button disabled
2. Call login use case → HTTP call, save tokens
3. Success → set authenticated → router redirects to dashboard
4. Failure → set error state → UI shows error message

### 6. ref.watch vs ref.read — The Most Important Distinction

```
ref.watch(provider)   → USE IN BUILD METHOD
  Causes widget to rebuild when value changes
  Used for: displaying state

ref.read(provider)    → USE IN CALLBACKS AND ASYNC METHODS
  Gets current value once, no subscription
  Used for: triggering actions
```

### 7. Trace Who Uses This File

```
authProvider / AuthState / AuthNotifier
    ↑
Used by:
    ├── app_router_provider.dart    (watches authState to drive navigation)
    ├── app_router.dart             (reads authState for redirect logic)
    ├── splash_screen.dart          (watches isLoading to show spinner)
    ├── login_screen.dart           (watches isLoading, error; calls login())
    ├── register_screen.dart        (watches isLoading, error; calls register())
    └── app_side_bar.dart           (calls logout())
```

This is the most widely-used file in the project.

### 8. Key Takeaways

1. `Notifier<State>` manages state. `state = newState` triggers all watchers to rebuild.
2. `build()` must be synchronous — use `unawaited()` for async startup logic
3. `ref.read()` in async methods (not `ref.watch()`) — you need the value once, not a subscription
4. Every state transition creates a NEW `AuthState` object — immutability pattern
5. `authProvider` is the single source of truth for authentication

---

## File 21 — `lib/app/router/app_router.dart`

### 1. Purpose of the File

Defines **all routes in the application** and the **redirect logic** that automatically sends the user to the correct screen based on their authentication state.

### 2. Concepts Used

**GoRouter Concepts**:
- `GoRouter` — Main router object holding route definitions and redirect logic
- `GoRoute` — Single route (path → screen mapping)
- `ShellRoute` — Provides a persistent layout wrapping nested routes (like a sidebar)
- `redirect` — Callback that runs on every navigation. Returns a new path to redirect, or `null` to proceed.
- `initialLocation` — First path to navigate to when the app starts

### 3. Explain the Code

```dart
class AppRouter {
  AppRouter({required this.authState}) : appRouter = _createRouter(authState);
  final AuthState authState;
  final GoRouter appRouter;
```
`AppRouter` is a plain Dart class. Takes `AuthState` and creates a configured `GoRouter`.

```dart
  redirect: (context, state) {
    final isSplashRoute = state.matchedLocation == RouteNames.splash;
    final isAuthRoute   = state.matchedLocation == RouteNames.login ||
                          state.matchedLocation == RouteNames.register;

    if (authState.isLoading) {
      return isSplashRoute ? null : RouteNames.splash;
    }
    if (!authState.isAuthenticated) {
      return isAuthRoute ? null : RouteNames.login;
    }
    return isSplashRoute || isAuthRoute ? RouteNames.dashboard : null;
  },
```

**The redirect decision tree:**
```
Is app loading?
  YES → Stay on splash. Redirect anything else TO splash.
  NO ↓
Is user NOT authenticated?
  YES → Allow login/register. Redirect everything else TO login.
  NO ↓
User IS authenticated.
  Is user on splash or auth page?
    YES → Redirect TO dashboard.
    NO  → Allow through (null = no redirect).
```

```dart
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: RouteNames.dashboard, builder: (_, _) => DashboardScreen()),
        GoRoute(path: RouteNames.users,     builder: (_, _) => UsersScreen()),
        // ...
      ],
    ),
```
`ShellRoute` wraps its child routes in `ShellScreen(child: child)`. Dashboard, Users, Services, Equipment, and Settings all share the same `ShellScreen` layout (with the sidebar). Only the `child` area changes.

### 4. The ShellRoute Pattern Visualized

```
URL: /dashboard
     ↓
ShellRoute renders:
     ShellScreen(
       child: DashboardScreen()  ← changes per route
     )
     ↓
ShellScreen renders:
     Row(
       AppSideBar(),             ← always visible (persistent)
       Expanded(child: child)    ← DashboardScreen here
     )
```

### 5. Key Takeaways

1. `GoRouter` manages all navigation — no `Navigator.push()` in this project
2. The `redirect` callback is the auth guard — runs on every navigation attempt
3. Returning `null` from redirect means "proceed as requested"
4. `ShellRoute` enables persistent layouts that survive page changes
5. `(_, _)` in `GoRoute.builder` discards unused params — a Dart 3.x feature

---

## File 22 — `lib/app/router/app_router_provider.dart`

### 1. Purpose of the File

**The bridge between Riverpod and GoRouter.** Creates a Riverpod provider that reads auth state, creates a `GoRouter`, and refreshes the router whenever auth state changes.

### 2. Explain the Code

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final router = AppRouter(authState: authState).appRouter;

  ref.listen<AuthState>(authProvider, (_, _) {
    router.refresh();
  });

  return router;
});
```

- `ref.watch(authProvider)` — Gets current `AuthState` AND makes this provider rebuild when auth state changes → creates a new router with new auth state
- `ref.listen(authProvider, ...)` — Calls `router.refresh()` whenever auth state changes → tells GoRouter to re-run redirect logic

**Why both `ref.watch` AND `ref.listen`?**
- `ref.watch` rebuilds the provider (creates a new router with updated state snapshot)
- `ref.listen` additionally calls `router.refresh()` on the EXISTING router to re-trigger redirect evaluation

This ensures the router both holds the latest auth state AND re-evaluates redirects.

### 3. Trace Who Uses This File

```
appRouterProvider
    ↑
Used by:
    └── app.dart (MyApp)
        → ref.watch(appRouterProvider) → passed to MaterialApp.router()
```

### 4. Key Takeaways

1. `ref.listen()` runs a side effect when a provider changes (unlike `ref.watch()` which rebuilds)
2. `router.refresh()` re-triggers GoRouter's redirect logic without full navigation
3. This file is the "glue" connecting state management to navigation
4. Flow: user logs in → `authProvider` changes → `appRouterProvider` rebuilds → router refreshes → redirect fires → user lands on dashboard

---

## File 23 — `lib/features/splash/presentation/screens/splash_screen.dart`

### 1. Purpose of the File

The **initial loading screen**. Appears while the app checks for a saved token. Shows a spinner during loading, then the router's redirect logic automatically sends the user elsewhere.

### 2. Explain the Code

```dart
class SplashScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: authState.isLoading
            ? const CircularProgressIndicator()
            : const Text('Redirecting...'),
      ),
    );
  }
}
```

- While `authState.isLoading` is true → shows a spinner
- When `isLoading` becomes false → shows "Redirecting..." briefly before the router's redirect fires

**Why does the user never stay here long?**
When `_checkInitialAuth()` completes in `AuthNotifier`, `isLoading` becomes false. The router's redirect fires immediately and sends the user to `/dashboard` or `/login`.

### 3. Key Takeaways

1. Splash screen is **passive** — it only shows state, never drives navigation
2. Navigation is driven entirely by the router's redirect logic
3. `ConsumerWidget` gives access to `ref` and thus `authProvider`
4. `CircularProgressIndicator` is a Material design loading spinner

---

## Files 24 & 25 — `login_screen.dart` / `register_screen.dart`

### 1. Purpose of These Files

**Authentication UI screens** where users enter credentials. Contain forms, text controllers, and connect to auth state management.

### 2. Concepts Used

**Flutter Concepts**:
- `ConsumerStatefulWidget` + `ConsumerState` — Riverpod-aware `StatefulWidget`. Needed because the screen has BOTH local state (text controllers) AND Riverpod state.
- `TextEditingController` — Manages text input and its value
- `dispose()` — Lifecycle method when widget is removed; controllers MUST be disposed to free memory
- `Scaffold` — Basic visual structure of a Material screen
- `TextField` — Text input widget
- `FilledButton` — Material 3 button (solid background)
- `ConstrainedBox` — Limits the width of its child (for responsive layout)

**Riverpod Concepts**:
- `ref.watch(authProvider)` — Gets state AND subscribes to changes (causes rebuild)
- `ref.read(authProvider.notifier).login(...)` — Calls a method on the notifier (`ref.read` in callbacks — no subscription needed)

### 3. Explain the Code

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'emilys');
  final _passwordController = TextEditingController(text: 'emilyspass');
```
Pre-filled with test credentials from `dummyjson.com`.

```dart
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
```
**ALWAYS dispose controllers.** Failing to do so causes memory leaks — the controller continues to hold memory and listeners after the screen is gone.

```dart
    FilledButton(
      onPressed: authState.isLoading
          ? null
          : () => ref.read(authProvider.notifier).login(
                _emailController.text.trim(),
                _passwordController.text,
              ),
      child: Text(authState.isLoading ? 'Signing in...' : 'Sign in'),
    ),
```
`onPressed: null` **disables** the button (Flutter convention). Prevents double-submissions during a pending request. When loading completes, the button re-enables.

### 4. ref.watch vs ref.read Summary

| Usage | When | Why |
|---|---|---|
| `ref.watch(authProvider)` | In `build()` method | Makes widget reactive — rebuilds on change |
| `ref.read(authProvider.notifier)` | In callbacks (`onPressed`) | One-time access, no subscription needed |

### 5. Key Takeaways

1. `ConsumerStatefulWidget` = `StatefulWidget` + Riverpod `ref`
2. `dispose()` is mandatory for controllers — always pair creation with disposal
3. `ref.watch()` in `build()` → reactive; `ref.read()` in callbacks → one-time action
4. `onPressed: null` disables a button — a Flutter convention
5. `authState.error` displays server error messages directly in the UI

---

## File 26 — `lib/features/shell/widgets/app_side_bar.dart`

### 1. Purpose of the File

The **navigation sidebar** visible in all authenticated screens. Lets users navigate between sections and provides a logout button.

### 2. Explain the Code

```dart
class AppSideBar extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    String curLocation = GoRouterState.of(context).uri.path;
```
`GoRouterState.of(context).uri.path` retrieves the **current URL path** from the router. This is how the sidebar knows which item to highlight.

```dart
    return Container(
      width: 250,
      child: Column(
        children: [
          ListTile(
            title: Text("Dashboard"),
            selected: curLocation.startsWith(RouteNames.dashboard),
            onTap: () => context.go(RouteNames.dashboard),
          ),
          // ... more ListTiles
          const Spacer(),
          ListTile(
            title: const Text('Logout'),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
```

- `selected: curLocation.startsWith(...)` — Highlights the active route
- `context.go(route)` — GoRouter navigation: replaces the current location (no back button)
- `Spacer()` — Flexible space that pushes the Logout button to the bottom of the column
- `ref.read(authProvider.notifier).logout()` — Calls logout on the auth notifier

### 3. Key Takeaways

1. `GoRouterState.of(context).uri.path` reads current route path from the widget tree
2. `context.go()` is GoRouter's navigation method — replaces current location
3. `Spacer()` is a Flutter layout trick to push widgets to the end of a Column
4. Logout directly triggers the auth notifier, which clears tokens and triggers a router redirect

---

## File 27 — `lib/features/shell/presentation/screens/shell_screen.dart`

### 1. Purpose of the File

`ShellScreen` is the **layout wrapper** for all authenticated screens. Provides the persistent sidebar and a content area that changes based on the current route.

### 2. Explain the Code

```dart
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSideBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

`child` is passed in by GoRouter's `ShellRoute`. As the user navigates between `/dashboard`, `/users`, etc., GoRouter replaces the `child` widget while keeping `ShellScreen` (and thus `AppSideBar`) in the tree.

`Expanded` makes the content area take all remaining horizontal space after the 250px sidebar.

### 3. The ShellRoute Connection

```
GoRouter (app_router.dart)
     ↓
ShellRoute.builder receives (context, state, child)
     ↓
Passes child to ShellScreen
     ↓
ShellScreen renders:
     Row(
       AppSideBar(),       ← persistent (never rebuilt on navigation)
       Expanded(child)     ← changes per route
     )
```

### 4. Key Takeaways

1. `ShellScreen` is not a route itself — it's a layout container used by `ShellRoute`
2. The `child` parameter is the actual page content, injected by GoRouter
3. `Row` + `Expanded` is the standard Flutter pattern for a sidebar layout
4. `StatelessWidget` because it has no state of its own — layout is fixed

---

## Files 28–32 — Placeholder Shell Screens

### Files
- `dashboard_screen.dart` / `users_screen.dart` / `services_screen.dart`
- `equipment_screen.dart` / `settings_screen.dart`

### Purpose

**Placeholder screens** for future features. Each is a minimal `StatelessWidget`:

```dart
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text("Dashboard"));
  }
}
```

All five follow the same pattern. Key learning points:
- `StatelessWidget` is correct — no local state, no Riverpod needed
- These screens render inside `ShellScreen`'s `Expanded` area
- Each has its own `GoRoute` in `app_router.dart`

**Architecturally**: When these features are implemented, each will follow the same clean architecture as the `auth` feature (data/domain/presentation layers).

---

## File 33 — `test/widget_test.dart` ⚠️ SKIP / LOW PRIORITY

The **auto-generated default test** from `flutter create`. Tests a counter app that no longer exists. References `find.text('0')` and `Icons.add` which are unrelated to this project.

**This test will fail if run.** It is not representative of how this project should be tested.

---

## Files 34–38 — Empty Placeholders ⚠️ SKIP / LOW PRIORITY

- `lib/core/network/api_exception.dart` — 1 line of whitespace. Intended for custom exception classes.
- `lib/core/network/auth_interceptor.dart` — 0 bytes. Intended for token refresh interceptor logic.
- `lib/app/theme/` — Empty directory. Intended for custom `ThemeData`.
- `lib/core/constants/` — Empty directory. Intended for app-wide constants.
- `lib/core/errors/` — Empty directory. Intended for custom error/failure classes.

These represent **planned but unimplemented** parts of the architecture.

---
**→ Continue to Part 4 for Phases 5–9 (Architecture Diagrams, Patterns, Checklist)**
