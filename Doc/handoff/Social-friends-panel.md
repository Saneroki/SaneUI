# Handoff: Social full screen friends panel (2026-10-18)

Goal (Saneroki): the full screen's friends panel holds everything the game's friends list does, so the
game's window is no longer needed.

## Done (committed, `dev/tests/run` green: Social 421 checks)

- `src/Social/Friends.lua` is now the panel shell: head, tabs (MinimalTabTemplate, fitted to the width,
  cut words get a tooltip), search box + filter row, lazy pages per list; `Friends.Open(key, focus)`.
- `src/Social/Contacts/` (new, in the TOC after `Feed.lua`):
  - `Contacts.lua` shared colours, status icons, `Ago`, status filter, `Tell`, `Mark`, `Divider`. Documents the view contract.
  - `Account.lua` head: status dropdown (Available/Away/Busy via `C_BattleNet.SetAFK/SetDND`), your BattleTag, `n / m online`, contacts menu (Broadcast via `Core.AskText`, Ignore List).
  - `Friends.lua` friends list: favourites first, per-row invite (travel pass) with refusal reasons, multi-account menu, tooltip (BattleTag, character, zone/realm, note, broadcast, other games), filter by status and kind; foot Add Friend / Send Message / Invite.
  - `Requests.lua` tab Requests (n): add-friend line (BattleTag/e-mail/name, target prefilled from Add Friend), pending requests with Accept and Decline menu (Decline, Block Invites).
  - `Ignored.lua` ignore list + blocked invites, Remove, Ignore Player, Back.
  - `Allies.lua` Recent Allies (`C_RecentAllies`): loading state, pinned first, game's menu, filter by status + activity.
  - `Raid.lua` Raid: description + Convert to Raid, 8 groups, drag to swap/move, Everyone is Assistant, role counts, Raid Info (saved instances, extend lock, shift-click link).
  - `Quick.lua` Quick Join (n) (`C_SocialQueue`): groups, role menu then `RequestToJoin`, whisper.
- `Board.lua`: `Board.List(holder, init, top)` and `Board.Button` accept a part of a panel (`holder.label`); `Board.Label`.
- `Layout.lua`: `FRIENDS_WIDTH` 340, `TABS`, `TAB_PAD`, `TOOLS`, `LINE`, `INVITE`.
- `Social.lua` texts; `dev/tests/social.lua` stand-ins and checks for every tab.

## Open / next

1. Game needs a restart (new files in the TOC). Then try every tab in the game (look, taint of the
   game's menus `FriendsFrame_ShowDropdown`, `UnitPopup_OpenMenu` RECENT_ALLY/RAID, raid drag in and out of combat).
2. Not built: Recruit-a-Friend tab and summon button, Report Player on a request, the first Real ID warning, Who list.
3. Not decided: should the game's key (O) / `ToggleFriendsFrame` open our full screen instead of the game's window?
4. Docs still to update: `src/Social/README.md` (features, files table), `Doc/agent/social.md` (file table),
   `Doc/changelog.txt`; then `dev/tools/project-index`.
5. Filters and the tab chosen are kept for the session only.
