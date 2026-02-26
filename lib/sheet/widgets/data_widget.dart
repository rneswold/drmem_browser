import 'package:drmem_browser/sheet/widgets/device_widgets.dart';
import 'package:flutter/material.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/snacks.dart';

// This builds widgets that show an error icon followed by red text
// indicating an unsupported type was received. This could happen if
// an older version of the app is reading a new version of DrMem.

Widget buildErrorWidget(ThemeData td, String msg) {
  Color errorColor = td.colorScheme.error;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.error, size: 16.0, color: errorColor),
      ),
      Text(msg, style: TextStyle(color: errorColor))
    ],
  );
}

class _SettingTextEditor extends StatelessWidget {
  final Device device;
  final String node;
  final void Function() exitFunc;
  final TextInputType? inpType;
  final DevValue? Function(BuildContext, String) parser;

  const _SettingTextEditor(
      {required this.device,
      required this.exitFunc,
      required this.node,
      this.inpType,
      required this.parser});

  @override
  Widget build(BuildContext context) {
    final td = Theme.of(context);

    return TextField(
        autofocus: true,
        style: td.textTheme.bodyMedium!.apply(color: Colors.cyan),
        textAlign: TextAlign.end,
        keyboardType: inpType,
        decoration: null,
        minLines: 1,
        maxLines: 1,
        onSubmitted: (value) async {
          exitFunc();

          final result = parser(context, value);

          if (result != null) {
            try {
              await DrMem.setDevice(context, node, device, result);
            } catch (e) {
              // ignore: use_build_context_synchronously
              displayError(context, e.toString());
            }
          }
        });
  }
}

String _hex(int v) => v.toRadixString(16).padLeft(2, '0');

// Displays an integer device value. Also registers for the units field.

class _DisplayIntWidget extends StatelessWidget {
  final int value;
  final Color color;

  const _DisplayIntWidget({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final units = DeviceWidget.getUnits(context);

    return Text(units != null ? "$value $units" : "$value",
        style: TextStyle(color: color));
  }
}

// Displays a floating point device value. Also registers for the units field.

class _DisplayFloatWidget extends StatelessWidget {
  final double value;
  final Color color;

  const _DisplayFloatWidget({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final units = DeviceWidget.getUnits(context);

    return Text(units != null ? "$value $units" : "$value",
        style: TextStyle(color: color));
  }
}

// Define an extension on the `DevValue` hierarchy.

extension on DevValue {
  // This extension builds a Widget that displays values of the given type. It
  // determines which subclass the object actually is to generate the
  // appropriate widget.

  Widget build(void Function() Function(DevValue)? setFunc) {
    final Color color = setFunc != null ? Colors.cyan : Colors.grey;

    Widget widget = switch (this) {
      DevBool(value: var v) => Icon(
          v ? Icons.radio_button_checked : Icons.radio_button_off,
          color: color),
      DevInt(value: var v) => _DisplayIntWidget(value: v, color: color),
      DevFlt(value: var v) => _DisplayFloatWidget(value: v, color: color),
      DevStr(value: var v) => Text(v, style: TextStyle(color: color)),
      DevColor(red: var r, green: var g, blue: var b) => Text(
          "R${_hex(r)}G${_hex(g)}B${_hex(b)}",
          style: TextStyle(color: Color.fromRGBO(r, g, b, 1.0)))
    };

    return GestureDetector(
        onTap: setFunc != null ? setFunc(this) : null, child: widget);
  }

  // Builds a widget that can edit values of the current object type.

  Widget buildEditor(
      BuildContext context, String node, void Function() exitFunc) {
    final device = DeviceWidget.getDevice(context)!;

    return switch (this) {
      DevBool() => buildBoolEditor(context, device, node, exitFunc),
      DevFlt() => buildFloatEditor(context, device, node, exitFunc),
      DevInt() => buildIntegerEditor(context, device, node, exitFunc),
      DevStr() => buildStringEditor(context, device, node, exitFunc),
      DevColor() => Container()
    };
  }

  Widget buildFloatEditor(BuildContext context, Device device, String node,
          void Function() exitFunc) =>
      _SettingTextEditor(
          device: device,
          node: node,
          exitFunc: exitFunc,
          inpType: TextInputType.number,
          parser: (context, value) {
            if (value.isNotEmpty) {
              try {
                return DevFlt(value: double.parse(value));
              } on FormatException {
                displayError(context, 'Bad numeric format ... setting ignored');
              }
            }
            return null;
          });

  Widget buildIntegerEditor(BuildContext context, Device device, String node,
          void Function() exitFunc) =>
      _SettingTextEditor(
          device: device,
          node: node,
          exitFunc: exitFunc,
          inpType: TextInputType.number,
          parser: (context, value) {
            if (value.isNotEmpty) {
              try {
                return DevInt(value: int.parse(value));
              } on FormatException {
                displayError(context, 'Bad numeric format ... setting ignored');
              }
            }
            return null;
          });

  Widget buildStringEditor(BuildContext context, Device device, String node,
          void Function() exitFunc) =>
      _SettingTextEditor(
          device: device,
          node: node,
          exitFunc: exitFunc,
          parser: (_, value) => DevStr(value: value));

  // Returns a widget tree which sends boolean values to a device. For the
  // boolean editor, we display two buttons which send `true` and `false`
  // values.

  Widget buildBoolEditor(
    BuildContext context,
    Device device,
    String node,
    void Function() exitFunc,
  ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ElevatedButton(
                onPressed: () async {
                  exitFunc();
                  await DrMem.setDevice(
                      context, node, device, const DevBool(value: true));
                },
                child: const Text("true")),
          ),
          Expanded(
            child: ElevatedButton(
                onPressed: () async {
                  exitFunc();
                  await DrMem.setDevice(
                      context, node, device, const DevBool(value: false));
                },
                child: const Text("false")),
          ),
        ],
      );
}

// This is the top-level widget that displays a `DevValue` type. This
// functionality was split into its own widget because it registers for
// reading updates. If the parent widget inlined this, then reading updates
// would redraw the parent, too.

class _DisplayValueWidget extends StatelessWidget {
  final void Function() Function(DevValue)? setFunc;

  const _DisplayValueWidget({required this.setFunc});

  @override
  Widget build(BuildContext context) {
    final value = DeviceWidget.getReading(context);

    return value?.build(setFunc) ?? Container();
  }
}

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatefulWidget {
  final String? node;

  const DataWidget({this.node, super.key});

  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  // When `null`, we simply display the incoming data. If not-null, it is
  // the last value received from the stream and is an example of the data
  // we need to edit.

  DevValue? _editValue;

  // Builds a widget to display a DrMem value type. This focuses solely on
  // the widget that displays the value. If the value is to have associated
  // widgets, they can incorporate this widget.

  Widget _buildDisplayWidget(BuildContext context) {
    final void Function() Function(DevValue)? setFunc =
        DeviceWidget.getSettable(context)
            ? (v) => () => setState(() => _editValue = v)
            : null;

    return _DisplayValueWidget(setFunc: setFunc);
  }

  // Create the appropriate widget based on the type of the incoming data.
  @override
  Widget build(BuildContext context) {
    final editValue = _editValue;

    return editValue != null && widget.node != null
        ? Expanded(
            child: TapRegion(
              onTapOutside: (_) => setState(() => _editValue = null),
              child: editValue.buildEditor(
                context,
                widget.node!,
                () => setState(() => _editValue = null),
              ),
            ),
          )
        : _buildDisplayWidget(context);
  }
}
