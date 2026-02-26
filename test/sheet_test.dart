import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import "package:drmem_provider/drmem_provider.dart";

import 'package:drmem_browser/sheet/row.dart';

void main() {
  group("Testing bad input", () {
    test("... bad row type", () {
      expect(BaseRow.fromJson({'type': 'junk'}), null);
    });
    test("... bad comment field type", () {
      expect(BaseRow.fromJson({'type': 'comment'}), null);
      expect(BaseRow.fromJson({'type': 'comment', 'junk': true}), null);
    });
    test("... bad device field type", () {
      expect(BaseRow.fromJson({'type': 'device'}), null);
      expect(BaseRow.fromJson({'type': 'device', 'label': true}), null);
      expect(BaseRow.fromJson({'type': 'device', 'junk': true}), null);
    });
  });

  group("testing equality", () {
    test("... EmptyRow", () {
      final rowA = EmptyRow(key: UniqueKey());
      final rowB = EmptyRow(key: UniqueKey());
      final rowC = PlotRow(key: UniqueKey());

      expect(rowA == rowA, true);
      expect(rowA == rowB, true);
      expect(rowA == rowC, false);
    });

    test("... CommentRow", () {
      final rowA = CommentRow("Hello", key: UniqueKey());
      final rowB = CommentRow("Hello", key: UniqueKey());
      final rowC = CommentRow("Good-bye", key: UniqueKey());
      final rowD = EmptyRow(key: UniqueKey());

      expect(rowA == rowA, true);
      expect(rowA == rowB, true);
      expect(rowA == rowC, false);
      expect(rowA == rowD, false);
    });

    test("... DeviceRow", () {
      final rowA = DeviceRow(Device(name: "device"), key: UniqueKey());
      final rowA2 = DeviceRow(Device(name: "device"), key: UniqueKey());
      final rowB =
          DeviceRow(Device(name: "device"), label: "label", key: UniqueKey());
      final rowB2 =
          DeviceRow(Device(name: "device"), label: "label", key: UniqueKey());
      final rowC =
          DeviceRow(Device(name: "device"), label: "label2", key: UniqueKey());
      final rowC2 =
          DeviceRow(Device(name: "device"), label: "label2", key: UniqueKey());
      final rowD = DeviceRow(Device(name: "device2"), key: UniqueKey());
      final rowD2 = DeviceRow(Device(name: "device2"), key: UniqueKey());
      final rowE =
          DeviceRow(Device(name: "device2"), label: "label", key: UniqueKey());
      final rowE2 =
          DeviceRow(Device(name: "device2"), label: "label", key: UniqueKey());
      final rowF =
          DeviceRow(Device(name: "device2"), label: "label2", key: UniqueKey());
      final rowF2 =
          DeviceRow(Device(name: "device2"), label: "label2", key: UniqueKey());
      final rowG = EmptyRow(key: UniqueKey());

      expect(rowA == rowA, true);
      expect(rowA == rowA2, true);
      expect(rowA == rowB, false);
      expect(rowA == rowC, false);
      expect(rowA == rowD, false);
      expect(rowA == rowE, false);
      expect(rowA == rowF, false);
      expect(rowA == rowG, false);

      expect(rowB == rowB, true);
      expect(rowB == rowB2, true);
      expect(rowB == rowC, false);
      expect(rowB == rowD, false);
      expect(rowB == rowE, false);
      expect(rowB == rowF, false);
      expect(rowB == rowG, false);

      expect(rowC == rowC, true);
      expect(rowC == rowC2, true);
      expect(rowC == rowD, false);
      expect(rowC == rowE, false);
      expect(rowC == rowF, false);
      expect(rowC == rowG, false);

      expect(rowD == rowD, true);
      expect(rowD == rowD2, true);
      expect(rowD == rowE, false);
      expect(rowD == rowF, false);
      expect(rowD == rowG, false);

      expect(rowE == rowE, true);
      expect(rowE == rowE2, true);
      expect(rowE == rowF, false);
      expect(rowE == rowG, false);

      expect(rowF == rowF, true);
      expect(rowF == rowF2, true);
      expect(rowF == rowG, false);
    });

    test("... PlotRow", () {
      final rowA = PlotRow(key: UniqueKey());
      final rowB = PlotRow(key: UniqueKey());
      final rowC = EmptyRow(key: UniqueKey());

      expect(rowA == rowA, true);
      expect(rowA == rowB, true);
      expect(rowA == rowC, false);
    });
  });

  group("Testing row serialization", () {
    test("... EmptyRow", () {
      final EmptyRow tmp = EmptyRow(key: UniqueKey());
      final EmptyRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as EmptyRow;

      expect(out.key, tmp.key);
    });

    test("... DeviceRow", () {
      // Test serialization of a device row which doesn't have a label.

      {
        final DeviceRow tmp =
            DeviceRow(Device(name: "device:state"), key: UniqueKey());
        final json = tmp.toJson();

        // Make sure that, when the label is null, we don't emit anything for
        // that field.

        expect(json.containsKey("label"), false);

        final DeviceRow out = BaseRow.fromJson(json, key: tmp.key) as DeviceRow;

        expect(out.name!.compareTo(tmp.name!), equals(0));
        expect(out.label, null);
        expect(out.key, tmp.key);
      }

      // Test serialization of a device row which has a label.

      {
        final DeviceRow tmp = DeviceRow(Device(name: "device:state"),
            label: "tag", key: UniqueKey());
        final DeviceRow out =
            BaseRow.fromJson(tmp.toJson(), key: tmp.key) as DeviceRow;

        expect(out.name!.compareTo(tmp.name!), equals(0));
        expect(out.label, tmp.label);
        expect(out.key, tmp.key);
      }
    });

    test("... CommentRow", () {
      final CommentRow tmp = CommentRow("This is a comment.", key: UniqueKey());
      final CommentRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as CommentRow;

      expect(out.comment, tmp.comment);
      expect(out.key, tmp.key);
    });

    test("... PlotRow", () {
      final PlotRow tmp = PlotRow(key: UniqueKey());
      final PlotRow out =
          BaseRow.fromJson(tmp.toJson(), key: tmp.key) as PlotRow;

      expect(out.key, tmp.key);
    });
  });
}
