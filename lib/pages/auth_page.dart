// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mygoatmanager/pages/homepage.dart';
import '../services/auth_service.dart';


class AuthPage extends StatefulWidget {
final VoidCallback? onLoginSuccess;

 const AuthPage({super.key, this.onLoginSuccess});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Form controllers
  final _loginNameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // API service instance
  final AuthService _authService = AuthService();

  // Google Sign In

  final GoogleSignIn _googleSignIn = GoogleSignIn(
  // No clientId parameter for Android!
  scopes: ['email', 'profile'],
);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkExistingSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginNameController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
  final isAuthenticated = await _authService.validateSession();
  if (isAuthenticated && mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/homepage');
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final availableWidth = constraints.maxWidth;

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: SizedBox(
                      height: availableHeight,
                      child: Column(
                        children: [
                          _buildHeader(context, availableWidth, availableHeight),
                          
                          Expanded(
                            child: _buildAuthCard(context, availableWidth, availableHeight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double availableWidth, double availableHeight) {
    final isSmallPhone = availableWidth < 360;
    final isLargePhone = availableWidth >= 360 && availableWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: availableWidth * 0.05,
        vertical: availableHeight * 0.02,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallPhone 
                ? availableWidth * 0.25
                : isLargePhone 
                  ? availableWidth * 0.22
                  : availableWidth * 0.20,
            height: isSmallPhone
                ? availableWidth * 0.25
                : isLargePhone
                  ? availableWidth * 0.22
                  : availableWidth * 0.20,
            padding: EdgeInsets.all(isSmallPhone ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isSmallPhone ? 50 : 60),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: isSmallPhone ? 2 : 3,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isSmallPhone ? 45 : 50),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/goat.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: isSmallPhone ? availableWidth * 0.15 : availableWidth * 0.12,
                    );
                  },
                ),
              ),
            ),
          ),
          
          SizedBox(height: availableHeight * 0.02),
          
          Text(
            AppLocalizations.of(context)!.welcomeToGoatManager,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallPhone 
                  ? availableWidth * 0.055
                  : isLargePhone
                    ? availableWidth * 0.05
                    : availableWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          
          SizedBox(height: availableHeight * 0.01),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 10 : 20),
            child: Text(
              AppLocalizations.of(context)!.manageYourFarmEfficiently,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: isSmallPhone 
                    ? availableWidth * 0.035
                    : isLargePhone
                      ? availableWidth * 0.032
                      : availableWidth * 0.028,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, double availableWidth, double availableHeight) {
    final isSmallPhone = availableWidth < 360;
    final cardMargin = isSmallPhone 
        ? availableWidth * 0.03
        : availableWidth * 0.04;
        
    final cardPadding = isSmallPhone
        ? availableWidth * 0.04
        : availableWidth * 0.045;

    return Container(
      margin: EdgeInsets.all(cardMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallPhone ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isSmallPhone ? 10 : 15,
            spreadRadius: isSmallPhone ? 2 : 3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            height: isSmallPhone ? 40 : 45,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                // Added padding to the indicator to increase the border space
                border: Border.all(color: Colors.transparent, width: 10), // Adjust width as needed
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              labelStyle: TextStyle(
                fontSize: isSmallPhone 
                    ? availableWidth * 0.038
                    : availableWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isSmallPhone 
                    ? availableWidth * 0.038
                    : availableWidth * 0.04,
              ),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.login),
                Tab(text: AppLocalizations.of(context)!.signup),
              ],
            ),
          ),
          
          SizedBox(height: availableHeight * 0.02),

          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(context, availableWidth, availableHeight),
                _buildSignupForm(context, availableWidth, availableHeight),
              ],
            ),
          ),

          SizedBox(height: availableHeight * 0.015),
          _buildDividerWithText(
            context,
            AppLocalizations.of(context)!.orContinueWith,
            availableWidth,
          ),
          SizedBox(height: availableHeight * 0.015),

          _buildSocialLoginButtons(context, availableWidth),

          if (_tabController.index == 1)
            Padding(
              padding: EdgeInsets.only(top: availableHeight * 0.015),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: availableWidth * 0.05),
                    child: Text(
                      AppLocalizations.of(context)!.bySigningUpYouAgree,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallPhone 
                            ? availableWidth * 0.028
                            : availableWidth * 0.03,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: availableHeight * 0.008),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showSnackBar('Terms of Service', Colors.blue),
                        child: Text(
                          AppLocalizations.of(context)!.termsOfService,
                          style: TextStyle(
                            color: const Color(0xFF4CAF50),
                            fontSize: isSmallPhone 
                                ? availableWidth * 0.028
                                : availableWidth * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.and,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallPhone 
                              ? availableWidth * 0.028
                              : availableWidth * 0.03,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showSnackBar('Privacy Policy', Colors.blue),
                        child: Text(
                          AppLocalizations.of(context)!.privacyPolicy,
                          style: TextStyle(
                            color: const Color(0xFF4CAF50),
                            fontSize: isSmallPhone 
                                ? availableWidth * 0.028
                                : availableWidth * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, double availableWidth, double availableHeight) {
    final isSmallPhone = availableWidth < 360;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(availableWidth * 0.02),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            _buildTextField(
              controller: _loginNameController,
              label: AppLocalizations.of(context)!.username,
              icon: Icons.person_outline,
              keyboardType: TextInputType.text,
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                if (!value.contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            _buildPasswordField(
              controller: _loginPasswordController,
              label: AppLocalizations.of(context)!.password,
              isVisible: _isPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPassword;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: isSmallPhone ? 20 : 24,
                      height: isSmallPhone ? 20 : 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF4CAF50),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    SizedBox(width: isSmallPhone ? 4 : 6),
                    Text(
                      AppLocalizations.of(context)!.rememberMe,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: isSmallPhone 
                            ? availableWidth * 0.032
                            : availableWidth * 0.035,
                      ),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog(context, availableWidth);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(
                      color: const Color(0xFF4CAF50),
                      fontSize: isSmallPhone 
                          ? availableWidth * 0.032
                          : availableWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: availableHeight * 0.02),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallPhone 
                        ? availableHeight * 0.018
                        : availableHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: isSmallPhone ? 20 : 24,
                        width: isSmallPhone ? 20 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.login,
                        style: TextStyle(
                          fontSize: isSmallPhone 
                              ? availableWidth * 0.038
                              : availableWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ) );
  }

  Widget _buildSignupForm(BuildContext context, double availableWidth, double availableHeight) {
    final isSmallPhone = availableWidth < 360;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(availableWidth * 0.02),
        child: Form(
          key: _signupFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            _buildTextField(
              controller: _signupNameController,
              label: AppLocalizations.of(context)!.fullName,
              icon: Icons.person_outline,
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterName;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            _buildTextField(
              controller: _signupEmailController,
              label: AppLocalizations.of(context)!.emailAddress,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterEmail;
                }
                if (!value.contains('@')) {
                  return AppLocalizations.of(context)!.enterValidEmail;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            _buildTextField(
              controller: _signupPhoneController,
              label: AppLocalizations.of(context)!.phoneNumber,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPhone;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            _buildPasswordField(
              controller: _signupPasswordController,
              label: AppLocalizations.of(context)!.password,
              isVisible: _isPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPassword;
                }
                if (value.length < 6) {
                  return AppLocalizations.of(context)!.passwordMinLength;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.015),

            _buildPasswordField(
              controller: _signupConfirmPasswordController,
              label: AppLocalizations.of(context)!.confirmPassword,
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
              screenWidth: availableWidth,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseConfirmPassword;
                }
                if (value != _signupPasswordController.text) {
                  return AppLocalizations.of(context)!.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            SizedBox(height: availableHeight * 0.02),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallPhone 
                        ? availableHeight * 0.018
                        : availableHeight * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: isSmallPhone ? 20 : 24,
                        width: isSmallPhone ? 20 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.createAccount,
                        style: TextStyle(
                          fontSize: isSmallPhone 
                              ? availableWidth * 0.038
                              : availableWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ) );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required double screenWidth,
    String? Function(String?)? validator,
  }) {
    final isSmallPhone = screenWidth < 360;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: isSmallPhone ? screenWidth * 0.032 : screenWidth * 0.035,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: isSmallPhone ? 20 : 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          vertical: isSmallPhone ? screenWidth * 0.03 : screenWidth * 0.035,
          horizontal: screenWidth * 0.04,
        ),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: isSmallPhone ? screenWidth * 0.036 : screenWidth * 0.038,
        color: Colors.grey[800],
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required double screenWidth,
    String? Function(String?)? validator,
  }) {
    final isSmallPhone = screenWidth < 360;
    
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: isSmallPhone ? screenWidth * 0.032 : screenWidth * 0.035,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: const Color(0xFF4CAF50),
          size: isSmallPhone ? 20 : 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
            size: isSmallPhone ? 18 : 20,
          ),
          onPressed: onToggleVisibility,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          vertical: isSmallPhone ? screenWidth * 0.03 : screenWidth * 0.035,
          horizontal: screenWidth * 0.04,
        ),
        isDense: true,
      ),
      style: TextStyle(
        fontSize: isSmallPhone ? screenWidth * 0.036 : screenWidth * 0.038,
        color: Colors.grey[800],
      ),
      validator: validator,
    );
  }

  Widget _buildDividerWithText(BuildContext context, String text, double screenWidth) {
    final isSmallPhone = screenWidth < 360;
    
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 8 : 12),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallPhone ? screenWidth * 0.03 : screenWidth * 0.032,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context, double screenWidth) {
    final isSmallPhone = screenWidth < 360;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _socialLogin,
            icon: Icon(
              Icons.g_mobiledata,
              color: Colors.white,
              size: isSmallPhone ? 20 : 24,
            ),
            label: Text(
              _tabController.index == 0 ? 'Login with Google' : 'Sign up with Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallPhone ? screenWidth * 0.04 : screenWidth * 0.045,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDB4437),
              padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog(BuildContext context, double screenWidth) {
    final emailController = TextEditingController();
    final isSmallPhone = screenWidth < 360;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallPhone ? 16 : 20),
          ),
          child: Container(
            padding: EdgeInsets.all(isSmallPhone ? 16 : 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(
                      color: const Color(0xFF4CAF50),
                      fontSize: isSmallPhone ? screenWidth * 0.045 : screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  Text(
                    AppLocalizations.of(context)!.enterEmailToReset,
                    style: TextStyle(
                      fontSize: isSmallPhone ? screenWidth * 0.032 : screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.emailAddress,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isSmallPhone ? screenWidth * 0.03 : screenWidth * 0.035,
                        horizontal: screenWidth * 0.03,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterEmail;
                      }
                      if (!value.contains('@')) {
                        return AppLocalizations.of(context)!.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallPhone ? screenWidth * 0.025 : screenWidth * 0.03,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallPhone ? screenWidth * 0.035 : screenWidth * 0.038,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              await _resetPassword(emailController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallPhone ? screenWidth * 0.025 : screenWidth * 0.03,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.resetPassword,
                            style: TextStyle(
                              fontSize: isSmallPhone ? screenWidth * 0.035 : screenWidth * 0.038,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // === API CALL METHODS ===

 Future<void> _login() async {
  if (!_loginFormKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final result = await _authService.login(
      _loginNameController.text.trim(),
      _loginPasswordController.text.trim(),
    );
    
    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSnackBar(
        AppLocalizations.of(context)!.loginSuccessful,
        const Color(0xFF4CAF50),
      );
      
      // **Call the callback if provided**
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        // **CRITICAL FIX: Use MaterialPageRoute instead of pushReplacementNamed**
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Homepage(
                currentLocale: const Locale('en'), // Provide required parameters
                onLocaleChanged: (locale) {}, // Provide empty callback
              ),
            ),
            (route) => false, // Remove all routes
          );
        }
      }
    } else {
      _showSnackBar(
        result.message,
        Colors.red,
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showSnackBar(
      'Login error: $e',
      Colors.red,
    );
  }
}

  Future<void> _signup() async {
  if (!_signupFormKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final result = await _authService.register({
      'username': _signupNameController.text.trim(),
      'email': _signupEmailController.text.trim(),
      'phone': _signupPhoneController.text.trim(),
      'password': _signupPasswordController.text.trim(),
    });

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _showSnackBar(
        AppLocalizations.of(context)!.accountCreatedSuccessfully,
        const Color(0xFF4CAF50),
      );
      
      _tabController.animateTo(0);
      _clearSignupFields();
    } else {
      _showSnackBar(
        result.message,
        Colors.red,
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showSnackBar(
      'Registration error: $e',
      Colors.red,
    );
  }
}
Future<void> _resetPassword(String email) async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await _authService.forgotPassword(email);

    setState(() {
      _isLoading = false;
    });

    _showSnackBar(
      result.message,
      result.success ? const Color(0xFF4CAF50) : Colors.red,
    );
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    _showSnackBar(
      'Reset password error: $e',
      Colors.red,
    );
  }
}
  void _socialLogin() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final result = await _authService.loginWithGoogle();

    if (result.success) {
      _showSnackBar(
        AppLocalizations.of(context)!.loginSuccessful,
        const Color(0xFF4CAF50),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/homepage');
      }
    } else {
      _showSnackBar(
        result.message,
        Colors.red,
      );
    }
  } catch (e) {
    _showSnackBar(
      'Google login failed: $e',
      Colors.red,
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

      void _clearSignupFields() {
    _signupNameController.clear();
    _signupEmailController.clear();
    _signupPhoneController.clear();
    _signupPasswordController.clear();
    _signupConfirmPasswordController.clear();
    setState(() {
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}