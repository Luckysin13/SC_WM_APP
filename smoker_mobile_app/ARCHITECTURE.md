# Application Architecture

## Domain-Driven Approach

The repository is modularized around domains: `discovery`, `dashboard`, `alarms`, `history`, `configuration`, `wifi_setup`, and `ota`. 
Each domain contains `presentation` elements cleanly disconnected from their logical representations mapping directly to `core/models`.

### State Operations

We implemented `Riverpod` globally via `flutter_riverpod`.
- **LiveState:** Mutable objects are completely destroyed. When JSON socket strings arrive, a new immutable copy utilizing `copyWithJson` drops into the provider state tree. This guarantees immediate redraws across decoupled screens simultaneously.
- **ConnectionStatus:** Used as a generic driver across widget overlays to visually disable and fade elements (Stale UI Handling), mitigating unsent state loops.

### Networking

Two networking modules run in parallel dynamically resolved via `TransportResolver`:
- **SmokerSocketClient:** Handles continuous stream pingbacks utilizing standard socket paradigms.
- **SmokerApiClient:** A standard REST component instantiated via `Dio` handling HTTP-specific `GET /api/networks` and `POST /` configurations.
