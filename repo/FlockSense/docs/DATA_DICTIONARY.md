# FlockSense Core Poultry Data Dictionary

Comprehensive dictionary defining standard entity schemas, fields, data types, and business constraints.

---

## 1. `FarmModel`
- `id` (`String`): Unique UUID identifying the farm.
- `name` (`String`): Display name of the farm.
- `totalSqFt` (`double`): Gross covered shed floor area.
- `birdCapacity` (`int`): Maximum rated bird placement capacity.

---

## 2. `DailyRecordModel`
- `batchId` (`String`): Foreign key to the active batch.
- `date` (`DateTime`): Date of record log.
- `mortality` (`int`): Count of dead birds removed during daily walk.
- `culls` (`int`): Count of sick/lame culled birds.
- `feedConsumedKg` (`double`): Total kg of feed consumed.
- `waterConsumedLiters` (`double`): Total liters of water metered.
- `averageWeight` (`double`): Sample average body weight in grams or kg.
