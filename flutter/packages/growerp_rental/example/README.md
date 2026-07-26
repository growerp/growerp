# growerp_rental example

`growerp_rental` provides Flutter widgets for a date-range rental Gantt
timeline, seasonal rate management, and rental statistics. It's normally
wired into a GrowERP app's screen registry rather than used standalone:

```dart
import 'package:growerp_rental/growerp_rental.dart';

final rentalWidgets = getRentalWidgets();
// {'GanttForm': ..., 'RentalRateForm': ..., 'StatisticsForm': ...}

// e.g. inside a GrowERP app's router:
// GoRoute(
//   path: '/rentalGantt',
//   builder: (context, state) => rentalWidgets['GanttForm']!(state.extra),
// ),
```

See the `hotel` and `rental` apps in this repository for a full working
integration.
