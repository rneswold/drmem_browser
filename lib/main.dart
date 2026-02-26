import "dart:developer" as dev;
import "dart:async";

import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/theme/theme.dart';
import 'package:drmem_browser/mdns_chooser.dart';
import 'package:drmem_browser/setting_page.dart';
import 'package:drmem_browser/param.dart';

// The entry point for the application.
Future<void> main() async {
  // Make sure everything is initialized before starting up our persistent
  // storage.

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize (and load) data associated with the persistent store.

  HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(
          (await getApplicationDocumentsDirectory()).path));

  runApp(const DrMemApp());
}

class DrMemApp extends StatelessWidget {
  const DrMemApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'DrMem Browser',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Provides the app model. This needs to be near the top of the widget
      // tree so that all subpages have access to the model data.

      home: BlocProvider(
        lazy: false,
        create: (_) => Model(),
        child: const DrMem(child: _NodeUpdater(child: _BaseWidget())),
      ));
}

class _NodeUpdater extends StatefulWidget {
  final Widget child;

  const _NodeUpdater({required this.child});

  @override
  State<_NodeUpdater> createState() => _NodeUpdaterState();
}

class _NodeUpdaterState extends State<_NodeUpdater> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Defer initialization to ensure the widget tree is ready and context is valid.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNodes());
  }

  void _initNodes() {
    final model = context.read<Model>();
    final clientId = model.state.clientId;

    dev.log("adding _NodeUpdater to context", name: "foundation");

    // Register all the known DrMem nodes.
    model.state.getNodeNames().forEach((node) =>
        DrMem.addNode(context, model.state.getNodeInfo(node)!, clientId));

    final state = this;

    // Subscribe to mDNS updates.
    _subscription = DrMem.mdnsSubscribe(context).listen((data) {
      final nodeState = data.bootTime == null ? "lost" : "found";

      dev.log("node ${data.name} was $nodeState", name: "nodeUpdater");

      model.add(AddNode(data));

      if (state.mounted) DrMem.addNode(state.context, data, clientId);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _BaseWidget extends StatefulWidget {
  const _BaseWidget();

  @override
  _BaseState createState() => _BaseState();
}

class _BaseState extends State<_BaseWidget> {
  int _selectIndex = 0;

  void changePage(int value) => setState(() => _selectIndex = value);

  // Creates the navigation bar. Right now it creates three icons to click on.

  BottomNavigationBar _buildNavBar() => BottomNavigationBar(
          currentIndex: _selectIndex,
          onTap: changePage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.devices), label: "Nodes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.web_stories), label: "Sheets"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings"),
          ]);

  NavigationRail _buildNavRail() => NavigationRail(
          selectedIndex: _selectIndex,
          onDestinationSelected: changePage,
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.devices), label: Text("Nodes")),
            NavigationRailDestination(
                icon: Icon(Icons.web_stories), label: Text("Sheets")),
            NavigationRailDestination(
                icon: Icon(Icons.settings), label: Text("Settings"))
          ]);

  Widget _display(BuildContext context) => switch (_selectIndex) {
        1 => const ParamPage(),
        2 => const SettingPage(),
        _ => const DnsChooser()
      };

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Scaffold(
              body: SafeArea(
                  child: Row(
            children: [
              _buildNavRail(),
              const VerticalDivider(),
              Expanded(child: _display(context)),
            ],
          )));
        } else {
          return Scaffold(
              body: SafeArea(child: _display(context)),
              bottomNavigationBar: _buildNavBar());
        }
      });
}
