# App Review Notes

## Product Summary

Debate-Coach is an education app for debate training. Users bring their own compatible API key and endpoint. The app sends the bundled `SKILL.md` or `SKILL-EN.md` prompt text exactly as shipped, without extra prompt rewriting, trimming, or orchestration.

## Review Flow

1. Launch the app.
2. Accept the onboarding disclaimer.
3. Open Settings.
4. Enter a test API endpoint, model, and API key.
5. Return to Chat.
6. Enter a motion and stance, or begin free Q&A.
7. The app sends the bundled skill prompt plus the local conversation to the configured endpoint.

## Data Handling

- Chat history is stored locally on device.
- API keys are stored in the iOS Keychain.
- No developer-operated account system is present in this version.

## Notes

- This build does not use WebView as the main app experience.
- This build does not direct users to buy API credits outside the app.
- Replace `support@example.com` and bundle identifier placeholders before release.
