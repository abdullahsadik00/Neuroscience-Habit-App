// =============================================================================
// FILE: upgrade_page.dart
//
// What this file is:
//   This file defines the "Upgrade to Pro" paywall screen for the NeuroSync app.
//
// Role in app architecture:
//   - This page is navigated to from elsewhere in the app when the user taps an
//     "Upgrade" button or hits a free-tier limit.
//   - It reads the user's current subscription status from neuro_provider.dart
//     (the central app state), so it knows whether to show the purchase buttons
//     or a "you're already Pro" confirmation.
//   - When the user taps a purchase button, it opens Stripe's hosted checkout
//     page in the phone's browser. Stripe handles payment; a Supabase Edge
//     Function (stripe-webhook) listens for the confirmation and flips isPro in
//     the database. This file does NOT process payments itself — it only opens
//     the link.
//
// Key concepts a learner needs to understand this file:
//   1. ConsumerWidget  — a Riverpod widget that can read/watch state providers.
//   2. ref.watch()     — subscribes the widget to a provider; rebuilds the UI
//                        automatically whenever the provider's value changes.
//   3. StatelessWidget — a widget that has no mutable state of its own; its
//                        appearance is determined entirely by its constructor
//                        arguments and any providers it reads.
//   4. const           — tells Dart the value is known at compile time, which
//                        lets Flutter skip rebuilding that widget unnecessarily.
//   5. url_launcher    — a Flutter plugin for opening URLs in the system browser.
//   6. flutter_animate — a package that adds animation helpers (.animate(),
//                        .fadeIn(), .slideY()) to any widget.
// =============================================================================

// TODO SETUP — Stripe integration (3 steps):
//
// 1. Create a Stripe account at https://stripe.com
//    - Create two prices: monthly ($9/mo) and annual ($79/yr)
//    - Enable Stripe Checkout
//    - Copy the payment link URLs into _monthlyUrl and _annualUrl below
//
// 2. Deploy the Supabase Edge Function (see supabase/functions/stripe-webhook/):
//    supabase functions deploy stripe-webhook
//    Set env vars in Supabase dashboard:
//      STRIPE_SECRET_KEY=sk_live_xxx
//      STRIPE_WEBHOOK_SECRET=whsec_xxx
//
// 3. In Stripe dashboard → Webhooks, add endpoint:
//    https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook
//    Events: checkout.session.completed, customer.subscription.deleted

// ---------------------------------------------------------------------------
// IMPORTS
// ---------------------------------------------------------------------------

// Flutter's Material Design widget library — provides Scaffold, AppBar, Text,
// Column, Row, Container, Icon, Colors, TextStyle, and dozens of other UI
// building blocks used throughout this file.
import 'package:flutter/material.dart';

// flutter_animate adds a fluent animation API to any widget. Calling
// .animate() on a widget returns an AnimatedWidget; chaining .fadeIn(),
// .slideY() etc. adds timed visual effects without writing AnimationController
// boilerplate manually.
import 'package:flutter_animate/flutter_animate.dart';

// flutter_riverpod is the state management library for this app. Importing it
// gives us ConsumerWidget and WidgetRef (ref), which are the tools for reading
// and reacting to shared app state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// url_launcher is a Flutter plugin that opens a URL (https://, mailto:, tel:,
// etc.) using the device's default app — a browser for https links. We use it
// to send users to the Stripe payment page.
import 'package:url_launcher/url_launcher.dart';

// neuro_provider.dart defines neuroProvider — the single source of truth for
// all app state (habits, streaks, subscription status, etc.). We watch it here
// to get the user's isPro flag.
import '../providers/neuro_provider.dart';

// app_theme.dart defines custom color/style extensions on BuildContext, like
// context.cardBg, context.borderColor, and context.textSecondary. These make
// colors automatically adapt to light/dark mode.
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// MODULE-LEVEL CONSTANTS
// These two constants live outside any class, so they're accessible anywhere
// in this file. In Dart, a leading underscore (_) marks something as
// "private to this file" — other files cannot import these constants.
// ---------------------------------------------------------------------------

// TODO: Replace with your actual Stripe Checkout payment link URLs
// The annual subscription checkout URL from your Stripe dashboard.
const _annualUrl = 'https://buy.stripe.com/YOUR_ANNUAL_LINK';

// The monthly subscription checkout URL from your Stripe dashboard.
const _monthlyUrl = 'https://buy.stripe.com/YOUR_MONTHLY_LINK';

// ---------------------------------------------------------------------------
// MAIN PAGE WIDGET
// ---------------------------------------------------------------------------

/// UpgradePage — the full-screen paywall that shows Pro features and purchase
/// buttons (or a "you're already Pro" banner if the user is subscribed).
///
/// Extends [ConsumerWidget] instead of the simpler [StatelessWidget] because
/// it needs to READ from a Riverpod provider (neuroProvider). ConsumerWidget
/// gives us a second parameter in build() called `ref`, which is the handle
/// for reading/watching providers.
///
/// This page is stateless beyond what Riverpod provides — it never calls
/// setState() because all state lives in the provider.
class UpgradePage extends ConsumerWidget {
  // 'const' constructor means Flutter can cache and reuse this widget object,
  // improving performance. 'super.key' passes the optional key parameter up to
  // the parent ConsumerWidget class (keys help Flutter identify widgets in the
  // tree when the layout changes).
  const UpgradePage({super.key});

  /// build() is called by Flutter whenever this widget needs to appear on
  /// screen (initial render) or re-render (when a watched provider changes).
  ///
  /// Parameters:
  ///   [context] — a handle to this widget's position in the widget tree.
  ///               Used to read themes (Theme.of(context)) and extensions
  ///               (context.cardBg).
  ///   [ref]     — Riverpod's "reference" object. Use ref.watch() to subscribe
  ///               to a provider, ref.read() to read it once without
  ///               subscribing.
  ///
  /// Returns a [Widget] — the complete UI tree for this screen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(neuroProvider) subscribes this widget to the NeuroState object.
    // Every time neuroProvider's state changes (e.g., isPro flips to true after
    // a successful payment), Flutter automatically calls build() again, so the
    // UI updates without any manual setState() call.
    // .isPro reads the boolean "is this user on the Pro plan?" field from state.
    final isPro = ref.watch(neuroProvider).isPro;

    // Scaffold is the standard full-screen page container in Flutter.
    // It provides slots for appBar (top bar), body (main content), FAB, drawer, etc.
    return Scaffold(
      // AppBar renders the top navigation bar.
      appBar: AppBar(
        title: const Text('Upgrade to Pro'), // The centred/left title text.
        backgroundColor: Colors.transparent, // No background — blends with the page.
      ),
      // SingleChildScrollView makes its child vertically scrollable.
      // Without this, long content on small screens would overflow and crash.
      body: SingleChildScrollView(
        // EdgeInsets.all(24) adds 24 logical pixels of padding on all four sides.
        // Logical pixels are device-independent — they look the same size on all
        // screen densities.
        padding: const EdgeInsets.all(24),
        // Column stacks its children vertically from top to bottom.
        child: Column(
          // CrossAxisAlignment.start aligns children to the LEFT edge of the column
          // (the cross axis of a vertical Column is horizontal).
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HERO BANNER ─────────────────────────────────────────────────
            // Container is a multi-purpose box widget. Here we give it padding,
            // a gradient background, and rounded corners.
            Container(
              padding: const EdgeInsets.all(24), // Inner spacing around the text.
              decoration: BoxDecoration(
                // LinearGradient draws a smooth colour transition from one colour
                // to another. 0xFF6366F1 is hex colour #6366F1 (indigo).
                // The 0xFF prefix is the alpha (opacity) channel — FF = fully opaque.
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo → purple.
                  begin: Alignment.topLeft, // Gradient starts at the top-left corner.
                  end: Alignment.bottomRight, // ...and ends at the bottom-right corner.
                ),
                // BorderRadius.circular(20) rounds all four corners with a 20px radius.
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji displayed as a large icon using a high fontSize.
                  const Text('🧠', style: TextStyle(fontSize: 36)),
                  // SizedBox with a height creates vertical space (a gap) between widgets.
                  const SizedBox(height: 12),
                  const Text(
                    'NeuroSync Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold, // Makes text thick/heavy.
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Built for people who miss habits — and come back stronger.',
                    style: TextStyle(
                      // withOpacity(0.85) makes the white colour 85% opaque (slightly
                      // transparent), creating a softer secondary text appearance.
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                // .animate() converts this Container into an animated widget from the
                // flutter_animate package.
                .animate()
                // .fadeIn() makes the widget appear with a fade-in effect (starts
                // invisible, transitions to fully visible). Default duration ~300ms.
                .fadeIn()
                // .slideY(begin: -0.1) slides the widget in from slightly above its
                // final position (begin: -0.1 means 10% of its height above target).
                // This subtle upward slide + fade creates a polished "drop in" feel.
                .slideY(begin: -0.1),

            const SizedBox(height: 28), // Vertical gap between sections.

            // ── FEATURE LIST HEADER ─────────────────────────────────────────
            // Theme.of(context).textTheme gives us the app's predefined text styles.
            // titleMedium is a medium-weight title style from the Material Design spec.
            // ?.copyWith(...) — the ?. is the "null-safe call" operator: if
            // textTheme.titleMedium is null, the whole expression returns null instead
            // of crashing. copyWith() creates a copy of the style with overrides.
            Text(
              'What you unlock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // The spread operator (...) inserts a LIST of widgets into the children
            // list, rather than inserting a single list object as one item.
            // _proFeatures is a List<_Feature>; .map() transforms each element.
            ..._proFeatures.map(
              // Arrow function (=>) — shorthand for a function that returns a single
              // expression. Here (f) is the current _Feature and the expression
              // builds a _FeatureRow widget for it.
              (f) => _FeatureRow(
                icon: f.icon, // Which icon to show for this feature.
                title: f.title, // The feature name.
                description: f.description, // The short explanation text.
                color: f.color, // The accent colour for the icon background.
              )
                  .animate()
                  .fadeIn(
                    // delay staggers each row's fade-in by 50ms × its list index,
                    // so rows appear one after another rather than all at once.
                    // _proFeatures.indexOf(f) returns the 0-based position of f.
                    // .ms is an extension from flutter_animate that converts an int
                    // (milliseconds) into a Duration object.
                    delay: (_proFeatures.indexOf(f) * 50).ms,
                  ),
            ),

            const SizedBox(height: 28),

            // ── SOCIAL PROOF CARD ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg, // App-theme card background (adapts to dark/light mode).
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor), // Thin border around the card.
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro users recover 2.3× faster',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Average recovery days drop from 4.1 → 1.8 days after unlocking failure signatures and personalized comeback protocols.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary, // Muted text colour from app theme.
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms), // Fade in after 300ms to follow the feature rows.

            const SizedBox(height: 28),

            // ── CONDITIONAL: ALREADY PRO vs. PURCHASE BUTTONS ───────────────
            // if (isPro) ...[...] else ...[...] is Dart's collection-if syntax.
            // It conditionally includes a list of widgets in the parent children
            // list, depending on the boolean condition.
            if (isPro) ...[
              // User is already subscribed — show a green confirmation banner.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // 0xFF10B981 is hex #10B981 (emerald green). withOpacity(0.12)
                  // makes it a very light tint for the background.
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3), // Subtle green border.
                  ),
                ),
                child: const Row(
                  children: [
                    // A filled checkmark circle icon in emerald green.
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12), // Horizontal gap between icon and text.
                    Text(
                      'You\'re on Pro — all features unlocked.',
                      // \' is an escape sequence for a literal apostrophe inside a
                      // single-quoted string without ending the string.
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // User is NOT on Pro — show purchase buttons.

              // Annual plan button (filled/primary, highlighted as best value).
              _PriceButton(
                label: 'Annual — \$79/year', // \$ escapes the dollar sign in Dart strings.
                sub: 'Save 27% · \$6.58/mo · Best value',
                color: const Color(0xFF6366F1), // Indigo accent.
                onTap: () => _launch(_annualUrl, context), // Opens Stripe annual URL.
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 10),

              // Monthly plan button (outlined/secondary style).
              _PriceButton(
                label: 'Monthly — \$9/month',
                sub: 'Cancel anytime',
                color: const Color(0xFF8B5CF6), // Purple accent.
                filled: false, // false = use OutlinedButton style instead of FilledButton.
                onTap: () => _launch(_monthlyUrl, context), // Opens Stripe monthly URL.
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // Reassurance text centred below the buttons.
              Center(
                child: Text(
                  '7-day free trial · No credit card to start',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ),
            ],

            const SizedBox(height: 40), // Bottom breathing room so content doesn't hug the edge.
          ],
        ),
      ),
    );
  }

  /// _launch — opens a URL in the device's external browser (e.g. Chrome/Safari).
  ///
  /// Parameters:
  ///   [url]     — the full https:// URL string to open (a Stripe checkout link).
  ///   [context] — the BuildContext, needed to show a SnackBar error if the URL
  ///               cannot be opened.
  ///
  /// Returns: a Future<void> — this function is async because launchUrl() is an
  ///   async operation that requires waiting for the OS to respond. The caller
  ///   does NOT need to await it; the animation fires and the browser opens
  ///   independently.
  ///
  /// Side effects:
  ///   - Opens the system browser with the given URL.
  ///   - If the URL cannot be opened (e.g. no browser installed), shows a
  ///     SnackBar error message at the bottom of the screen.
  Future<void> _launch(String url, BuildContext context) async {
    // Uri.parse() converts a plain String into a typed Uri object that
    // url_launcher's launchUrl() requires. It validates the URL format.
    final uri = Uri.parse(url);

    // launchUrl() is from the url_launcher package. It opens the URI.
    // LaunchMode.externalApplication forces it to open in the system browser
    // (not an in-app WebView), which is required for secure payment flows.
    // The ! prefix is the logical NOT operator — we check "if launchUrl FAILED".
    // await pauses execution here until launchUrl() completes and returns a bool.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // context.mounted is a safety check: after an await, the widget might
      // have been removed from the tree (user navigated away). Accessing context
      // on a dismounted widget throws an error. This guard prevents that crash.
      if (context.mounted) {
        // ScaffoldMessenger.of(context) finds the nearest Scaffold ancestor and
        // shows a brief notification bar at the bottom of the screen (SnackBar).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page. Try again.')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

/// _Feature — a simple data class (record-like struct) that holds the display
/// properties for one Pro feature row.
///
/// This is a private class (leading underscore), so it cannot be used outside
/// this file. It is not a widget — it's just a plain Dart object that bundles
/// four related pieces of data together, making the _proFeatures list below
/// easy to read and extend.
class _Feature {
  final IconData icon; // The Material icon to display (e.g. Icons.psychology).
  final Color color; // The accent colour used for the icon's background circle.
  final String title; // Short feature name shown in bold.
  final String description; // One-line explanation of what this feature does.

  // 'const' constructor: all fields are final (immutable), so Dart can create
  // these objects at compile time rather than at runtime. This is a performance
  // optimisation for objects that never change.
  // 'required' means the caller MUST provide a value — there is no default.
  const _Feature({required this.icon, required this.color, required this.title, required this.description});
}

// ---------------------------------------------------------------------------
// FEATURE DATA
// ---------------------------------------------------------------------------

// _proFeatures is a compile-time constant list of _Feature objects.
// Each entry describes one Pro feature that will be rendered as a row in the UI.
// This data-driven approach means adding a new feature only requires adding
// one entry here — the UI renders it automatically via .map() above.
const _proFeatures = [
  _Feature(
    icon: Icons.psychology, // Brain/mind icon.
    color: Color(0xFF6366F1), // Indigo.
    title: 'Unlimited habits & swaps',
    description: 'Free plan caps at 2 habits and 1 swap.',
  ),
  _Feature(
    icon: Icons.replay_circle_filled, // Circular replay arrow icon.
    color: Color(0xFFF59E0B), // Amber/yellow.
    title: 'Unlimited Comeback Protocol',
    description: 'Free plan gives you 3 comebacks/month. Pro removes the cap.',
  ),
  _Feature(
    icon: Icons.insights, // Line-chart / insights icon.
    color: Color(0xFF8B5CF6), // Purple.
    title: 'Failure Signatures (v2 Playbook)',
    description: 'See which habit slips most, your hardest day of the week, and your avg recovery speed.',
  ),
  _Feature(
    icon: Icons.bolt, // Lightning bolt icon.
    color: Color(0xFF10B981), // Emerald green.
    title: 'Personalized recovery protocol',
    description: 'Comeback micro-actions tailored to your failure style and peak energy window.',
  ),
  _Feature(
    icon: Icons.notifications_active, // Bell/notification icon.
    color: Color(0xFF3B82F6), // Blue.
    title: 'Smart nudges',
    description: 'Loss aversion alerts when myelination is decaying. Comeback streak protection.',
  ),
];

// ---------------------------------------------------------------------------
// PRIVATE WIDGETS
// ---------------------------------------------------------------------------

/// _FeatureRow — renders a single feature item as an icon + title + description
/// laid out horizontally (icon on the left, text on the right).
///
/// Extends [StatelessWidget] because it has no internal state — its appearance
/// is fully determined by the four constructor arguments passed in. It never
/// needs to call setState().
///
/// Used by: UpgradePage.build() via the .map() call over _proFeatures.
class _FeatureRow extends StatelessWidget {
  final IconData icon; // Which Material icon to show.
  final Color color; // Accent colour for the icon's circular background.
  final String title; // Feature name displayed in bold.
  final String description; // Supporting description in smaller muted text.

  // Private constructor — can only be instantiated within this file.
  const _FeatureRow({required this.icon, required this.color, required this.title, required this.description});

  /// build() — returns the visual widget tree for one feature row.
  @override
  Widget build(BuildContext context) {
    // Padding wraps a child and adds space around it.
    // EdgeInsets.only(bottom: 14) adds 14px of space ONLY below the row,
    // creating a gap between consecutive feature rows.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      // Row lays out its children horizontally (left to right).
      child: Row(
        // CrossAxisAlignment.start aligns all children to the TOP of the row
        // (the cross axis of a horizontal Row is vertical). This ensures the
        // icon stays at the top when the description text wraps to multiple lines.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured circular background for the icon.
          Container(
            width: 36, height: 36, // Fixed 36×36 logical pixel square.
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), // Very light tinted background.
              borderRadius: BorderRadius.circular(8), // Slightly rounded square.
            ),
            child: Icon(icon, color: color, size: 18), // Icon at 18px, coloured to match.
          ),
          const SizedBox(width: 12), // Horizontal gap between icon and text.
          // Expanded makes the Column take up ALL remaining horizontal space in the Row.
          // Without this, the text might not wrap correctly on narrow screens.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), // Semi-bold.
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary, // Muted colour from app theme extension.
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// _PriceButton — a full-width purchase button that shows a plan name and a
/// subtitle (e.g. savings info). Supports two visual styles:
///   - filled = true  → FilledButton  (solid colour background, for the highlighted plan)
///   - filled = false → OutlinedButton (transparent with a coloured border, for secondary)
///
/// Extends [StatelessWidget] because appearance is fully controlled by props.
///
/// Used by: UpgradePage.build() for the annual and monthly plan buttons.
class _PriceButton extends StatelessWidget {
  final String label; // Primary text — the plan name and price (e.g. "Annual — $79/year").
  final String sub; // Secondary text shown below the label (e.g. "Save 27%").
  final Color color; // The accent colour used for background (filled) or border (outlined).
  final bool filled; // true = FilledButton style; false = OutlinedButton style.
  final VoidCallback onTap; // The function to call when the user taps the button.
                            // VoidCallback is a Dart typedef for `void Function()` —
                            // a function that takes no arguments and returns nothing.

  // Note: 'this.filled = true' sets a DEFAULT value of true for the 'filled'
  // parameter, so callers don't need to pass it unless they want false.
  const _PriceButton({required this.label, required this.sub, required this.color, required this.onTap, this.filled = true});

  /// build() — returns either a FilledButton or OutlinedButton depending on [filled].
  @override
  Widget build(BuildContext context) {
    // SizedBox with width: double.infinity forces the button to stretch to the
    // full available width of its parent, instead of shrinking to wrap its content.
    return SizedBox(
      width: double.infinity, // double.infinity = "take as much width as available".
      // The ternary operator: condition ? valueIfTrue : valueIfFalse.
      // If filled is true, build a FilledButton; otherwise build an OutlinedButton.
      child: filled
          ? FilledButton(
              onPressed: onTap, // Called when the user taps the button.
              style: FilledButton.styleFrom(
                backgroundColor: color, // Solid background using the provided accent colour.
                padding: const EdgeInsets.symmetric(vertical: 16), // Top/bottom inner spacing.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // Rounded corners.
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8), // Slightly transparent white subtitle.
                    ),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap, // Called when the user taps the button.
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color), // Coloured border instead of a filled background.
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    // For the outlined variant, text is coloured (not white) since
                    // the background is transparent.
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary, // Muted theme colour for the subtitle.
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
