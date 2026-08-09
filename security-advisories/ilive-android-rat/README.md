# ILIVE Android RAT / Banking Malware — Public Defensive Advisory

> Defensive threat-intelligence publication only. The malware APK, decrypted operational source, operator credentials, and secret tokens are intentionally not published.

## Executive summary
A malicious Android APK associated with a real-world unauthorized UPI/PhonePe incident exhibits extensive Remote Access Trojan (RAT), banking/credential theft, Accessibility abuse, Device Administrator persistence, SMS/notification collection, PIN-capture logic, built-in ADB/wireless-debugging automation, screen hiding/overlay control, and remote command capabilities.

## Sample identifiers
- Package: `i422sh.wvp49.uyef.pm8qa`
- SHA-256: `8c4c373b4ae09691a86525eb504205b6365c8ec9fbedb3ea190b9f60312700a3`
- Observed filename: `ILIVE.apk` / `ILIVE(1).apk`
- Version: `9.10.36`
- Version code: `1973`
- minSdk: 26
- targetSdk: 33

## High-confidence capabilities
- Packed/obfuscated outer loader with encrypted real payload
- Accessibility-service abuse and remote UI automation
- Financial/payment app targeting
- PIN/keypad capture logic
- SMS inbox and notification collection capability
- Device Administrator / anti-uninstall behavior
- Foreground/boot/job/alarm persistence
- Built-in ADB/native ADB components and wireless-debugging pairing automation logic
- Screenshot, UI-tree, tap, swipe, key-event and ADB-shell remote actions
- Camera/photo, contacts, SMS and album-data collection commands
- Web credential harvesting / keylogging-related logic
- Black-screen / overlay / transparent-screen controls
- Launcher/icon hiding and anti-delete features
- Post-compromise install/update/uninstall APK commands

## Financial targets
The analyzed target table contained 83 financial/payment/trading/crypto package identifiers. Examples include PhonePe, Google Pay, Paytm, BHIM, CRED, SBI, ICICI, HDFC, Axis Bank, Bank of Baroda, IDFC First Bank, Groww, Zerodha, Upstox, Angel One, Binance, Coinbase, MetaMask and Trust Wallet.

## Infrastructure / IOCs
- `chaorencctv1.com`
- `duodaduo.com`
- Related-domain candidate: `chaorencctv.com` (validate independently)
- Observed panel: `https://chaorencctv1.com/panel`
- Observed campaign/build identifier: `10028`
- Observed endpoint patterns include `/adv.php?apk=10028&device=...`, `/api/ocr-captcha`, and `/api/keylog/ingest` on the secondary backend.

## Important installation finding
Static reverse engineering did not identify a pre-install zero-click exploit that causes the APK to execute merely because the raw APK exists in storage. A passive APK file on an otherwise uncompromised Android device does not execute its own code until installation/execution occurs. Separate privileged installation mechanisms (for example already-authorized ADB, another privileged/root process, device-management/privileged installers, or unrelated platform exploitation) must be considered independently.

## Defensive actions
1. Do not install APKs received through unknown links/messages.
2. Disable **Install unknown apps** for browsers, messengers and file managers unless required.
3. Review Accessibility services and remove unknown entries.
4. Review Device Admin, Notification Access, Overlay, Usage Access, VPN and All-files access.
5. Keep USB debugging and Wireless debugging OFF when not needed and revoke old ADB authorizations.
6. If this sample was installed on a banking device, preserve evidence first, then consider a clean factory reset and manual reinstall from trusted stores.
7. Change banking/UPI/account credentials from a known-clean device where appropriate.

## Disclosure note
This repository publishes only defensive indicators and analysis. It intentionally withholds the malware binary, decrypted operational source, C2 credentials, secret tokens, and operator access details to avoid enabling abuse.
