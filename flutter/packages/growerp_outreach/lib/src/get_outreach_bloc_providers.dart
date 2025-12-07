import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'bloc/outreach_campaign_bloc.dart';
import 'bloc/outreach_message_bloc.dart';
import 'bloc/platform_config_bloc.dart';

List<BlocProvider> getOutreachBlocProviders(RestClient restClient) {
  return [
    BlocProvider<OutreachCampaignBloc>(
      create: (context) => OutreachCampaignBloc(restClient),
    ),
    BlocProvider<OutreachMessageBloc>(
      create: (context) => OutreachMessageBloc(restClient),
    ),
    BlocProvider<PlatformConfigBloc>(
      create: (context) => PlatformConfigBloc(restClient),
    ),
  ];
}
