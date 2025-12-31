# TrueMusic Fix — MP Model

## Core idea
- The server is authoritative for playback state.
- The client requests actions.
- The server validates, applies, and replicates.

## What is "state"?
DeviceState (serializable):
- deviceId (stable string)
- deviceKind
- isPlaying (bool)
- mediaId (string)
- trackIndex (int)
- positionMs (int) (optional)
- volume (0..1 or 0..N)
- lastUpdateTick/time (for interpolate/reconcile)

## Identifying a device (deviceId)
Must be stable and reproducible:
- Inventory device: `playerOnlineId + ":" + itemGuidOrFullType + ":" + slot` (if there is a GUID)
- World object: `squareX,Y,Z + ":" + objectIndex + ":" + kind`
- Vehicle: `vehicleId + ":" + partId`

> If there is no true GUID, use the best stable composition available and accept that in edge cases we re-resolve.

## Network commands (pattern)
Client -> Server:
- `RequestPlay(deviceId, mediaId)`
- `RequestStop(deviceId)`
- `RequestSetVolume(deviceId, volume)`
- `RequestNext(deviceId)`
- `RequestPrev(deviceId)`
- `RequestInsertMedia(deviceId, itemRef)` (if applicable)

Server -> Clients (broadcast / relevant):
- `StateUpdate(deviceId, DeviceState)`
- `StateRemove(deviceId)`

## Validation rules (server)
Before applying:
- The device exists and resolves to a deviceKind.
- The media exists and resolves to a mediaKind.
- `Compat.canPlay(deviceCaps, mediaDesc) == true`
- The player has actual access (distance, ownership, etc.) if applicable.

## Replication storage
Options:
1) Object/vehicle/item ModData (when possible)
2) GlobalModData / server-held map (when the device has no clear host)

Rule:
- If a “device host” exists (vehicle part / world object), prefer local ModData.
- Otherwise keep a server-side map and replicate via commands.

## Reconcile / Desync
Client:
- on `StateUpdate`, overwrite UI state with server state.
- if using optimistic UI, correct smoothly.

## Performance
- Do not spam updates every tick.
- For continuous playback: update every X seconds or only on relevant changes.
