# Pomodoro Grove — iPhone project

Peach Pop, cozy clay plants, and four categories: Vocabulary, Casual reading, Philosophy, and News. Three completed sessions meet your daily goal. Every completed session adds a permanent plant; completing all four categories adds a butterfly.

This package contains source code and a configured iOS project, **not a built IPA**. The web build, native project sync, and 10 JavaScript tests pass. Compilation with Xcode and real-device notification testing remain to be done.

## Build an IPA with GitHub Actions

1. Create a private GitHub repository and commit this folder's contents, including `.github/workflows/ios-ipa.yml`. Do not include `node_modules` or generated build folders. GitHub Actions must be enabled and your account must have available macOS runner usage.
2. Open **Actions → Build iPhone IPA → Run workflow**.
3. After the run succeeds, download the **PomodoroGrove-iPhone** artifact and unzip it. It contains `PomodoroGrove-unsigned.ipa`.

The workflow uses a macOS runner with Xcode 26+, builds for a physical iPhone, and packages an unsigned IPA. It does not need your Apple ID, signing certificate, or Apple password. Sideloadly performs signing on your own computer.

## Install with Sideloadly

1. Download Sideloadly from https://sideloadly.io on your Mac or Windows computer. Follow its current prerequisite instructions; Windows requires Apple's web versions of iTunes and iCloud.
2. Connect your iPhone by USB, unlock it, and trust the computer.
3. Open Sideloadly, select your phone, drag in `PomodoroGrove-unsigned.ipa`, enter your Apple ID in Sideloadly, and start installation.
4. Follow iOS prompts to trust the developer and enable Developer Mode if requested.
5. Open Pomodoro Grove and start a 10-second preview. Allow notifications, then lock your phone to check the completion reminder.

Free Apple accounts need re-signing every seven days. Configure Sideloadly's automatic refresh and keep your computer available for it. See its current instructions for USB/Wi-Fi pairing. Keep the same Apple ID and bundle identifier for updates; deleting the app deletes its on-device garden.

## Build on your own Mac

Requires Node.js 22+ and Xcode 26+ with iOS SDK support. The app supports iOS 15+.

```sh
npm ci
npm test
npm run ios:ipa
```

Output: `output/PomodoroGrove-unsigned.ipa`.
For Xcode editing: `npm run ios:sync` then `npm run ios:open`.

## Behavior and remaining device checks

- All artwork is bundled. The installed app works offline and saves its garden using native Preferences. It does not sync with the web preview or another phone.
- Lock-screen completion uses a scheduled local notification. Notification sound follows the in-app bell setting and iOS notification, volume, and Focus settings.
- iOS may suspend the app. The timer uses its saved deadline; reopening the app adds the completed plant once. It does not require a JavaScript timer to keep running in the background.
- Pause cancels the reminder; resume schedules the updated deadline. Ending early cancels the reminder and adds no plant.
- The 10-second preview never adds permanent plants.
- Before relying on it, test: a locked-phone completion, paused session, resumed session, early end, notification permission denied, app relaunch, offline launch, and an update installed over the existing app. Native notification delivery and iPhone layout have not been verified on a physical device yet.

Sources: https://capacitorjs.com/docs/ios · https://capacitorjs.com/docs/apis/local-notifications · https://capacitorjs.com/docs/apis/preferences · https://sideloadly.io

