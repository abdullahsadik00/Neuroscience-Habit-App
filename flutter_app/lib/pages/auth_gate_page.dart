// =============================================================================
// FILE: auth_gate_page.dart
//
// What this file is:
//   This file defines the authentication entry screen for the NeuroSync app.
//   It is the first screen a user sees when they are NOT yet logged in.
//
// Role in the app architecture:
//   The app's routing logic (typically in main.dart or a router file) decides
//   whether to show AuthGatePage (not logged in) or the main habit dashboard
//   (already logged in). This page sits at the "gate" — you must pass through
//   it to enter the rest of the app.
//
// Key concepts a learner needs to understand this file:
//
//   1. StatefulWidget vs StatelessWidget
//      Flutter has two kinds of widgets. A StatelessWidget never changes its
//      appearance after it is built. A StatefulWidget owns a "State" object
//      that can hold mutable data (like loading flags, error messages, etc.)
//      and call setState() to trigger a rebuild when that data changes.
//      We use StatefulWidget here because the form has changing state
//      (_loading, _sent, _error).
//
//   2. TextEditingController
//      A controller is a special object that "owns" a text input field.
//      You attach it to a TextField widget, and then you can read whatever
//      the user typed via controller.text at any time.
//
//   3. setState()
//      This is how you tell Flutter "my data changed, please redraw the
//      widget". You pass a callback function that mutates your fields, and
//      Flutter schedules a rebuild automatically.
//
//   4. async / await
//      Network calls (like sending an email) take time. Dart uses async
//      functions and await to pause execution until the operation finishes,
//      without freezing the whole app. The Future<void> return type means
//      "this function does something asynchronous and returns nothing."
//
//   5. Supabase magic link authentication
//      Instead of passwords, this app emails the user a one-time "magic link".
//      Clicking it opens the app (via a deep link URL scheme) and logs them
//      in automatically. Supabase is the backend-as-a-service that handles
//      all auth logic.
//
//   6. flutter_animate
//      A package that adds simple entrance animations (fade, slide, scale) to
//      any widget by chaining .animate() and effect methods on it.
// =============================================================================

// TODO SETUP — Before this screen works you need:
//
// 1. Create a Supabase project at https://supabase.com
//    - Project name: neurosync (or anything you like)
//    - Choose a region close to your users
//
// 2. Enable Email (magic link) auth:
//    Dashboard → Authentication → Providers → Email
//    - Enable Email provider: ON
//    - "Confirm email": OFF (so magic link logs in immediately)
//    - "Enable email OTP": ON
//
// 3. For deep-link redirect (so the magic link opens the app):
//    Dashboard → Authentication → URL Configuration
//    - Add to "Redirect URLs": com.neuroflow://login-callback/
//    - For web: http://localhost:62728
//
//    In flutter_app/android/app/src/main/AndroidManifest.xml add inside <activity>:
//      <intent-filter>
//        <action android:name="android.intent.action.VIEW" />
//        <category android:name="android.intent.category.DEFAULT" />
//        <category android:name="android.intent.category.BROWSABLE" />
//        <data android:scheme="com.neuroflow" android:host="login-callback" />
//      </intent-filter>
//
//    In flutter_app/ios/Runner/Info.plist add:
//      <key>CFBundleURLTypes</key>
//      <array>
//        <dict>
//          <key>CFBundleURLSchemes</key>
//          <array><string>com.neuroflow</string></array>
//        </dict>
//      </array>
//
// 4. Copy your project URL and anon key from:
//    Dashboard → Project Settings → API
//    Then run with:
//      flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//                  --dart-define=SUPABASE_ANON_KEY=eyJxxxx
//    Or add them to a .env file (never commit to git).

// Flutter's core UI library. Provides Widget, Text, Column, Scaffold,
// TextField, FilledButton, and almost every visual building block used here.
import 'package:flutter/material.dart';

// A third-party animation package. Adds the .animate() extension method to
// any widget, letting you chain entrance effects like .fadeIn() and .slideY().
import 'package:flutter_animate/flutter_animate.dart';

// The official Supabase client for Flutter. Gives us Supabase.instance.client,
// which we use to call the authentication API (signInWithOtp).
import 'package:supabase_flutter/supabase_flutter.dart';

// Our own theme file. Defines custom color tokens (textSecondary, cardBg,
// borderColor, etc.) accessible via BuildContext extension methods like
// context.cardBg. Keeps the app visually consistent.
import '../theme/app_theme.dart';

/// AuthGatePage is the authentication entry screen.
///
/// It extends [StatefulWidget], which is a widget that has mutable state
/// attached to it. Flutter splits StatefulWidget into two classes:
///   - The widget itself (AuthGatePage) — describes configuration, is immutable.
///   - The state object (_AuthGatePageState) — holds mutable data and the
///     build() method that draws the UI.
///
/// This page is shown when the user is not yet logged in. Once they
/// successfully receive and tap a magic link, the app's auth listener
/// (in main.dart) detects the new session and navigates to the main screen.
class AuthGatePage extends StatefulWidget {
  /// The const constructor means Flutter can reuse this widget object
  /// efficiently. `super.key` passes the optional key to the parent class;
  /// keys help Flutter identify and track widgets across rebuilds.
  const AuthGatePage({super.key});

  /// createState() is called once by Flutter to create the mutable state
  /// object linked to this widget. The => is Dart's arrow syntax for a
  /// single-expression function body — identical to writing { return ...; }.
  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

/// _AuthGatePageState holds all the mutable data and UI logic for AuthGatePage.
///
/// The leading underscore (_) is Dart's convention for "private to this file".
/// It extends State<AuthGatePage>, which gives us the setState() method and
/// access to the widget's configuration via `widget.someProperty`.
class _AuthGatePageState extends State<AuthGatePage> {
  // --- Fields (mutable state) ---

  /// Controls the email text input field. We read the user's typed email via
  /// _emailController.text. Must be disposed when the widget is removed from
  /// the tree to prevent memory leaks (see dispose() below).
  final _emailController = TextEditingController();

  /// True while the magic-link network request is in flight. We use this to
  /// show a loading spinner and disable the button so the user can't tap twice.
  bool _loading = false;

  /// Flips to true after the magic link email is successfully sent.
  /// When true, the form is replaced by a "check your inbox" confirmation card.
  bool _sent = false;

  /// Holds an error message string when something goes wrong (bad email format,
  /// network failure, Supabase error). Null means no error is currently shown.
  /// The String? type means "a String OR null" — the ? makes it nullable.
  String? _error;

  /// dispose() is a lifecycle method called by Flutter when this widget is
  /// permanently removed from the screen (e.g., user navigated away).
  ///
  /// We MUST call _emailController.dispose() here to release the memory and
  /// listeners held by the TextEditingController. Forgetting this causes a
  /// memory leak. Always call super.dispose() last.
  @override
  void dispose() {
    _emailController.dispose(); // Free the text field's resources.
    super.dispose(); // Let the parent State class clean up too.
  }

  /// _sendMagicLink() handles the form submission.
  ///
  /// It validates the email the user typed, then calls the Supabase auth API
  /// to email a magic link. Updates the UI to show a spinner while waiting,
  /// a confirmation card on success, or an error message on failure.
  ///
  /// Returns: Future<void> — nothing is returned, but the function is async
  /// so it can await the network call without blocking the UI thread.
  Future<void> _sendMagicLink() async {
    // .trim() removes any leading/trailing whitespace the user may have typed.
    final email = _emailController.text.trim();

    // Basic client-side validation before making a network request.
    // isEmpty checks if the string has no characters.
    // !email.contains('@') is a crude but effective email format check.
    if (email.isEmpty || !email.contains('@')) {
      // setState() triggers a UI rebuild so the error message appears in the
      // TextField's errorText. The => arrow is shorthand for a one-line body.
      setState(() => _error = 'Enter a valid email address.');
      return; // Exit the function early — do not proceed to the network call.
    }

    // Show the loading spinner and clear any previous error before the request.
    setState(() {
      _loading = true; // Activates the CircularProgressIndicator in the button.
      _error = null;   // Removes any previously displayed error message.
    });

    // try/catch/finally is Dart's error-handling structure.
    //   try    — run the risky async code.
    //   on X   — catch a specific exception type (AuthException from Supabase).
    //   catch  — catch any other unexpected error.
    //   finally — always run this code, whether success or failure.
    try {
      // await pauses this function here until Supabase responds.
      // Supabase.instance.client is the globally-initialized Supabase client.
      // .auth.signInWithOtp() sends a one-time-password magic link email.
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        // emailRedirectTo is the deep-link URL the magic link will open.
        // "com.neuroflow://login-callback/" is a custom URL scheme registered
        // in AndroidManifest.xml and Info.plist that opens THIS app.
        emailRedirectTo: 'com.neuroflow://login-callback/',
      );

      // `mounted` is a built-in flag on State that is false if the widget was
      // removed from the tree while we were awaiting the network call. Always
      // check `mounted` before calling setState() after an await, otherwise
      // Flutter will throw an error.
      if (mounted) setState(() => _sent = true); // Switch to confirmation card.
    } on AuthException catch (e) {
      // AuthException is Supabase's specific error type for auth failures
      // (e.g., rate limit exceeded, invalid email domain). e.message contains
      // a human-readable description of what went wrong.
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      // The underscore _ is a Dart convention for "I don't care about this
      // variable" — we catch any other unexpected error but don't need its value.
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      // Always turn off the loading spinner, regardless of outcome.
      if (mounted) setState(() => _loading = false);
    }
  }

  /// build() is called by Flutter every time the widget needs to be drawn
  /// (on first render, and after every setState() call).
  ///
  /// [context] is a BuildContext — a handle to the widget's position in the
  /// widget tree. It lets us look up theme data, navigate, and use our custom
  /// theme extension methods (context.cardBg, context.textSecondary, etc.).
  ///
  /// Returns: a Widget describing what should appear on screen.
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic Material Design page structure:
    // an app bar slot, a body slot, a floating action button slot, etc.
    // Here we only use `body`.
    return Scaffold(
      // SafeArea insets its child away from OS-level intrusions like the
      // notch, the status bar, and the home indicator bar at the bottom.
      body: SafeArea(
        // Padding adds empty space around its child widget.
        // EdgeInsets.symmetric(horizontal: 28) means 28 logical pixels of
        // padding on the left AND right sides only.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          // Column arranges its children vertically, one below the other.
          child: Column(
            // crossAxisAlignment controls horizontal alignment of children
            // inside a Column. .start means children align to the left edge.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacer() is a flexible empty gap that expands to fill available
              // vertical space. flex: 2 means this Spacer takes twice the space
              // of a Spacer with flex: 1. This pushes the content to the middle.
              const Spacer(flex: 2),

              // App title text with styling from the theme.
              // Theme.of(context) retrieves the active ThemeData object.
              // .textTheme.headlineLarge is a predefined large headline style.
              // ?.copyWith(...) — the ?. is the null-safe member access operator.
              // It means "call copyWith only if headlineLarge is not null".
              // copyWith() creates a copy of the style with specific overrides.
              Text(
                'NeuroSync',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,       // Make text bold.
                      color: const Color(0xFF6366F1),   // Indigo brand color (hex).
                    ),
              // .animate() comes from flutter_animate. It wraps this widget in
              // an animation runner. .fadeIn() makes it fade from invisible to
              // visible. .slideY(begin: -0.2) makes it slide down 20% of its
              // own height as it enters.
              ).animate().fadeIn().slideY(begin: -0.2),

              // SizedBox with only height creates vertical whitespace (a gap).
              const SizedBox(height: 8),

              // Subtitle text. context.textSecondary is a custom extension
              // method defined in app_theme.dart that returns a muted color.
              Text(
                'Your personal habit recovery system.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textSecondary, // Muted secondary text color.
                    ),
              // delay: 100.ms means this animation starts 100 milliseconds
              // after the widget first appears, creating a staggered effect.
              // 100.ms is flutter_animate's extension on int to create a Duration.
              ).animate().fadeIn(delay: 100.ms),

              // A flex: 1 Spacer — takes half the space of the flex: 2 Spacers,
              // creating visual breathing room between the title and the form.
              const Spacer(),

              // The `if (!_sent) ...` is a Dart collection-if inside a list
              // literal. The spread operator `...` means "insert all items from
              // this list into the parent list". Together they conditionally
              // insert a group of widgets depending on _sent's value.
              if (!_sent) ...[
                // Form view: shown while the user hasn't submitted the email yet.

                // "Sign in with email" label above the text field.
                Text(
                  'Sign in with email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600), // Semi-bold (600 on 100-900 scale).
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 16), // Gap between label and text field.

                // TextField is the text input widget.
                TextField(
                  controller: _emailController, // Binds the controller to read typed text.
                  // keyboardType hints to the OS which keyboard to show.
                  // emailAddress brings up a keyboard with @ and . easy to reach.
                  keyboardType: TextInputType.emailAddress,
                  // autofillHints lets the OS offer saved email addresses
                  // from the user's password manager or browser.
                  autofillHints: const [AutofillHints.email],
                  // textInputAction changes the action button on the soft keyboard.
                  // .done shows a "Done" button (checkmark or return key label).
                  textInputAction: TextInputAction.done,
                  // onSubmitted is called when the user taps the keyboard action
                  // button. The _ discards the passed string value (we read from
                  // the controller instead) and calls our send function.
                  onSubmitted: (_) => _sendMagicLink(),
                  // decoration wraps all visual styling of the TextField:
                  // hint text, background, borders, and error display.
                  decoration: InputDecoration(
                    hintText: 'you@example.com', // Placeholder shown when field is empty.
                    filled: true,                // Fill the field background with a color.
                    fillColor: context.cardBg,   // Background color from our theme.
                    // border is the default border (used as fallback).
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners (12px radius).
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    // enabledBorder is shown when the field is not focused.
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    // focusedBorder is shown when the user taps into the field.
                    // We highlight it with the brand indigo color.
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    // errorText displays a red message below the field.
                    // When _error is null, no error message is shown.
                    errorText: _error,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16), // Gap between field and button.

                // SizedBox with width: double.infinity stretches its child to
                // fill the full available width (like "match parent" in Android).
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // onPressed: null disables the button (grayed out, not tappable).
                    // We disable it while loading to prevent duplicate submissions.
                    // The ternary `_loading ? null : _sendMagicLink` means:
                    //   if _loading is true → null (disabled)
                    //   otherwise → pass the function reference (enabled)
                    onPressed: _loading ? null : _sendMagicLink,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo brand color.
                      // EdgeInsets.symmetric(vertical: 16) gives the button tall
                      // top/bottom padding, making it easier to tap.
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // RoundedRectangleBorder gives the button rounded corners.
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    // The button's child changes based on _loading state.
                    // When loading: show a small circular spinner.
                    // When idle: show the "Send magic link" label.
                    child: _loading
                        // CircularProgressIndicator is Flutter's spinning loader.
                        // strokeWidth: 2 makes the ring thin. We constrain its
                        // size with SizedBox so it doesn't expand to fill the button.
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Send magic link',
                            style: TextStyle(fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 250.ms),

              ] else ...[
                // Confirmation view: shown after the magic link email was sent.

                // Container is a general-purpose box widget. Here we use it
                // to create a styled card (background color, border, rounded corners).
                Container(
                  padding: const EdgeInsets.all(24), // 24px padding on all sides.
                  decoration: BoxDecoration(
                    color: context.cardBg,              // Card background from theme.
                    borderRadius: BorderRadius.circular(16), // Rounded corners.
                    // Border.all creates a uniform border on all four sides.
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      // Icon widget from Flutter's built-in Material icons set.
                      // size: 48 controls the icon's pixel size.
                      const Icon(Icons.mark_email_read_outlined,
                          size: 48,
                          color: Color(0xFF6366F1)), // Indigo brand color.

                      const SizedBox(height: 16),

                      // "Check your inbox" heading.
                      Text(
                        'Check your inbox',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center the text horizontally.
                      ),

                      const SizedBox(height: 8),

                      // Confirmation message that includes the user's email.
                      // String interpolation: ${expression} is replaced with
                      // the value of that expression inside the string.
                      Text(
                        'We sent a magic link to ${_emailController.text.trim()}. Tap it to sign in.',
                        style: TextStyle(color: context.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                // .scale(begin: const Offset(0.95, 0.95)) starts the card at
                // 95% of its final size and scales up to 100%, giving a subtle
                // "pop in" entrance. Offset here represents (scaleX, scaleY).
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 16),

                // Center widget horizontally centers its single child.
                Center(
                  // TextButton is a flat, text-only button (no fill or border).
                  child: TextButton(
                    // When tapped, reset _sent and clear the email field so the
                    // user can go back to the form and type a different address.
                    onPressed: () => setState(() {
                      _sent = false;              // Switch back to the form view.
                      _emailController.clear();   // Wipe the typed email text.
                    }),
                    child: Text('Use a different email',
                        style: TextStyle(color: context.textSecondary)),
                  ),
                ),
              ],

              // Bottom balancing Spacer — paired with the top flex: 2 Spacer to
              // keep the form vertically centered on the screen.
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
