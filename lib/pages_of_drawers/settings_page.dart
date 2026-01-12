import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:mygoatmanager/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Video player controller
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String _videoError = '';
  
  // Real user data from AuthService
  String? userName;
  String? userEmail;
  String farmName = "Your Farm";
  
  // Use your auth page's colors
  final Color primaryColor = const Color(0xFF4CAF50);
  final Color primaryDarkColor = const Color(0xFF2E7D32);
  final Color primaryLightColor = const Color(0xFFC8E6C9);
  
  // Auth service instance
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _loadUserData();
  }
  
  // Load real user data
  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      
      if (userData != null && mounted) {
        String? foundName = userData['username']?.toString();
        
        if (foundName == null || foundName.isEmpty) {
          foundName = userData['name']?.toString();
        }
        
        if (foundName == null || foundName.isEmpty) {
          foundName = userData['fullName']?.toString();
        }
        
        setState(() {
          userName = foundName ?? 'Not set';
          userEmail = userData['email']?.toString();
        });
      }
      
      final directUsername = await _authService.getUsername();
      if (directUsername != null && directUsername.isNotEmpty && mounted) {
        setState(() {
          if (userName == null || userName == 'Not set' || userName == 'User') {
            userName = directUsername;
          }
        });
      }
      
      final directEmail = await _authService.getUserEmail();
      if (directEmail != null && directEmail.isNotEmpty && mounted) {
        setState(() {
          if (userEmail == null || userEmail!.isEmpty) {
            userEmail = directEmail;
          }
        });
      }
      
    } catch (e) {
      try {
        final email = await _authService.getUserEmail();
        if (email != null && mounted) {
          setState(() {
            userEmail = email;
            userName = 'Not set';
          });
        }
      } catch (e2) {
        // Ignore error
      }
    }
  }
  
  void _initializeVideoPlayer() async {
    try {
      print('Initializing video player...');
      
      // Try different video paths
      final videoPaths = [
        'assets/videos/goat.png.mp4',
        'assets/videos/goat.mp4',
        'assets/videos/farm.mp4',
      ];
      
      String? workingPath;
      for (var path in videoPaths) {
        try {
          final controller = VideoPlayerController.asset(path);
          await controller.initialize();
          if (controller.value.isInitialized) {
            print('Video found at: $path');
            workingPath = path;
            controller.dispose();
            break;
          }
        } catch (e) {
          print('Failed to load video at $path: $e');
        }
      }
      
      if (workingPath == null) {
        throw Exception('No video found at any of the paths');
      }
      
      _videoController = VideoPlayerController.asset(workingPath);
      
      // Listen for initialization
      _videoController.addListener(() {
        if (_videoController.value.hasError && mounted) {
          setState(() {
            _hasVideoError = true;
            _videoError = _videoController.value.errorDescription ?? 'Video error';
          });
          print('Video error: $_videoError');
        }
      });
      
      // Initialize the controller
      await _videoController.initialize();
      
      if (mounted) {
        if (_videoController.value.isInitialized) {
          print('Video successfully initialized');
          print('Video duration: ${_videoController.value.duration}');
          print('Video size: ${_videoController.value.size}');
          
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            allowFullScreen: false,
            materialProgressColors: ChewieProgressColors(
              playedColor: primaryColor,
              handleColor: primaryDarkColor,
              backgroundColor: Colors.grey[300]!,
              bufferedColor: Colors.grey[200]!,
            ),
          );
          
          setState(() {
            _isVideoInitialized = true;
            _hasVideoError = false;
          });
          
          // Start playback
          _videoController.play();
          print('Video playback started');
        } else {
          setState(() {
            _hasVideoError = true;
            _videoError = 'Video failed to initialize';
          });
          print('Video failed to initialize');
        }
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoError = e.toString();
        });
      }
    }
  }
  
  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Profile Text Section
          _buildProfileTextSection(),
          
          // Video Section
          _buildVideoSection(),
          
          // Personal Information Section
          _buildPersonalInfoSection(),
          
          // Settings Options
          _buildSettingsOptions(),
        ],
      ),
    );
  }
  
  Widget _buildProfileTextSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          'Profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryDarkColor,
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoSection() {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 300,
            child: _hasVideoError
                ? _buildVideoErrorWidget()
                : _isVideoInitialized && _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : _buildVideoLoadingWidget(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 10),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(
              'Video not available',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _retryVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Retry'),
            ),
            if (_videoError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: $_videoError',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _retryVideo() {
    setState(() {
      _isVideoInitialized = false;
      _hasVideoError = false;
      _videoError = '';
    });
    _initializeVideoPlayer();
  }
  
  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              'Personal information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryDarkColor,
              ),
            ),
          ),
          
          _buildInfoField(
            icon: Icons.person_outline,
            label: 'NAME',
            value: userName ?? 'Loading...',
            isEditable: true,
            onEdit: () {
              _showEditDialog('Name', userName ?? '', (newValue) {
                if (newValue.isNotEmpty) {
                  setState(() {
                    userName = newValue;
                  });
                }
              });
            },
          ),
          
          const SizedBox(height: 15),
          
          if (userEmail != null && userEmail!.isNotEmpty)
            _buildInfoField(
              icon: Icons.email_outlined,
              label: 'Email',
              value: userEmail!,
              isEditable: false,
              onEdit: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email cannot be changed.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          
          const SizedBox(height: 15),
          
          _buildInfoField(
            icon: Icons.agriculture_outlined,
            label: 'Farm',
            value: farmName,
            isEditable: true,
            onEdit: () {
              _showEditDialog('Farm Name', farmName, (newValue) {
                setState(() {
                  farmName = newValue;
                });
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    bool isEditable = true,
    required VoidCallback onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: primaryColor,
          size: 22,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: isEditable
            ? IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryLightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
                onPressed: onEdit,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Widget _buildSettingsOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              'Account settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryDarkColor,
              ),
            ),
          ),
          
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              leading: Icon(
                Icons.lock_outline,
                color: primaryColor,
                size: 22,
              ),
              title: Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[500],
              ),
              onTap: () {
                _showChangePasswordDialog();
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit $title',
            style: TextStyle(color: primaryDarkColor),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter new $title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(controller.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
  
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password', style: TextStyle(color: primaryDarkColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );
  }
}