import posthog from 'posthog-js';

export function trackEvent(event: string, props?: Record<string, unknown>): void {
  try {
    posthog.capture(event, props);
  } catch {
    // PostHog unavailable — fail silently
  }
}
