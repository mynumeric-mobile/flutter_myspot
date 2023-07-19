import 'package:flutter/material.dart';
import 'package:flutter_myspot/flutter_myspot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpotScenario.createState(["home"]); //option if you want to display only once
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(colorScheme: const ColorScheme.dark()),

        /// first wrap the call to your widget in a holewidget with your scenario,
        /// don't forget to reference with a key your widget
        /// here const MyHomePage(title: 'Flutter Demo Home Page'), become :
        home: HoleWidget(
          scenario: SpotScenario(
            //id: "home", //option if you want to display only once
            // you can set a title
            titleWidget: SpotScenario.textWidgetBuilder(text: "Wellcome to our tutorial", context: context),
            // and a scene for each widget to highlight
            scenes: [
              SpotScene(
                description: SpotScenario.textWidgetBuilder(
                    text: "You can change this number",
                    context: context,
                    style: const TextStyle(color: Colors.white, fontSize: 20)),
                audioAsset: "number.mp3",
              ),
              SpotScene(
                description: SpotScenario.textWidgetBuilder(
                    text: "by subtracting one", context: context, style: const TextStyle(color: Colors.white, fontSize: 20)),
                audioAsset: "subtracting.mp3",
              ),
              SpotScene(
                description: SpotScenario.textWidgetBuilder(
                    text: "or adding one", context: context, style: const TextStyle(color: Colors.white, fontSize: 20)),
                audioAsset: "adding.mp3",
              ),
            ],
            endMode: EndMode.loop,
          ),
          child: MyHomePage(title: 'Flutter Demo Home Page', key: GlobalKey()),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  //secondly declare an array of GlobaKey. You must have as many elements as widgets to highlight
  final List<GlobalKey> tutorialKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// optionaly you add a tutorail button to call your scénario later
          SpotButton.tutorial(
            context,
            HoleWidget(
              scenario: SpotScenario(
                // you can set a title
                titleWidget: SpotScenario.textWidgetBuilder(text: "Wellcome to our tutorial", context: context),
                // and a scene for each widget to highlight
                scenes: [
                  SpotScene(
                    description: SpotScenario.textWidgetBuilder(
                        text: "You can change this number",
                        context: context,
                        style: const TextStyle(color: Colors.white, fontSize: 20)),
                    audioAsset: "number.mp3",
                  ),
                  SpotScene(
                    description: SpotScenario.textWidgetBuilder(
                        text: "by subtracting one", context: context, style: const TextStyle(color: Colors.white, fontSize: 20)),
                    audioAsset: "subtracting.mp3",
                  ),
                  SpotScene(
                    description: SpotScenario.textWidgetBuilder(
                        text: "or adding one", context: context, style: const TextStyle(color: Colors.white, fontSize: 20)),
                    audioAsset: "adding.mp3",
                  ),
                ],
                endMode: EndMode.loop,
              ),
              child: MyHomePage(title: 'Flutter Demo Home Page', key: GlobalKey()),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  //Third step add to each widget to highlight one of the keys defined previously
                  Text(
                    key: widget.tutorialKeys[0],
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            key: widget.tutorialKeys[1],
            heroTag: "btn1",
            onPressed: _decrementCounter,
            tooltip: 'decrement',
            child: const Icon(Icons.remove),
          ),
          FloatingActionButton(
            key: widget.tutorialKeys[2],
            heroTag: "btn2",
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
