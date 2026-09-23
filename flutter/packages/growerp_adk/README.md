# GrowERP ADK

The Agent Development Kit (ADK) package for the GrowERP Flutter frontend. It provides the domain logic, services, and UI views for managing AI agents, agent configurations, scheduled jobs, agent chat, and governance.

## Purpose

`growerp_adk` is dedicated to handling the agent-based functionality within GrowERP applications. It provides:

- **AI Agents Management** - Listing, viewing, and managing AI agents
- **Agent Configuration** - Configuring agent behaviors, properties, and system prompts
- **Function Catalog** - Picking individual pre-built agent functions (e.g. the GrowERP Operations Team) into a tenant one at a time, instead of an all-or-nothing team load, plus an AI-assisted "Suggest a function" feasibility check that pre-fills the config dialog
- **Scheduled Jobs** - Setting up and managing recurring or scheduled tasks for agents
- **Agent Chat** - Conversational interfaces for interacting with agents directly
- **Governance & Audit** - Action auditing and write approvals to safely manage agent actions
- **Agent Catalog** (support app only) - Two tabs: reviewing/promoting a tenant-nominated agent into the shared catalog, and running the same "Suggest a function" check on behalf of a named tenant (support's own session has no tenant of its own)
- **Knowledge Base** - Services and views for managing agent knowledge

## Key Domains

- **Agents** - Core views and configurations (`adk_agent_list_view`, `adk_agent_config_dialog`)
- **Catalog** - Function picker and AI-assisted suggestions (`adk_function_catalog_view`, `adk_suggest_function_panel`); support app's tabbed "Agent Catalog" (`adk_agent_catalog_view`) combines the promotion review queue (`adk_catalog_promotion_view`) with the suggestion panel
- **Chat** - Chat interfaces (`adk_chat_view`, `adk_chat_dialog`)
- **Jobs** - Job scheduling and management (`adk_job_list_view`, `adk_job_service`)
- **Governance** - Approvals and action lists (`adk_approvals_list_view`, `adk_actions_list_view`, `adk_governance_service`)
- **Knowledge** - Knowledge base management (`adk_knowledge_view`, `adk_knowledge_service`)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  growerp_adk:
    path: ../growerp_adk  # or from pub.dev when published
```

## Usage

```dart
import 'package:growerp_adk/growerp_adk.dart';

// Access the agent list view
AdkAgentListView();

// Open the agent chat view
AdkChatView(agentId: 'agent_id');

// Manage scheduled jobs
AdkJobListView();

// Pick individual functions into this tenant (e.g. the GrowERP Operations
// Team), or describe a new one for an AI feasibility check
AdkFunctionCatalogView.show(context);
```

## Architecture

```text
growerp_adk/
├── lib/
│   ├── growerp_adk.dart           # Public API exports
│   └── src/
│       ├── adk_actions_list_view.dart     # Action audit list
│       ├── adk_agent_config_dialog.dart   # Agent configuration
│       ├── adk_agent_list_view.dart       # Main agents list
│       ├── adk_approvals_list_view.dart   # Write approvals
│       ├── adk_chat_view.dart             # Agent chat interface
│       ├── adk_function_catalog_view.dart # Function picker + "Suggest a function"
│       ├── adk_suggest_function_panel.dart # Reusable inline suggestion panel
│       ├── adk_agent_catalog_view.dart    # Support app: "Agent Catalog" (Promotion + Suggestion tabs)
│       ├── adk_catalog_promotion_view.dart # Promotion tab content: review/promote nominated agents
│       ├── adk_job_list_view.dart         # Scheduled jobs list
│       ├── adk_knowledge_view.dart        # Knowledge management
│       └── ... (services)                 # Backend communication services
└── example/                       # Demo app with integration tests
```

## Testing

Integration tests are available. Run them using melos or flutter test:

```sh
# Using melos (recommended)
melos bootstrap
melos build
melos test --no-select

# Or manually
cd example
flutter test integration_test
```

## Related Packages

- `growerp_core` - Core UI components and foundational services
- `growerp_models` - Shared data models and entities

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
