TRANSFER WITHOUT ADB · UNTESTED ALTERNATIVES

Open Settings → Quest setup → Alternative: transfer without ADB. The page provides a local receiving-folder button, a mounted Quest-folder selector, path copying, local import and ZIP export. A raw MTP device has no normal Finder path. ADB remains the recommended, tested route with SHA-256 verification. No assurance of accuracy, completeness, compatibility or success is provided for external apps; use at your own risk. Other headsets may differ.


USB TRANSFER WITH AN MTP APP · QUEST → MAC

1. In RealmCraft, save your progress and quit the game normally. Keep the Quest awake. Use a USB data cable to connect it to the Mac.

2. Put on the headset and approve its USB file-access/file-transfer notification. This is separate from USB debugging. If the notification is missing, consult Meta's current device instructions; menus and account restrictions can differ.

3. On the Mac, install an MTP-capable app from its official source, for example OpenMTP or MacDroid. For a route without ADB, explicitly choose MTP in MacDroid, not its ADB or debugging-based connection mode. Check the vendor's current terms and costs yourself.

4. Open the headset's internal storage in that app. Navigate to Android → data → com.TellurionMobile.RealmCraft → files → local. If the detected game uses a different package, use the Quest path shown below. If the folder is inaccessible or empty because of access restrictions, this route is not usable: stop and use the recommended ADB setup.

5. Review ALL numeric world folders. There may be several worlds. Choose deliberately which to copy; do not assume the first folder is your current world. Copy each selected complete world folder into a new local folder named with date, time and world ID. Use Open receiving folder below as your destination. This folder starts empty; opening it does not copy anything from the Quest. Do not move or delete the Quest original.

6. Wait until the transfer app reports completion. Check that world_data, player_data and the chunk files are present, and compare file counts and sizes where the tool permits. In Finder, compress each copied world folder to retain a ZIP backup. File counts and sizes alone do not establish byte-for-byte equality.

7. Use Import copied world / ZIP below. Choose one numeric world folder or its ZIP at a time. Companion creates a library entry from the local copy. Keep your original copy and the Quest save until you have independently confirmed that the backup is usable.


STARTING DIRECTLY ON THE QUEST · CONDITIONAL THIRD-PARTY ROUTE

1. Save in RealmCraft and quit the game. A normal file manager is not a guaranteed backup tool. The Quest's standard Files app may not expose game data at all.

2. If you want to investigate a headset file manager, the QuestFiles store link below is one example. Check its current capabilities, price, permissions and headset support before installing or buying it. We have not tested it with RealmCraft. Store availability or a file-transfer feature does not establish access to Android/data.

3. In the file manager, try to open the RealmCraft local path shown below. If Android/data or the complete world folders are unavailable, stop. Do not assume that “all files” permission grants access, and do not root the device or bypass permissions.

4. ONLY if the app can read complete world folders: identify every world and copy each chosen folder separately, preferably as a ZIP named with date, time and world ID. Keep the original on the Quest. Partial exports, screenshots and a single world_data file are not complete backups.

5. If that app supports downloading these files through a local browser transfer server, follow its instructions: put the Mac and Quest on your own trusted network, start the server, and type the exact address it displays into the Mac browser. Download the world ZIP into the receiving folder. If download/export is not supported, this route is unavailable. Stop the server after use; do not expose it publicly. Companion does not start a server or transmit files for you.

6. Wait for completion, keep the original, then import the local ZIP in Companion. Local import checks do not verify the original wireless transfer against the Quest. If any step is unavailable or uncertain, use ADB.


MAC → QUEST · MANUAL RESTORE IS NOT PROTECTED BY COMPANION

ADB restore is strongly recommended. Manual copying does not provide Companion's running-game guard, automatic pre-restore backup, rollback or end-to-end comparison. No correctness or success guarantee is provided.

1. Save in RealmCraft and quit it before any change. First make an independent, complete backup of the current destination world on the Quest, and retain a ZIP on the Mac. If you cannot make a usable backup, do not continue.

2. Select the intended backup in Savegames and use Export this backup as ZIP below. Extract it on the Mac. Find the numeric world folder containing world_data, player_data and chunk files. Do not edit files inside Companion's library or copy its UUID wrapper/metadata folder to the Quest.

3. In your MTP app or headset file manager, open the local path shown below and confirm the destination world ID. Choose explicitly which world to replace. A working download from the Quest does not prove that writing back is supported. Do not proceed if the tool cannot access and write the entire destination.

4. Follow the transfer app's documented complete-folder replacement procedure for ONLY that world, with the game closed and an independent backup retained. Do not merge an old and new chunk set, overwrite unrelated worlds, or discard your recovery copy. If safe complete replacement is unavailable, stop and use ADB.

5. Wait for copying to finish and compare the result with the source if the tool supports it. Then test in the game: load, make a small change, save, quit and reload. Files may be readable yet not writable by RealmCraft because of permissions. If saving fails or anything is missing, stop using the modified world and recover from the retained backup through the recommended ADB workflow. Companion cannot verify or fix permissions for this manual route.

SOURCES / QUELLEN · 2026-09-06
OpenMTP: https://openmtp.ganeshrvel.com/
MacDroid (select MTP / MTP wählen): https://www.macdroid.app/
QuestFiles store listing (not a RealmCraft compatibility confirmation / keine RealmCraft-Kompatibilitätsbestätigung): https://www.meta.com/experiences/questfiles-vr-file-manager/1162974433570137/
Meta USB/device guidance: https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
