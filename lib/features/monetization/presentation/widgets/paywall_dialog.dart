import 'package:flutter/material.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF2D1B4E),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 60, color: Colors.yellow),
            const SizedBox(height: 16),
            const Text(
              'Limit Reached',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have used your free generation.\nUnlock unlimited magic or watch an ad to continue!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement IAP
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium Purchased (Mock)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Unlock Unlimited', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // TODO: Implement AdMob
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ad Watched (Mock)')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Watch Ad (Free)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
