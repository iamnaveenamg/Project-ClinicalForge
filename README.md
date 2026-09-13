# Project-ClinicalForge



[ Step 1: Source DB ] ──► [ Step 2: Metadata Config ] ──► [ Step 3: Event Hubs / Kafka ]
                                                                     │
 ┌───────────────────────────────────────────────────────────────────┘
 ▼
[ Step 4: ADF Batch ] ──► [ Step 5: Databricks Lakehouse ] ──► [ Step 6: Gold DWH ] ──► [ Step 7: Consumption ]