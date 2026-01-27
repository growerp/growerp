# GrowERP Courses Package

A Flutter package for course management with AI-powered content generation.

## Features

- **Course Management**: Create, update, and delete courses with modules and lessons
- **AI Content Generation**: Generate platform-specific content (LinkedIn, Medium, Email, YouTube, Twitter, Substack)
- **In-App Course Viewer**: Present courses within the GrowERP system for user training and support
- **Progress Tracking**: Track user progress through courses
- **Help Overlay**: Contextual help tooltips linked to course lessons

## Usage

```dart
import 'package:growerp_courses/growerp_courses.dart';

// Register widgets
final widgets = getCoursesWidgets();

// Get BLoC providers
final providers = getCoursesBlocProviders(restClient);
```

## Widgets

- `CourseList` - List of all courses
- `CourseDialog` - Create/edit course dialog
- `CourseViewer` - Full course player with progress tracking
- `GenerateMediaDialog` - AI content generation interface
- `HelpOverlay` - Contextual help for system operation support
