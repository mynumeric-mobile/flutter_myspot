Flutter_MySpot is a plug alowing you to easily implement tutorial in your app

<div align="center">
  <video  controls autoplay src="https://github.com/mynumeric-mobile/flutter_spot/assets/60822263/677de86d-3368-4e3e-af2d-d4ce50375abc" width="400" />
</div>

## Features

Manage scenario with scene to explain élément on your flutter widget adding key to desired widget

<li>Allow reponsive and moving widget as target,</li>
<li>Audio support (using <a href="https://pub.dev/packages/audioplayers">audioplayer</a>),</li>
<li>Handle play once (using <a href="https://pub.dev/packages/flutter_secure_storage">flutter_secure_storage)</a>,</li>

## Getting started

To install plug-in add to your public.yaml :
```dart
dependencies:
  flutter:
    sdk: flutter

  flutter_myspot:
    git: https://github.com/mynumeric-mobile/flutter_myspot
```

## Usage

examples for package could be found in example folder

- first wrap your page with HoleWidget

this widget hold scenario. Scenario is composed by properties and an array of scenes. Each scene is used sequencialy to highlight a designet widget.

note that your widget must have a key :

```dart
HoleWidget(
          scenario: SpotScenario(
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
            ],
            
          ),
          child: MyHomePage(title: 'Flutter Demo Home Page', key: GlobalKey()),
        ));
  }
```
- Next designate widget to highlight :
  add in top of your main widget an array 'tutorialKeys' add as many GlobalKey as you want scene
  
```dart
class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  final List<GlobalKey> tutorialKeys = [GlobalKey()];// add this line
....
```

  and add tutorialKey to desired widget.

```dart
  Text(
    key: widget.tutorialKeys[0],
```

<h2>Handle play once</h2>

If you want to display tutorial only on first use, you can call createState(["home"]) where "home" is a unique id for your scene. Your state must be set before any scenario is play in main or in splashscreen. When state is created you just have to set key property of your scene to limit to display her content to first run.

For exemple :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpotScenario.createState(["home"]); //option if you want to display only once
  runApp(const MyApp());
}
```

in your scenario declaration add

```dart
HoleWidget(
          scenario: SpotScenario(
            titleWidget: SpotScenario.textWidgetBuilder(text: "Wellcome to our tutorial", context: context),
            // and a scene for each widget to highlight
            scenes: [
              SpotScene(
                id:"home,
                description: SpotScenario.textWidgetBuilder(
                    text: "You can change this number",
...
```

Note that you can use state for other purpose. You just need to at a unique ID.

to set value
```dart
SpotScenario.setState("myUniqueID", false);
```
to read state 
```dart
SpotScenario.spotIDs["myUniqueID"]
```

<h2>Adding help button</h2>

MySpot provide a widget to easily add help button to your screen:

```dart
SpotButton.tutorial(
            context,HoleWidget(...
```
<h2>Defining scenario</h2>

To have more readable code you could define your tutorials in external class
```dart
class Tutorial {
  static HoleWidget home(context) => HoleWidget(
        scenario: SpotScenario(
          id: "home",
            ...
          child:MyScreenWidget()
          }
```

and then you can use just like this :

```dart
Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Tutorial.home(context),
                      ),
                    );
```
And help button become just :

```dart
SpotButton.tutorial(context, Tutorial.home(context))
```

<h2>Defining endMode</h2>

EndMode define behavior after end of scenario. There is 3 modes :

<h3><li>redirectTochild</li></h3>
This is the default one. When end is reach we leave tutorial and navigate to the child widget.
<h3><li>loop</li></h3>
In this mode we play scenario in loop.
<h3><li>stayInactive</li></h3>
If you want to keep MySpot to read another scenario for exemple you must use this one.

<h2>Changing scénario</h2>

In some case it could be intresting having svereal scenario for one screen. For exemple a scenario for introducing screen then give the hand to user to do an action and play after that an other scenario or after returning from popup. For that you have to add key for HoleWidget et the use it as follow:

```dart
widget.spotKey?.currentState?.changeScenario(Tutorial.home2(
                      context,
                      HomeWidget()));
```                   
