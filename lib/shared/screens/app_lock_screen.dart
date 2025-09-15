import 'package:flutter/material.dart';
import '../../core/services/security_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final TextEditingController _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    final method = await SecurityService.instance.getLockMethod();
    if (method == AppLockMethod.biometrics) {
      final ok = await SecurityService.instance.authenticateWithBiometrics();
      if (ok && mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Déverrouiller')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Entrez votre code PIN pour accéder à Guinèmali'),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Code PIN',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final ok = await SecurityService.instance.verifyPin(_pin.text.trim());
                    if (ok && mounted) {
                      Navigator.of(context).pop(true);
                    } else {
                      setState(() => _error = 'PIN incorrect');
                    }
                  },
                  child: const Text('Déverrouiller'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _tryBiometrics,
                  child: const Text('Utiliser biométrie'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


