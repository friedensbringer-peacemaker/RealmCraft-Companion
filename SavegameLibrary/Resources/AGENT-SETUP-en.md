# RealmCraft Companion · Agent assistance

## Request
Help me set up RealmCraft Companion 1.1.0 on my Mac, in English, one step at a time. First establish where I am stuck. Give one concrete action and the expected result at a time. Use the setup guide included below.

## My current status (optional)
- macOS version:
- Quest model:
- App version and exact visible error:
- Last successfully completed step:

## Instructions for the agent
- Check your actual tools. Without local access, guide me through the app; never claim to have operated my Mac or headset.
- Prefer the existing app and official Meta/Google guides. Check current documentation when menus differ instead of inventing steps.
- I must complete account sign-in, verification, license acceptance and USB-debugging authorization myself. Never ask for passwords, one-time codes or payment details.
- Start with setup and diagnosis. Do not overwrite or delete a world. Do not restore, uninstall, reset or clean up without my specific request. Force-stop does not save: establish that my progress was saved first.
- Start diagnosis with read-only commands. Obtain the ADB path and selected headset from the app or device list; never guess a device ID. When several devices exist, use -s with the ID I selected for device-specific commands.
- Do not upload savegames, full logs or personal paths to a service. Request only relevant error text and explain which details I can redact.
- Do not bypass Android access controls or macOS security. No root and no global disabling of Gatekeeper.
- At the end, report verified results and remaining issues separately. Setup succeeds when ADB is detected, the selected Quest is authorized, and RealmCraft and a world are found. Create a first backup only when I request it.

## Optional read-only diagnosis
Setup displays the ADB path. Use that exact path as one executable argument (quote shell paths safely):
- adb version
- adb devices -l
- adb -s SELECTED_ID shell pm list packages
- adb -s SELECTED_ID shell pidof com.TellurionMobile.RealmCraft

For pidof, exit code 1 with no output can mean the game is closed; first confirm connectivity. The detected package ID may differ. Use the app for backups and restore; do not bypass its verification with manual adb push.

## Limits
This file does not launch an agent or grant access. It contains static guidance, no personal diagnostics or savegames. The agent needs information I supply or separately configured local tools.

## Setup guide

STEP-BY-STEP SETUP

You need a Mac running macOS 14 or later, an already set up Quest, a USB data cable and your phone with the Meta Horizon app. Internet is needed for Meta account setup and downloading ADB. Backups themselves stay local.

1 · OPEN THE APP ON YOUR MAC

Extract the community ZIP. Drag “RealmCraft Companion.app” into Applications and launch that copy. The first launch uses English. The language selector at the top switches the entire interface; your choice is remembered. Click the gear button to open Setup.

If macOS blocks the app, read the linked Apple “Open apps safely” guide. This community build is not yet notarized. Do not disable security for the entire Mac.

2 · SET UP ADB IN THE APP

ADB is the connection tool between your Mac and Quest. Look under “1. Android Debug Bridge”. If a version number appears, ADB is already available; continue with step 3.

If ADB is missing: open Google's license terms using the link. Read them and decide whether to accept. Only then tick the checkbox and click “Install / update ADB from Google”. Wait for success, then click “Check again”.

Alternatively, click “Select existing ADB …” and choose the adb file inside your platform-tools folder. The finished app does not require Android Studio, Python or Xcode. A Mac does not need the Windows ADB driver.

3 · PREPARE YOUR META ACCOUNT

Open the linked Meta device guide. Meta requires a verified developer account, team membership and age 18 or above. Use your Quest account, create or join a team, and complete account verification yourself.

4 · ENABLE DEVELOPER MODE

On your phone: Meta Horizon → headset icon → paired headset → Headset Settings → Developer Mode on. If missing, check step 3 and headset connectivity. Menu names may change.

5 · AUTHORIZE USB DEBUGGING

Connect Quest directly to Mac and put it on. Click “Check again” on Mac. Accept “Allow USB debugging” inside Quest. Choose “Always allow from this computer” only for your trusted Mac. Meta also lists Settings → Developer → MTP Notification on.

Debugging authorizes ADB commands from this Mac. A file-transfer prompt is a different permission. A charging-only cable cannot carry data. Enter account passwords and verification codes only in Meta's sign-in flow, never in an AI chat.

6 · CHECK THE CONNECTION

Setup should show an ADB version. “Quest & RealmCraft” should detect the game and at least one world. The main window should show your device and a world ID. Detection runs automatically; the circular-arrow button checks again.

No Quest: wake the headset, reconnect the cable, try another data cable or USB port. Start with a direct connection without a hub. “Confirm USB debugging”: put on the headset and check the prompt. “RealmCraft not installed”: select the correct headset and install the game there. “No world”: create and save a world in the game.

If the debugging prompt never appears, check developer mode and the current Meta guide. Finish any transfer before restarting the headset or ADB. Use “Help from an agent” in this help for guided troubleshooting.

7 · MAKE YOUR FIRST BACKUP

Save your progress in the game and close RealmCraft completely. Select the correct Quest and world on the Mac. Click “Back up Quest → Mac”. Keep the cable connected and do not reopen the game until “Backed up and verified” appears. A new dated entry appears on the left.

The stop button can close the game from your Mac, but does not save progress. Only use it after saving in the game.

8 · FIND YOUR BACKUP OR EXPORT A ZIP

The folder button at bottom left opens the whole library in Finder. The folder button beside a selected save reveals its world folder. “Export ZIP” creates a portable backup. Keep an additional copy before trying a restore.

Default folder: ~/Library/Application Support/RealmCraftLibrary/Savegames. Change it in Setup. Leave “Copy existing savegames to the new folder” selected to bring your entries along. The originals are preserved.

9 · RESTORE LATER

Save and close the game. Select a backup on the left and check its date, world ID and target headset. “Restore to Quest” first opens a confirmation. Only “Back up & restore” starts the transfer. The current target world is backed up automatically beforehand. If an error occurs, keep the game closed and read the message. See “Restore Mac → Quest” for details.

SOURCES

Meta device setup and Android hardware-device guide, checked on 5 September 2026. Links below open the original guides; use current Meta instructions if menus differ.


Official sources / Offizielle Quellen:
- https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
- https://developer.android.com/studio/run/device
- https://developer.android.com/tools/releases/platform-tools
- https://support.apple.com/en-gb/102445
