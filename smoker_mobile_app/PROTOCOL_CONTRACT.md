# Smoker Protocol Contract

The interactions executed by the `smoker_mobile_app` mirror the v5.0.1+ firmware constraints. 

## WebSocket Endpoints

- All raw socket interactions occur on `<host>:<port>/ws`
- WebSockets operate bidirectionally using stringified JSON parsing. Partial payloads update properties differentially via `LiveState.copyWithJson()`. 

## Outbound Commands

- `getValues` : Request immediate read payload
- `getHistory` : Start chunked history transfers
- `getOTAInfo` : Request update details.
- `checkOTAUpdates` : Ping GH for new bins
- `startOTAUpdate` : Execute a firmware reload
- `FanMode:<auto|manual>` : Toggle PID logic
- `2b<value>` : Change Pit Setpoint
- `8b<value>` : Change Meat Done Target
- `9b<value>` : Keep Warm Target
- `KeepWarm<true|false>` : Enable the Keep Warm switch 
- `DoneAlarm<true|false>` : Enable Meat Alarm buzzer
- `CalibratePit:<value>`
- `CalibrateMeat:<value>`
- `UpdatePID:<kp>:<ki>:<kd>`
- `UpdateTimezone:<tz>`
- `StartAutotune:<true|false>`

## Inbound Fragments

JSON properties are strictly monitored:
`boxValue[0-9]`, `kp`, `ki`, `kd`, `timezone`, `t`, `o`, `otaStatus`, `otaProgress`

### History Fragments
`history_meta` seeds sequence constraints formatting ID hashes and chunk sizes.
`history_chunk` events merge payloads to form standard timestamp points (`t`, `p`, `m`, `s`, `f`).
