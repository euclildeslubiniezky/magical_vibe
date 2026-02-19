import 'package:flutter/material.dart';

class ElementSelectionScreen extends StatelessWidget {
  const ElementSelectionScreen({Key? key}) : super(key: key);

  final List<String> elements = const [
    "Fire",
    "Water",
    "Thunder",
    "Ice",
    "Wind",
    "Light",
    "Dark"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1a002b),
              Color(0xFF000000),
            ],
            radius: 1.2,
            center: Alignment.center,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "属性を選んでください",
                style: TextStyle(
                  fontSize: 28,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: elements
                    .map(
                      (e) => ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                            side: const BorderSide(
                                color: Colors.white54),
                          ),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
