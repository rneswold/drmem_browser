import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import "package:drmem_browser/sheet/widgets/device_widgets.dart";

// The base class for all row types. A sheet is a list of objects derived
// from BaseRow.

sealed class BaseRow {
  final Key key;

  const BaseRow({required this.key});

  Widget buildRowEditor(BuildContext context, int index);
  Widget buildRowRunner(BuildContext context);
  Icon getIcon();

  Map<String, dynamic> toJson();

  // Factory method that can take a map from a JSON string and convert to a
  // derived BaseRow class.

  static BaseRow? fromJson(Map<String, dynamic> map, {Key? key}) {
    switch (map) {
      case {'type': "empty"}:
        return EmptyRow(key: key ?? UniqueKey());

      case {'type': "comment", 'content': String comment}:
        return CommentRow(comment, key: key ?? UniqueKey());

      case {'type': "device", 'device': String device, 'node': String node}:
        return DeviceRow(Device(name: device),
            node: node, label: map['label'], key: key ?? UniqueKey());

      case {'type': "plot"}:
        return PlotRow(key: key ?? UniqueKey());

      default:
        return null;
    }
  }
}

// This type represents a separator in the rendered sheet. How this separation
// has been represented has been changed throught the life of the application.

class EmptyRow extends BaseRow {
  const EmptyRow({required super.key});

  @override
  Icon getIcon() => const Icon(Icons.menu);

  @override
  Widget buildRowEditor(BuildContext context, int index) {
    return const Padding(padding: EdgeInsets.only(top: 8.0), child: Divider());
  }

  @override
  Widget buildRowRunner(BuildContext context) {
    return const Divider();
  }

  @override
  Map<String, dynamic> toJson() => {'type': "empty"};

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) {
    return other is EmptyRow;
  }
}

// This row type holds text which allows the user to add comments to the sheet.

class CommentRow extends BaseRow {
  final String comment;

  const CommentRow(this.comment, {required super.key});

  @override
  Icon getIcon() => const Icon(Icons.chat);

  @override
  Widget buildRowEditor(BuildContext context, index) =>
      _CommentEditor(index, comment);

  @override
  Widget buildRowRunner(BuildContext context) {
    final ThemeData td = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 32.0),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: MarkdownBody(
          data: comment,
          fitContent: true,
          styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
          styleSheet:
              MarkdownStyleSheet(p: TextStyle(color: td.colorScheme.tertiary)),
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'type': "comment", 'content': comment};

  @override
  int get hashCode => 1 + comment.hashCode;

  @override
  bool operator ==(Object other) =>
      other is CommentRow && comment == other.comment;
}

// This row type monitors a device.

class DeviceRow extends BaseRow {
  final Device? name;
  final String? node;
  final String? label;

  const DeviceRow(this.name, {this.label, this.node, required super.key});

  @override
  Icon getIcon() => const Icon(Icons.developer_board);

  @override
  Widget buildRowEditor(BuildContext context, int index) =>
      DeviceEditor(index, name, label: label);

  @override
  Widget buildRowRunner(BuildContext context) =>
      DeviceWidget(label: label, device: name, node: node);

  @override
  Map<String, dynamic> toJson() {
    var tmp = {'type': "device", 'device': name?.name, 'node': node};

    if (label != null && label!.isNotEmpty) {
      tmp['label'] = label!;
    }
    return tmp;
  }

  @override
  int get hashCode => 2 + name.hashCode + label.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DeviceRow &&
      ((name == null && other.name == null) ||
          (name != null &&
              other.name != null &&
              name!.compareTo(other.name!) == 0)) &&
      label == other.label;
}

// This row type displays a plot.

class PlotRow extends BaseRow {
  const PlotRow({required super.key});

  @override
  Icon getIcon() => const Icon(Icons.auto_graph);

  @override
  Widget buildRowEditor(BuildContext context, int index) =>
      const Text("edit plot");

  @override
  Widget buildRowRunner(BuildContext context) => const Text("display plot");

  @override
  Map<String, dynamic> toJson() => {'type': "plot"};

  @override
  int get hashCode => 3;

  @override
  bool operator ==(Object other) => other is PlotRow;
}

InputDecoration getTextFieldDecoration(BuildContext context, String label) {
  final ThemeData td = Theme.of(context);

  return InputDecoration(
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.all(12.0),
      hintStyle: td.textTheme.bodyMedium!
          .copyWith(color: td.colorScheme.onSurface.withValues(alpha: .25)),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      isDense: true,
      hoverColor: td.colorScheme.secondary.withValues(alpha: .25),
      focusColor: td.colorScheme.primary.withValues(alpha: .25),
      fillColor: td.colorScheme.secondary.withValues(alpha: .125),
      border: InputBorder.none);
}

class _CommentEditor extends StatefulWidget {
  final int idx;
  final String text;

  const _CommentEditor(this.idx, this.text);

  @override
  _CommentEditorState createState() => _CommentEditorState();
}

class _CommentEditorState extends State<_CommentEditor> {
  late final TextEditingController controller;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: TextField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  autocorrect: true,
                  minLines: 1,
                  maxLines: null,
                  decoration: getTextFieldDecoration(
                      context, "Comment (uses Markdown)"),
                  keyboardType: TextInputType.multiline,
                  controller: controller,
                  onChanged: (value) => setState(() => changed = true)),
            ),
            TextButton(
                onPressed: changed
                    ? () {
                        setState(() => changed = false);
                        context.read<Model>().add(UpdateRow(widget.idx,
                            CommentRow(controller.text, key: UniqueKey())));
                      }
                    : null,
                child: const Text("Save"))
          ],
        ),
      );
}
