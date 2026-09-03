#!/usr/bin/env bash
# Dump every fact a store submission needs to be checked against.
# Generic: works on any React Native repo. Missing pieces print "n/a", never fail.
#
# Usage: collect-evidence.sh [repo-root] [--platform ios|android|both]
#        default: repo-root=.  platform=both
set -uo pipefail

ROOT="."; PLATFORM="both"
while [ $# -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM="${2:-both}"; shift 2 ;;
    --platform=*) PLATFORM="${1#*=}"; shift ;;
    *) ROOT="$1"; shift ;;
  esac
done
case "$PLATFORM" in ios|android|both) ;; *) echo "unknown platform: $PLATFORM (ios|android|both)"; exit 2 ;; esac
cd "$ROOT" || exit 1

say()  { printf '\n=== %s ===\n' "$1"; }
want() { [ "$PLATFORM" = "both" ] || [ "$PLATFORM" = "$1" ]; }
first(){ ls $1 2>/dev/null | head -1; }

printf 'platform: %s   repo: %s\n' "$PLATFORM" "$(pwd)"

# ───────────────────────────── iOS ─────────────────────────────
if want ios; then
PBX=$(first 'ios/*.xcodeproj/project.pbxproj')
# The app target's plist is the one carrying the most UsageDescription keys;
# picking by path order grabs a notification extension and reports every key absent.
PLIST=$(find ios -maxdepth 3 -name 'Info.plist' -not -path '*Pods*' -not -path '*Tests*' 2>/dev/null \
  | while read -r f; do echo "$(grep -c 'UsageDescription\|CFBundleDisplayName' "$f") $f"; done \
  | sort -rn | head -1 | cut -d' ' -f2-)
XCP=$(find ios -maxdepth 3 -name 'PrivacyInfo.xcprivacy' -not -path '*Pods*' 2>/dev/null | head -1)

say "iOS IDENTITY"
[ -n "$PBX" ] && grep -oE '(PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|CURRENT_PROJECT_VERSION) = [^;]*' "$PBX" | sort -u || echo "n/a"

say "iOS DEVICE SUPPORT  (1=iPhone 2=iPad 1,2=universal)"
[ -n "$PBX" ] && grep -oE '(TARGETED_DEVICE_FAMILY|SUPPORTS_MACCATALYST|SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD|SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD) = [^;]*' "$PBX" | sort | uniq -c || echo "n/a"

say "iOS PERMISSION PROMPTS  (each implies a declared data type)"
[ -n "$PLIST" ] && grep -A1 'UsageDescription' "$PLIST" | grep -oE '<key>NS[A-Za-z]+UsageDescription</key>|<string>.*</string>' || echo "n/a"

say "iOS ENCRYPTION / TRACKING KEYS"
[ -n "$PLIST" ] && { grep -A1 'ITSAppUsesNonExemptEncryption' "$PLIST" || echo "ITSAppUsesNonExemptEncryption: ABSENT -> ASC will prompt for export compliance"; }
if [ -n "$PLIST" ] && grep -q 'NSUserTrackingUsageDescription' "$PLIST"; then
  echo ">> ATT PRESENT: App Privacy MUST declare >=1 type as used for tracking, or ASC blocks Add for Review"
else
  echo ">> ATT absent: declare no tracking"
fi

say "iOS PRIVACY MANIFEST"
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
fi

# ─────────────────────────── Android ───────────────────────────
if want android; then
say "ANDROID IDENTITY"
grep -oE '(applicationId|namespace) "[^"]*"|versionCode [0-9]+|versionName "[^"]*"' android/app/build.gradle 2>/dev/null | sort -u || echo "n/a"

say "ANDROID PERMISSIONS  (each implies a Data safety type)"
grep -oE 'android:name="android\.permission\.[A-Z_]+"' android/app/src/main/AndroidManifest.xml 2>/dev/null \
  | sed 's/.*permission\.//; s/"//' | sort -u || echo "n/a"

say "ANDROID ADVERTISING ID  (a declared AD_ID permission = Data safety 'Advertising' purpose)"
grep -rqE 'com\.google\.android\.gms\.permission\.AD_ID' android/app/src/main 2>/dev/null \
  && echo "AD_ID: declared -> Play expects an advertising/marketing purpose" \
  || echo "AD_ID: not declared"

say "ANDROID SIGNING  (Play re-signs; SHA-restricted services need BOTH fingerprints)"
grep -nE 'signingConfigs|storeFile|minifyEnabled|shrinkResources' android/app/build.gradle 2>/dev/null | head || echo "n/a"
fi

# ─────────────────────── platform-agnostic ─────────────────────
say "DEPENDENCIES  (classify these yourself - do not rely on a vendor list)"
if [ -f package.json ]; then
python3 -c "
import json
d=json.load(open('package.json')).get('dependencies',{})
print(f'{len(d)} dependencies:')
[print('  ',k) for k in sorted(d)]
"
cat <<'TXT'
  ^ Identify any that do analytics, marketing automation, attribution or ads.
    An attribution/ad SDK makes 'used for tracking' a Yes. A marketing-automation
    SDK earns the Marketing/Advertising purpose on whatever data it receives.
TXT
else echo "n/a"; fi
if [ -f ios/Podfile ]; then
  grep -q 'WithoutAdIdSupport' ios/Podfile \
    && echo "  ad-id support: DISABLED (no IDFA read)" \
    || echo "  ad-id support: not disabled -> an analytics SDK may be able to read the IDFA"
  grep -oE "setup_permissions\(\[[^]]*\]" ios/Podfile
fi

say "WEBVIEWS  ('unrestricted web access' = No only if every one is guarded)"
grep -rlE '<WebView|react-native-webview' src app 2>/dev/null | grep -v __tests__ | while read -r f; do
  printf '  %-58s guards:%s\n' "$f" "$(grep -cE 'onShouldStartLoadWithRequest|originWhitelist' "$f")"
done

say "NOTE"
cat <<'TXT'
Feature-flag defaults, inert controls, the real auth path and UGC moderation are NOT
scanned here — they live wherever each project puts them, and a grep that finds nothing
is indistinguishable from nothing to find. Derive them by READING the repo. See SKILL.md.
TXT

say "LIVE URLS  (a support URL must not be the privacy policy)"
if [ -n "${STORE_URLS:-}" ]; then
  for u in ${STORE_URLS}; do
    printf '  %-52s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0' -L "$u")"
  done
else
  echo "  set STORE_URLS='<privacy> <support> <deletion>' to probe"
fi
