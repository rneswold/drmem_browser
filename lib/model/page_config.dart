import 'package:drmem_browser/sheet/row.dart';

// Holds the configuration for one sheet of parameters.

class PageConfig {
  List<BaseRow> content;

  PageConfig({List<BaseRow>? content}) : content = content ?? [];

  // Serializes a PageConfig to a JSON object. The JSON object consists of one
  // field containing an array of serialized rows.

  Map<String, dynamic>? toJson() =>
      {'rows': content.map((e) => e.toJson()).toList()};

  // Deserializes a JSON object into a PageConfig.

  static PageConfig fromJson(Map<String, dynamic> json) {
    if (json case {'rows': List rows}) {
      final items = rows
          .map((e) => e is Map<String, dynamic> ? BaseRow.fromJson(e) : null)
          .nonNulls
          .toList();

      return PageConfig(content: items);
    }
    return PageConfig();
  }

  List<BaseRow> get rows => content;

  void appendRow(BaseRow row) => content.add(row);

  // Moves a row from one offset to another.
  //
  // NOTE: these index parameters are generated by the Flutter `OrderableList`
  // widget so their values are a little unusual. The logic in this method
  // uses the widget's idea of offsets.

  void moveRow(int oIdx, int nIdx) {
    if (oIdx >= 0 &&
        oIdx < content.length &&
        nIdx >= 0 &&
        nIdx <= content.length) {
      final newIndex = oIdx < nIdx ? nIdx - 1 : nIdx;
      final BaseRow element = content.removeAt(oIdx);

      if (newIndex < content.length) {
        content.insert(newIndex, element);
      } else {
        content.add(element);
      }
    }
  }

  void removeRow(int index) {
    if (index >= 0 && index < content.length) {
      content.removeAt(index);
    }
  }

  void updateRow(int index, BaseRow row) {
    if (index >= 0 && index < content.length) {
      content[index] = row;
    } else {
      content.add(row);
    }
  }
}