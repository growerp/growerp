library growerp_marketing;

// Re-export assessment and landing page models from growerp_models for convenience
export 'package:growerp_models/growerp_models.dart'
    show
        Assessment,
        AssessmentQuestion,
        AssessmentQuestionOption,
        AssessmentResult,
        ScoringThreshold,
        Assessments,
        AssessmentQuestions,
        AssessmentQuestionOptions,
        AssessmentResults,
        ScoringThresholds,
        LandingPage,
        LandingPages,
        LandingPageSection,
        CredibilityInfo,
        CredibilityStatistic,
        Persona,
        Personas,
        ContentPlan,
        ContentPlans,
        SocialPost,
        SocialPosts;

// BLoC exports
export 'src/bloc/assessment_bloc.dart';
export 'src/bloc/landing_page_bloc.dart';
export 'src/bloc/landing_page_event.dart';
export 'src/bloc/landing_page_state.dart';
export 'src/bloc/landing_page_generation_bloc.dart';
export 'src/bloc/page_section_bloc.dart';
export 'src/bloc/page_section_event.dart';
export 'src/bloc/page_section_state.dart';
export 'src/bloc/credibility_bloc.dart';
export 'src/bloc/credibility_event.dart';
export 'src/bloc/credibility_state.dart';
export 'src/bloc/question_bloc.dart';
export 'src/bloc/question_event.dart';
export 'src/bloc/question_state.dart';
export 'src/bloc/persona_bloc.dart';
export 'src/bloc/persona_event.dart';
export 'src/bloc/persona_state.dart';
export 'src/bloc/content_plan_bloc.dart';
export 'src/bloc/content_plan_event.dart';
export 'src/bloc/content_plan_state.dart';
export 'src/bloc/social_post_bloc.dart';
export 'src/bloc/social_post_event.dart';
export 'src/bloc/social_post_state.dart';

export 'src/get_marketing_bloc_providers.dart';

export 'src/screens/screens.dart';
export 'src/screens/generate_landing_page_dialog.dart';

// Integration test helpers and test data
export 'src/test_data.dart';
// export 'src.*integration_test/landing_page_test.dart';
// export 'src.*integration_test/assessment_test.dart';
// export 'src.*integration_test/question_test.dart';
// export 'src.*integration_test/persona_test.dart';
// export 'src.*integration_test/content_plan_test.dart';
// export 'src.*integration_test/social_post_test.dart';
