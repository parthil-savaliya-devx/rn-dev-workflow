#!/usr/bin/env bash
# Dump every fact an App Store Connect submission needs to be checked against.
# Generic: works on any React Native repo. Missing pieces print "n/a", never fail.
# Usage: collect-evidence.sh [repo-root]   (defaults to cwd)
set -uo pipefail
cd "${1:-.}" || exit 1
say() { printf '\n=== %s ===\n' "$1"; }
first() { ls $1 2>/dev/null | head -1; }

PBX=$(first 'ios/*.xcodeproj/project.pbxproj')
# The app target's plist is the one carrying the most UsageDescription keys;
# picking by path order grabs a notification extension and reports every key absent.
PLIST=$(find ios -maxdepth 3 -name 'Info.plist' -not -path '*Pods*' -not -path '*Tests*' 2>/dev/null \
  | while read -r f; do echo "$(grep -c 'UsageDescription\|CFBundleDisplayName' "$f") $f"; done \
  | sort -rn | head -1 | cut -d' ' -f2-)
XCP=$(find ios -maxdepth 3 -name 'PrivacyInfo.xcprivacy' -not -path '*Pods*' 2>/dev/null | head -1)

say "IDENTITY"
[ -n "$PBX" ] && grep -oE '(PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|CURRENT_PROJECT_VERSION) = [^;]*' "$PBX" | sort -u || echo "n/a"

say "DEVICE SUPPORT  (1=iPhone 2=iPad 1,2=universal)"
[ -n "$PBX" ] && grep -oE '(TARGETED_DEVICE_FAMILY|SUPPORTS_MACCATALYST|SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD|SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD) = [^;]*' "$PBX" | sort | uniq -c || echo "n/a"

say "PERMISSION PROMPTS  (each needs an App Privacy type)"
[ -n "$PLIST" ] && grep -A1 'UsageDescription' "$PLIST" | grep -oE '<key>NS[A-Za-z]+UsageDescription</key>|<string>.*</string>' || echo "n/a"

say "ENCRYPTION / TRACKING KEYS"
[ -n "$PLIST" ] && { grep -A1 'ITSAppUsesNonExemptEncryption' "$PLIST" || echo "ITSAppUsesNonExemptEncryption: ABSENT -> ASC will prompt for export compliance"; }
[ -n "$PLIST" ] && grep -q 'NSUserTrackingUsageDescription' "$PLIST" \
  && echo ">> ATT PRESENT: App Privacy MUST declare >=1 type as used for tracking, or ASC blocks Add for Review" \
  || echo ">> ATT absent: declare no tracking"

say "PRIVACY MANIFEST"
if [ -n "$XCP" ]; then
python3 - "$XCP" <<'PY'
import plistlib,sys
d=plistlib.load(open(sys.argv[1],'rb'))
print("NSPrivacyTracking:", d.get('NSPrivacyTracking'))
print("required-reason APIs:", len(d.get('NSPrivacyAccessedAPITypes',[])))
for x in d.get('NSPrivacyCollectedDataTypes',[]):
    t=x['NSPrivacyCollectedDataType'].replace('NSPrivacyCollectedDataType','')
    p=' + '.join(q.replace('NSPrivacyCollectedDataTypePurpose','') for q in x['NSPrivacyCollectedDataTypePurposes'])
    print(f"  {t:20} linked={str(x['NSPrivacyCollectedDataTypeLinked']):5} track={str(x['NSPrivacyCollectedDataTypeTracking']):5} {p}")
PY
else echo "n/a"; fi

say "AD / ATTRIBUTION SDKs  (any hit => tracking is likely Yes)"
grep -icE 'appsflyer|branch|adjust|react-native-fbsdk|singular|kochava|tenjin|google-mobile-ads|admob' package.json 2>/dev/null | sed 's/^/matches: /'
grep -oE '"@?[a-z0-9@/._-]*(firebase|analytics|smartech|clevertap|moengage|segment|mixpanel|amplitude|posthog|sentry|bugsnag|datadog|onesignal|braze|iterable)[a-z0-9@/._-]*"' package.json 2>/dev/null | sort -u
[ -f ios/Podfile ] && { grep -q 'RNFirebaseAnalyticsWithoutAdIdSupport' ios/Podfile \
  && echo "ad-id support: DISABLED (no IDFA read)" \
  || echo "ad-id support: ENABLED -> binary can read IDFA"; }
[ -f ios/Podfile ] && grep -oE 'setup_permissions\(\[[^]]*\]' ios/Podfile

say "WEBVIEWS  ('unrestricted web access' = No only if every one is guarded)"
grep -rlE '<WebView|react-native-webview' src 2>/dev/null | grep -v __tests__ | while read -r f; do
  g=$(grep -cE 'onShouldStartLoadWithRequest|originWhitelist' "$f")
  printf '  %-58s guards:%s\n' "$f" "$g"
done

say "NOTE"
cat <<'TXT'
Feature-flag defaults, inert controls and UGC moderation are NOT scanned here — they
live wherever each project puts them, and a grep that finds nothing is
indistinguishable from nothing to find. Derive them by READING the repo. See
SKILL.md step 3.
TXT

say "ANDROID"
grep -oE '(applicationId|namespace) "[^"]*"|versionCode [0-9]+|versionName "[^"]*"' android/app/build.gradle 2>/dev/null | sort -u || echo "n/a"

say "LIVE URLS  (Support URL must not be the privacy policy)"
for p in "${STORE_URLS:-}"; do :; done
for u in ${STORE_URLS:-}; do
  printf '  %-52s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0' -L "$u")"
done
[ -z "${STORE_URLS:-}" ] && echo "  set STORE_URLS='<privacy> <support> <deletion>' to probe"
