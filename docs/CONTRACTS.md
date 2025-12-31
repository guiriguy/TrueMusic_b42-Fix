# TrueMusic Fix (B42.13) — Contracts

## Goals
- B42.13 friendly
- Mod-friendly: so other mods could use without the need to intrude or break their head.
- Stable in MP.
- Try to evade intruse vanila code and fragile, using registries per contract (AcceptedMedia and helpers)

## Definitions

### Media
Media is any reproducible item by a device (cassette, vinyl, CD, VHS...)

### Device
Device is the player such as: radio, boombox, walkman, vinyl player, radio car, etc.

### Kind (Contrato de tipo)
"Kind" will identify the media or device with stable strings
- Media kinds (our case): `cassette`, `vinyl`
- Device kinds (our case): `boombox`, `walkman`, `vinyl_player`, `vehicle_radio`

> Rule, "kind" is stable and versionable, if a kind is changed is a breaking change

## Public API (Stable)

### Media Registry
Other mods can register media without the need to recode

#### `TrueMusic.MediaRegistry.register(mediaKind, matcher, descriptorFactory, opts?)`
- `mediaKind: string` (ej `cassette`)
- `matcher: function(item)->boolean`
- `descriptorFactory: function(item)->MediaDescriptor`
- `opts` opcional:
  - `priority: number` (default 0)
  - `modId: string` (for debugging)
  - `contractVersion: number` (default 1)

**MediaDescriptor (mínimo)**
- `id: string` (unique, idealy `modid:itemFulltype` all lowercase)
- `title: string`
- `artist?: string`
- `cover?: string|Texture` (if applicable)
- `sourceItemFullType: string`
- `mediaKind: string`

### Device Compatibility
#### `TrueMusic.DeviceRegistry.register(deviceKind, matcher, capabilitiesFactory, opts?)`
**DeviceCapabilities (mínimo)**
- `deviceKind: string`
- `acceptedMediaKinds: set<string>` (ej boombox accepts cassette)
- `hasVolume: boolean`
- `supportsShuffle?: boolean`
- `supportsSeek?: boolean`
- `supportsTrackList?: boolean`

### Resolution Helpers (Core)
#### `TrueMusic.Media.resolve(item) -> MediaDescriptor|nil`

#### `TrueMusic.Device.resolve(context) -> DeviceDescriptor|nil`
`context` could be:
- inventory item
- world object
- vehicle part + vehicle
- wearable slot, etc.

#### `TrueMusic.Compat.canPlay(deviceCaps, mediaDesc) -> boolean`

## ModData usage (Namespacing)
- All our info goes after this `item:getModData().TrueMusic = {...}`
- Recommended keys:
  - `contractVersion`
  - `mediaKind`
  - `mediaId`
  - `cachedDescriptor` (if anything is saved, must be short)
  - `debug` (opt-in)

**Golden Rule:** ModData is a *cache*, not a real fount of data. The contract is done by registry.

## “No Tags / Legacy Items”
If an item doesn't have a "tag":
- It will be registried by `MediaRegistry.register()` with a matcher `fullType`, `displayName`, `scriptItem`, etc.
- Optional: we make a cache of `mediaKind`/`mediaId` in modData on the first resolve.

## Vehicles
Normally the “VehiclePart:getInventoryItem()” don't have tags nor clean scripts:
- We resolve it with `DeviceRegistry.register("vehicle_radio", ...)` that looks into `part:getId()` / `part:getItemType()` / `vehicle:getScript()`.
- We never asume we can edit the script of another mod.

## Contract Versioning
- `contractVersion = 1` first one.
- Compatible changes:
  - add optional fields
  - add new kinds
- Incompatible changes:
  - rename kinds
  - change the semantics such as `resolve()` o priority
