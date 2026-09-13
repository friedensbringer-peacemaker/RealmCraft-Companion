# RealmCraft Companion · Agent assistance

## Request
Help me set up RealmCraft Companion on my Mac, in English, one step at a time. First establish where I am stuck. Give one concrete action and the expected result at a time. Use the setup guide included below.

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

## Setup

FIRST-LAUNCH ASSISTANT

On first launch, Companion opens a step-by-step guide automatically. It separates actions on the Mac, phone and headset. Use Next and Back at your own pace. Later closes it and remembers your step; reopen it from Settings → Device setup. All settings opens the complete configuration. The final screen reports what was actually detected; finishing never starts a backup or restore.

This guide was integrated using Meta Quest as the example. Menus, permissions, account requirements and save locations can differ on other headsets or software versions. Other-headset compatibility is not guaranteed. Follow the manufacturer’s current instructions when they differ.

WHAT YOU NEED FOR EACH TASK

Recipes, material plans, build guides and help can be consulted without a connected Quest. Local recipes are comparison data, not a fully confirmed RealmCraft recipe collection. Item icons are optional; names and quantities remain visible without an installed pack.

ADB is needed for a direct Quest connection. Maps, chest search and ore analysis require the optional map tools. Tectonicus has its own experimental setup. Build coach reading uses macOS speech; Conversation has separate speech and model setup.

DURATION AND BACKGROUND TASKS

Backup and map duration depend on data volume, file count, cable, free space and cache. Wait for confirmed completion instead of relying on fixed minute estimates. Follow-up backups can reuse verified unchanged files but still check the complete snapshot.

Atlas first prepares an independently verified working copy. During the subsequent background computation you can use other areas. Progress, Cancel and later Open map remain available in the app. Optional system notices require your explicit activation and macOS permission. Tectonicus is a separate workflow and does not use these Atlas notices.

All saved chunks means the already saved coverage, not the entire theoretically generatable world. Opening an existing map does not start regeneration. Cloud-offloaded files may need downloading first.

STEP-BY-STEP SETUP

You need a Mac running macOS 14 or later, an already set up Quest, a USB data cable and your phone with the Meta Horizon app. Internet is needed for Meta account setup and downloading ADB. Backups themselves stay local.

1 · OPEN THE APP ON YOUR MAC

Extract the community ZIP. Drag “RealmCraft Companion.app” into Applications and launch that copy. The first launch uses English. Use the language selector in setup or Settings → Language to switch the entire interface; your choice is remembered. Open Settings → Device setup. The details below supplement the first-launch assistant; All settings opens its detailed options.

If macOS blocks the app, read the linked Apple “Open apps safely” guide. This community build is not yet notarized. Do not disable security for the entire Mac.

2 · SET UP ADB IN THE APP

ADB is the connection tool between your Mac and Quest. Look under Prepare your Mac in the guide, or All settings → Manage ADB. If a version number appears, ADB is already available; continue with step 3.

If ADB is missing: open Google's license terms using the link. Read them and decide whether to accept. Only then tick the checkbox and click Install ADB in the guide, or Install / update ADB from Google in the detailed settings. Wait for success, then click “Check again”.

Alternatively, under All settings → Manage ADB, click “Select existing ADB …” and choose the adb file inside your platform-tools folder. The Quest connection does not require Android Studio, Python or Xcode. Maps and chest search use additional tools; their one-click setup is described below. A Mac does not need the Windows ADB driver.

3 · PREPARE YOUR META ACCOUNT

Open the linked Meta device guide. Follow its current requirements for developer accounts, teams and account verification. Use your Quest account and complete the required confirmations yourself; manufacturer requirements can change.

4 · ENABLE DEVELOPER MODE

On your phone: Meta Horizon → headset icon → paired headset → Headset Settings → Developer Mode on. If missing, check step 3 and headset connectivity. Menu names may change.

5 · AUTHORIZE USB DEBUGGING

Connect Quest directly to Mac and put it on. Click “Check again” on Mac. Accept “Allow USB debugging” inside Quest. Choose “Always allow from this computer” only for your trusted Mac. If your Quest version offers Settings → Developer → MTP Notification, follow the current Meta instructions for it.

Debugging authorizes ADB commands from this Mac. A file-transfer prompt is a different permission. A charging-only cable cannot carry data. Enter account passwords and verification codes only in Meta's sign-in flow, never in an AI chat.

6 · CHECK THE CONNECTION

Setup should show an ADB version. “Quest & RealmCraft” should detect the game and at least one world. Use Worlds & backups → (…) → Device & world to check the device/world and choose Check connection.

No Quest: wake the headset, reconnect the cable, try another data cable or USB port. Start with a direct connection without a hub. “Confirm USB debugging”: put on the headset and check the prompt. “RealmCraft not installed”: select the correct headset and install the game there. “No world”: create and save a world in the game.

If the debugging prompt never appears, check developer mode and the current Meta guide. Finish any transfer before restarting the headset or ADB. Use “Help from an agent” in this help for guided troubleshooting.

7 · MAKE YOUR FIRST BACKUP

Save your progress in the game and close RealmCraft completely. Select the correct Quest and world on the Mac. Click “Backup from device”. Keep the cable connected and do not reopen the game until “Backed up and verified” appears. A new dated entry appears on the left.

Worlds & backups → (…) → Device & world → Close RealmCraft on Quest closes the game without saving. Use it only after saving in the game.

8 · FIND YOUR BACKUP OR EXPORT A ZIP

Under Worlds & backups → (…), Open library folder opens the library and Show in Finder reveals the selected world folder. Export ZIP archives one save; Export library backup ZIP archives the whole library. Keep an additional copy before trying a restore.

Default folder: ~/Library/Application Support/RealmCraftLibrary/Savegames. Change it under Device setup → All settings. Leave “Copy existing savegames to the new folder” selected to bring your entries along. The originals are preserved.

9 · RESTORE LATER

Save and close the game. Select a backup on the left and check its date, world ID and target headset. “Restore to Quest” first opens a confirmation. Only “Back up & restore” starts the transfer. The current target world is backed up automatically beforehand. If an error occurs, keep the game closed and read the message. See “Restore Mac → Quest” for details.

SOURCES

Meta device setup, Android hardware-device guide and Apple security guidance. Links below open the original guides; use current Meta instructions if menus differ.


SET UP MAPS AND CHEST SEARCH (OPTIONAL)

Open Settings → Device setup. In Choose your storage or All settings, click Install map tools under Map & chest tools. The same button appears in Maps when tools are missing.

The app installs Python, NumPy and Pillow in a private folder for your user and tests them afterwards. Internet is required, but no administrator password, Homebrew, Xcode or preinstalled Python. Python is downloaded from Astral/GitHub; packages come from PyPI. Existing Python installations are unchanged.

If installation fails, you can retry; a previous installation is preserved. Normal backups and the Player view do not need these map tools.


TRANSFER WITHOUT ADB · UNTESTED ALTERNATIVES

Open Settings → Device setup → Alternative: transfer without ADB. The page provides a local receiving-folder button, a mounted Quest-folder selector, path copying, local import and ZIP export. A raw MTP device has no normal Finder path. ADB remains the recommended, tested route with SHA-256 verification. No assurance of accuracy, completeness, compatibility or success is provided for external apps; use at your own risk. Other headsets may differ.

START WITHOUT A HEADSET

Choose Later in the assistant. On Home, Use offline opens recipes; Quick find at the top finds recipes, build guides, videos and help. Import a backup opens Worlds & backups, where Import backup… opens the file picker. Set up Quest returns to setup. No backup starts automatically.
