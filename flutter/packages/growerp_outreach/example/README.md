# GrowERP Outreach Example

Example application demonstrating the `growerp_outreach` package for multi-platform outreach campaign management.

## Features

- **Campaign Management**: Create and manage outreach campaigns across multiple platforms
- **Multi-Platform Support**: Email, LinkedIn, Twitter, Medium, Substack, and Facebook
- **Campaign Metrics**: Track messages sent, responses, and leads generated
- **Message History**: View all messages sent as part of campaigns
- **Platform Adapters**: Extensible architecture for adding new platforms

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- GrowERP backend running locally or accessible via network
- Melos for workspace management

### Running the Example

1. **Bootstrap the workspace** (from flutter directory):
   ```bash
   melos bootstrap
   ```

2. **Run the example app**:
   ```bash
   cd packages/growerp_outreach/example
   flutter run
   ```

3. **Login** with your GrowERP credentials

## Menu Structure

The example app includes the following menu options:

- **Main**: Dashboard with quick access to campaigns
- **Outreach**: 
  - Campaigns: List and manage all outreach campaigns
  - Automation: Platform automation controls (coming soon)
  - Leads: View and manage leads generated from campaigns
- **Organization**: Company and employee management

## Using the Outreach Features

### Creating a Campaign

1. Navigate to **Outreach → Campaigns**
2. Click the **+** button to create a new campaign
3. Fill in campaign details:
   - Campaign name
   - Select platforms (Email, LinkedIn, Twitter, etc.)
   - Target audience description
   - Message template with personalization tokens
   - Email subject (if EMAIL platform selected)
   - Daily limit per platform
4. Save the campaign

### Viewing Campaign Metrics

1. Click on any campaign in the list
2. View metrics dashboard showing:
   - Messages sent
   - Responses received
   - Leads generated
   - Response rate
3. Scroll down to see message history

### Platform Adapters

The example demonstrates the platform adapter architecture:

- **Email**: Uses Moqui EmailServices for sending
- **LinkedIn**: Stub implementation (requires browsermcp integration)
- **Twitter**: Stub implementation (requires browsermcp integration)

## Integration with Backend

The example connects to the GrowERP backend services:

- `OutreachCampaign` entity for campaign data
- `OutreachMessage` entity for message tracking
- `CampaignMetrics` entity for performance metrics
- `PlatformConfiguration` entity for platform settings

## Development

To extend this example:

1. Add new screens to `lib/`
2. Update `menu_options.dart` to include new menu items
3. Implement platform adapters in the main `growerp_outreach` package
4. Add integration tests in `integration_test/`

## License

This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.
