// =============================================================================
// FILE: notification_service.dart
//
// WHAT THIS FILE IS:
//   A service class that schedules and manages all push notifications for the
//   NeuroSync habit app. "Service" here means a plain Dart class (not a widget)
//   that encapsulates a specific capability — in this case, local notifications.
//
// ROLE IN THE APP ARCHITECTURE:
//   This file sits in the "services" layer, below UI widgets and above native
//   platform APIs. Other files (e.g., main.dart, habit screens) call the static
//   methods here to schedule or cancel reminders. It never rebuilds a widget —
//   it only talks to the device OS notification system.
//
//   Flow: UI/logic layer  →  NotificationService  →  flutter_local_notifications
//         (your app code)       (this file)            (native Android / iOS API)
//
// KEY CONCEPTS A LEARNER NEEDS TO KNOW:
//   1. LOCAL NOTIFICATIONS vs PUSH NOTIFICATIONS:
//      - Push notifications come from a remote server (e.g., Firebase).
//      - Local notifications are scheduled entirely on-device, no server needed.
//        This file uses local notifications only.
//
//   2. STATIC MEMBERS:
//      All methods and fields in this class are marked `static`. That means you
//      call them on the class name itself (NotificationService.init()) rather
//      than on an instance. You never write `NotificationService()` to create an
//      object. Think of it like a utility/helper namespace.
//
//   3. ASYNC / AWAIT:
//      Talking to the OS (requesting permissions, scheduling alarms) is slow and
//      might fail. Dart models this with `Future<T>` — a value that will arrive
//      later. Marking a function `async` lets you use `await` inside it, which
//      pauses that function until the Future completes, without blocking the UI.
//
//   4. TIMEZONES:
//      If you schedule "8:00 AM" using plain DateTime, it might fire at the
//      wrong time when the user travels or observes daylight saving. The `tz`
//      package provides timezone-aware datetimes (TZDateTime) that always refer
//      to the user's local clock, not a fixed UTC offset.
//
// ANDROID MANIFEST SETUP (still required — already documented in README.md):
//   Add inside <manifest> in android/app/src/main/AndroidManifest.xml:
//     <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
//     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
//
// WHY inexactAllowWhileIdle (not exactAllowWhileIdle):
//   Exact alarms require the SCHEDULE_EXACT_ALARM permission. Android 12+ forces
//   users to grant this manually in system Settings — a friction that kills
//   onboarding conversion. Inexact alarms fire within ~15 minutes of the target
//   time, which is perfectly acceptable for daily habit reminders.
// =============================================================================

// --- IMPORTS ------------------------------------------------------------------

// flutter_local_notifications: The main package for scheduling and showing
// notifications on both Android and iOS without a remote server.
// It wraps the native Android AlarmManager / iOS UNUserNotificationCenter APIs.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// timezone/timezone.dart: Provides TZDateTime — a DateTime that knows about
// the device's local timezone (including daylight saving transitions).
// We alias it as `tz` so we can write `tz.TZDateTime(...)` for clarity.
import 'package:timezone/timezone.dart' as tz;

// timezone/data/latest.dart: Contains the full IANA timezone database
// (hundreds of city/region entries). Must be loaded once at startup via
// tz_data.initializeTimeZones() before any TZDateTime can be created.
import 'package:timezone/data/latest.dart' as tz_data;

// =============================================================================

/// A static service class that owns every local notification in the app.
///
/// Because all members are `static`, you never instantiate this class.
/// Instead, call its methods directly on the class:
///   ```dart
///   await NotificationService.init();
///   await NotificationService.scheduleDailyReminder();
///   ```
///
/// The class is responsible for:
///   - Initialising the notifications plugin once.
///   - Requesting OS permission from the user.
///   - Scheduling four types of timed reminders.
///   - Cancelling reminders when they are no longer needed.
class NotificationService {

  // ---------------------------------------------------------------------------
  // FIELDS (class-level variables — all static, so shared across the whole app)
  // ---------------------------------------------------------------------------

  /// The singleton instance of the flutter_local_notifications plugin.
  ///
  /// `static` — one shared instance for the entire app lifetime.
  /// `final` — the reference itself cannot be reassigned after creation.
  /// `_` prefix — Dart convention for private members (not accessible outside
  ///   this file).
  ///
  /// FlutterLocalNotificationsPlugin is the single entry point for all
  /// notification operations: scheduling, cancelling, and initialising.
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Guards against calling init() more than once.
  ///
  /// Initialising the plugin twice can cause duplicate channel registrations on
  /// Android. This flag is checked at the top of init() and flipped to `true`
  /// after the first successful initialisation.
  static bool _initialized = false;

  // --- Notification Channel constants ----------------------------------------
  // Android groups notifications into "channels". Users can disable individual
  // channels in their phone's Settings app. We use one channel for all reminders.

  /// The unique identifier string for this app's Android notification channel.
  ///
  /// `const` means the value is known at compile time and never changes —
  /// more efficient than a regular `final` variable.
  static const _channelId = 'neurosync_main';

  /// The human-readable name shown in Android's notification settings UI
  /// (Settings → Apps → NeuroSync → Notifications → "NeuroSync Reminders").
  static const _channelName = 'NeuroSync Reminders';

  // --- Notification ID constants ---------------------------------------------
  // Every scheduled notification needs a unique integer ID. Using named
  // constants instead of raw numbers makes the code self-documenting and
  // prevents accidental ID collisions (e.g., cancelling the wrong notification).

  /// ID for the recurring 8 AM morning habit reminder.
  static const _idDailyReminder = 1;

  /// ID for the loss-aversion nudge that fires N days after the user stops
  /// opening the app ("Your myelination is decaying").
  static const _idLossAversion = 2;

  /// ID for the comeback-streak nudge that fires 2 days after a missed habit.
  static const _idComebackNudge = 3;

  /// ID for the recurring 8 PM evening check-in reminder.
  static const _idEveningCheckin = 4;

  // ---------------------------------------------------------------------------
  // METHODS
  // ---------------------------------------------------------------------------

  /// Initialises the notifications plugin. Must be called once at app startup
  /// (typically from main.dart) before any other method in this class.
  ///
  /// What it does:
  ///   1. Loads the full IANA timezone database into memory.
  ///   2. Configures platform-specific initialisation settings.
  ///   3. Passes those settings to the plugin.
  ///
  /// Returns: `Future<void>` — a Future that completes when init is done,
  /// carrying no value. The caller should `await` this.
  ///
  /// Side effect: sets _initialized = true so subsequent calls are no-ops.
  static Future<void> init() async {
    // Guard: if already initialised, exit immediately. The `return` inside an
    // async function just completes the Future with no value.
    if (_initialized) return;

    // Load the full timezone database (all cities/regions). This must happen
    // before any tz.TZDateTime constructor is called, or it will throw.
    tz_data.initializeTimeZones();

    // Android needs to know which icon to show in the notification tray.
    // '@mipmap/ic_launcher' refers to the app's default launcher icon stored
    // in android/app/src/main/res/mipmap-*/ic_launcher.png.
    // `const` here means this object is created at compile time (memory-efficient).
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin = Apple's OS family: iOS + macOS) settings.
    // We defer all three permission prompts to false here because we want to
    // ask the user at a deliberate onboarding moment (better conversion rates)
    // rather than on first app launch when they might not yet trust the app.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // don't show banner/alert permission yet
      requestBadgePermission: false, // don't ask to show badge count on icon yet
      requestSoundPermission: false, // don't ask to play notification sounds yet
    );

    // Combine the per-platform settings into one unified object, then pass it
    // to the plugin. `await` pauses this function until the plugin is ready.
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Mark as done so we don't re-initialise on hot-restart or subsequent calls.
    _initialized = true;
  }

  /// Asks the OS to show a permission dialog to the user.
  ///
  /// On iOS, the first call to this will display a system alert:
  ///   "NeuroSync would like to send you notifications — Allow / Don't Allow"
  /// On Android 13+ (API 33+), notifications also require runtime permission.
  ///
  /// Returns: `Future<bool>` — true if permission was granted on at least one
  /// platform, false if the user denied or an error occurred.
  ///
  /// Why try/catch? Platform calls can throw if the plugin isn't ready or the
  /// device is in an unusual state. We catch all errors and return false so the
  /// app doesn't crash — the user simply won't get notifications.
  static Future<bool> requestPermission() async {
    try {
      // resolvePlatformSpecificImplementation<T>() returns the iOS-specific
      // implementation if we're on iOS, or null on Android. The `?.` (null-safe
      // call) means: "only call requestPermissions if this isn't null".
      // `alert: true` — allow banner notifications to appear on screen.
      // `badge: true` — allow a number badge on the app icon.
      // `sound: true` — allow notification sounds.
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Same pattern for Android — resolves to the Android implementation or null.
      final android = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // `== true` is needed because both variables are nullable (bool?).
      // In Dart, `null == true` is false, so this safely handles the case
      // where the platform-specific implementation wasn't available.
      return ios == true || android == true;
    } catch (_) {
      // `_` is a conventional name for "I acknowledge this variable exists but
      // I don't need to inspect the error". We silently return false.
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATION DETAIL GETTERS
  // These are computed properties (getters) — they look like fields but run
  // code each time they are accessed. The `get` keyword defines a getter.
  // ---------------------------------------------------------------------------

  /// Builds the Android-specific visual and behavioural details for a notification.
  ///
  /// Returns: a new [AndroidNotificationDetails] instance each time it's called.
  ///
  /// `Importance.high` — shows as a banner at the top of the screen and makes
  ///   a sound (Android's "heads-up" notification behaviour).
  /// `Priority.high` — equivalent signal for older Android versions (< API 26).
  static AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
        _channelId,   // must match the channel ID registered during init
        _channelName, // human-readable label shown in notification settings
        importance: Importance.high, // controls whether it appears as a banner
        priority: Priority.high,     // legacy priority for Android < 8.0
        icon: '@mipmap/ic_launcher', // icon shown in the status bar
      );

  /// Bundles the Android and iOS details into a single cross-platform object
  /// that the plugin's `zonedSchedule` method accepts.
  ///
  /// Returns: a [NotificationDetails] wrapping both platform configs.
  ///
  /// `DarwinNotificationDetails()` with no arguments uses iOS defaults
  /// (sound on, alert style from system settings, etc.).
  static NotificationDetails get _details => NotificationDetails(
        android: _androidDetails,                  // use our custom Android config
        iOS: const DarwinNotificationDetails(),    // use iOS defaults
      );

  // ---------------------------------------------------------------------------
  // SCHEDULING METHODS
  // ---------------------------------------------------------------------------

  /// Schedules a repeating daily reminder at 8:00 AM in the user's local timezone.
  ///
  /// The notification fires every day at 8 AM until explicitly cancelled.
  ///
  /// Parameters: none — the time is hardcoded to 8:00 AM.
  ///
  /// Returns: `Future<void>` — completes when the notification is registered
  /// with the OS. If something goes wrong, the error is silently swallowed.
  static Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.zonedSchedule(
        _idDailyReminder,                              // unique ID to identify/cancel this notification
        'Build your neural pathway',                   // notification title (bold text)
        "Tap to log today's habits and strengthen your myelination.", // notification body
        _nextInstanceOf(hour: 8, minute: 0),           // when to fire — next occurrence of 8:00 AM
        _details,                                      // visual/sound settings (Android + iOS)
        // inexactAllowWhileIdle: fire ~15 min near the target time even if the
        // device is in Doze mode (screen off, low power). Avoids needing the
        // SCHEDULE_EXACT_ALARM permission (see file header for rationale).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // absoluteTime: treat the scheduled time as a wall-clock time, not
        // relative to a calendar component. Required for zonedSchedule.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // DateTimeComponents.time: repeat daily, matching only the time part
        // (hour + minute). Without this, it would fire only once.
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Silently ignore failures (e.g., permission not granted, plugin not
      // initialised). The app continues to work without notifications.
    }
  }

  /// Schedules a repeating evening check-in notification at 8:00 PM local time.
  ///
  /// Fires every day at 20:00 (8 PM) and prompts the user to log slips or
  /// comebacks. The logic is identical to scheduleDailyReminder — only the
  /// hour, title, and body differ.
  ///
  /// Returns: `Future<void>`.
  static Future<void> scheduleEveningCheckin() async {
    try {
      await _plugin.zonedSchedule(
        _idEveningCheckin,               // unique ID for the evening check-in slot
        "How'd today go?",               // notification title
        'Log any slips or comebacks — data turns into recovery insights.', // body
        _nextInstanceOf(hour: 20, minute: 0), // next occurrence of 8:00 PM
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (_) {}
  }

  /// Schedules a one-time "loss aversion" nudge for N days in the future.
  ///
  /// This is a behavioural psychology technique: framing inaction as *losing*
  /// something (neural pathway decay) is more motivating than framing action
  /// as *gaining* something.
  ///
  /// INTENDED USAGE:
  ///   - Called when the app moves to the background (onPause lifecycle).
  ///   - Cancelled via cancelLossAversionNudge() when the user reopens the app.
  ///   This creates a "snooze bomb" that only goes off if the user truly ghosts.
  ///
  /// Parameters:
  ///   [daysFromNow] — how many days to wait before firing. Defaults to 3.
  ///     Providing a named parameter with a default value (int daysFromNow = 3)
  ///     means callers can omit it: scheduleLossAversionNudge() uses 3 days,
  ///     or they can override: scheduleLossAversionNudge(daysFromNow: 5).
  ///
  /// Returns: `Future<void>`.
  static Future<void> scheduleLossAversionNudge({int daysFromNow = 3}) async {
    try {
      // Cancel any previously scheduled nudge before scheduling a new one.
      // Without this, re-calling this method would accumulate duplicate entries.
      await _plugin.cancel(_idLossAversion);

      // Calculate the target date: right now + N days.
      // tz.TZDateTime.now(tz.local) — "now" expressed in the device's local
      // timezone. `.add(Duration(...))` returns a new TZDateTime offset by the
      // given duration (Dart Duration objects are immutable — add returns a copy).
      final fireAt = tz.TZDateTime.now(tz.local).add(Duration(days: daysFromNow));

      await _plugin.zonedSchedule(
        _idLossAversion,
        '🧠 Your myelination is decaying',  // title — emotionally evocative on purpose
        'Without reinforcement, neural pathways weaken. 3 minutes is all it takes to reverse this.',
        // Construct a TZDateTime for 9:00 AM on the target day.
        // Arguments: (timezone, year, month, day, hour, minute)
        // We extract year/month/day from fireAt to get "N days from today",
        // but pin the hour to 9 and minute to 0 for a civilised delivery time.
        tz.TZDateTime(tz.local, fireAt.year, fireAt.month, fireAt.day, 9, 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // No matchDateTimeComponents here — this is a one-shot notification,
        // not a repeating one. Omitting the parameter means fire once and done.
      );
    } catch (_) {}
  }

  /// Schedules a one-time "comeback streak at risk" nudge for 2 days from now.
  ///
  /// Fires at 10:00 AM exactly 2 days from now, at 10:00 AM local time.
  /// Reminds the user that a habit was missed and prompts them to open the
  /// Comeback Protocol feature before the streak resets further.
  ///
  /// INTENDED USAGE: called after a habit slip is recorded.
  ///
  /// Returns: `Future<void>`.
  static Future<void> scheduleComebackNudge() async {
    try {
      // Cancel any previous comeback nudge to avoid duplicates stacking up.
      await _plugin.cancel(_idComebackNudge);

      // `const Duration(days: 2)` — a compile-time constant duration of 48 hours.
      // Using `const` here is a minor performance optimisation (object is reused
      // from memory rather than newly allocated).
      final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(days: 2));

      await _plugin.zonedSchedule(
        _idComebackNudge,
        '↩ Your comeback streak is at risk',   // title with a return-arrow emoji
        'You missed a habit yesterday. Open your Comeback Protocol before the pathway fades.',
        // Pin delivery to 10:00 AM on the calculated future date.
        tz.TZDateTime(tz.local, fireAt.year, fireAt.month, fireAt.day, 10, 0),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // One-shot (no matchDateTimeComponents), so it fires once and stops.
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // CANCELLATION METHODS
  // ---------------------------------------------------------------------------

  /// Cancels the loss-aversion nudge that was previously scheduled.
  ///
  /// Should be called whenever the user opens the app (app resume / foreground
  /// lifecycle event). If no nudge was scheduled, this is a safe no-op.
  ///
  /// Returns: `Future<void>`.
  static Future<void> cancelLossAversionNudge() async {
    try {
      // _plugin.cancel(id) removes a pending notification by its integer ID.
      // If no notification with that ID exists, it does nothing — safe to call
      // unconditionally.
      await _plugin.cancel(_idLossAversion);
    } catch (_) {}
  }

  /// Cancels ALL pending notifications registered by this app.
  ///
  /// Use this when the user explicitly turns off all reminders in settings,
  /// or during a sign-out / data-clear flow.
  ///
  /// Returns: `Future<void>`.
  static Future<void> cancelAll() async {
    try {
      // cancelAll() removes every scheduled notification for this app from
      // the OS queue, regardless of ID. Irreversible — call scheduling methods
      // again to restore them.
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------

  /// Calculates the next occurrence of a given wall-clock time in local timezone.
  ///
  /// Examples:
  ///   If it is currently 07:50 and you call _nextInstanceOf(hour: 8, minute: 0),
  ///   it returns today at 08:00.
  ///
  ///   If it is currently 08:10 and you call _nextInstanceOf(hour: 8, minute: 0),
  ///   it returns tomorrow at 08:00 (because today's 8 AM has already passed).
  ///
  /// Parameters:
  ///   [hour]   — 24-hour clock hour (0–23). `required` means callers must
  ///              provide it; there is no default.
  ///   [minute] — minute of the hour (0–59). Also required.
  ///
  /// Returns: a [tz.TZDateTime] representing the next firing time.
  ///
  /// The `_` prefix makes this private — only code inside this file can call it.
  static tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    // Get the current moment in the device's local timezone.
    final now = tz.TZDateTime.now(tz.local);

    // Build a candidate TZDateTime for today at the requested hour:minute.
    // `var` (instead of `final`) because we might need to mutate it below.
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the scheduled time has already passed today, advance by one day.
    // `.isBefore(now)` — returns true if `scheduled` is earlier than `now`.
    // `.add(const Duration(days: 1))` — returns a new TZDateTime 24 hours later.
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    // Return the (possibly adjusted) next-occurrence time.
    return scheduled;
  }
}
