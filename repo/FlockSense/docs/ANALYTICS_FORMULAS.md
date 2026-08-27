# FlockSense Poultry Analytics & Performance Formulas

This document defines the standard mathematical formulas and poultry science metrics implemented in the FlockSense Performance & Analytics engine.

---

## 1. Feed Conversion Ratio (FCR)

The Feed Conversion Ratio measures the efficiency with which a flock converts feed intake into live body mass.

### Cumulative FCR Formula
$$\text{Cumulative FCR} = \frac{\text{Total Cumulative Feed Consumed (kg)}}{\text{Total Live Biomass (kg)}}$$

Where:
$$\text{Total Live Biomass (kg)} = \text{Current Live Birds} \times \left(\frac{\text{Average Body Weight (g)}}{1000}\right)$$

### Benchmark Standards
- **Broilers (Day 35–42)**: Target FCR typically ranges between **1.45 and 1.68**.
- A lower FCR indicates higher feed efficiency and profitability.

---

## 2. Average Daily Gain (ADG)

Average Daily Gain measures the daily growth rate of the birds over the production cycle.

### Formula
$$\text{ADG (g/day)} = \frac{\text{Current Average Body Weight (g)} - \text{Day 1 Chick Weight (g)}}{\text{Flock Age (Days)}}$$

- Standard day-old chick weight default: **42.0 grams**.
- Typical broiler ADG targets: **55.0 to 68.0 g/bird/day**.

---

## 3. Cumulative Mortality Percentage

Measures total flock losses relative to initial placement population.

### Formula
$$\text{Cumulative Mortality \%} = \left(\frac{\sum (\text{Mortality} + \text{Culls})}{\text{Total Birds Placed}}\right) \times 100$$

- Standard commercial target: **< 3.5% cumulative** across a 40-day broiler cycle.

---

## 4. European Production Efficiency Factor (EPEF / PEF)

EPEF is the global benchmark index integrating survival, growth rate, and feed efficiency into a single score.

### Formula
$$\text{EPEF} = \frac{\text{Liveability \%} \times \text{Average Body Weight (kg)}}{\text{Flock Age (Days)} \times \text{Cumulative FCR}} \times 100$$

Where:
$$\text{Liveability \%} = 100 - \text{Cumulative Mortality \%}$$

### Performance Classification
- **> 400**: Exceptional / World-class management
- **350 – 400**: Good commercial standard
- **300 – 350**: Average
- **< 300**: Underperforming / Review environmental or health factors
