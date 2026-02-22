
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:convert';

void main() {
  runApp(const SentinelPrimeApp());
}

class SentinelPrimeApp extends StatelessWidget {
  const SentinelPrimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel Prime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF00FF), // Magenta
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        textTheme: GoogleFonts.outfitTextTheme(
          const TextTheme(
            displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  String _status = "INITIALIZING CORE...";
  bool _ready = false;
  String _targetUrl = "";
  String _verificationKey = "";

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _status = "SYNCING WITH DISCOVERY NODE...");
    
    try {
      // MOCK DISCOVERY: In a real app, this fetches from Gist or Firebase
      // For this demo, we simulate the auto-populate logic.
      await Future.delayed(const Duration(seconds: 2));
      
      // In production, fetch your discovery endpoint:
      // final response = await http.get(Uri.parse('YOUR_DISCOVERY_URL'));
      // final data = jsonDecode(response.body);
      
      // FALLBACK: User can enter manually if sync fails, but we aim for auto.
      _targetUrl = "https://giant-falcons-tie.loca.lt"; // Placeholder
      _verificationKey = "69.92.112.151";

      setState(() => _status = "HANDSHAKE COMPLETE. REDIRECTING...");
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MissionControlView(
              url: _targetUrl,
              password: _verificationKey,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _status = "SYNC FAILED. CHECK NETWORK.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitSquareCircle(
              color: Color(0xFFFF00FF),
              size: 80.0,
            ),
            const SizedBox(height: 40),
            Text(
              "SENTINEL PRIME",
              style: GoogleFonts.orbitron(
                fontSize: 24,
                letterSpacing: 4,
                color: const Color(0xFF00FFFF), // Cyan
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissionControlView extends StatefulWidget {
  final String url;
  final String password;

  const MissionControlView({super.key, required this.url, required this.password});

  @override
  State<MissionControlView> createState() => _MissionControlViewState();
}

class _MissionControlViewState extends State<MissionControlView> {
  late final WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _bypassTunnelPassword();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // AUTOMATED TUNNEL BYPASS LOGIC
  void _bypassTunnelPassword() {
    final js = """
      (function() {
        const input = document.querySelector('input[name="password"]') || document.querySelector('input[type="text"]');
        const button = document.querySelector('button.btn-primary') || document.querySelector('button');
        if (input && button) {
          input.value = '${widget.password}';
          button.click();
        }
      })();
    """;
    controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "MISSION CONTROL",
          style: GoogleFonts.orbitron(fontSize: 16, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00FFFF)),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: SpinKitPulse(color: Color(0xFFFF00FF)),
            ),
        ],
      ),
    );
  }
}
