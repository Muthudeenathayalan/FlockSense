# IoT Climate Telemetry & Webhook Integration Protocols

Specification for integrating environmental controller hardware (Rotem, Fancom, Chore-Time) with FlockSense Cloud.

---

## 1. MQTT Ingestion Payload
```json
{
  "farmId": "farm_4981",
  "shedId": "shed_01",
  "timestamp": "2026-09-07T10:30:00Z",
  "telemetry": {
    "temperatureC": 26.4,
    "targetTempC": 26.0,
    "relativeHumidity": 62.0,
    "staticPressurePa": 28.5,
    "ammoniaPpm": 8.2,
    "carbonDioxidePpm": 1850,
    "waterFlowLitersPerHour": 48.5,
    "fansRunningCount": 4
  }
}
```
