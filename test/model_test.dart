import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drmem_provider/drmem_provider.dart';

import 'package:drmem_browser/model/model_events.dart';
import 'package:drmem_browser/model/model.dart';
import 'package:drmem_browser/model/page_config.dart';
import 'package:drmem_browser/sheet/row.dart';

class MockStorage extends Mock implements Storage {}

void _testSerialization() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(
      () => storage.write(any(), any<dynamic>()),
    ).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  test("... serialize PageConfig", () {
    var pc = PageConfig(content: [EmptyRow(key: UniqueKey())]);

    expect(pc.toJson(), {
      'rows': [
        {'type': "empty"}
      ]
    });

    pc = PageConfig(content: [
      EmptyRow(key: UniqueKey()),
      CommentRow("Hello", key: UniqueKey())
    ]);

    expect(pc.toJson(), {
      'rows': [
        {'type': "empty"},
        {'type': "comment", 'content': "Hello"}
      ]
    });
  });

  test("... serialize Model", () {});
}

void _testDeserialization() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(
      () => storage.write(any(), any<dynamic>()),
    ).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  test("... deserialize PageConfig", () {
    // Check for malformed input.

    expect(PageConfig.fromJson({}).content, []);
    expect(PageConfig.fromJson({'rows': true}).content, []);
    expect(PageConfig.fromJson({'rows': "hi"}).content, []);
    expect(
        PageConfig.fromJson({
          'rows': ["hi"]
        }).content,
        []);

    // Check for valid inputs.

    expect(PageConfig.fromJson({'rows': []}).content, []);
    expect(
        PageConfig.fromJson({
          'rows': [
            {'type': "empty"}
          ]
        }).content,
        [EmptyRow(key: UniqueKey())]);
    expect(
        PageConfig.fromJson({
          'rows': [
            {'type': "empty"},
            {'type': "device", 'device': "junk", 'node': "host"}
          ]
        }).content,
        [
          EmptyRow(key: UniqueKey()),
          DeviceRow(Device(name: "junk"), key: UniqueKey())
        ]);
    expect(
        PageConfig.fromJson({
          'rows': [
            {'type': "empty"},
            "hi",
            {'type': "device", 'device': "junk", 'node': "host"}
          ]
        }).content,
        [
          EmptyRow(key: UniqueKey()),
          DeviceRow(Device(name: "junk"), key: UniqueKey())
        ]);
    expect(
        PageConfig.fromJson({
          'rows': [
            {'type': "empty"},
            "hi",
            {
              'type': "device",
              'label': "label",
              'device': "junk",
              'node': "host"
            }
          ]
        }).content,
        [
          EmptyRow(key: UniqueKey()),
          DeviceRow(Device(name: "junk"), label: "label", key: UniqueKey())
        ]);
  });

  test("... deserialize Model", () {
    Model model = Model();
    var json = {
      'selectedSheet': "First",
      'sheets': {
        'First': {
          'rows': [
            {'type': "empty"}
          ]
        },
        'Second': {
          'rows': [
            {'type': "empty"},
            {'type': "comment", 'content': "hello"}
          ]
        }
      },
      'defaultNode': null,
      'nodes': []
    };

    AppState s = model.fromJson(json)!;

    expect(
        model.toJson(s),
        allOf([
          containsPair('selectedSheet', "First"),
          containsPair(
              'sheets',
              allOf([
                containsPair(
                    'First',
                    containsPair(
                        'rows',
                        allOf([
                          isList,
                          containsAllInOrder([containsPair('type', "empty")])
                        ]))),
                containsPair(
                    'Second',
                    containsPair(
                        'rows',
                        allOf([
                          isList,
                          containsAll([
                            containsPair('type', "empty"),
                            allOf([
                              containsPair('type', "comment"),
                              containsPair('content', "hello")
                            ])
                          ])
                        ]))),
              ])),
          containsPair('defaultNode', null),
          containsPair('nodes', []),
          contains('clientId')
        ]));
  });
}

// Tests the persistence of the app.

void _testStorage() async {
  group("test default", () {
    late Storage storage;

    setUp(() {
      storage = MockStorage();
      when(
        () => storage.write(any(), any<dynamic>()),
      ).thenAnswer((_) async {});
      HydratedBloc.storage = storage;
    });
    test("check defaults", () async {
      var model = Model();

      // Check empty sheets database.

      expect(model.state.selectedSheet, "Untitled");
      expect(model.state.selected.content.isEmpty, true);
      expect(model.state.sheetNames, ["Untitled"]);

      expect(
          model.toJson(model.state),
          allOf([
            containsPair('selectedSheet', "Untitled"),
            containsPair('sheets',
                containsPair('Untitled', containsPair('rows', isEmpty))),
            containsPair('defaultNode', null),
            containsPair('nodes', []),
            contains('clientId')
          ]));

      // Add a row to our sheet. Then check to see that it was added.

      final key = UniqueKey();
      model.add(AppendRow(EmptyRow(key: key)));

      await pumpEventQueue();

      expect(model.state.selectedSheet, "Untitled");
      expect(model.state.selected.content.isEmpty, false);
      expect(model.state.selected.content, [EmptyRow(key: key)]);
      expect(model.state.sheetNames, ["Untitled"]);

      expect(
          model.toJson(model.state),
          allOf([
            containsPair('selectedSheet', "Untitled"),
            containsPair(
                'sheets',
                containsPair(
                    'Untitled',
                    containsPair(
                        'rows', containsAll([containsPair('type', "empty")])))),
            containsPair('defaultNode', null),
            containsPair('nodes', []),
            contains('clientId')
          ]));
    });
  });
}

void main() {
  _testSerialization();
  _testDeserialization();
  _testStorage();
}
