# Assessment Module Integration Guide for Admin App

## Overview

This guide explains how to integrate the Assessment module into the GrowERP Admin app to enable assessment creation and respondent evaluation.

## Prerequisites

- Admin app project setup complete
- `growerp_assessment` package added to dependencies
- `growerp_core` and `growerp_models` configured
- BLoC providers setup in main app

## Step 1: Update Admin App pubspec.yaml

Add assessment package dependency:

```yaml
dependencies:
  growerp_assessment: ^1.9.0
  # ... other dependencies
```

## Step 2: Add BLoC Providers

Update `main.dart` to include assessment BLoC providers:

```dart
import 'package:growerp_assessment/growerp_assessment.dart';

void main() {
  // In your main setup function:
  getItInstance.registerSingleton<AssessmentRepository>(
    AssessmentRepository(
      apiClient: AssessmentApiClient(dio),
      logger: logger,
    ),
  );

  // Add to BLoC provider list
  final blocProviders = [
    // ... existing providers
    BlocProvider(
      create: (context) => AssessmentBloc(
        repository: getItInstance<AssessmentRepository>(),
      ),
    ),
  ];
}
```

## Step 3: Create Assessment Routes

Add routes to app navigation:

```dart
// In your routes file or routing configuration
import 'package:growerp_assessment/growerp_assessment.dart';

final assessmentRoutes = <String, WidgetBuilder>{
  '/assessment': (context) => AssessmentListScreen(),
  '/assessment/create': (context) => CreateAssessmentScreen(),
  '/assessment/:id/view': (context) => AssessmentDetailScreen(),
  '/assessment/:id/run': (context) => RunAssessmentScreen(),
};
```

## Step 4: Create Screen Wrappers

### Assessment List Screen

```dart
class AssessmentListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/assessment/create'),
          ),
        ],
      ),
      body: BlocListener<AssessmentBloc, AssessmentState>(
        listener: (context, state) {
          if (state is AssessmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<AssessmentBloc, AssessmentState>(
          builder: (context, state) {
            if (state is AssessmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AssessmentsLoaded) {
              return ListView.builder(
                itemCount: state.assessments.length,
                itemBuilder: (context, index) {
                  final assessment = state.assessments[index];
                  return ListTile(
                    title: Text(assessment.assessmentName),
                    subtitle: Text(assessment.status),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/assessment/${assessment.assessmentId}/run',
                      ),
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/assessment/${assessment.assessmentId}/view',
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('No assessments available'));
          },
        ),
      ),
    );
  }
}
```

### Run Assessment Screen

```dart
class RunAssessmentScreen extends StatelessWidget {
  final String assessmentId;

  const RunAssessmentScreen({required this.assessmentId});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Assessment'),
            content: const Text('Are you sure you want to cancel this assessment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: AssessmentFlowScreen(
        assessmentId: assessmentId,
        onComplete: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
```

## Step 5: Add Navigation Menu Item

Add assessment to admin app menu:

```dart
// In your menu/drawer configuration
const NavigationItem(
  title: 'Assessments',
  icon: Icons.quiz,
  route: '/assessment',
  badge: assessmentCount, // Optional: show pending count
),
```

## Step 6: Update App Navigation

Ensure your app navigation handles assessment routes:

```dart
// In your main navigation logic
onGenerateRoute: (settings) {
  // ... existing routes
  
  if (settings.name?.startsWith('/assessment') ?? false) {
    // Parse and handle assessment routes
    final segments = settings.name!.split('/');
    if (segments[1] == 'assessment') {
      if (segments.length == 2) {
        return MaterialPageRoute(
          builder: (_) => AssessmentListScreen(),
        );
      } else if (segments.length > 2 && segments[2] == 'run') {
        return MaterialPageRoute(
          builder: (_) => RunAssessmentScreen(assessmentId: segments[3]),
        );
      }
    }
  }
  
  // ... other routes
},
```

## Step 7: Add Permissions/Roles

Update user permissions to include assessment access:

```dart
// In your permissions/roles configuration
const assessmentPermissions = {
  'assessment_view': 'View assessments',
  'assessment_create': 'Create assessments',
  'assessment_edit': 'Edit assessments',
  'assessment_delete': 'Delete assessments',
  'assessment_submit': 'Submit assessments',
  'assessment_view_results': 'View assessment results',
};
```

## Step 8: Integration Testing

Create integration tests for assessment flow in admin app:

```dart
void main() {
  group('Assessment Integration Tests', () {
    testWidgets('User can navigate to assessment list', (tester) async {
      await tester.pumpWidget(const AdminApp());
      
      // Navigate to assessments
      await tester.tap(find.byIcon(Icons.quiz));
      await tester.pumpAndSettle();
      
      expect(find.text('Assessments'), findsWidgets);
    });

    testWidgets('User can run assessment flow', (tester) async {
      // Setup test data
      final assessment = Assessment(
        assessmentId: 'test-123',
        pseudoId: 'test-pseudo',
        ownerPartyId: 'company-1',
        assessmentName: 'Lead Qualification Survey',
        description: 'Test assessment',
        status: 'ACTIVE',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(const AdminApp());
      
      // Navigate to and run assessment
      await tester.tap(find.byIcon(Icons.quiz));
      await tester.pumpAndSettle();
      
      // Start assessment
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      
      // Verify Step 1 loaded
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });
  });
}
```

## Step 9: Add Assessment Dashboard

Optional: Create admin dashboard for assessment analytics:

```dart
class AssessmentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        return GridView.count(
          crossAxisCount: 2,
          children: [
            _buildStatCard(
              'Active Assessments',
              state is AssessmentsLoaded ? state.assessments.length : 0,
              Colors.blue,
            ),
            _buildStatCard(
              'Completed',
              state is AssessmentsLoaded 
                ? state.assessments.where((a) => a.status == 'COMPLETED').length
                : 0,
              Colors.green,
            ),
            _buildStatCard(
              'Pending Review',
              state is AssessmentsLoaded
                ? state.assessments.where((a) => a.status == 'PENDING').length
                : 0,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(), style: const TextTheme().displayMedium),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

## Troubleshooting

### Issue: AssessmentBloc not provided

**Solution**: Ensure BLoC is added to provider list in main.dart

### Issue: Assessment routes not found

**Solution**: Verify route paths match navigation configuration exactly

### Issue: API client not initialized

**Solution**: Check Dio configuration and baseUrl in main.dart

### Issue: BLoC state not updating

**Solution**: Verify listener widgets are wrapped with BlocListener/BlocBuilder

## Testing Checklist

- [ ] Assessment list loads successfully
- [ ] Can navigate to run assessment
- [ ] Step 1 form validates correctly
- [ ] Step 2 displays questions
- [ ] Step 3 shows results with correct score
- [ ] Can navigate back to admin app
- [ ] Results are saved to backend
- [ ] Previous responses are not shown for new users

## Performance Optimization

1. **Lazy Load Questions**: Load questions on-demand per screen
2. **Cache Assessments**: Cache assessment list for quick navigation
3. **Batch API Calls**: Submit all answers in single request
4. **Paginate Results**: Show results in batches of 20

## Security Considerations

1. **Authentication**: Ensure user is authenticated before accessing
2. **Authorization**: Check user has permission for assessment
3. **Tenant Isolation**: Verify assessments are from user's tenant
4. **Data Validation**: Validate answers before submission
5. **HTTPS Only**: Ensure API calls use HTTPS

## Related Documentation

- [Assessment Package README](README.md)
- [Screens Documentation](lib/src/screens/SCREENS_README.md)
- [BLoC Usage Guide](../../docs/BLoC_USAGE_GUIDE.md)
- [Backend API Reference](../../docs/ASSESSMENT_API_REFERENCE.md)
