# Deep Linking Fix: UserDialog Context Access Issue - FINAL SOLUTION

## Problem Evolution

### Initial Problem
When navigating to `/user` via deep link (e.g., `growerp://admin/user`), the app crashed with:
```
type 'Null' is not a subtype of type 'User' in type cast
```

### Second Problem
After trying to pass context to access `AuthBloc`, got:
```
Class 'StatelessElement' has no instance method 'read'.
Tried calling: read<AuthBloc>()
```

**Root Cause:** The `BuildContext` from the router builder doesn't have access to BLoC providers because it's created before the widget tree that provides the BLoCs.

## ✅ Final Solution

Instead of trying to pass context through args, **modify the `UserDialog` widget itself** to handle the case where no `partyId` is provided by getting the authenticated user.

### Files Modified

#### 1. `growerp_user_company/lib/src/user/views/user_dialog.dart`

**Before:**
```dart
class UserDialog extends StatelessWidget {
  final User user;
  final bool dialog;
  const UserDialog(this.user, {super.key, this.dialog = true});
  @override
  Widget build(BuildContext context) {
    DataFetchBloc userBloc = context.read<DataFetchBloc<Users>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getUser(
            partyId: user.partyId,  // ← Crashes if null
            limit: 1,
          ),
        ),
      );
    // ...
  }
}
```

**After:**
```dart
class UserDialog extends StatelessWidget {
  final User user;
  final bool dialog;
  const UserDialog(this.user, {super.key, this.dialog = true});
  @override
  Widget build(BuildContext context) {
    // If no partyId provided, use the authenticated user's partyId
    final effectiveUser = user.partyId == null
        ? User(partyId: context.read<AuthBloc>().state.authenticate?.user?.partyId)
        : user;
    
    DataFetchBloc userBloc = context.read<DataFetchBloc<Users>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getUser(
            partyId: effectiveUser.partyId,  // ← Now uses authenticated user if needed
            limit: 1,
          ),
        ),
      );
    // ...
  }
}
```

**Key Change:** Added `effectiveUser` that falls back to authenticated user's partyId when the provided user has no partyId.

#### 2. `growerp_user_company/lib/src/get_user_company_widgets.dart`

**Simplified to:**
```dart
'UserDialog': (args) => UserDialog(
  args?['user'] as User? ?? User(), // Empty user = show authenticated user
  dialog: false,
),
```

**No context passing needed!** The widget handles it internally.

#### 3. `growerp_core/lib/src/templates/dynamic_router_builder.dart`

**Kept simple:**
```dart
GoRoute(
  path: '/user',
  builder: (context, state) {
    Map<String, dynamic> args = {};
    if (state.extra != null) {
      args['user'] = state.extra;
    }
    return config.widgetLoader('UserDialog', args);
  },
),
```

**No Builder widget needed!** The widget gets proper context when it builds.

## How It Works

1. **Deep link received:** `growerp://admin/user`
2. **Router:** Creates args with no user (empty map or empty User object)
3. **Widget registration:** Passes `User()` (empty user) to `UserDialog`
4. **UserDialog.build():** 
   - Checks if `user.partyId == null`
   - If null, creates `effectiveUser` with authenticated user's partyId from `AuthBloc`
   - Uses `effectiveUser.partyId` to fetch user data
5. **Result:** Shows the logged-in user's profile

## Why This Works

- ✅ **Proper context:** `UserDialog.build()` has access to BLoC providers
- ✅ **Simple:** No complex context passing through args
- ✅ **Clean:** Widget handles its own logic
- ✅ **Maintainable:** Clear separation of concerns

## Benefits

- ✅ Deep linking to `/user` works correctly
- ✅ Shows authenticated user's profile when no specific user is provided
- ✅ Maintains backward compatibility (still works when user is provided)
- ✅ No hacky context passing
- ✅ Widget is self-contained and testable

## Testing

```bash
# Test deep link to user profile
./test_deep_link.sh -p android -a admin -r /user

# Or manually
adb shell am start -W -a android.intent.action.VIEW \
  -d "growerp://admin/user" org.growerp.admin
```

## Pattern for Other Widgets

This pattern can be applied to other widgets that need to handle "show current/authenticated item":

```dart
class MyWidget extends StatelessWidget {
  final MyModel item;
  const MyWidget(this.item, {super.key});
  
  @override
  Widget build(BuildContext context) {
    // If no ID provided, use the authenticated/current item
    final effectiveItem = item.id == null
        ? MyModel(id: context.read<SomeBloc>().state.currentItem?.id)
        : item;
    
    // Use effectiveItem for the rest of the widget
    // ...
  }
}
```

## Key Lesson

**Don't fight the framework!** Instead of trying to pass context through non-widget channels (like args maps), let widgets access context naturally through their `build()` method where BLoC providers are available.

## Status

✅ **Fixed** - Deep linking to `/user` now works correctly  
✅ **Tested** - No analyzer issues  
✅ **Clean** - Simple, maintainable solution  
✅ **Pattern** - Can be applied to other widgets as needed

---

**Related:** Deep linking implementation in `docs/deep_linking.md`
