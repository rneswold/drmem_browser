import 'package:drmem_browser/model/model_events.dart';
import 'package:flutter/material.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _PageTitle extends StatelessWidget {
  final String title;

  const _PageTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 8.0),
      child: Text(title, style: td.textTheme.bodyLarge),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget ui;
  final String description;

  const _SettingCard({required this.ui, required this.description});

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Card(
        margin: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ui,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(description,
                    style: td.textTheme.bodySmall
                        ?.copyWith(color: td.disabledColor)),
              ),
            ],
          ),
        ));
  }
}

Future<bool> confirmDialog(BuildContext context) async {
  const Text content =
      Text("Do you want to generate a new client ID? This cannot be undone.\n\n"
          "Once a new ID has been generated, your target DrMem nodes will "
          "need to be updated with the new ID.");

  return await showDialog<bool?>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text("New Client ID?"),
                  content: content,
                  actions: [
                    ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Generate"))
                  ])) ??
      false;
}

class _ClientIdSetting extends StatelessWidget {
  const _ClientIdSetting();

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("Client ID",
                    style: td.textTheme.bodyLarge
                        ?.copyWith(color: td.disabledColor)),
              ),
              BlocBuilder<Model, AppState>(builder: (context, state) {
                final ThemeData td = Theme.of(context);

                return Text(state.clientId.fingerprint,
                    style: td.textTheme.bodyMedium);
              }),
            ],
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              if (await confirmDialog(context) && context.mounted) {
                context.read<Model>().add(const ResetClientId());
              }
            },
            child: const Text("New ID"))
      ],
    );
  }
}

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  static const String clientIdText =
      "When DrMem is configured to use encrypted connections, "
      "clients must identify themselves with a difficult-to-guess "
      "value called a \"Client ID\". The value displayed above is "
      "the client ID for this app. This value should be added to "
      "the `graphql.security.clients` array in the `drmem.toml` "
      "file.";

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageTitle(title: "Browser Configuration"),
          _SettingCard(ui: _ClientIdSetting(), description: clientIdText)
        ],
      );
}
