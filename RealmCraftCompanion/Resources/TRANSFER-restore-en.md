MAC → QUEST · MANUAL RESTORE IS NOT PROTECTED BY COMPANION

ADB restore is strongly recommended. Manual copying does not provide Companion's running-game guard, automatic pre-restore backup, rollback or end-to-end comparison. No correctness or success guarantee is provided.

1. Save in RealmCraft and quit it before any change. First make an independent, complete backup of the current destination world on the Quest, and retain a ZIP on the Mac. If you cannot make a usable backup, do not continue.

2. Select the intended backup in Savegames and use Export this backup as ZIP below. Extract it on the Mac. Find the numeric world folder containing world_data, player_data and chunk files. Do not edit files inside Companion's library or copy its UUID wrapper/metadata folder to the Quest.

3. In your MTP app or headset file manager, open the local path shown below and confirm the destination world ID. Choose explicitly which world to replace. A working download from the Quest does not prove that writing back is supported. Do not proceed if the tool cannot access and write the entire destination.

4. Follow the transfer app's documented complete-folder replacement procedure for ONLY that world, with the game closed and an independent backup retained. Do not merge an old and new chunk set, overwrite unrelated worlds, or discard your recovery copy. If safe complete replacement is unavailable, stop and use ADB.

5. Wait for copying to finish and compare the result with the source if the tool supports it. Then test in the game: load, make a small change, save, quit and reload. Files may be readable yet not writable by RealmCraft because of permissions. If saving fails or anything is missing, stop using the modified world and recover from the retained backup through the recommended ADB workflow. Companion cannot verify or fix permissions for this manual route.
