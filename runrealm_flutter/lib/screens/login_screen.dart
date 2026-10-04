import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/futuristic_theme.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Icon(
                    Icons.directions_run_rounded,
                    size: 100,
                    color: FuturisticTheme.primaryCyan,
                  ),
                  SizedBox(height: 24),
                  // App Name
                  Text(
                    'RUNREALM',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: FuturisticTheme.primaryCyan.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'CONQUER YOUR CITY',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 4,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 80),
                  
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => authProvider.signInWithGoogle(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom Google 'G' using Flutter's built-in image or text
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[600],
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Fallback Anonymous Button
                  TextButton(
                    onPressed: () => authProvider.signInAnonymously(),
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
