import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin HrApi {
  // hr
  @GET("rest/s1/growerp/100/Departments")
  Future<Departments> getDepartments({
    @Query('partyId') String? partyId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Department")
  Future<Department> createDepartment({
    @Field() required Department department,
  });

  @PATCH("rest/s1/growerp/100/Department")
  Future<Department> updateDepartment({
    @Field() required Department department,
  });

  @DELETE("rest/s1/growerp/100/Department")
  Future<void> deleteDepartment({@Field() required Department department});

  @GET("rest/s1/growerp/100/JobTitles")
  Future<JobTitles> getJobTitles({
    @Query('jobTitleId') String? jobTitleId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/JobTitle")
  Future<JobTitle> createJobTitle({@Field() required JobTitle jobTitle});

  @PATCH("rest/s1/growerp/100/JobTitle")
  Future<JobTitle> updateJobTitle({@Field() required JobTitle jobTitle});

  @DELETE("rest/s1/growerp/100/JobTitle")
  Future<void> deleteJobTitle({@Field() required JobTitle jobTitle});

  @GET("rest/s1/growerp/100/OnboardingTasks")
  Future<OnboardingTasks> getOnboardingTasks({
    @Query('onboardingTaskId') String? onboardingTaskId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/OnboardingTask")
  Future<OnboardingTask> createOnboardingTask({
    @Field() required OnboardingTask onboardingTask,
  });

  @PATCH("rest/s1/growerp/100/OnboardingTask")
  Future<OnboardingTask> updateOnboardingTask({
    @Field() required OnboardingTask onboardingTask,
  });

  @DELETE("rest/s1/growerp/100/OnboardingTask")
  Future<void> deleteOnboardingTask({
    @Field() required OnboardingTask onboardingTask,
  });

  @GET("rest/s1/growerp/100/Employees")
  Future<Employees> getEmployees({
    @Query('partyId') String? partyId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/Employee")
  Future<Employee> createEmployee({@Field() required Employee employee});

  @PATCH("rest/s1/growerp/100/Employee")
  Future<Employee> updateEmployee({@Field() required Employee employee});

  @PATCH("rest/s1/growerp/100/EmployeeOnboardingTask")
  Future<Employee> updateEmployeeOnboardingTask({
    @Field() required String partyId,
    @Field() required String onboardingTaskId,
    @Field() required bool completed,
  });

  @GET("rest/s1/growerp/100/LeaveRequests")
  Future<LeaveRequests> getLeaveRequests({
    @Query('leaveRequestId') String? leaveRequestId,
    @Query('partyId') String? partyId,
    @Query('statusId') String? statusId,
    @Query('search') String? search,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/LeaveRequest")
  Future<LeaveRequest> createLeaveRequest({
    @Field() required LeaveRequest leaveRequest,
  });

  @PATCH("rest/s1/growerp/100/LeaveRequest")
  Future<LeaveRequest> updateLeaveRequest({
    @Field() required LeaveRequest leaveRequest,
  });

  @DELETE("rest/s1/growerp/100/LeaveRequest")
  Future<void> deleteLeaveRequest({
    @Field() required LeaveRequest leaveRequest,
  });
}
