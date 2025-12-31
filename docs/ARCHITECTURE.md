# TrueMusic Fix — Architecture (Rewrite)

## Principles
- Clear separation: core/shared vs client/ui vs server/mp
- Registries are the main extension mechanism (mod-friendly)
- Keep state minimal and serializable
- “Resolve once, cache lightly”

## Proposed Folder Structure

media/
  shared/
    Core.lua                -- init + glue
    Log.lua                 -- logging toggles
    Util.lua                -- pure helpers
    Contracts.lua           -- constants + types (kinds, keys)
    Registry/
      MediaRegistry.lua
      DeviceRegistry.lua
    Resolve/
      MediaResolve.lua
      DeviceResolve.lua
    State/
      DeviceState.lua       -- state model (play/pause/track/volume)
      Serialization.lua     -- encode/decode state for mp/moddata
    Compat/
      Rules.lua             -- canPlay(), validations
  client/
    UI/
      RadioWindow.lua
      DeviceHUD.lua
      Components/...        -- reusable widgets
    Actions/
      PlayAction.lua
      StopAction.lua
      InsertMediaAction.lua
    Net/
      ClientCommands.lua
  server/
    Net/
      ServerCommands.lua
    State/
      Authority.lua         -- server as source of truth
  patches/
    LegacyAdapters.lua      -- temporary bridge to legacy if needed

docs/
  CONTRACTS.md
  ARCHITECTURE.md
  MP.md

## Layers

### shared/core
- Registries (MediaRegistry/DeviceRegistry)
- Resolution (resolve)
- Validation (Compat rules)
- Serializable state models

### client
- UI + TimedActions (UI, input, feedback only)
- Optional lightweight prediction (optimistic UI), but always reconcile with server

### server
- MP authority:
  - who is playing what
  - effective volume (if applicable)
  - current track and time (if modeled)

## Events / Initialization
- OnGameBoot / OnGameStart:
  - register built-in media/device matchers
  - build registries
- OnLoad / OnInitWorld:
  - reconcile caches if needed
- Debug:
  - a toggle in sandbox options or mod options:
    - `TrueMusic.debug = true`

## Extension Points (for other mods)
- `TrueMusic.MediaRegistry.register()`
- `TrueMusic.DeviceRegistry.register()`
- (Optional) `TrueMusic.Hooks.onResolvedMedia(fn)` for diagnostics (not required)

## Error handling
- The resolver must never crash on weird items:
  - use `pcall` where needed
  - log in debug, fail soft (return nil)
