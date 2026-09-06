USB TRANSFER WITH AN MTP APP · QUEST → MAC

1. In RealmCraft, save your progress and quit the game normally. Keep the Quest awake. Use a USB data cable to connect it to the Mac.

2. Put on the headset and approve its USB file-access/file-transfer notification. This is separate from USB debugging. If the notification is missing, consult Meta's current device instructions; menus and account restrictions can differ.

3. On the Mac, install an MTP-capable app from its official source, for example OpenMTP or MacDroid. For a route without ADB, explicitly choose MTP in MacDroid, not its ADB or debugging-based connection mode. Check the vendor's current terms and costs yourself.

4. Open the headset's internal storage in that app. Navigate to Android → data → com.TellurionMobile.RealmCraft → files → local. If the detected game uses a different package, use the Quest path shown below. If the folder is inaccessible or empty because of access restrictions, this route is not usable: stop and use the recommended ADB setup.

5. Review ALL numeric world folders. There may be several worlds. Choose deliberately which to copy; do not assume the first folder is your current world. Copy each selected complete world folder into a new local folder named with date, time and world ID. Use Open receiving folder below as your destination. This folder starts empty; opening it does not copy anything from the Quest. Do not move or delete the Quest original.

6. Wait until the transfer app reports completion. Check that world_data, player_data and the chunk files are present, and compare file counts and sizes where the tool permits. In Finder, compress each copied world folder to retain a ZIP backup. File counts and sizes alone do not establish byte-for-byte equality.

7. Use Import copied world / ZIP below. Choose one numeric world folder or its ZIP at a time. Companion creates a library entry from the local copy. Keep your original copy and the Quest save until you have independently confirmed that the backup is usable.
