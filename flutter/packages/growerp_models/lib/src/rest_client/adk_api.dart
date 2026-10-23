import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin AdkApi {
  // ========== Agent Manager ==========

  /// Get agent dashboard data
  @GET("rest/s1/growerp-agent/Dashboard")
  Future<AgentDashboard> getAgentDashboard();

  /// List agent instances
  @GET("rest/s1/growerp-agent/Agents")
  Future<AgentInstances> getAgentInstances({
    @Query('status') String? status,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  /// Get single agent instance
  @GET("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<AgentInstance> getAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Create agent instance
  @POST("rest/s1/growerp-agent/Agents")
  Future<AgentInstance> createAgentInstance({
    @Field() required AgentInstance agent,
  });

  /// Update agent instance
  @PATCH("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<AgentInstance> updateAgentInstance({
    @Field() required AgentInstance agent,
  });

  /// Delete agent instance
  @DELETE("rest/s1/growerp-agent/Agent/{instanceId}")
  Future<void> deleteAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Start agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/start")
  Future<void> startAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Pause agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/pause")
  Future<void> pauseAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// Stop agent instance
  @POST("rest/s1/growerp-agent/Agent/{instanceId}/stop")
  Future<void> stopAgentInstance({
    @Path('instanceId') required String instanceId,
  });

  /// List approval requests
  @GET("rest/s1/growerp-agent/Approvals")
  Future<List<ApprovalRequest>> getAgentApprovalRequests({
    @Query('status') String? status,
  });

  /// Resolve (approve/reject) approval request
  @POST("rest/s1/growerp-agent/Approval/{requestId}/resolve")
  Future<void> resolveAgentApprovalRequest({
    @Path('requestId') required String requestId,
    @Field() required bool approved,
    @Field() String? comment,
  });

  /// Check rate limit
  @GET("rest/s1/growerp-agent/RateLimit/check")
  Future<RateLimitCheck> checkAgentRateLimit({
    @Query('instanceId') required String instanceId,
    @Query('platform') required String platform,
  });

  // ADK Agent Config endpoints
  /// [catalog]: support only, the shared "_NA_" catalog agents instead of
  /// the caller's own.
  @GET("rest/s1/growerp/100/AdkAgentConfig")
  Future<AdkAgentConfigs> getAdkAgentConfigs({
    @Query('search') String? search,
    @Query('catalog') bool? catalog,
  });

  /// The server's time zone, plus the next runs of [cronExpression] when given.
  @GET("rest/s1/growerp/100/AdkAgentConfig/SchedulePreview")
  Future<AdkSchedulePreview> getAdkSchedulePreview({
    @Query('cronExpression') String? cronExpression,
  });

  @POST("rest/s1/growerp/100/AdkAgentConfig/LoadAgentTeam")
  Future<void> loadAgentTeam({
    @Query("teamName") String? teamName,
    @Field() List<String>? adkAgentConfigIds,
  });

  /// The agent catalog: every published "_NA_" template AdkAgentConfig across
  /// every real team, plus whether this tenant already has each one.
  @GET("rest/s1/growerp/100/AdkAgentConfig/AgentCatalog")
  Future<AdkAgentCatalog> getAdkAgentCatalog();

  /// Feasibility-checked "suggest a new function". [screenCatalogJson] should be
  /// the same catalog JSON the chat view already builds via
  /// WidgetRegistry.getWidgetCatalog(), so a "just navigate there" outcome can
  /// be recognised.
  @POST("rest/s1/growerp/100/AdkAgentConfig/SuggestFunction")
  Future<AdkFunctionSuggestion> suggestAgentFunction({
    @Field() required String description,
    @Field() String? screenCatalogJson,
    @Field() String? ownerPartyId,
  });

  /// Tenant side of catalog promotion: opt one of this tenant's own agents
  /// in/out of the support app's review queue.
  @POST("rest/s1/growerp/100/AdkAgentConfig/Nominate")
  Future<void> nominateAdkAgentConfig({
    @Field() required String adkAgentConfigId,
    @Field() bool nominated = true,
  });

  /// Support-only: the catalog promotion review queue.
  @GET("rest/s1/growerp/100/AdkAgentConfig/NominatedAgents")
  Future<AdkNominatedAgents> getNominatedAgents();

  /// Support-only: clone a nominated tenant agent into the shared "_NA_" catalog.
  @POST("rest/s1/growerp/100/AdkAgentConfig/Promote")
  Future<dynamic> promoteAgentToCatalog({
    @Field() required String adkAgentConfigId,
  });

  @POST("rest/s1/growerp/100/AdkAgentConfig")
  Future<AdkAgentConfig> createAdkAgentConfig({
    @Field() String? agentName,
    @Field() String? modelName,
    @Field() String? llmProvider,
    @Field() String? apiKey,
    @Field() String? instruction,
    @Field() String? description,
    @Field() String? scheduleExpression,
    @Field() bool? scheduleEnabled,
    @Field() String? schedulePrompt,
    @Field() String? scheduleChatRoomId,
    @Field() String? toolMode,
    @Field() String? serviceAllowlist,
    @Field() String? writePolicy,
    @Field() String? approvalChatRoomId,
    @Field() String? agentRole,
    @Field() String? orchestrationType,
    @Field() bool? websiteChat,
    @Field() bool? webSearch,
    @Field() int? maxLlmCalls,
    @Field() int? loopMaxIterations,
    @Field() String? teamName,
    @Field() bool? loopEnabled,
    @Field() String? loopChatRoomId,
    @Field() String? loopReportEmail,
    @Field() String? parameters,
  });

  @PATCH("rest/s1/growerp/100/AdkAgentConfig")
  Future<AdkAgentConfig> updateAdkAgentConfig({
    @Query('adkAgentConfigId') required String adkAgentConfigId,
    @Field() String? agentName,
    @Field() String? modelName,
    @Field() String? llmProvider,
    @Field() String? apiKey,
    @Field() String? instruction,
    @Field() String? description,
    @Field() String? scheduleExpression,
    @Field() bool? scheduleEnabled,
    @Field() String? schedulePrompt,
    @Field() String? scheduleChatRoomId,
    @Field() String? toolMode,
    @Field() String? serviceAllowlist,
    @Field() String? writePolicy,
    @Field() String? approvalChatRoomId,
    @Field() String? agentRole,
    @Field() String? orchestrationType,
    @Field() bool? websiteChat,
    @Field() bool? webSearch,
    @Field() int? maxLlmCalls,
    @Field() int? loopMaxIterations,
    @Field() String? teamName,
    @Field() bool? loopEnabled,
    @Field() String? loopChatRoomId,
    @Field() String? loopReportEmail,
    @Field() String? parameters,
    @Field() bool? catalog,
    @Field() bool? catalogPublished,
    @Field() String? catalogCategory,
  });

  /// Rule checks on an agent (no AI call); with adkAgentConfigId the stored
  /// agent with the given values laid over it.
  @POST("rest/s1/growerp/100/AdkAgentConfig/Check")
  Future<AdkAgentCheckResult> checkAdkAgentConfig({
    @Field() String? adkAgentConfigId,
    @Field() String? instruction,
    @Field() String? schedulePrompt,
    @Field() String? llmProvider,
    @Field() String? toolMode,
    @Field() String? serviceAllowlist,
    @Field() String? writePolicy,
    @Field() bool? webSearch,
    @Field() bool? scheduleEnabled,
    @Field() String? scheduleExpression,
    @Field() int? maxLlmCalls,
  });

  /// Start a test run in the background; poll [getAdkAgentTest].
  @POST("rest/s1/growerp/100/AdkAgentTest")
  Future<AdkAgentTestStart> startAdkAgentTest({
    @Field() required String adkAgentConfigId,
    @Field() String? prompt,
    @Field() bool? dryRun,
  });

  @GET("rest/s1/growerp/100/AdkAgentTest")
  Future<AdkAgentTestRun> getAdkAgentTest({
    @Query('testRunId') required String testRunId,
  });

  @DELETE("rest/s1/growerp/100/AdkAgentConfig")
  Future<void> deleteAdkAgentConfig({
    @Query('adkAgentConfigId') required String adkAgentConfigId,
    @Query('catalog') bool? catalog,
  });

  // Phase 4: coordinator team membership
  @GET("rest/s1/growerp/100/AdkAgentTeam")
  Future<AdkAgentTeamMembers> getAdkAgentTeam({
    @Query('coordinatorConfigId') required String coordinatorConfigId,
  });

  @POST("rest/s1/growerp/100/AdkAgentTeam")
  Future<void> createAdkAgentTeam({
    @Field() required String coordinatorConfigId,
    @Field() required String memberConfigId,
    @Field() int? sequenceNum,
    @Field() String? delegationMode,
  });

  @DELETE("rest/s1/growerp/100/AdkAgentTeam")
  Future<void> deleteAdkAgentTeam({
    @Query('adkAgentTeamMemberId') required String adkAgentTeamMemberId,
  });

  // Team download / upload. teamName omitted -> the untagged "Other agents" bucket.
  @GET("rest/s1/growerp/100/AdkAgentTeam/Export")
  Future<AdkAgentTeamExport> getAdkAgentTeamExport({
    @Query('teamName') String? teamName,
  });

  @POST("rest/s1/growerp/100/AdkAgentTeam/Import")
  Future<AdkAgentTeamImportResult> postAdkAgentTeamImport({
    @Field() required String jsonText,
    @Field() bool? toCatalog,
  });

  // External MCP server registry (tenant-level)
  @GET("rest/s1/growerp/100/AdkMcpServer")
  Future<AdkMcpServers> getAdkMcpServers({@Query('search') String? search});

  @POST("rest/s1/growerp/100/AdkMcpServer")
  Future<AdkMcpServer> createAdkMcpServer({
    @Field() required String serverName,
    @Field() required String url,
    @Field() String? transport,
    @Field() String? headersJson,
    @Field() bool? enabled,
  });

  @PATCH("rest/s1/growerp/100/AdkMcpServer")
  Future<AdkMcpServer> updateAdkMcpServer({
    @Query('adkMcpServerId') required String adkMcpServerId,
    @Field() String? serverName,
    @Field() String? url,
    @Field() String? transport,
    @Field() String? headersJson,
    @Field() bool? enabled,
  });

  @DELETE("rest/s1/growerp/100/AdkMcpServer")
  Future<void> deleteAdkMcpServer({
    @Query('adkMcpServerId') required String adkMcpServerId,
  });

  // Attach / detach an MCP server to an agent
  @GET("rest/s1/growerp/100/AdkAgentMcpServer")
  Future<AdkAgentMcpServers> getAdkAgentMcpServers({
    @Query('configId') required String configId,
  });

  @POST("rest/s1/growerp/100/AdkAgentMcpServer")
  Future<void> createAdkAgentMcpServer({
    @Field() required String configId,
    @Field() required String adkMcpServerId,
    @Field() int? sequenceNum,
  });

  @DELETE("rest/s1/growerp/100/AdkAgentMcpServer")
  Future<void> deleteAdkAgentMcpServer({
    @Query('adkAgentMcpServerId') required String adkAgentMcpServerId,
  });

  // ADK Job endpoints
  @GET("rest/s1/growerp/100/AdkJob")
  Future<AdkJobs> getAdkJobs({@Query('search') String? search});

  @POST("rest/s1/growerp/100/AdkJob/{jobName}/clearLock")
  Future<void> clearAdkJobLock({@Path() required String jobName});

  @POST("rest/s1/growerp/100/AdkJob/{jobName}/paused")
  Future<void> updateAdkJobPaused({
    @Path() required String jobName,
    @Field() required bool paused,
  });

  // ADK agent governance: action audit log + write approvals (tenant-scoped)
  @GET("rest/s1/growerp/100/AdkAction")
  Future<AdkActionLogs> getAdkActions({
    @Query('configId') String? configId,
    @Query('search') String? search,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/AdkSystemUsage")
  Future<AdkActionLogs> getAdkSystemUsage({
    @Query('search') String? search,
    @Query('limit') int? limit,
  });

  @GET("rest/s1/growerp/100/AdkApproval")
  Future<AdkApprovals> getAdkApprovals({
    @Query('status') String? status,
    @Query('search') String? search,
  });

  @PATCH("rest/s1/growerp/100/AdkApproval")
  Future<void> updateAdkApproval({
    @Query('adkApprovalId') required String adkApprovalId,
    @Field() required String decision, // approved | rejected
  });

  // ADK knowledge base (tenant-scoped RAG)
  @GET("rest/s1/growerp/100/AdkKnowledge")
  Future<AdkKnowledgeDocs> getAdkKnowledge({@Query('search') String? search});

  @GET("rest/s1/growerp/100/AdkKnowledge/{adkKnowledgeDocId}")
  Future<AdkKnowledgeDoc> getAdkKnowledgeDetail({
    @Path() required String adkKnowledgeDocId,
  });

  @POST("rest/s1/growerp/100/AdkKnowledge")
  Future<AdkKnowledgeDoc> createAdkKnowledge({
    @Field() required String title,
    @Field() required String text,
    @Field() String? sourceType,
  });

  @PATCH("rest/s1/growerp/100/AdkKnowledge/{adkKnowledgeDocId}")
  Future<void> updateAdkKnowledge({
    @Path() required String adkKnowledgeDocId,
    @Field() String? title,
    @Field() String? text,
  });

  @DELETE("rest/s1/growerp/100/AdkKnowledge")
  Future<void> deleteAdkKnowledge({
    @Query('adkKnowledgeDocId') required String adkKnowledgeDocId,
  });

  @POST("rest/s1/growerp/100/AdkKnowledgeImportProducts")
  Future<dynamic> importAdkKnowledgeProducts();
}
