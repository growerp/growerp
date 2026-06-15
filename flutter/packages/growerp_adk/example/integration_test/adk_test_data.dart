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

// Fixed test data for the growerp_adk example integration tests. Each runner
// calls CommonTest.createCompanyAndAdmin first, which provisions a fresh owner
// company, so agent/knowledge names only need to be unique within a run.
import 'package:growerp_models/growerp_models.dart';

/// Agents created by the agent test — a read-only (safe-by-default) agent and a
/// scoped agent whose writes require approval (governance). The agent test adds
/// the first two and updates with [agentsUpdate].
List<AdkAgentConfig> agents = [
  const AdkAgentConfig(
    agentName: 'ReadOnly Assistant',
    modelName: 'gemini-2.5-flash',
    instruction: 'You are a read-only reporting assistant.',
    description: 'Answers questions, never writes.',
    toolMode: 'readOnly',
    writePolicy: 'block',
  ),
  const AdkAgentConfig(
    agentName: 'Scoped Order Agent',
    modelName: 'gemini-2.5-flash',
    instruction: 'Manage orders within the allow-list.',
    description: 'Writes need approval.',
    toolMode: 'scoped',
    serviceAllowlist: 'growerp.*#get*, mantle.order.*',
    writePolicy: 'approve',
  ),
];

/// Edited values applied by the agent update test (paired by index with
/// [agents]).
List<AdkAgentConfig> agentsUpdate = [
  const AdkAgentConfig(
    agentName: 'ReadOnly Assistant v2',
    modelName: 'gemini-2.5-flash',
    instruction: 'Updated read-only reporting assistant.',
    description: 'Updated description.',
    toolMode: 'readOnly',
    writePolicy: 'block',
  ),
  const AdkAgentConfig(
    agentName: 'Scoped Order Agent v2',
    modelName: 'gemini-2.5-flash',
    instruction: 'Updated scoped order agent.',
    description: 'Still needs approval.',
    toolMode: 'scoped',
    serviceAllowlist: 'growerp.*#get*',
    writePolicy: 'approve',
  ),
];

/// A scheduled agent — saving it creates a backing AdkJob row.
List<AdkAgentConfig> scheduledAgents = [
  const AdkAgentConfig(
    agentName: 'Hourly Reporter',
    modelName: 'gemini-2.5-flash',
    instruction: 'Produce an hourly status report.',
    toolMode: 'readOnly',
    writePolicy: 'block',
    scheduleEnabled: true,
    scheduleExpression: '0 0 * * * ?',
    schedulePrompt: 'What is the current status?',
  ),
];

/// Knowledge-base documents (pure REST CRUD, no LLM needed to create).
List<AdkKnowledgeDoc> knowledgeDocs = [
  const AdkKnowledgeDoc(
    title: 'Return Policy',
    content: 'Customers may return items within 30 days for a full refund.',
  ),
  const AdkKnowledgeDoc(
    title: 'Shipping Note',
    content: 'Orders ship within two business days from the main warehouse.',
  ),
];

/// Edited values applied by the knowledge update test (paired by index with
/// [knowledgeDocs]).
List<AdkKnowledgeDoc> knowledgeDocsUpdate = [
  const AdkKnowledgeDoc(
    title: 'Return Policy (updated)',
    content: 'Customers may return items within 45 days for a full refund.',
  ),
  const AdkKnowledgeDoc(
    title: 'Shipping Note (updated)',
    content: 'Orders ship within one business day from the main warehouse.',
  ),
];
