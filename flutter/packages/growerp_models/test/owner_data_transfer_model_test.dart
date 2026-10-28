import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

/// Owner data downloads and uploads as the backend returns them.
void main() {
  test('a running download parses from the REST wrapper', () {
    final job = OwnerDataTransfer.fromJson({
      'ownerDataTransfer': {
        'ownerDataTransferId': '100001',
        'direction': 'EXPORT',
        'status': 'RUNNING',
        'progress': 'Selecting data, round 2: 812 records (+40)',
        'counts': <String, dynamic>{},
        'createdDate': 1793613600000,
      },
    });
    expect(job.ownerDataTransferId, '100001');
    expect(job.isRunning, isTrue);
    expect(job.createdDate, DateTime.fromMillisecondsSinceEpoch(1793613600000));
    expect(job.completedDate, isNull);
  });

  test('a finished upload has the new owner and the counts', () {
    final job = OwnerDataTransfer.fromJson({
      'direction': 'IMPORT',
      'status': 'DONE',
      'newOwnerPartyId': '101200',
      'counts': {'mantle.party.Party': 21, 'mantle.product.Product': 13},
    });
    expect(job.isRunning, isFalse);
    expect(job.newOwnerPartyId, '101200');
    expect(job.counts['mantle.product.Product'], 13);
  });

  test('no download yet: the empty REST answer has no status', () {
    final job = OwnerDataTransfer.fromJson({});
    expect(job.status, isNull);
    expect(job.isRunning, isFalse);
    expect(job.counts, isEmpty);
  });
}
