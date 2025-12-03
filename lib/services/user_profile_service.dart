import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _usernameKey = 'user_profile_username';
  static const String _emailKey = 'user_profile_email';
  static const String _profileImagePathKey = 'user_profile_image_path';

  // Default values
  static const String _defaultUsername = 'User Profile';
  static const String _defaultEmail = 'user@example.com';

  /// Get username from persistent storage
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? _defaultUsername;
  }

  /// Get email from persistent storage
  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? _defaultEmail;
  }

  /// Get profile image path from persistent storage
  static Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  /// Save username to persistent storage
  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  /// Save email to persistent storage
  static Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  /// Save profile image path to persistent storage
  static Future<void> setProfileImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, imagePath);
  }

  /// Save all profile data at once
  static Future<void> saveProfile({
    required String username,
    required String email,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    if (imagePath != null) {
      await prefs.setString(_profileImagePathKey, imagePath);
    }
  }

  /// Get all profile data
  static Future<Map<String, dynamic>> getProfile() async {
    return {
      'username': await getUsername(),
      'email': await getEmail(),
      'imagePath': await getProfileImagePath(),
    };
  }

  /// Clear all profile data (for testing)
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_profileImagePathKey);
  }
}
