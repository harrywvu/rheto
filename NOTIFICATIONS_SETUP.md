# Rheto Notifications System

## Overview
The app now includes a comprehensive notification system that reminds users to complete daily activities and maintains their streaks.

## Features

### 1. Scheduled Notifications (3x Daily)
- **7:00 AM**: "Time to stimulate your mind - Complete your daily activities"
- **2:00 PM**: "Time to stimulate your mind - Complete your daily activities"
- **9:00 PM**: "Time to stimulate your mind - Complete your daily activities"

These notifications are automatically scheduled and repeat daily.

### 2. Contextual Notifications (After Activity Completion)
Triggered when user completes an activity:

**If all domains completed:**
- Title: "Incredible! 🎉"
- Body: "You've completed all domains today. Rest well!"
- Only shows once per day

**If missing domains (streak active):**
- Title: "Streak at Risk! 🔥"
- Body: "Giving up so soon? Guess you're not built for intelligence. Complete X more domain(s)."

**If missing domains (no streak):**
- Title: "Keep Going! 💪"
- Body: "You still have X domain(s) to stimulate today"

### 3. Smart Notification Logic
- Notifications only show once per day (after first activity completion)
- Automatically resets at midnight
- Detects streak status and tailors message accordingly
- Stops sending notifications once all 3 domains are completed

## Implementation Details

### Files Created
- `lib/services/notification_service.dart` - Core notification service

### Files Modified
- `pubspec.yaml` - Added dependencies:
  - `flutter_local_notifications: ^17.1.0`
  - `timezone: ^0.9.2`
- `lib/main.dart` - Initialize notification service on app startup
- `lib/services/progress_service.dart` - Trigger contextual notifications after activity completion

### Dependencies
```yaml
flutter_local_notifications: ^17.1.0  # Local notification scheduling
timezone: ^0.9.2                       # Timezone support for scheduling
```

## How It Works

### Initialization
1. App starts → `main()` initializes `NotificationService`
2. Notification service sets up Android/iOS channels
3. Three notifications are scheduled for 7:00, 14:00, and 21:00 daily
4. Notifications repeat every day automatically

### Activity Completion Flow
1. User completes an activity
2. `ProgressService.completeActivity()` is called
3. Progress is saved and metrics updated
4. `NotificationService.showContextualNotification()` is triggered
5. Service checks:
   - Has notification already been shown today?
   - How many domains completed?
   - Is streak active?
6. Appropriate notification is shown with contextual message

### Daily Reset
- Notification tracking resets at midnight
- Scheduled notifications continue to repeat
- User can receive contextual notification again next day

## Platform Support

### Android
- Uses `flutter_local_notifications` with Android notification channels
- Requires `SCHEDULE_EXACT_ALARM` permission (handled by plugin)
- Notifications appear in system tray

### iOS
- Uses `flutter_local_notifications` with iOS notification handling
- Requires user permission (requested on first notification)
- Notifications appear in notification center

## User Permissions
The app requests notification permissions on first use. Users can:
- Allow notifications (recommended)
- Deny notifications (app still works, no reminders)
- Change permissions in device settings

## Testing
To test notifications:
1. Complete an activity → contextual notification should appear
2. Wait for scheduled times (7:00, 14:00, 21:00) → scheduled notification should appear
3. Complete all 3 domains → "Incredible!" notification should appear
4. Next day → notification tracking resets

## Future Enhancements
- Custom notification sounds
- Notification history/log
- User-configurable notification times
- Notification frequency settings
- Deep linking to specific activities from notifications
