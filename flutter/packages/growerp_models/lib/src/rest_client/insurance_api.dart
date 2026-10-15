import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin InsuranceApi {
  // insurance agency
  @GET("rest/s1/growerp/100/Policies")
  Future<Policies> getPolicies({
    @Query('policyId') String? policyId,
    @Query('insuredPartyId') String? insuredPartyId,
    @Query('carrierPartyId') String? carrierPartyId,
    @Query('statusId') String? statusId,
    @Query('expiringWithinDays') int? expiringWithinDays,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Policy")
  Future<Policy> createPolicy({@Field() required Policy policy});

  @PATCH("rest/s1/growerp/100/Policy")
  Future<Policy> updatePolicy({@Field() required Policy policy});

  @DELETE("rest/s1/growerp/100/Policy")
  Future<void> deletePolicy({@Field() required Policy policy});

  @POST("rest/s1/growerp/100/PolicyRenew")
  Future<Policy> renewPolicy({@Field() required Policy policy});

  @POST("rest/s1/growerp/100/PolicyCommission")
  Future<Policy> receivePolicyCommission({
    @Field() required String policyId,
    @Field() required String amount,
  });

  @GET("rest/s1/growerp/100/Claims")
  Future<Claims> getClaims({
    @Query('claimId') String? claimId,
    @Query('policyId') String? policyId,
    @Query('statusId') String? statusId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Claim")
  Future<Claim> createClaim({@Field() required Claim claim});

  @PATCH("rest/s1/growerp/100/Claim")
  Future<Claim> updateClaim({@Field() required Claim claim});

  @DELETE("rest/s1/growerp/100/Claim")
  Future<void> deleteClaim({@Field() required Claim claim});

  @GET("rest/s1/growerp/100/LeaveAllowances")
  Future<LeaveBalances> getLeaveAllowances({
    @Query('partyId') String? partyId,
    @Query('year') int? year,
  });

  @PATCH("rest/s1/growerp/100/LeaveAllowance")
  Future<LeaveBalances> updateLeaveAllowance({
    @Field() required String partyId,
    @Field() required String leaveTypeEnumId,
    @Field() required int year,
    @Field() required String days,
  });
}
