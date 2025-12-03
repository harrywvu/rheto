import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:rheto/services/user_profile_service.dart';
import 'package:rheto/widgets/analytics_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditMode = false;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String? _selectedImagePath;
  String? _currentImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final profile = await UserProfileService.getProfile();
    setState(() {
      _usernameController.text = profile['username'] as String;
      _emailController.text = profile['email'] as String;
      _currentImagePath = profile['imagePath'] as String?;
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = img_picker.ImagePicker();
      final image = await picker.pickImage(
        source: img_picker.ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and email cannot be empty')),
      );
      return;
    }

    try {
      await UserProfileService.saveProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        imagePath: _selectedImagePath ?? _currentImagePath,
      );

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _currentImagePath = _selectedImagePath ?? _currentImagePath;
          _selectedImagePath = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _selectedImagePath = null;
      _loadProfileData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                  if (!_isEditMode)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF74C0FC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.pen,
                          color: Color(0xFF74C0FC),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Card (View or Edit Mode)
              _isEditMode ? _buildEditMode() : _buildViewMode(),

              const SizedBox(height: 32),

              // Analytics Dashboard
              const Text(
                'Analytics',
                style: TextStyle(
                  fontFamily: 'Ntype82-R',
                  fontSize: 16,
                  color: Color(0xFFD7DADC),
                ),
              ),
              const SizedBox(height: 16),
              const AnalyticsDashboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    final displayImage = _currentImagePath;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image with Edit Button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF74C0FC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Color(0xFF74C0FC), width: 2),
                ),
                child: displayImage != null && File(displayImage).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          File(displayImage),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: FaIcon(
                          FontAwesomeIcons.circleUser,
                          color: Color(0xFF74C0FC),
                          size: 40,
                        ),
                      ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditMode = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF74C0FC),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.camera,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap camera icon to change photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Color(0xFF74C0FC),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // Username
          Text(
            'Username',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _usernameController.text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
          ),
          const SizedBox(height: 20),

          // Email
          Text(
            'Email',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    final displayImage = _selectedImagePath ?? _currentImagePath;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF74C0FC), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF74C0FC).withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image with Edit Button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF74C0FC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Color(0xFF74C0FC), width: 2),
                ),
                child: displayImage != null && File(displayImage).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          File(displayImage),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: FaIcon(
                          FontAwesomeIcons.circleUser,
                          color: Color(0xFF74C0FC),
                          size: 40,
                        ),
                      ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF74C0FC),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.camera,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tap to change photo text
          Text(
            'Tap camera icon to change photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Lettera',
              color: Color(0xFF74C0FC),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),

          // Username Field
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF74C0FC),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Email Field
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF74C0FC),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF74C0FC),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Save Changes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Ntype82-R',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
