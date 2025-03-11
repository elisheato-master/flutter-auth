// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/constants.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  Db? _db;
  
  UserModel? get currentUser => _currentUser;
  
  // Get MongoDB connection
  Future<Db> get database async {
    if (_db != null) return _db!;
    
    // Connect to MongoDB
    _db = await Db.create(Constants.mongoDbUri);
    await _db!.open();
    
    return _db!;
  }
  
  // Sign up with email and password
  Future<UserModel?> signUpWithEmail(String email, String password) async {
    try {
      final db = await database;
      final userCollection = db.collection(Constants.usersCollection);
      
      // Check if user already exists
      final existingUser = await userCollection.findOne({'email': email});
      
      if (existingUser != null) {
        throw Exception('User already exists');
      }
      
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Create a user ID
      final userId = ObjectId().hexString;
      
      // Create user model
      final user = UserModel(
        id: userId,
        email: email,
      );
      
      // Create user document
      final userData = user.toMap();
      userData['password'] = hashedPassword;
      
      // Insert into database
      await userCollection.insertOne(userData);
      
      // Save user session locally
      await _saveUserSession(user);
      
      _currentUser = user;
      notifyListeners();
      
      return user;
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final db = await database;
      final userCollection = db.collection(Constants.usersCollection);
      
      // Hash the password for comparison
      final hashedPassword = _hashPassword(password);
      
      // Find user by email and password
      final userData = await userCollection.findOne({
        'email': email,
        'password': hashedPassword,
      });
      
      if (userData == null) {
        throw Exception('Invalid email or password');
      }
      
      // Create user model
      final user = UserModel.fromMap(userData);
      
      // Save user session locally
      await _saveUserSession(user);
      
      _currentUser = user;
      notifyListeners();
      
      return user;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Save user session to shared preferences
  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_email', user.email);
    if (user.displayName != null) {
      await prefs.setString('user_display_name', user.displayName!);
    }
  }
  
  // Load user session from shared preferences
  Future<UserModel?> loadUserFromSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      
      if (userId != null && userEmail != null) {
        final displayName = prefs.getString('user_display_name');
        
        final user = UserModel(
          id: userId,
          email: userEmail,
          displayName: displayName,
        );
        
        _currentUser = user;
        notifyListeners();
        
        return user;
      }
      
      return null;
    } catch (e) {
      print('Error loading user session: $e');
      return null;
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_currentUser != null) return true;
    
    final user = await loadUserFromSession();
    return user != null;
  }
  
  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  // Close database connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
    }
  }
}
