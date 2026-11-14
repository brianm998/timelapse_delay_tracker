# 0254: App Store readiness

- PrivacyInfo.xcprivacy declares only the UserDefaults required-reason API (CA92.1); no tracking, domains or collected data.
- Info.plist keys come from INFOPLIST_KEY_ build settings (the plist is generated): non-exempt encryption NO, category photography, display name "Timelapse Delay".
- iPad: stays universal with four orientations and multitasking (no UIRequiresFullScreen). ContentView already centres a 640pt column above 700pt, so no layout change; a test renders iPad sizes and Split View width offscreen.
- A unit test loads the manifest from the app bundle so it cannot drop out of the target.
