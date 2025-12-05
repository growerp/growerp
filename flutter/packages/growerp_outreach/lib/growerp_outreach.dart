library growerp_outreach;

// BLoC exports
export 'src/bloc/outreach_campaign_bloc.dart';
export 'src/bloc/outreach_message_bloc.dart';
export 'src/bloc/platform_config_bloc.dart';

// Screen exports
export 'src/screens/campaign_list_screen.dart';
export 'src/screens/campaign_detail_screen.dart';
export 'src/screens/automation_screen.dart';
export 'src/screens/platform_config_list_screen.dart';
export 'src/screens/platform_config_detail_screen.dart';
export 'src/screens/outreach_message_list.dart';
export 'src/screens/outreach_message_detail_screen.dart';

// Widget exports
export 'src/widgets/campaign_metrics_card.dart';
export 'src/widgets/message_list_item.dart';

// Service exports
export 'src/services/platform_automation_adapter.dart';
export 'src/services/adapters/email_automation_adapter.dart';
export 'src/services/adapters/linkedin_automation_adapter.dart';
export 'src/services/adapters/x_automation_adapter.dart';
export 'src/services/automation_orchestrator.dart';
