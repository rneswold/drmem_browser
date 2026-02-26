import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'snacks.dart';

class _Title extends StatelessWidget {
  final String title;

  const _Title({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
        child: Row(children: [
          const Icon(Icons.developer_board),
          Container(width: 12.0),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ]),
      );
}

// Creates a widget that is used as a section separator when displaying node
// information.

class _Header extends StatelessWidget {
  final String label;

  const _Header({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
      padding:
          const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 4.0),
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          )
        ],
      ));
}

class _ShowProperty extends StatelessWidget {
  final String label;
  final int labelFlex;
  final String? value;

  const _ShowProperty(
      {required this.label, required this.labelFlex, this.value});

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Row(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: labelFlex,
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(color: td.hintColor)),
          ),
        ),
        Flexible(
            fit: FlexFit.tight,
            flex: 20,
            child: Text(value ?? "unknown",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: td.colorScheme.primary)))
      ],
    );
  }
}

// This is an immutable Widget that displays node information.

class _NodeInfo extends StatelessWidget {
  final NodeInfo node;
  final List<DriverInfo> driverInfo;
  final List<DeviceInfo> deviceInfo;

  const _NodeInfo(
      {required this.node, required this.driverInfo, required this.deviceInfo});

  static const EdgeInsets _all8 = EdgeInsets.all(8.0);

  // Build the widget.
  @override
  Widget build(BuildContext context) {
    const int nodePropFlex = 8;
    const int gqlPropFlex = 14;

    return Padding(
      padding: _all8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title(title: node.name),
          Expanded(
            child: Scaffold(
              body: SingleChildScrollView(
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShowProperty(
                        label: "version",
                        labelFlex: nodePropFlex,
                        value: node.version),
                    _ShowProperty(
                        label: "address",
                        labelFlex: nodePropFlex,
                        value: "${node.addr.host}:${node.addr.port}"),
                    _ShowProperty(
                        label: "location",
                        labelFlex: nodePropFlex,
                        value: node.location),
                    if (node.bootTime != null)
                      _ShowProperty(
                          label: "boot time",
                          labelFlex: nodePropFlex,
                          value: node.bootTime!.toLocal().toString()),
                    const _Header(label: "GraphQL Endpoints"),
                    _ShowProperty(
                        label: "queries",
                        labelFlex: gqlPropFlex,
                        value: node.queries),
                    _ShowProperty(
                        label: "mutations",
                        labelFlex: gqlPropFlex,
                        value: node.mutations),
                    _ShowProperty(
                        label: "subscriptions",
                        labelFlex: gqlPropFlex,
                        value: node.subscriptions),
                    const _Header(label: "Drivers"),
                    _DriversListView(drivers: driverInfo),
                    const _Header(label: "Devices"),
                    _DevicesListView(devices: deviceInfo),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close")),
            ),
          )
        ],
      ),
    );
  }
}

class _DisplayDriverInfo extends StatelessWidget {
  final String description;

  const _DisplayDriverInfo({required this.description});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Expanded(child: Markdown(data: description)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Close")),
                )
              ],
            )),
      );
}

// Builds a row of driver information, including the Help button which brings
// up a window containing the description text for the driver.

Widget _buildDrvInfoRow(DriverInfo info, BuildContext context) {
  final ThemeData td = Theme.of(context);

  return Container(
    margin: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
    decoration: const BoxDecoration(color: Colors.white10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Flexible(
          flex: 8,
          fit: FlexFit.tight,
          child: Text(info.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: td.colorScheme.primary))),
      Container(width: 10.0),
      Flexible(
          flex: 16,
          fit: FlexFit.tight,
          child: Text(info.summary, style: TextStyle(color: td.hintColor))),
      Container(width: 10.0),
      IconButton(
          color: td.colorScheme.secondary,
          onPressed: () async => showDialog(
                context: context,
                builder: (context) =>
                    _DisplayDriverInfo(description: info.description),
              ),
          icon: const Icon(Icons.help))
    ]),
  );
}

Widget _buildChip(ThemeData td, String content) => Container(
      decoration: BoxDecoration(
          border: Border.all(color: td.hintColor),
          borderRadius: BorderRadius.circular(8.0),
          shape: BoxShape.rectangle,
          color: td.disabledColor),
      child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(content, style: td.textTheme.labelMedium)),
    );

String _makeDateChipContent(String label, DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');

  return "$label: $year-$month-$day, $hour:$minute";
}

List<Widget> _buildChips(ThemeData td, DeviceInfo info) => [
      if (info.units != null) _buildChip(td, "units: ${info.units}"),
      if (info.history != null) ...[
        _buildChip(td, "points: ${info.history!.totalPoints}"),
        _buildChip(td,
            _makeDateChipContent("oldest", info.history!.summary!.$1.stamp)),
        _buildChip(
            td, _makeDateChipContent("last", info.history!.summary!.$2.stamp)),
      ]
    ];

class _DeviceInfoRow extends StatelessWidget {
  final DeviceInfo info;

  const _DeviceInfoRow({required this.info});

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      padding: const EdgeInsets.only(top: 4.0, left: 8.0, bottom: 4.0),
      decoration: const BoxDecoration(color: Colors.white10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    Future.wait([
                      Clipboard.setData(ClipboardData(text: info.device.name))
                    ]);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Added ${info.device.name} to clipboard")));
                  },
                  child: Text(info.device.name,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: td.colorScheme.primary)),
                ),
              ),
              if (info.settable)
                const Expanded(
                  child: Text(
                    "settable",
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Expanded(
                  child: Text(
                    "read-only",
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              top: 4.0, left: 20.0, right: 20.0, bottom: 4.0),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 10.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.end,
              children: _buildChips(td, info),
            ),
          ),
        )
      ]),
    );
  }
}

// Local widget which displays a list of drivers.

class _DriversListView extends StatelessWidget {
  final List<DriverInfo> drivers;

  const _DriversListView({required this.drivers});

  @override
  Widget build(BuildContext context) {
    List<Widget> d = drivers.map((e) => _buildDrvInfoRow(e, context)).toList();
    List<Widget> all = [
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 16.0),
        child: Text(
            "This node is configured with these ${drivers.length} drivers.",
            style: TextStyle(color: Theme.of(context).hintColor)),
      )
    ];

    all.addAll(d);

    return Column(children: all);
  }
}

// Local widget which displays a list of drivers.

class _DevicesListView extends StatelessWidget {
  final List<DeviceInfo> devices;

  const _DevicesListView({required this.devices});

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 16.0),
          child: Text(
              "This node provides ${devices.length} devices. Double tap on "
              "a device name to copy it to the clipboard.",
              style: TextStyle(color: Theme.of(context).hintColor)),
        ),
        ...devices.map((e) => _DeviceInfoRow(info: e))
      ]);
}
// This public function returns the widget that displays node information.

Future<void> displayNode(NodeInfo node, BuildContext context) async {
  try {
    final driverInfo = await DrMem.getDriverInfo(context, node.name);

    if (context.mounted) {
      final deviceInfo = await DrMem.getDeviceInfo(context,
          node: node.name, device: DevicePattern(name: "*"));

      if (context.mounted) {
        showDialog(
            context: context,
            builder: (context) => Dialog.fullscreen(
                child: _NodeInfo(
                    node: node,
                    driverInfo: driverInfo,
                    deviceInfo: deviceInfo)));
      }
    }
  } on Exception catch (e) {
    // ignore: use_build_context_synchronously
    displayError(context, e.toString());
  }
}
