import 'dart:ui' show FragmentProgram;

import 'package:demo_2/game/game.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _GameView());
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    return const _GameWrapper();
  }
}

class _GameWrapper extends StatefulWidget {
  const _GameWrapper();

  @override
  State<_GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<_GameWrapper> {
  SomeShipGame? game;

  // PreloadedPrograms is a simple data class that holds the preloaded
  late final Future<PreloadedPrograms> preloadedPrograms =
      Future.wait([
        FragmentProgram.fromAsset('shaders/sea.frag'),
        FragmentProgram.fromAsset('shaders/ship_wake.frag'),
        FragmentProgram.fromAsset('shaders/ship.frag'),
        FragmentProgram.fromAsset('shaders/smoke.frag'),
        FragmentProgram.fromAsset('shaders/vignette.frag'),
      ]).then(
        (l) => (sea: l[0], wake: l[1], ship: l[2], smoke: l[3], vignette: l[4]),
      );

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: DefaultTextStyle.merge(
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFBE294), fontSize: 12),
        child: FutureBuilder(
          future: preloadedPrograms,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              throw snapshot.error!;
            }

            // Show a loading indicator while the fragment programs are loading
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return GameWidget(
              // It is a good idea to save the game instance on state
              // to avoid issues with hot reload
              game: game ??= SomeShipGame(
                preloadedPrograms: snapshot.data!,
              ),
            );
          },
        ),
      ),
    );
  }
}
