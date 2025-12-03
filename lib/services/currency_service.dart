import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _coinsKey = 'user_coins_balance';
  static const double _initialCoins = 100.0; // Starting balance

  /// Get current coin balance
  static Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_coinsKey) ?? _initialCoins;
  }

  /// Add coins to balance
  static Future<void> addCoins(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBalance = await getBalance();
    await prefs.setDouble(_coinsKey, currentBalance + amount);
  }

  /// Deduct coins from balance
  static Future<bool> deductCoins(double amount) async {
    final currentBalance = await getBalance();
    if (currentBalance < amount) {
      return false; // Insufficient funds
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_coinsKey, currentBalance - amount);
    return true;
  }

  /// Check if user has enough coins
  static Future<bool> hasEnoughCoins(double requiredAmount) async {
    final balance = await getBalance();
    return balance >= requiredAmount;
  }

  /// Set balance (for testing/initialization)
  static Future<void> setBalance(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_coinsKey, amount);
  }

  /// Reset to initial balance (for testing)
  static Future<void> resetBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_coinsKey, _initialCoins);
  }
}
