export 'package:growerp_models/testing.dart';

import 'package:growerp_models/growerp_models.dart';

final user1 = User(partyId: 'U1', firstName: 'John', lastName: 'Doe');
final user2 = User(partyId: 'U2', firstName: 'Jane', lastName: 'Roe');

final company1 = Company(partyId: 'C1', name: 'Acme');
final company2 = Company(partyId: 'C2', name: 'Globex');

final companyUser1 = CompanyUser(
  type: PartyType.company,
  partyId: 'C1',
  name: 'Acme',
);
final companyUser2 = CompanyUser(
  type: PartyType.user,
  partyId: 'U2',
  name: 'Jane Roe',
);

final event1 = CommunicationEvent(communicationEventId: 'E1', subject: 'Hi');
final event2 = CommunicationEvent(communicationEventId: 'E2', subject: 'Re');
