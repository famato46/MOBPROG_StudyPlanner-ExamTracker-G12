import 'package:flutter/material.dart';
import 'main_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigaVersoHome();
  }

  _navigaVersoHome() async {
    // Aspetta 2.5 secondi per far vedere il logo in tutto il suo splendore
    await Future.delayed(const Duration(milliseconds: 2500), () {});
    
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()), // Niente 'const' qui, come abbiamo imparato!
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Se il tuo logo sta meglio su sfondo nero, cambia in Colors.black
      body: Center(
        // Ora mostriamo SOLO l'immagine, perfettamente al centro
        child: Image.asset(
          'assets/icon/UniPath_ICON.png',
          width: 150, // Puoi aumentare questo numero se vuoi il logo più grande (es. 200)
          height: 150,
        ),
      ),
    );
  }
}