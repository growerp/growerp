import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

mixin MenuApi {
  // ============================================
  // MENU CONFIGURATION ENDPOINTS
  // ============================================

  /// Get menu configuration by ID or appId+userLoginId
  /// Returns configuration with hierarchical menu items
  /// Set userVersion=true to get user-specific config instead of seed data
  @GET("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> getMenuConfiguration({
    @Query('menuConfigurationId') String? menuConfigurationId,
    @Query('appId') String? appId,
    @Query('userVersion') bool? userVersion,
    @Query('includeAllGroups') bool? includeAllGroups,
  });

  /// List all menu configurations with pagination
  @GET("rest/s1/growerp/100/MenuConfigurations")
  Future<MenuConfigurations> listMenuConfigurations({
    @Query('menuConfigurationId') String? menuConfigurationId,
    @Query('appId') String? appId,
    @Query('userId') String? userId,
    @Query('isActive') String? isActive,
    @Query('start') int? start,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  /// Create new menu configuration
  @POST("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> createMenuConfiguration({
    @Field() required String appId,
    @Field() String? userId,
    @Field() required String name,
    @Field() String? description,
    @Field() String? isActive,
  });

  /// Update menu configuration
  @PATCH("rest/s1/growerp/100/MenuConfiguration")
  Future<MenuConfiguration> updateMenuConfiguration({
    @Field() required String menuConfigurationId,
    @Field() String? name,
    @Field() String? description,
    @Field() String? isActive,
  });

  /// Delete menu configuration and all its items
  @DELETE("rest/s1/growerp/100/MenuConfiguration")
  Future<Map<String, int>> deleteMenuConfiguration({
    @Field() required String menuConfigurationId,
  });

  /// Clone menu configuration for user customization
  @POST("rest/s1/growerp/100/MenuConfiguration/clone")
  Future<MenuConfiguration> cloneMenuConfiguration({
    @Field() required String sourceMenuConfigurationId,
    @Field() String? name,
  });

  /// Reset menu configuration to default (copies items from default app config)
  @POST("rest/s1/growerp/100/MenuConfiguration/reset")
  Future<void> resetMenuConfiguration({
    @Field() required String menuConfigurationId,
  });

  // ============================================
  // MENU ITEM ENDPOINTS (UNIFIED)
  // ============================================

  /// Create new menu item (can be top-level or child)
  @POST("rest/s1/growerp/100/MenuItem")
  Future<MenuItem> createMenuItem({
    @Field() required String menuConfigurationId,
    @Field() String? parentMenuItemId,
    @Field() String? itemKey,
    @Field() required String title,
    @Field() String? route,
    @Field() String? iconName,
    @Field() String? widgetName,
    @Field() String? image,
    @Field() String? selectedImage,
    @Field() String? userGroupsJson,
    @Field() String? updateGroupsJson,
    @Field() String? artifactGroupId,
    @Field() int? sequenceNum,
    @Field() String? isActive,
  });

  /// Update menu item
  @PATCH("rest/s1/growerp/100/MenuItem")
  Future<MenuItem> updateMenuItem({
    @Field() required String menuItemId,
    @Field() String? parentMenuItemId,
    @Field() String? itemKey,
    @Field() String? title,
    @Field() String? route,
    @Field() String? iconName,
    @Field() String? widgetName,
    @Field() String? image,
    @Field() String? selectedImage,
    @Field() String? userGroupsJson,
    @Field() String? updateGroupsJson,
    @Field() String? artifactGroupId,
    @Field() int? sequenceNum,
    @Field() String? isActive,
    @Field() String? isMinimized,
    @Field() String? tileType,
  });

  /// Delete menu item and its children
  @DELETE("rest/s1/growerp/100/MenuItem")
  Future<Map<String, int>> deleteMenuItem({
    @Query('menuItemId') required String menuItemId,
  });

  /// Reorder multiple menu items (batch sequence update)
  @PATCH("rest/s1/growerp/100/MenuItems/reorder")
  Future<Map<String, int>> reorderMenuItems({
    @Field() required String menuConfigurationId,
    @Field() required List<Map<String, dynamic>> itemSequences,
  });

  /// Toggle menu item active status
  @PATCH("rest/s1/growerp/100/MenuItem/toggle")
  Future<void> toggleMenuItemActive({@Field() required String menuItemId});

  /// Show/hide the menu item of a screen for the current user, in every app
  @PATCH("rest/s1/growerp/100/MenuItem/visibility")
  Future<void> setUserMenuWidgetVisibility({
    @Field() required String widgetName,
    @Field() required bool hidden,
  });

  /// Set which user groups may see and write through one screen, for this
  /// organization. Writes land on the organization's own menu configuration.
  /// Returns only the ids and the two group lists, not a whole MenuItem, so the
  /// response is deliberately not deserialized into one.
  @PATCH("rest/s1/growerp/100/MenuItem/groups")
  Future<void> setMenuItemGroups({
    @Field() required String menuItemId,
    @Field() required List<String> userGroups,
    @Field() required List<String> updateGroups,
  });
}
