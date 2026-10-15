import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin ChatActivityApi {
  // chat
  @GET("rest/s1/growerp/100/ChatRoom")
  Future<ChatRooms> getChatRooms({
    @Query('hasRead') bool? hasRead, // return rooms with unread messages
    @Query('userId') String? userId,
    @Query('chatRoomName') String? chatRoomName,
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('isPrivate') bool? isPrivate,
    @Query('search') String? searchString,
    @Query('filter') String? filter,
    @Query('namePrefix') String? namePrefix,
  });

  @POST("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> createChatRoom({@Field() required ChatRoom chatRoom});

  @PATCH("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> updateChatRoom({@Field() required ChatRoom chatRoom});

  @DELETE("rest/s1/growerp/100/ChatRoom")
  Future<ChatRoom> deleteChatRoom({@Field() required String chatRoomId});

  @GET("rest/s1/growerp/100/ChatMessage")
  Future<ChatMessages> getChatMessages({
    @Query('chatRoomId') String? chatRoomId,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? searchString,
  });

  @POST("rest/s1/growerp/100/ChatMessage")
  Future<ChatMessage> createChatMessage({
    @Field() required ChatMessage chatMessage,
  });

  // notification
  @GET("rest/s1/growerp/100/Notification")
  Future<Notifications> getNotifications({@Query('limit') int? limit});

  // activities
  @GET("rest/s1/growerp/100/Activity")
  Future<Activities> getActivity({
    @Query('activityId') String? activityId,
    @Query('activityType') ActivityType? activityType,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('open') bool? open,
    @Query('my') bool? my,
    @Query('isForDropDown') bool? isForDropDown,
    @Query('search') String? searchString,
    @Query('companyPseudoId') String? companyPseudoId,
    @Query('userPseudoId') String? userPseudoId,
  });

  @POST("rest/s1/growerp/100/Activity")
  Future<Activity> createActivity({@Field() required Activity activity});

  @PATCH("rest/s1/growerp/100/Activity")
  Future<Activity> updateActivity({@Field() required Activity activity});

  @GET("rest/s1/growerp/100/ActivityNote")
  Future<ActivityNotes> getActivityNotes({
    @Query('activityId') required String activityId,
  });

  @POST("rest/s1/growerp/100/ActivityNote")
  Future<ActivityNotes> createActivityNote({
    @Field() required String activityId,
    @Field() required String noteText,
  });

  // communications of persons and companies
  @GET("rest/s1/growerp/100/CommunicationEvent")
  Future<CommunicationEvents> getCommunicationEvents({
    @Query('communicationEventId') String? communicationEventId,
    @Query('userPseudoId') String? userPseudoId,
    @Query('companyPseudoId') String? companyPseudoId,
    @Query('search') String? searchString,
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST("rest/s1/growerp/100/CommunicationEvent")
  Future<CommunicationEvent> createCommunicationEvent({
    @Field() required CommunicationEvent communicationEvent,
  });

  @PATCH("rest/s1/growerp/100/CommunicationEvent")
  Future<CommunicationEvent> updateCommunicationEvent({
    @Field() required CommunicationEvent communicationEvent,
  });

  @DELETE("rest/s1/growerp/100/CommunicationEvent")
  Future<CommunicationEvent> deleteCommunicationEvent({
    @Field() required CommunicationEvent communicationEvent,
  });
}
