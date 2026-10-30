# SkuaZZ

A personal fork of [VibeSkua](https://github.com/NinjaXz/VibeSkua) that fixes the problems I kept running into while botting several AQW accounts at once, plus a few quality-of-life features that came out of those fixes.

Everything else (tabbed host, army controls, scheduler, headless mode, etc.) is VibeSkua's work. See the [VibeSkua README](https://github.com/NinjaXz/VibeSkua) for the full feature list.

---

## Problems fixed

### Accounts falling back to the login screen after a relogin
An account would disconnect, relog fine, and a few minutes later "blink" and go back to the login screen for good. Three causes:

* **~30 relogins at once.** The "connection lost" check runs every 100 ms and the relogin only marked itself as running *after* stopping the script, which can take seconds. Every check in that window started its own relogin, and the extra ones logged the account out again after the first one succeeded. The relogin is now claimed before anything is awaited.
* **Stale connection overlay.** After a relogin the connection overlay (`mcConnDetail`) could stay on stage with its old text while the player was already in game. The "stuck on loading" check then called `Logout()` after `LoadTimeout`, which counts as an intentional logout and skips auto relogin. The overlay is ignored while the player is connected and loaded, and "has been lost" only counts when the socket is really down.
* **Relogin cancelling itself.** Logging out between relogin attempts sent the same message a manual logout sends, which cancelled the relogin in progress. Retries after a failed first attempt never happened.

### Scripts not restarting after a disconnect
When stopped by a logout, CoreBots restarts the script by itself 5 seconds later, while the account is still disconnected. The script then stopped with *"Please log-in before starting the bot"* and sat on that dialog, so the relogin's own restart got "Script already running". `RestartScriptAsync` now waits for auto relogin to bring the player back first.

### False disconnects
Transient Flash read failures (a busy Flash returning `false`) were taken as a disconnect. A disconnect now has to persist for 10 seconds before relogin triggers.

### Class Enhance button doing nothing / spamming `/join`
* Updating the scripts brings back an unpatched `CoreAdvanced.cs`, so the Enhance script failed to compile without telling anyone. The class enhance patch is now re-applied automatically before every script compile, and errors are shown.
* The enhance script (and the Loadouts Manager's, after equipping) returned to the map with `Map.FullName` (`battleon-3`), so CoreBots sent `/join battleon-3-<room>` in an endless retry loop. Both use `Map.Name` now.

### Local scripts missing from Search Scripts
Scripts copied into the Scripts folder by hand (third-party packs such as UltrasLW) didn't show up in Search Scripts. They are now listed under All / Local / Pinned with a "Local" tag. Update All and Download All still only touch repository scripts.

---

## Added along the way

* **Multiple launchers.** Open an account in a new launcher or pick one of the open launchers. Launchers can start empty and stay open with no tabs. Tabs can be moved between launchers while running, and closing a launcher with running accounts asks first.
* **Per-class enhance profiles.** In CoreBots Options › Class Enhance, each class gets its recommended enhancements, which you can override. A "Keep" option leaves a slot untouched, and an Enhance button applies the profile to the equipped class.
* **Class enhance profiles in Loadouts.** Each loadout has a "Use class profile" option: Equip then enhances with the class's CoreBots profile instead of the enhancements saved with the loadout. The loadout shows the profile that will be applied, and a ✎ button opens it in CoreBots Options › Class Enhance, on the same account and class.
* **CoreBots profiles of connected accounts.** The CoreBots Options header is a dropdown with every account logged in on any open tab, so you can edit another account's options without switching tabs. The Loadouts Manager has the same dropdown to view, rename and delete another account's loadouts (equipping and saving stay on the account of the tab).
* **Script options from the Manager.** A ⚙ button next to the auto-start script opens that script's options dialog without starting a client.
* **Simpler UI.** The account toolbar only shows selection actions while accounts are checked. The script shows its name instead of the full path. Boolean options are on/off switches instead of Enabled/Disabled buttons.

---

## Building

There are no releases for this fork, so build it from source (.NET 10 SDK):

```cmd
BuildProject.bat
```

This compiles the client, the Manager and the plugins, and stages everything into `Build\`. Run `Build\SkuaZZ.Manager.exe`.

Manual build:

```bash
dotnet build Skua.App.Avalonia -c Release
dotnet build Skua.Manager.Avalonia -c Release
powershell -ExecutionPolicy Bypass -File .\package-build.ps1
```

> **Note:** The Manager's updater checks [KzizYvMh/skuaziz](https://github.com/KzizYvMh/skuaziz/releases) releases.

**Game player:** the game runs in a separate program, the Skua build of [Mugetsu](https://github.com/mugetsu-aqw/mugetsu) (a modified [Ruffle](https://ruffle.rs)), shipped in the `player` folder. It is licensed under the GPL-3.0, separately from SkuaZZ; its full source is at [retr0gr4d3/skua-mugetsu](https://github.com/retr0gr4d3/skua-mugetsu), and its license texts are in `player\LICENSES`.

---

## Credits

* **[auqw/skua](https://github.com/auqw/skua)** — Original Skua framework and botting API.
* **[ArrowDev](https://github.com/ArrowDev123/Skua) (BlackArrow on Discord)** — Early Avalonia port.
* **[NinjaXz/VibeSkua](https://github.com/NinjaXz/VibeSkua)** — The Avalonia client overhaul this fork is based on.
* **[retr0gr4d3/Bonxie](https://github.com/retr0gr4d3/Bonxie)** — Ruffle/Mugetsu game player integration.

---

### Disclaimer

**Educational & personal use only.** This project is a derivative of [auqw/skua](https://github.com/auqw/skua) and is provided "as-is" under the MIT License. No ownership is claimed over the original assets, game data or the game developers' intellectual property.

Using this software may violate the game's Terms of Service. You use it entirely at your own risk; the author is not responsible for bans or any other action taken against your accounts.
