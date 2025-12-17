library growerp_outreach;

// BLoC exports
export 'src/bloc/outreach_campaign_bloc.dart';
export 'src/bloc/outreach_message_bloc.dart';
export 'src/bloc/platform_config_bloc.dart';

// Screen exports
export 'src/screens/campaign_list_screen.dart';
export 'src/screens/campaign_detail_screen.dart';
export 'src/screens/campaign_execution_dialog.dart';
export 'src/screens/automation_screen.dart';
export 'src/screens/platform_config_list_screen.dart';
export 'src/screens/platform_config_detail_screen.dart';
export 'src/screens/outreach_message_list.dart';
export 'src/screens/outreach_message_detail_screen.dart';
export 'src/screens/search_campaign_list.dart';

// Widget exports
export 'src/widgets/campaign_metrics_card.dart';
export 'src/widgets/message_list_item.dart';
export 'src/widgets/automation_progress_card.dart';

// Service exports
export 'src/services/platform_automation_adapter.dart';
export 'src/services/flutter_mcp_browser_service.dart';
export 'src/services/snapshot_parser.dart';
export 'src/services/adapters/email_automation_adapter.dart';
export 'src/services/adapters/linkedin_automation_adapter.dart';
export 'src/services/adapters/x_automation_adapter.dart';
export 'src/services/adapters/substack_automation_adapter.dart';
export 'src/services/automation_orchestrator.dart';
export 'src/services/campaign_automation_service.dart';
export 'src/utils/rate_limiter.dart';

// Model exports
export 'src/models/platform_settings.dart';

export 'src/get_outreach_bloc_providers.dart';
export 'src/get_outreach_widgets.dart';

// Integration test exports
export 'src/integration_test/outreach_campaign_test.dart';
