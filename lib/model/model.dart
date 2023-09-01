import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'model_events.dart';
import 'node_info.dart';

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

// Holds the state of the app's data model. This model consists of the set of
// DrMem nodes we know about and our local database of sheets that were
// configured. It also keeps track of the last sheet that was selected.

class AppState {
  UniqueKey id = UniqueKey();
  String _selectedSheet;
  final Map<String, PageConfig> _sheets;
  String? defaultNode;
  final List<NodeInfo> _nodes;

  // Create an instance of `AppState`.

  AppState(
      {Map<String, PageConfig>? sheets,
      String activeSheet = "Untitled",
      List<NodeInfo>? nodes,
      String? defNode})
      : _sheets = sheets ?? {},
        _selectedSheet = activeSheet,
        _nodes = nodes ?? [],
        defaultNode = defNode {
    // If the selected sheet doesn't exist, create a new, blank sheet
    // associated with the name. This covers two cases: 1) it guarantees
    // the selected sheet refers to an entry in the map, and 2) it ensures
    // the map is never empty.

    if (!_sheets.containsKey(_selectedSheet)) {
      _sheets[_selectedSheet] = PageConfig();
    }
  }

  // Create a new `AppState` using the passed parameters. If the selected sheet
  // doesn't exist, then pick an existing key or set the state as `AppState()`
  // does.

  AppState clone() => AppState(
      sheets: _sheets,
      activeSheet: _selectedSheet,
      nodes: _nodes,
      defNode: defaultNode);

  // Determines the next "Untitled##" name for an unnamed sheet. Hopefully users
  // name their sheets so that this function doesn't have to iterate too far to
  // find the next, available name.

  String nextUntitled() {
    int idx = 0;
    String name = "";

    do {
      idx = idx + 1;
      name = "Untitled$idx";
    } while (_sheets.containsKey(name));
    return name;
  }

  List<String> get sheetNames => _sheets.keys.toList();

  // Returns the page that's currently selected.

  PageConfig get selected => _sheets[_selectedSheet]!;

  // These allow manipulation of and access to the selected sheet. It makes
  // sure that `_sheets` and `_selectedSheet` are in a good state.

  String get selectedSheet => _selectedSheet;

  set selectedSheet(String name) {
    if (!_sheets.containsKey(name)) {
      _sheets[name] = PageConfig();
    }
    _selectedSheet = name;
  }
}

// Defines the page's data model and handles events to modify it.

class Model extends HydratedBloc<ModelEvent, AppState> {
  Model() : super(AppState()) {
    on<AppendRow>(_appendRow);
    on<DeleteRow>(_deleteRow);
    on<UpdateRow>(_updateRow);
    on<MoveRow>(_moveRow);
    on<SelectSheet>(_selectSheet);
    on<RenameSelectedSheet>(_renameSelectedSheet);
    on<AddSheet>(_addSheet);
    on<DeleteSheet>(_delSheet);
  }

  @override
  Map<String, dynamic>? toJson(AppState state) => {
        'selectedSheet': state.selectedSheet,
        'sheets': Map.fromEntries(
            state._sheets.entries.map((e) => MapEntry(e.key, e.value.toJson())))
      };

  // Given a map (generated by JSON text), return an instance of `AppState`.

  @override
  AppState? fromJson(Map<String, dynamic> json) {
    developer.log("input: $json", name: "Model.fromJson");

    if (json
        case {
          'selectedSheet': String ss,
          'sheets': Map<String, dynamic> sheets,
        }) {
      return AppState(
          sheets: Map.fromEntries(sheets.entries
              .map((e) => MapEntry(e.key, PageConfig.fromJson(e.value)))),
          activeSheet: ss);
    }
    return null;
  }

  // Adds a new row to the end of the currently selected sheet.

  void _appendRow(AppendRow event, Emitter<AppState> emit) {
    state.selected.appendRow(event.newRow);
    emit(state.clone());
  }

  // Removes the row specified by the index from the currently selected sheet.

  void _deleteRow(DeleteRow event, Emitter<AppState> emit) {
    state.selected.removeRow(event.index);
    emit(state.clone());
  }

  // This event is received when a child widget wants to change the type of a
  // row. This also needs to handle the case when the list of rows is empty.

  void _updateRow(UpdateRow event, Emitter<AppState> emit) {
    state.selected.updateRow(event.index, event.newRow);
    emit(state.clone());
  }

  void _moveRow(MoveRow event, Emitter<AppState> emit) {
    state.selected.moveRow(event.oldIndex, event.newIndex);
    emit(state.clone());
  }

  void _selectSheet(SelectSheet event, Emitter<AppState> emit) {
    state.selectedSheet = event.name;
    emit(state.clone());
  }

  void _renameSelectedSheet(RenameSelectedSheet event, Emitter<AppState> emit) {
    // If the new name doesn't exist, then we can proceed. If it does exist,
    // we ignore the request.
    //
    // TODO: We should report the error.

    if (!state._sheets.containsKey(event.newName)) {
      PageConfig conf = state._sheets.remove(state.selectedSheet)!;

      state._selectedSheet = event.newName;
      state._sheets[event.newName] = conf;
      emit(state.clone());
    } else {
      developer.log("can't rename sheet ... ${event.newName} already exists",
          name: "Model.renameSheet");
    }
  }

  // Adds a new, empty sheet to the application state. The title will be of
  // the form "Untitled#", where the number will be determined based on the
  // availability.

  void _addSheet(AddSheet event, Emitter<AppState> emit) {
    state.selectedSheet = state.nextUntitled();
    emit(state.clone());
  }

  void _delSheet(DeleteSheet event, Emitter<AppState> emit) {
    // Remove the current sheet.

    state._sheets.remove(state.selectedSheet);

    // If we still have sheets, then pick the first key for the new selected
    // sheet. If the last sheet was deleted, determine the next, "Untitled"
    // name and create a blank page associated with it.

    state.selectedSheet = state._sheets.isNotEmpty
        ? state._sheets.keys.first
        : state.nextUntitled();
    emit(state.clone());
  }
}
