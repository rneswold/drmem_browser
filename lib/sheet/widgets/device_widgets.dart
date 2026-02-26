import "dart:developer" as dev;
import 'dart:io';

import 'package:drmem_browser/sheet/widgets/data_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/sheet/row.dart';

import 'package:drmem_browser/snacks.dart';

enum _DeviceModelAspect { label, name, units, settable, reading }

// This is an `InheritedModel` widget which holds the latest information
// associated with a device. Widgets downstream can register for apects and
// will get updated when their field of interest changes.

class _DeviceModel extends InheritedModel<_DeviceModelAspect> {
  final bool settable;
  final String label;
  final Device? device;
  final String? units;
  final (DateTime, DevValue)? reading;

  const _DeviceModel(
      {required this.label,
      required this.device,
      this.settable = false,
      this.units,
      this.reading,
      required super.child});

  @override
  bool updateShouldNotify(covariant _DeviceModel oldWidget) =>
      settable != oldWidget.settable ||
      label != oldWidget.label ||
      device != oldWidget.device ||
      units != oldWidget.units ||
      reading != oldWidget.reading;

  @override
  bool updateShouldNotifyDependent(
          covariant _DeviceModel oldWidget, Set<_DeviceModelAspect> deps) =>
      (settable != oldWidget.settable &&
          deps.contains(_DeviceModelAspect.settable)) ||
      (label != oldWidget.label && deps.contains(_DeviceModelAspect.label)) ||
      (device != oldWidget.device && deps.contains(_DeviceModelAspect.name)) ||
      (units != oldWidget.units && deps.contains(_DeviceModelAspect.units)) ||
      (reading != oldWidget.reading &&
          deps.contains(_DeviceModelAspect.reading));
}

// Creates a widget that displays a row of information for a DrMem device.

class DeviceWidget extends StatelessWidget {
  final Stream<_DeviceModel>? Function(BuildContext) _builder;

  // The constructor simply builds a function that is used to set up the stream
  // of readings from a device.

  DeviceWidget(
      {String? label,
      required Device? device,
      required String? node,
      super.key})
      : _builder = device != null && node != null
            ? _buildStream(label: label, device: device, node: node)
            : _singleton(device, node);

  // Returns a stream that emits one value. This is used when the user hasn't
  //  defined a device in the row.

  static Stream<_DeviceModel> Function(BuildContext) _singleton(
      Device? device, String? node) {
    dev.log("building empty stream", name: "DeviceWidget");

    return (BuildContext context) async* {
      if (device == null) {
        if (node == null) {
          yield _DeviceModel(
              label: "no device and node specified",
              device: device,
              units: null,
              settable: false,
              child: _DeviceRowWrapper(node: null));
        } else {
          yield _DeviceModel(
              label: "no device specified",
              device: device,
              units: null,
              settable: false,
              child: _DeviceRowWrapper(node: null));
        }
      } else if (node == null) {
        yield const _DeviceModel(
            label: "no node specified",
            device: null,
            units: null,
            settable: false,
            child: _DeviceRowWrapper(node: null));
      }
    };
  }

  // This private, helper method builds a closure which creates a stream that
  // returns `_DeviceModel` widgets. This allows the `DeviceWidget` to be
  // a `StatelessWidget` since all the updates are returned by the stream.

  static Stream<_DeviceModel>? Function(BuildContext) _buildStream(
      {String? label, required Device device, required String node}) {
    final cookedLabel = label ?? device.name;
    dev.log("building monitor stream", name: "DeviceWidget");

    return (BuildContext context) async* {
      dev.log("configured for ${device.name}@$node", name: "DeviceWidget");
      try {
        // First, get device information from the node. This will tell us
        // whether the device is settable and also provide the units, if any.

        final di =
            await DrMem.getDeviceInfo(context, node: node, device: device);

        // If the query returns one instance of device information, we're good.

        if (di
            case [DeviceInfo(settable: bool settable, units: String? units)]) {
          // Yield the first InheritedModel. In this case, all fields except
          // the reading field is complete.

          yield _DeviceModel(
              label: cookedLabel,
              device: device,
              units: units,
              settable: settable,
              child: _DeviceRowWrapper(node: node));

          // If the widget is still mounted in the tree, stream the readings
          // of the device.

          if (context.mounted) {
            yield* DrMem.monitorDevice(context, node, device).map((event) =>
                _DeviceModel(
                    label: cookedLabel,
                    device: device,
                    units: units,
                    settable: settable,
                    reading: (event.stamp, event.value),
                    child: _DeviceRowWrapper(node: node)));
          }
        } else {
          throw HttpException("bad device ${device.name}@$node");
        }
      } catch (ex) {
        // ignore: use_build_context_synchronously
        displayError(context, ex.toString());
      }
    };
  }

  static _DeviceModel _of(BuildContext context, _DeviceModelAspect aspect) =>
      InheritedModel.inheritFrom<_DeviceModel>(context, aspect: aspect)!;

  static String? getUnits(BuildContext context) =>
      _of(context, _DeviceModelAspect.units).units;

  static String getLabel(BuildContext context) =>
      _of(context, _DeviceModelAspect.label).label;

  static bool getSettable(BuildContext context) =>
      _of(context, _DeviceModelAspect.settable).settable;

  static Device? getDevice(BuildContext context) =>
      _of(context, _DeviceModelAspect.label).device;

  static DateTime? getTimestamp(BuildContext context) =>
      _of(context, _DeviceModelAspect.reading).reading?.$1;

  static DevValue? getReading(BuildContext context) =>
      _of(context, _DeviceModelAspect.reading).reading?.$2;

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: _builder(context),
      builder: (context, snapshot) =>
          snapshot.hasData ? snapshot.data! : Container());
}

// Private widget which builds a device row. This row should be a descendant of
// a `_DeviceModel` because it uses widgets that display updating field of a
// device model.

class _DeviceRowWrapper extends StatefulWidget {
  final String? node;

  const _DeviceRowWrapper({this.node});

  @override
  _DeviceRowWrapperState createState() => _DeviceRowWrapperState();
}

class _DeviceRowWrapperState extends State<_DeviceRowWrapper> {
  bool _expand = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _expand = !_expand),
                child: Text(
                  DeviceWidget.getLabel(context),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: td.colorScheme.primary),
                ),
              ),
            ),
            DataWidget(node: widget.node),
          ],
        ),
        if (_expand) const _DisplayTimestamp(),
      ],
    );
  }
}

// Private widget that displays the timestamp of the readings. Rather than have
// the containing widget register for timestamp updates (resulting in the whole
// widget getting updated), we create a widget that registers for and only
// displays the timestamp.

class _DisplayTimestamp extends StatelessWidget {
  const _DisplayTimestamp();

  // Convert local `DateTime` into a string.

  static String _tsToString(DateTime ts) {
    final year = ts.year.toRadixString(10).padLeft(4, '0');
    final month = ts.month.toRadixString(10).padLeft(2, '0');
    final day = ts.day.toRadixString(10).padLeft(2, '0');
    final hour = ((ts.hour + 11) % 12 + 1).toRadixString(10).padLeft(2, '0');
    final minute = ts.minute.toRadixString(10).padLeft(2, '0');
    final second = ts.second.toRadixString(10).padLeft(2, '0');
    final ampm = ts.hour < 12 ? "am" : "pm";

    return "$year-$month-$day $hour:$minute:$second $ampm ${ts.timeZoneName}";
  }

  @override
  Widget build(BuildContext context) {
    final ts = DeviceWidget.getTimestamp(context)?.toLocal();

    // If the timestamp is `null`, the device doesn't have a value yet so we
    // have to display something else.

    return Text(ts != null ? _tsToString(ts) : "--",
        style: const TextStyle(color: Colors.grey));
  }
}

class DeviceEditor extends StatefulWidget {
  final int _idx;
  final Device? _device;
  final String? _node;
  final String _label;

  const DeviceEditor(this._idx, this._device,
      {String? node, String? label, super.key})
      : _node = node,
        _label = label ?? "";

  @override
  State<DeviceEditor> createState() => _DeviceEditorState();
}

class _DeviceEditorState extends State<DeviceEditor> {
  late final TextEditingController ctrlDevice;
  late final TextEditingController ctrlLabel;
  late final TextEditingController ctrlNode;
  final RegExp re = RegExp(r'^[-:\w\d]*$');

  @override
  void initState() {
    super.initState();
    ctrlDevice = TextEditingController(text: widget._device?.name);
    ctrlLabel = TextEditingController(text: widget._label);
    ctrlNode = TextEditingController(text: widget._node);
  }

  @override
  void dispose() {
    ctrlDevice.dispose();
    ctrlLabel.dispose();
    ctrlNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextField(
                        autocorrect: false,
                        style: Theme.of(context).textTheme.bodyMedium,
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue,
                                  newValue) =>
                              re.hasMatch(newValue.text) ? newValue : oldValue)
                        ],
                        minLines: 1,
                        decoration:
                            getTextFieldDecoration(context, "Device name"),
                        controller: ctrlDevice,
                        onSubmitted: (value) => context.read<Model>().add(
                              UpdateRow(
                                  widget._idx,
                                  DeviceRow(Device(name: value),
                                      node: ctrlNode.text,
                                      label: ctrlLabel.text,
                                      key: UniqueKey())),
                            )),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextField(
                      autocorrect: false,
                      style: Theme.of(context).textTheme.bodyMedium,
                      minLines: 1,
                      decoration: getTextFieldDecoration(context, "Node"),
                      controller: ctrlNode,
                      onSubmitted: (value) => context.read<Model>().add(
                            UpdateRow(
                                widget._idx,
                                DeviceRow(Device(name: ctrlDevice.text),
                                    node: value,
                                    label: ctrlLabel.text,
                                    key: UniqueKey())),
                          )),
                ),
              ],
            ),
            TextField(
                autocorrect: false,
                style: Theme.of(context).textTheme.bodyMedium,
                minLines: 1,
                decoration: getTextFieldDecoration(context, "Label (optional)"),
                controller: ctrlLabel,
                onSubmitted: (value) => context.read<Model>().add(
                      UpdateRow(
                          widget._idx,
                          DeviceRow(Device(name: ctrlDevice.text),
                              node: ctrlNode.text,
                              label: value,
                              key: UniqueKey())),
                    )),
          ],
        ),
      );
}
