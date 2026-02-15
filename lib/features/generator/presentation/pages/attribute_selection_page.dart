import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magical_vibe/core/app_theme.dart';
import '../../data/generator_controller.dart';
import 'video_player_page.dart';
import '../../../monetization/presentation/widgets/paywall_dialog.dart';

class AttributeSelectionPage extends ConsumerWidget {
  const AttributeSelectionPage({super.key});

  static const List<Map<String, dynamic>> attributes = [
    {'name': 'Fire', 'icon': Icons.local_fire_department, 'color': Colors.red},
    {'name': 'Ice', 'icon': Icons.ac_unit, 'color': Colors.cyan},
    {'name': 'Lightning', 'icon': Icons.flash_on, 'color': Colors.yellow},
    {'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Wind', 'icon': Icons.air, 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Map<String, dynamic>?>>(generatorControllerProvider, (previous, next) {
      // Close loading dialog if previous state was loading and next is not
      if (previous is AsyncLoading && next is! AsyncLoading) {
        Navigator.of(context).pop(); 
      }

      next.when(
        data: (data) {
          if (data != null && data['videoUrl'] != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(videoUrl: data['videoUrl']),
              ),
            );
          }
        },
        error: (error, stack) {
          if (error.toString().contains('Free limit reached')) {
             showDialog(
              context: context,
              builder: (context) => const PaywallDialog(),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          }
        },
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Element'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0518),
              Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(top: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: attributes.length,
          itemBuilder: (context, index) {
            final attr = attributes[index];
            return _AttributeCard(
              name: attr['name'] as String,
              icon: attr['icon'] as IconData,
              color: attr['color'] as Color,
              onTap: () {
                ref.read(generatorControllerProvider.notifier).generateVideo(attr['name']);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AttributeCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AttributeCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
