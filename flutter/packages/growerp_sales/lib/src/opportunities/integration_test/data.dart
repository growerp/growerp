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

import 'package:decimal/decimal.dart';
import 'package:growerp_core/test_data.dart';
import 'package:growerp_models/growerp_models.dart';

List<Opportunity> opportunities = [
  Opportunity(
    opportunityName: 'Dummy Opp Name 1',
    description: 'Dummmy descr 1',
    stageId: 'Prospecting',
    nextStep: 'testing1',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('10000'),
    estProbability: Decimal.parse('10'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 2',
    description: 'Dummmy descr2',
    stageId: 'Qualification',
    nextStep: 'testing2',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('40000'),
    estProbability: Decimal.parse('40'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 3',
    description: 'Dummmy descr 3',
    stageId: 'Demo/Meeting',
    nextStep: 'testing3',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('30000'),
    estProbability: Decimal.parse('30'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 4',
    description: 'Dummmy descr4',
    stageId: 'Proposal',
    nextStep: 'testing4',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('40000'),
    estProbability: Decimal.parse('40'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 5',
    description: 'Dummmy descr 5',
    stageId: 'Quote',
    nextStep: 'testing5',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('50000'),
    estProbability: Decimal.parse('50'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 6',
    description: 'Dummmy descr6',
    stageId: 'Prospecting',
    nextStep: 'testing6',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('60000'),
    estProbability: Decimal.parse('60'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 7',
    description: 'Dummmy descr 7',
    stageId: 'Qualification',
    nextStep: 'testing7',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('70000'),
    estProbability: Decimal.parse('70'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 8',
    description: 'Dummmy descr8',
    stageId: 'Demo',
    nextStep: 'testing8',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('80000'),
    estProbability: Decimal.parse('80'),
  ),
];
