import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactourteamPage extends StatefulWidget {
  const ContactourteamPage({super.key});

  @override
  State<ContactourteamPage> createState() => _ContactourteamPageState();
}

class _ContactourteamPageState extends State<ContactourteamPage> {
  // URLs for social media and contact
  final String phoneNumber = '9440871455';
  final String email = 'syedAlthaf510@gmail.com';
  final String website = 'https://www.myqrmart.com';
  final String location = 'Proddatur Rameswaram, ysr district, Andhra Pradesh, India';
  
  final Map<String, String> socialMediaUrls = {
    'whatsapp': 'https://wa.me/919440871455',
    'facebook': 'https://facebook.com/myqrmart',
    'instagram': 'https://instagram.com/myqrmart',
    'youtube': 'https://www.youtube.com/@ProddaturITHub/shorts',
  };

  // Function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              color: Colors.deepOrange,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Contact Our Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Logo and Branding Section
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Column(
                children: [
                  const Text(
                    'myqrmart',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Our Core Team MYQRMART (Stone Age), We care for you and your farm. Please contact us by below means, if you have any Query',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Social Media Section
                    const SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Follow Us On',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialIcon(
                                FontAwesomeIcons.whatsapp,
                                Colors.green,
                                socialMediaUrls['whatsapp']!,
                              ),
                              const SizedBox(width: 24),
                              _buildSocialIcon(
                                FontAwesomeIcons.facebook,
                                Colors.blue[800]!,
                                socialMediaUrls['facebook']!,
                              ),
                              const SizedBox(width: 24),
                              _buildSocialIcon(
                                FontAwesomeIcons.instagram,
                                Colors.pink,
                                socialMediaUrls['instagram']!,
                              ),
                              const SizedBox(width: 24),
                              _buildSocialIcon(
                                FontAwesomeIcons.youtube,
                                Colors.red,
                                socialMediaUrls['youtube']!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Contact Details
                    const SizedBox(height: 30),
                    _buildContactTile(
                      icon: Icons.phone,
                      title: 'Call Us',
                      subtitle: phoneNumber,
                      onTap: () => _launchUrl('tel:$phoneNumber'),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    
                    _buildContactTile(
                      icon: Icons.email,
                      title: 'Email Us',
                      subtitle: email,
                      onTap: () => _launchUrl('mailto:$email'),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    
                    _buildContactTile(
                      icon: Icons.web,
                      title: 'Website',
                      subtitle: website,
                      onTap: () => _launchUrl(website),
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    
                    _buildContactTile(
                      icon: Icons.location_on,
                      title: 'Location',
                      subtitle: location,
                      onTap: () {
                        // For opening map, you might need to use a maps package
                        // or encode the location for Google Maps
                        _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(location)}');
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            Container(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeFull(location)}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.deepOrange.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Open Map',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.deepOrange,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}