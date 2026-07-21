# GrowERP Rental

Date-range rental building block for the GrowERP system: shared by the `hotel` and
`rental` (equipment-hire) verticals.

Provides:

- `GanttForm` — Gantt-style availability/booking timeline
- `RentalRateForm` — seasonal/date-range rate management
- `StatisticsForm` — rental utilization/revenue statistics

Actual reservations are ordinary `growerp_order_accounting` sales orders (`onlyRental`
FinDoc lists); this package only adds the rental-specific scheduling and rate UI on top.

No standalone `example` app — integration-tested through the `hotel` and `rental` apps.
