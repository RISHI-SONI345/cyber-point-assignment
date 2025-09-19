import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  String _generateToken(String email, String date) {
    final input = '$email|$date';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12); // first 12 hex chars
  }

  @override
  Widget build(BuildContext context) {
    const name = 'Rishi Soni';
    const email = 'rishisoni1545@gmail.com';
    const submissionDate = '2025-09-19';

    final token = _generateToken(email.toLowerCase(), submissionDate);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Name: $name', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Email: $email', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              'Submission Token: $token',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
