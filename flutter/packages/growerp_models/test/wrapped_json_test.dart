import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

/// Models accept the backend's wrapped form ({"category": {...}}) as well as
/// the bare object (`_$XFromJson(json['category'] ?? json)`), the second
/// one is what a list response hands to each item.
typedef Case = (
  String model,
  String wrapperKey,
  String idField,
  Map<String, dynamic> Function(Map<String, dynamic>) parse,
);

void main() {
  final List<Case> cases = [
    (
      'Category',
      'category',
      'categoryId',
      (j) => Category.fromJson(j).toJson(),
    ),
    ('Product', 'product', 'productId', (j) => Product.fromJson(j).toJson()),
    ('User', 'user', 'partyId', (j) => User.fromJson(j).toJson()),
    ('Company', 'company', 'partyId', (j) => Company.fromJson(j).toJson()),
    (
      'CompanyUser',
      'companyUser',
      'partyId',
      (j) => CompanyUser.fromJson(j).toJson(),
    ),
    ('FinDoc', 'finDoc', 'pseudoId', (j) => FinDoc.fromJson(j).toJson()),
    (
      'FinDocItem',
      'finDocItem',
      'itemSeqId',
      (j) => FinDocItem.fromJson(j).toJson(),
    ),
    ('Asset', 'asset', 'assetId', (j) => Asset.fromJson(j).toJson()),
    (
      'Location',
      'location',
      'locationId',
      (j) => Location.fromJson(j).toJson(),
    ),
    (
      'GlAccount',
      'glAccount',
      'glAccountId',
      (j) => GlAccount.fromJson(j).toJson(),
    ),
    (
      'ItemType',
      'itemType',
      'itemTypeId',
      (j) => ItemType.fromJson(j).toJson(),
    ),
    (
      'PaymentType',
      'paymentType',
      'paymentTypeId',
      (j) => PaymentType.fromJson(j).toJson(),
    ),
    (
      'TimePeriod',
      'timePeriod',
      'periodId',
      (j) => TimePeriod.fromJson(j).toJson(),
    ),
    (
      'LedgerJournal',
      'ledgerJournal',
      'journalId',
      (j) => LedgerJournal.fromJson(j).toJson(),
    ),
    (
      'Activity',
      'activity',
      'activityId',
      (j) => Activity.fromJson(j).toJson(),
    ),
    (
      'TimeEntry',
      'timeEntry',
      'timeEntryId',
      (j) => TimeEntry.fromJson(j).toJson(),
    ),
    (
      'Opportunity',
      'opportunity',
      'opportunityId',
      (j) => Opportunity.fromJson(j).toJson(),
    ),
    (
      'Subscription',
      'subscription',
      'subscriptionId',
      (j) => Subscription.fromJson(j).toJson(),
    ),
    (
      'ChatRoom',
      'chatRoom',
      'chatRoomId',
      (j) => ChatRoom.fromJson(j).toJson(),
    ),
    (
      'ChatMessage',
      'chatMessage',
      'chatMessageId',
      (j) => ChatMessage.fromJson(j).toJson(),
    ),
    (
      'CommunicationEvent',
      'communicationEvent',
      'communicationEventId',
      (j) => CommunicationEvent.fromJson(j).toJson(),
    ),
    (
      'WebsiteForm',
      'webForm',
      'formId',
      (j) => WebsiteForm.fromJson(j).toJson(),
    ),
    (
      'Department',
      'department',
      'partyId',
      (j) => Department.fromJson(j).toJson(),
    ),
    (
      'JobTitle',
      'jobTitle',
      'jobTitleId',
      (j) => JobTitle.fromJson(j).toJson(),
    ),
    ('Employee', 'employee', 'partyId', (j) => Employee.fromJson(j).toJson()),
    (
      'LeaveRequest',
      'leaveRequest',
      'leaveRequestId',
      (j) => LeaveRequest.fromJson(j).toJson(),
    ),
    (
      'OnboardingTask',
      'onboardingTask',
      'onboardingTaskId',
      (j) => OnboardingTask.fromJson(j).toJson(),
    ),
    ('Policy', 'policy', 'policyId', (j) => Policy.fromJson(j).toJson()),
    ('Claim', 'claim', 'claimId', (j) => Claim.fromJson(j).toJson()),
    (
      'WorkOrder',
      'workOrder',
      'workEffortId',
      (j) => WorkOrder.fromJson(j).toJson(),
    ),
    ('BomItem', 'bomItem', 'toProductId', (j) => BomItem.fromJson(j).toJson()),
    ('Routing', 'routing', 'routingId', (j) => Routing.fromJson(j).toJson()),
    (
      'LinerType',
      'linerType',
      'linerTypeId',
      (j) => LinerType.fromJson(j).toJson(),
    ),
    (
      'LinerPanel',
      'linerPanel',
      'qcNum',
      (j) => LinerPanel.fromJson(j).toJson(),
    ),
    (
      'CashBookEntry',
      'cashBookEntry',
      'transactionId',
      (j) => CashBookEntry.fromJson(j).toJson(),
    ),
    (
      'EmailSequence',
      'emailSequence',
      'emailSequenceId',
      (j) => EmailSequence.fromJson(j).toJson(),
    ),
    (
      'Application',
      'application',
      'applicationId',
      (j) => Application.fromJson(j).toJson(),
    ),
    (
      'WikiPage',
      'wikiPage',
      'wikiPageId',
      (j) => WikiPage.fromJson(j).toJson(),
    ),
  ];

  for (final (model, key, idField, parse) in cases) {
    test('${model}FromJson_wrappedAndBare_giveTheSameObject', () {
      // Arrange
      final bare = <String, dynamic>{idField: 'X1'};
      final wrapped = <String, dynamic>{key: bare};
      // Act
      final fromBare = parse(bare);
      final fromWrapped = parse(wrapped);
      // Assert
      expect(fromBare[idField], 'X1');
      expect(fromWrapped, fromBare);
    });
  }

  // Website only reads the wrapped form: it is only ever parsed from a whole
  // REST response, never as a list item or a nested field.
  test('WebsiteFromJson_wrapped_readsTheWebsite', () {
    expect(
      Website.fromJson({
        'website': {'id': 'W1', 'hostName': 'acme.growerp.com'},
      }).hostName,
      'acme.growerp.com',
    );
  });

  // the client picks the markdown or the html editor from wikiType
  test('WikiPageFromJson_wrapped_readsTheWikiType', () {
    expect(
      WikiPage.fromJson({
        'wikiPage': {'pagePath': 'pricing', 'wikiType': 'html.ftl'},
      }).wikiType,
      'html.ftl',
    );
  });
}
