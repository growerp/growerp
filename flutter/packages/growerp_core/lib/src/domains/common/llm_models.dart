/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/// One selectable LLM: the model id sent to the backend and the provider that
/// serves it. The provider decides which API is called and which LlmConfig row
/// holds the API key, so the two always travel together.
class LlmModel {
  final String provider;
  final String modelId;
  const LlmModel(this.provider, this.modelId);
}

/// Providers GrowERP can talk to. Used for the API key rows in System Setup and
/// to group the model list below.
const List<String> llmProviders = ['gemini', 'anthropic', 'openai'];

/// Providers the ADK agent runtime can actually run an agent on. google-adk ships
/// a Gemini and a Claude model implementation; an agent on any other provider
/// registers but has no runner to answer with.
/// Mirrors AdkManager.SUPPORTED_PROVIDERS.
const List<String> adkRoutedProviders = ['gemini', 'anthropic'];

/// The models offered in the System Setup, System Defaults and ADK agent
/// screens. A model not listed here can still be used by picking "Other model"
/// and typing its id — that is also how an OpenAI model is selected until
/// specific ids are curated here.
const List<LlmModel> llmModels = [
  LlmModel('gemini', 'gemini-3.5-flash-lite'),
  LlmModel('gemini', 'gemini-2.5-flash'),
  LlmModel('gemini', 'gemini-2.5-flash-lite'),
  LlmModel('anthropic', 'claude-opus-5'),
  LlmModel('anthropic', 'claude-sonnet-5'),
  LlmModel('anthropic', 'claude-haiku-4-5'),
];

/// Provider serving [modelId], for values stored before the provider was kept
/// alongside the model. Mirrors GeminiAiUtil.providerForModel on the backend.
String providerForModel(String modelId) {
  if (modelId.startsWith('claude')) return 'anthropic';
  if (modelId.startsWith('gpt') || RegExp(r'^o\d').hasMatch(modelId)) {
    return 'openai';
  }
  return 'gemini';
}
