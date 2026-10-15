# Installing PadUI

1. Close all Ryzom clients.
2. Back up the existing `user` folder and character interface settings.
3. Extract the package. Copy all files **inside its `user` folder** into your Ryzom installation's `user` folder, replacing matching files. Do not create a nested `user/user` directory.
4. Restart the client. Repeat for separate installations.

A Windows example is `C:\Spiele\steamapps\common\Ryzom\user`. Linux and macOS locations depend on the installation; check the writable data folder actually used by your client.

Open PadUI settings through the window list. Language, accents, transparency and layouts are configured centrally, including team and compact timer sizing. Timers support countdown and stopwatch modes; changing mode resets that timer.

Both `padui_mob_catalog.lua` and `padui_mobs.lua` go directly in `user`; no separate BM JSON is required. Learned boss names and many settings use Ryzom's per-character UI storage. Exit normally to save them.

For updates, replace all supplied files. Restoring older files does not automatically reset saved colours or settings. Use your backup for a full restoration.

For bug reports, include PadUI version, OS, exact client build and reproduction steps. Remove private information from logs.
