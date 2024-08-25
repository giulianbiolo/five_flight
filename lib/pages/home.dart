import 'package:five_flight/components/ofmmap.dart';
import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("FiveFlight Demo"),
      ),
      body: const Center(
          child: OFMMap(),
      ),
    );
  }
}
