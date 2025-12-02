# Metric Snapshots Setup Guide

## Overview
This guide explains how to set up daily metric snapshots that are automatically uploaded to Supabase at the end of each assessment.

## What Gets Uploaded

Every day (once per day), the following metrics are captured and stored:

### Critical Thinking Domain
- Accuracy
- Bias Detection
- Reflection (Cognitive Reflection)
- Justification Quality

### Memory Domain
- Recall Accuracy
- Recall Latency
- Retention Curve
- Item Mastery

### Creativity Domain
- Fluency
- Flexibility
- Originality
- Refinement Gain

## Supabase Table Structure

The metrics are stored in the `metric_snapshots` table with the following schema:

```json
{
  "table": "metric_snapshots",
  "columns": [
    {
      "name": "id",
      "type": "uuid",
      "purpose": "auto-generated primary key"
    },
    {
      "name": "user_id",
      "type": "uuid",
      "purpose": "user identifier"
    },
    {
      "name": "domain",
      "type": "text",
      "purpose": "\"memory\", \"creativity\", \"critical_thinking\""
    },
    {
      "name": "metric_name",
      "type": "text",
      "purpose": "e.g. \"Recall Accuracy\", \"Fluency\", \"Retention Curve\""
    },
    {
      "name": "value",
      "type": "numeric",
      "purpose": "the actual sub-metric value (0-100 scale)"
    },
    {
      "name": "captured_at",
      "type": "timestamp",
      "purpose": "when the snapshot was taken (ISO 8601 format)"
    }
  ]
}
```

## Setup Instructions

### 1. Install Dependencies
Run `flutter pub get` to install the new `supabase_flutter` dependency:

```bash
flutter pub get
```

### 2. Initialize Supabase in Your App

In your `main.dart`, initialize Supabase before running the app:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(const MyApp());
}
```

### 3. Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy:
   - **Project URL** (use as `YOUR_SUPABASE_URL`)
   - **anon public key** (use as `YOUR_SUPABASE_ANON_KEY`)

### 4. Set Up Row Level Security (RLS) Policies

For security, set up RLS policies on the `metric_snapshots` table:

**Enable RLS:**
1. Go to **Authentication** → **Policies**
2. Select the `metric_snapshots` table
3. Enable RLS

**Create Policy for Inserts:**
```sql
CREATE POLICY "Users can insert their own metric snapshots"
ON metric_snapshots
FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

**Create Policy for Selects:**
```sql
CREATE POLICY "Users can view their own metric snapshots"
ON metric_snapshots
FOR SELECT
USING (auth.uid() = user_id);
```

## How It Works

### Daily Upload Flow

1. **User completes assessment** → Results screen is shown
2. **User clicks "Proceed"** → The following happens:
   - Metrics are saved to local storage (SharedPreferences)
   - Baseline metrics are updated in ProgressService
   - **Daily snapshot check**: System checks if metrics were already uploaded today
   - **If not uploaded today**: All 12 metrics (4 per domain × 3 domains) are sent to Supabase
   - **If already uploaded today**: Upload is skipped (prevents duplicate daily entries)
3. **Navigation to Home Screen** → User continues to home

### One Upload Per Day

The service uses `SharedPreferences` to track the last upload date. The `_lastSnapshotDateKey` stores the ISO 8601 timestamp of the last successful upload. This ensures:

- Only one snapshot per calendar day per user
- Subsequent assessments on the same day don't create duplicate entries
- Each new calendar day resets the counter

### Batch Insert

All 12 metrics are inserted in a single batch operation for efficiency:

```dart
await supabase.from('metric_snapshots').insert(snapshots);
```

## Integration with Authentication

Currently, the system uses a placeholder user ID:

```dart
userId: 'placeholder-user-id', // TODO: Replace with actual user ID from auth
```

### When Authentication is Added

Replace the placeholder with the actual authenticated user ID:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
await MetricSnapshotService.uploadDailySnapshots(
  userId: userId,
  criticalThinkingMetrics: finalCTMetrics,
  memoryMetrics: finalMemMetrics,
  creativityMetrics: finalCreMetrics,
);
```

## API Reference

### MetricSnapshotService

#### `uploadDailySnapshots()`
Uploads all metrics for the current day. Only uploads once per calendar day.

```dart
static Future<bool> uploadDailySnapshots({
  required String userId,
  required Map<String, double> criticalThinkingMetrics,
  required Map<String, double> memoryMetrics,
  required Map<String, double> creativityMetrics,
}) async
```

**Returns:** `true` if successful or already uploaded today, `false` on error

**Example:**
```dart
final success = await MetricSnapshotService.uploadDailySnapshots(
  userId: 'user-123',
  criticalThinkingMetrics: {
    'Accuracy': 85.5,
    'Bias Detection': 72.0,
    'Reflection': 80.0,
    'Justification Quality': 88.0,
  },
  memoryMetrics: {
    'Recall Accuracy': 90.0,
    'Recall Latency': 75.0,
    'Retention Curve': 82.0,
    'Item Mastery': 88.0,
  },
  creativityMetrics: {
    'Fluency': 70.0,
    'Flexibility': 65.0,
    'Originality': 75.0,
    'Refinement Gain': 80.0,
  },
);
```

#### `getSnapshotsForUser()`
Retrieves all snapshots for a user within an optional date range.

```dart
static Future<List<Map<String, dynamic>>> getSnapshotsForUser({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
}) async
```

**Example:**
```dart
final snapshots = await MetricSnapshotService.getSnapshotsForUser(
  userId: 'user-123',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
```

#### `getSnapshotsForDomain()`
Retrieves snapshots for a specific domain (memory, creativity, or critical_thinking).

```dart
static Future<List<Map<String, dynamic>>> getSnapshotsForDomain({
  required String userId,
  required String domain,
  DateTime? startDate,
  DateTime? endDate,
}) async
```

**Example:**
```dart
final memorySnapshots = await MetricSnapshotService.getSnapshotsForDomain(
  userId: 'user-123',
  domain: 'memory',
  startDate: DateTime.now().subtract(Duration(days: 7)),
);
```

#### `hasUploadedToday()`
Checks if metrics have already been uploaded today.

```dart
static Future<bool> hasUploadedToday() async
```

**Example:**
```dart
final uploaded = await MetricSnapshotService.hasUploadedToday();
if (uploaded) {
  print('Metrics already uploaded today');
}
```

#### `clearLastSnapshotDate()`
Clears the last snapshot date (useful for testing).

```dart
static Future<void> clearLastSnapshotDate() async
```

## Data Querying Examples

### Get All Metrics for a User (Last 30 Days)

```sql
SELECT * FROM metric_snapshots
WHERE user_id = 'user-123'
  AND captured_at >= NOW() - INTERVAL '30 days'
ORDER BY captured_at DESC;
```

### Get Average Metric Values by Domain (Last 7 Days)

```sql
SELECT 
  domain,
  metric_name,
  AVG(value) as average_value,
  MAX(value) as max_value,
  MIN(value) as min_value
FROM metric_snapshots
WHERE user_id = 'user-123'
  AND captured_at >= NOW() - INTERVAL '7 days'
GROUP BY domain, metric_name
ORDER BY domain, metric_name;
```

### Track Progress for a Specific Metric

```sql
SELECT 
  captured_at,
  value
FROM metric_snapshots
WHERE user_id = 'user-123'
  AND domain = 'memory'
  AND metric_name = 'Recall Accuracy'
ORDER BY captured_at ASC;
```

## Troubleshooting

### Metrics Not Uploading

1. **Check Supabase Connection:**
   - Verify `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` are correct
   - Check network connectivity

2. **Check RLS Policies:**
   - Ensure RLS policies are correctly configured
   - Verify the user_id matches the authenticated user

3. **Check Logs:**
   - Look for error messages in the console
   - The service logs all errors with `print('Error uploading metric snapshots: $e')`

### Duplicate Entries

- The daily check should prevent duplicates
- If duplicates appear, run `MetricSnapshotService.clearLastSnapshotDate()` to reset (for testing only)

### Authentication Issues

- Until authentication is implemented, use a consistent placeholder user ID for testing
- Once authentication is added, replace with `Supabase.instance.client.auth.currentUser?.id`

## Files Modified

1. **pubspec.yaml** - Added `supabase_flutter: ^2.5.0` dependency
2. **lib/services/metric_snapshot_service.dart** - New service for Supabase uploads
3. **lib/screens/results_screen.dart** - Integrated snapshot upload on assessment completion

## Next Steps

1. ✅ Install dependencies with `flutter pub get`
2. ✅ Initialize Supabase in `main.dart`
3. ✅ Set up RLS policies in Supabase dashboard
4. ⏳ Replace placeholder user ID with authenticated user ID (when auth is implemented)
5. ⏳ Create analytics dashboard to visualize metric trends
