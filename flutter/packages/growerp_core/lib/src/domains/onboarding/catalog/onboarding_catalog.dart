/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:genui/genui.dart';
import 'package:growerp_models/growerp_models.dart';

import '../widgets/finalize_menu_widget.dart';
import '../widgets/menu_preview_card.dart';
import '../widgets/options_card.dart';
import '../widgets/welcome_card.dart';

const _catalogId = 'com.growerp.onboarding';

// Tells Gemini which catalogId to emit in every createSurface message.
const _catalogIdInstruction = '''
**CATALOG ID:** You MUST always use catalogId "$_catalogId" in every createSurface message.

Example createSurface:
```json
{"version":"v0.9","createSurface":{"surfaceId":"s1","catalogId":"$_catalogId","sendDataModel":true}}
```
''';

Catalog buildOnboardingCatalog({
  required Future<void> Function(String text) onUserMessage,
  required void Function(OnboardingMenuConfig config) onFinalize,
}) =>
    Catalog(
      [
        WelcomeCard.catalogItem(onUserMessage),
        OptionsCard.catalogItem(onUserMessage),
        MenuPreviewCard.catalogItem(onUserMessage),
        FinalizeMenuWidget.catalogItem(onFinalize),
      ],
      catalogId: _catalogId,
      systemPromptFragments: [_catalogIdInstruction],
    );
