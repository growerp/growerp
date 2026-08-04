
// Parses a real get#WebsiteConversions payload: the backend must send dates as
// ISO strings, epoch millis throw in DateTimeConverter and used to leave the
// support screen stuck on its loading spinner.
import 'dart:convert';
import 'package:test/test.dart';
import 'package:growerp_models/growerp_models.dart';

const _payload = r'''{
  "websiteConversions" : [ {
    "conversionId" : "100001",
    "sourceUrl" : "https://www.accugeo.com",
    "siteId" : "ACCUGEOFOUR",
    "companyName" : "AccuGeo Four",
    "adminEmail" : "gen4-test@example.com",
    "adminFirstName" : "Site",
    "adminLastName" : "Administrator",
    "currencyId" : "USD",
    "applicationId" : "AppAdmin",
    "hostNames" : "www.accugeo.com,accugeo.com,accugeo.localhost:8080",
    "maxPages" : 4,
    "status" : "COMPLETED",
    "statusMessage" : "Website ready on www.accugeo.com,accugeo.com,accugeo.localhost:8080",
    "pageCount" : 4,
    "imageCount" : 1,
    "createdOwnerPartyId" : "100007",
    "createdCompanyPartyId" : "100009",
    "productStoreId" : "100002",
    "createdDate" : "2026-08-04T02:57:31.209+0000",
    "completedDate" : "2026-08-04T02:58:03.612+0000"
  }, {
    "conversionId" : "100000",
    "sourceUrl" : "https://www.thaitrangrubber.com/",
    "siteId" : "TRANGRUBBER",
    "companyName" : "Trang Rubber",
    "adminEmail" : "test1@example.com",
    "adminFirstName" : "tran",
    "adminLastName" : "rubber",
    "currencyId" : "USD",
    "applicationId" : "AppAdmin",
    "hostNames" : "www.thaitrangrubber.com,thaitrangrubber.com",
    "maxPages" : 12,
    "status" : "COMPLETED",
    "statusMessage" : "Website ready on www.thaitrangrubber.com,thaitrangrubber.com",
    "pageCount" : 11,
    "imageCount" : 9,
    "createdOwnerPartyId" : "100002",
    "createdCompanyPartyId" : "100004",
    "productStoreId" : "100001",
    "createdDate" : "2026-08-04T02:34:59.533+0000",
    "completedDate" : "2026-08-04T02:36:20.480+0000"
  } ]
}''';

void main() {
  test('website conversion list payload parses', () {
    final result = WebsiteConversions.fromJson(jsonDecode(_payload));
    expect(result.websiteConversions, isNotEmpty);
    final first = result.websiteConversions.first;
    expect(first.conversionId, isNotEmpty);
    expect(first.createdDate, isNotNull);
  });
}
