import 'package:flutter/material.dart';
import 'package:drmem_browser/pkg/drmem_provider/drmem_provider.dart';

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

// Define an extension on the `DevValue` hierarchy.

extension on DevValue {
  // This extension builds a Widget that displays values of the given type. It
  // determines which subclass the object actually is to generate the
  // appropriate widget.

  Widget build(BuildContext context, void Function()? setFunc, String? units) {
    final Color color = setFunc != null ? Colors.cyan : Colors.grey;
    final TextStyle style = TextStyle(color: color);
    final data = this;
    Widget? widget;

    // Booleans display a checkbox.

    if (data is DevBool) {
      widget = Icon(
          data.value ? Icons.radio_button_checked : Icons.radio_button_off,
          color: color);
    }

    // Integers display their value with an optional units designation.

    else if (data is DevInt) {
      widget = Text(units != null ? "${data.value} $units" : "${data.value}",
          style: style);
    }

    // Doubles display their value with an optional units designation.

    else if (data is DevFlt) {
      widget = Text(units != null ? "${data.value} $units" : "${data.value}",
          style: style);
    }

    // Strings are displayed as strings.

    else if (data is DevStr) {
      widget = Text(data.value, style: style);
    }

    if (widget != null) {
      if (setFunc != null) {
        return GestureDetector(onTap: setFunc, child: widget);
      } else {
        return widget;
      }
    } else {
      // If we don't recognize the type, display an error message.

      return buildErrorWidget(Theme.of(context), "unknown data type");
    }
  }
}

// This widget is responsible for displaying live data. It will start the
// monitor subscription so that it is the only widget that has to refresh when
// new data arrives.

class DataWidget extends StatefulWidget {
  final String device;
  final bool settable;
  final String? units;

  const DataWidget(this.device, this.settable, this.units, {super.key});

  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  bool _setDevice = false;

  Widget _buildDisplayWidget(BuildContext context) {
    final DrMem drmem = DrMem.of(context);
    void Function()? setFunc =
        widget.settable ? () => setState(() => _setDevice = true) : null;

    return StreamBuilder(
        stream: drmem.monitorDevice("rpi4", widget.device),
        builder: (context, snapshot) => snapshot.hasData
            ? snapshot.data!.value.build(context, setFunc, widget.units)
            : Container());
  }

  Widget _buildSettingWidget(BuildContext context) {
    return const Icon(Icons.ac_unit);
  }

  // Create the appropriate widget based on the type of the incoming data.
  @override
  Widget build(BuildContext context) {
    return _setDevice
        ? _buildSettingWidget(context)
        : _buildDisplayWidget(context);
  }
}
