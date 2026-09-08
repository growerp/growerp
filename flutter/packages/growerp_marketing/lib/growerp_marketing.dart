// Re-export marketing models from growerp_models for convenience
export 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';
export 'package:growerp_models/growerp_models.dart'
    show
        Persona,
        Personas,
        ContentPlan,
        ContentPlans,
        SocialPost,
        SocialPosts,
        MasterContent,
        MasterContents;

// BLoC exports
export 'src/bloc/persona_bloc.dart';
export 'src/bloc/persona_event.dart';
export 'src/bloc/persona_state.dart';
export 'src/bloc/content_plan_bloc.dart';
export 'src/bloc/content_plan_event.dart';
export 'src/bloc/content_plan_state.dart';
export 'src/bloc/social_post_bloc.dart';
export 'src/bloc/social_post_event.dart';
export 'src/bloc/social_post_state.dart';
export 'src/bloc/master_content_bloc.dart';
export 'src/bloc/master_content_event.dart';
export 'src/bloc/master_content_state.dart';
export 'src/bloc/email_sequence_bloc.dart';
export 'src/bloc/email_sequence_event.dart';
export 'src/bloc/email_sequence_state.dart';

export 'src/get_marketing_bloc_providers.dart';

export 'src/screens/screens.dart';

// Integration test helpers and test data
export 'src/test_data.dart';
// export 'src.*integration_test/persona_test.dart';
// export 'src.*integration_test/content_plan_test.dart';
// export 'src.*integration_test/social_post_test.dart';
export 'src/get_marketing_widgets.dart';
export 'src/screens/marketing_dashboard_chart_mini.dart';
