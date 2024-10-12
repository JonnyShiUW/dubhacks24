# Flutter Front-end

The front-end of this To-Do App is written in Flutter, an opensource framework by Google "...for building beautiful, natively compiled, multi-platform applications from a single codebase".

## Background

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Setup

Make sure your current directory is `todo_frontend`. (run `pwd` just to make sure)

Assuming you already have this repo locally and have Flutter setup (reference the top-level README for directions), install all of the required dependancies using:

```shell
flutter pub get  
```
You should see an output like:
```
Resolving dependencies... 
  collection 1.17.2 (1.18.0 available)
  flutter_lints 2.0.3 (3.0.0 available)
  lints 2.1.1 (3.0.0 available)
  material_color_utilities 0.5.0 (0.8.0 available)
  meta 1.9.1 (1.11.0 available)
  stack_trace 1.11.0 (1.11.1 available)
  stream_channel 2.1.1 (2.1.2 available)
  test_api 0.6.0 (0.6.1 available)
  web 0.1.4-beta (0.3.0 available)
Got dependencies! 
```
You *can* update the dependancies using `flutter pub upgrade`, but
this app is only garunteed to work with these dependencies.

Running the front-end locally is a piece of cake. Simply run
```shell
flutter run lib/main.dart
```
If you do not have a phone emulator running, the app can be opened in a browser as well.

Note that if you are using VSCode, an even easier way is to "Run and Debug" by clicking the "Play" button in the top right (or on the left panel) pf VSCode. 'F5' also works!

You should be good to go! Don't forget to read all of the comments I've left you in `lib/main.dart` :)


