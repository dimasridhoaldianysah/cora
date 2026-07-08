import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String githubUrl = 'https://github.com/dimasridhoaldianysah/cora.git';

Future<void> _launchGitHub() async {
  final uri = Uri.parse(githubUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Image.asset(
            'assets/images/logo_text_about_screen.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            'CORA',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versi 1.0.0',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Controller Robotic Arm (CORA) adalah aplikasi '
            'pendamping yang didesain secara khusus untuk '
            'mengendalikan, melatih (Teach & Record), serta mengotomasi '
            'pergerakan dari proyek lengan robot DIY berbasis Arduino '
            'maupun ESP32 secara nirkabel via Bluetooth.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Dikembangkan oleh:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tim CORA',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.code,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'GitHub',
                onPressed: _launchGitHub,
              ),
              Text(
                'GitHub',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
