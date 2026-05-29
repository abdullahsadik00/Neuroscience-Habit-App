// =============================================================================
// FILE: auth_provider.dart
//
// This file defines the authentication-related Riverpod providers for the app.
//
// ROLE IN APP ARCHITECTURE:
//   This file sits at the foundation of the app's auth layer. Other files
//   (screens, widgets, other providers) import these providers to know whether
//   a user is logged in, who that user is, and to react when their login state
//   changes. Think of it as the single source of truth for "who is using the
//   app right now."
//
// KEY CONCEPTS TO UNDERSTAND THIS FILE:
//
//   1. Riverpod — a state management library for Flutter. Instead of passing
//      data down through widget constructors, Riverpod lets any widget or
//      provider read shared state from a central registry. You declare a
//      "provider" (a named piece of state), and anywhere in the app you can
//      watch or read it.
//
//   2. Provider<T> — the simplest Riverpod provider. It holds a single value
//      of type T that is computed once (or recomputed when dependencies change)
//      and can be read by widgets or other providers.
//
//   3. StreamProvider<T> — a Riverpod provider that wraps a Dart Stream.
//      A Stream is like a pipe that delivers values over time (e.g., "user
//      logged in", then later "user logged out"). StreamProvider listens to
//      the stream and exposes the latest value to widgets.
//
//   4. Supabase — a backend-as-a-service (like Firebase). It handles user
//      accounts, the database, and authentication for us. The Flutter SDK
//      (supabase_flutter) gives us a Dart client to interact with it.
//
//   5. ref — short for "reference". Inside a Riverpod provider's body,
//      `ref` is the object you use to read or watch other providers. Calling
//      ref.watch(someProvider) means "give me the current value of someProvider
//      AND rebuild/recompute me whenever that value changes."
// =============================================================================

// Brings in the Riverpod library for Flutter.
// Riverpod provides Provider, StreamProvider, and the `ref` object used below.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Brings in the Supabase Flutter SDK.
// This gives us SupabaseClient (the object that talks to our Supabase backend),
// the User type (represents a logged-in user's data), and AuthState
// (an event object emitted each time the user's auth status changes).
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// PROVIDER: supabaseClientProvider
//
// Purpose: Exposes the single shared SupabaseClient instance to the rest of
// the app. The client is the main object you use to talk to Supabase (auth,
// database, storage, etc.).
//
// Why wrap it in a provider? So that any widget or provider that needs the
// client can just call ref.read(supabaseClientProvider) instead of calling
// Supabase.instance.client everywhere. This also makes testing easier because
// you can swap in a fake client in tests.
//
// `final` means this provider variable itself cannot be reassigned after it is
// created — it is a compile-time constant reference. The VALUE it holds can
// still change, but the provider object is fixed.
// -----------------------------------------------------------------------------
final supabaseClientProvider = Provider<SupabaseClient>(
  // The underscore `_` is a Dart convention for "I have a parameter here
  // (the ref object) but I don't need to use it in this body".
  // Supabase.instance.client returns the already-initialized SupabaseClient
  // singleton — there is always exactly one of these for the whole app.
  (_) => Supabase.instance.client,
);

/// Emits AuthState on every sign-in / sign-out event.
///
/// This StreamProvider listens to Supabase's authentication event stream.
/// Every time the user signs in, signs out, or their token refreshes, Supabase
/// emits a new [AuthState] event into this stream. Any widget that watches this
/// provider will automatically rebuild when a new auth event arrives.
///
/// Typical use: redirect the user to the login screen when they sign out, or
/// to the home screen when they sign in.
///
/// [AsyncValue] wrapping: StreamProvider automatically wraps its value in
/// AsyncValue<AuthState>, which can be in one of three states:
///   - AsyncLoading  — the stream hasn't emitted anything yet
///   - AsyncData     — a new AuthState event arrived; use .value to get it
///   - AsyncError    — something went wrong with the stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  // ref.watch(supabaseClientProvider) reads the SupabaseClient from the
  // provider we defined above. Using ref.watch (instead of ref.read) here
  // means: "if the supabaseClientProvider ever changes, recompute this stream
  // too." In practice the client never changes after startup, but this is the
  // correct Riverpod pattern for declaring dependencies between providers.
  //
  // .auth is the Supabase authentication sub-client — it handles login/logout.
  // .onAuthStateChange is a Stream<AuthState> that fires whenever the user's
  // authentication status changes (login, logout, token refresh, etc.).
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// The currently signed-in user, or null when logged out.
///
/// This is a simple synchronous provider (not a stream) that returns the
/// user object for whoever is logged in right now. If no one is logged in,
/// it returns null. The `?` after `User` is Dart's nullable type syntax —
/// it means the value is allowed to be null.
///
/// Typical use: read the user's ID or email to personalise the UI, or check
/// `currentUserProvider == null` to decide whether to show the login screen.
///
/// IMPORTANT: This provider gives you a snapshot at read time. If you need
/// to react to login/logout events in real time, use [authStateProvider]
/// (the StreamProvider above) instead.
final currentUserProvider = Provider<User?>((ref) {
  // ref.watch(supabaseClientProvider) — again we read the shared client.
  // .auth.currentUser is a synchronous getter on the Supabase auth client.
  // It immediately returns the User object if someone is logged in, or null
  // if no session exists. No network call is made here — Supabase caches
  // the session locally on the device.
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
