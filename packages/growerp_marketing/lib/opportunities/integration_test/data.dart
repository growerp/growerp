/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:core/domains/common/integration_test/data.dart';
import 'package:decimal/decimal.dart';
import 'package:growerp_marketing/opportunities/models/opportunity_model.dart';

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
    stageId: 'Demo',
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
