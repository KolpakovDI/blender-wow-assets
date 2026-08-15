# SESSION 2026-08-15j — Q1 ZoneHint UI + VisitZone smoke

## Done

- **QuestUI**: строка `→ ZoneHint`; цель `VisitZone` = «Посетить: …»
- **NextStepChip**: `zoneHintOverride` из `QuestAccepted.ZoneHint` / ActiveQuests
- **QuestSystem**: `QuestAccepted` шлёт `ZoneHint` / `TargetZone` / `QuestName`
- **QuestTrackerHud**: objective `VisitZone`

## Smoke (Play)

Quest 8 accept (prereq 7+1 seeded) → `VisitZone` FrostRidge → Current=1, ReadyToTurnIn=true.

## Also (same session, continuous)

- Quest list subtitle ZoneHint
- ZoneController MESSAGES/HABITAT_BANNERS для ScoutPost…TrailCamp
- ZoneSystem DETAIL_PRIORITY GaleCliff/MossGlade
- Play smoke quest **107** ScoutPost VisitZone 1/1

