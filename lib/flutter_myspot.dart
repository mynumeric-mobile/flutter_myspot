library flutter_myspot;

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum EndMode { loop, redirectTochild, stayInactive }

const FlutterSecureStorage spotStorage = FlutterSecureStorage();

class HoleWidget extends StatefulWidget {
  const HoleWidget({super.key, required this.child, required this.scenario});
  final Widget child;

  final SpotScenario scenario;

  @override
  State<HoleWidget> createState() => HoleWidgetState();

  static getSpot() {}
}

class HoleWidgetState extends State<HoleWidget> {
  late SpotScene _currentSpotScene;
  late SpotScenario scenario;
  bool _showDescription = false;
  int _currentIndex = 0;
  Timer? _movementDelayTimer;
  Timer? _hidingDelayTimer;
  bool _hideChild = false;
  AudioPlayer player = AudioPlayer();
  StreamSubscription? _subscription;
  BoxConstraints? currentConstraints;

  bool _sleepMode = false;
  bool disable = false;

  @override
  void initState() {
    scenario = widget.scenario;
    isDisable();

    _currentSpotScene = SpotScene(spot: Spot(spotHeight: 1, spotWidth: 1, left: -100, top: -100));
    if (!disable) {
      Future.delayed(const Duration(seconds: 0), () {
        start();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        currentConstraints = constraints;
        return disable
            ? widget.child
            : Material(
                child: Stack(
                  //fit: StackFit.expand,
                  children: [
                    if (!_hideChild) widget.child,
                    if (!_sleepMode)
                      ColorFiltered(
                        colorFilter:
                            ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.srcOut), // This one will create the magic
                        child: Stack(
                          //fit: StackFit.expand,
                          children: [
                            if (_currentSpotScene.spot != null)
                              Container(
                                decoration: const BoxDecoration(
                                    color: Colors.black,
                                    backgroundBlendMode: BlendMode.dstOut), // This one will handle background + difference out
                              ),
                            if (_currentSpotScene.spot != null)
                              //first move spot light
                              AnimatedPositioned(
                                top: _currentSpotScene.spot!.top,
                                left: _currentSpotScene.spot!.left,
                                duration: _currentSpotScene.movmentDuration,
                                curve: Curves.fastOutSlowIn,
                                onEnd: () async {
                                  //then after movementduration show description and start playing
                                  _showDescription = true;
                                  setState(() {});

                                  if (_currentSpotScene.audioAsset != null) {
                                    await player.play(AssetSource(_currentSpotScene.audioAsset!));
                                  } else {
                                    goToNext();
                                  }
                                },
                                child: AnimatedContainer(
                                  height: _currentSpotScene.spot!.spotHeight,
                                  width: _currentSpotScene.spot!.spotWidth,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: scenario.shadow
                                        ? const [
                                            BoxShadow(
                                              color: Colors.white,
                                              spreadRadius: 15,
                                              blurRadius: 10,
                                              offset: Offset(0, 0),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  duration:
                                      Duration(microseconds: (_currentSpotScene.movmentDuration.inMicroseconds / 2).round()),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (scenario.titleWidget != null && !_sleepMode)
                      Positioned(
                          left: calcPosX(scenario.titlePosition),
                          top: calcPosY(scenario.titlePosition),
                          child: AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 500),
                            child: scenario.titleWidget!,
                          )),
                    if (_currentSpotScene.description != null && !_sleepMode)
                      Positioned(
                        left: calcPosX(_currentSpotScene.descriptionPosition),
                        top: calcPosY(_currentSpotScene.descriptionPosition),
                        child: AnimatedOpacity(
                          opacity: _showDescription ? 1 : 0,
                          duration: scenario.hidingDelay,
                          child: _currentSpotScene.description!,
                        ),
                      ),
                    if (scenario.displayQuit && !_sleepMode)
                      positionedButton(
                          button: scenario.quitButton,
                          onPress: () {
                            quit();
                          }),
                    if (scenario.displayReplay && !_sleepMode)
                      positionedButton(
                          button: scenario.replayButton,
                          onPress: () {
                            goTo(0);
                          }),
                  ],
                ),
              );
      }),
    );
  }

  double calcPosX(SpotPosition pos) => pos.left * currentConstraints!.maxWidth;
  double calcPosY(SpotPosition pos) => pos.top * currentConstraints!.minHeight;

  positionedButton({required SpotButton button, required Null Function() onPress}) => Positioned(
        left: calcPosX(button.position),
        top: calcPosY(button.position),
        child: InkWell(
          onTap: () {
            onPress.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              button.icon,
              color: button.color,
              size: 50,
            ),
          ),
        ),
      );

  void changeScenario(SpotScenario newScenario) {
    scenario = newScenario;
    _sleepMode = false;
    isDisable();
    setState(() {});

    if (!disable) start();
  }

  void start() {
    scenario.init(widget.child);
    _currentSpotScene = SpotScene(spot: Spot(spotHeight: 1, spotWidth: 1, left: -100, top: -100));
    _currentIndex = -1;

    //we need to wait audio title to complete
    _subscription = player.onPlayerComplete.listen((event) {
      goToNext();
    });
    if (scenario.audioAsset != null) {
      player.play(AssetSource(scenario.audioAsset!));
    } else {
      goTo(0);
    }
  }

  void goToNext() {
    _movementDelayTimer = Timer(_currentSpotScene.delay, () {
      //after delay hide description
      _showDescription = false;
      if (mounted) setState(() {});
      _hidingDelayTimer = Timer(scenario.hidingDelay, () {
        //wait hidingDelay and go to next scene
        _currentIndex++;
        if (_currentIndex > scenario.scenes.length - 1) {
          //we reach the end

          if (scenario.endMode == EndMode.loop) {
            _currentIndex = scenario.endMode == EndMode.loop ? 0 : _currentIndex -= 1;
          } else {
            _currentIndex -= 1;
            quit();
          }
        }
        _currentSpotScene = scenario.scenes[_currentIndex];
        if (mounted) setState(() {});
      });
    });
  }

  void goTo(int scene) {
    if (scenario.scenes.length > scene) {
      cleanTimers();
      _currentIndex = scene;
      _currentSpotScene = scenario.scenes[_currentIndex];
      setState(() {});
    }
  }

  void quit() {
    player.pause();
    _subscription?.cancel();
    cleanTimers();

    if (scenario.id != null) {
      SpotScenario.setState(scenario.id!, false);
    }

    if (scenario.endMode == EndMode.stayInactive) {
      _sleepMode = true;
      setState(() {});
    } else {
      _hideChild = true;
      setState(() {});
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.child,
          transitionDuration: const Duration(seconds: 1),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  void cleanTimers() {
    _movementDelayTimer?.cancel();
    _hidingDelayTimer?.cancel();
  }

  void isDisable() {
    disable =
        !scenario.forceDisplay && SpotScenario.spotIDs.containsKey(scenario.id) && SpotScenario.spotIDs[scenario.id] == false;
  }
}

class Spot {
  double spotWidth;
  double spotHeight;
  late double left;
  late double top;

  Spot({required this.spotWidth, required this.spotHeight, required this.left, required this.top});
}

class SpotScenario {
  String? id;
  Widget? titleWidget;
  List<SpotScene> scenes;

  bool shadow;
  EndMode endMode;
  Duration hidingDelay;

  SpotPosition titlePosition;

  bool displayQuit;
  bool displayReplay;
  SpotButton quitButton;
  SpotButton replayButton;

  String? audioAsset;

  bool forceDisplay;

  SpotScenario({
    required this.scenes,
    this.id,
    this.forceDisplay = false,
    this.titleWidget,
    this.shadow = true,
    this.endMode = EndMode.redirectTochild,
    this.displayQuit = true,
    this.displayReplay = true,
    this.audioAsset,
    this.hidingDelay = const Duration(seconds: 1),
    quitButton,
    replayButton,
    titlePosition,
  })  : quitButton = quitButton ?? SpotButton(position: SpotPosition(0.8, 0.07), icon: Icons.arrow_circle_right_outlined),
        replayButton = replayButton ?? SpotButton(position: SpotPosition(0.05, 0.9), icon: Icons.replay),
        titlePosition = titlePosition ?? SpotPosition(0.05, 0.17);

  init(child) {
    if (child.key == null) return;
    var keys = child.key.currentWidget.tutorialKeys;
    if (scenes.length > keys.length) {
      throw Exception("Le nombre de clefs dans le widget ne correspond pas au nombre de scène dans votre scénario!");
    }
    for (int i = 0; i < scenes.length; i++) {
      scenes[i].componentKey = keys[i];
    }
  }

  static textWidgetBuilder({required String text, TextStyle? style, required context}) => SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
                flex: 10,
                child: Text(
                  textAlign: TextAlign.center,
                  text,
                  style:
                      style ?? Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                )),
          ],
        ),
      );

  static Map<String, bool> spotIDs = {};

  static createState(List<String> ids) async {
    for (String k in ids) {
      spotIDs[k] = (await spotStorage.read(key: k)) != false.toString();
    }
  }

  static resetState() async {
    for (String k in spotIDs.keys) {
      spotIDs[k] = true;
      await spotStorage.write(key: k, value: true.toString());
    }
  }

  static setState(String id, bool display) async {
    await spotStorage.write(key: id, value: display.toString());
    spotIDs[id] = display;
  }
}

class SpotPosition {
  double left;
  double top;

  SpotPosition(this.left, this.top);
}

class SpotButton {
  SpotPosition position;

  IconData icon;
  Color? color;

  SpotButton({required this.position, required this.icon, this.color});

  static tutorial(context, HoleWidget holeWidget) {
    var w = holeWidget;

    w.scenario.forceDisplay = true;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => w,
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.help_outline,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class SpotScene {
  GlobalKey? componentKey;
  Spot? _spot;
  bool deformable;
  SpotPosition descriptionPosition;
  Widget? description;
  String? audioAsset;

  late Duration movmentDuration;

  late Duration delay;

  SpotScene({
    this.delay = const Duration(seconds: 0),
    this.movmentDuration = const Duration(seconds: 2),
    this.deformable = false,
    this.audioAsset,
    descriptionPosition,
    this.description,
    spot,
  })  : _spot = spot,
        descriptionPosition = descriptionPosition ?? SpotPosition(0.05, 0.66);

  Spot? get spot {
    return _spot ?? _fromComponent;
  }

  set spot(Spot? value) {
    _spot = value;
  }

  Spot? get _fromComponent {
    if (componentKey?.currentContext == null) return null;
    var enlarge = 1.2;
    RenderBox box = componentKey!.currentContext!.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero);
    var diameter = max(box.size.width, box.size.height) * enlarge;

    double xOffset = deformable ? diameter * (1 - enlarge) / 2 : (box.size.width - diameter) / 2;
    double yOffset = deformable ? diameter * (1 - enlarge) / 2 : (box.size.height - diameter) / 2;

    return Spot(
      spotWidth: deformable ? box.size.width * enlarge : diameter,
      spotHeight: deformable ? box.size.height * enlarge : diameter,
      left: position.dx + xOffset,
      top: position.dy + yOffset,
    );
  }
}
