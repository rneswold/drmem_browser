import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'model_events.dart';

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

  void moveRow(int oIdx, int nIdx) {
    if (oIdx >= 0 &&
        oIdx < content.length &&
        nIdx >= 0 &&
        nIdx < content.length) {
      final newIndex = oIdx < nIdx ? nIdx - 1 : nIdx;
      final BaseRow element = content.removeAt(oIdx);

      content.insert(newIndex, element);
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
  late String selectedSheet;
  final Map<String, PageConfig> _sheets;

  // Resets the sheets environment to a single, empty sheet which is selected.
  // Since the `_sheets` field is `final`, we have to call `.clear()` to empty
  // it.

  void _cleanSheets() {
    _sheets.clear();
    _sheets['Untitled'] = PageConfig();
    selectedSheet = "Untitled";
  }

  // Create a default instance of `AppState`. This consists of one, empty page
  // named "Untitled" and is the selected page.

  AppState() : _sheets = {} {
    _cleanSheets();
  }

  // Create a new `AppState` using the passed parameters. If the selected sheet
  // doesn't exist, then pick an existing key or set the state as `AppState()`
  // does.

  AppState.init(this.selectedSheet, this._sheets) {
    if (!_sheets.containsKey(selectedSheet)) {
      if (_sheets.isNotEmpty) {
        selectedSheet = _sheets.keys.first;
      } else {
        _cleanSheets();
      }
    }
  }

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

  List<String> get sheetNames =>
      _sheets.isNotEmpty ? _sheets.keys.toList() : [nextUntitled()];

  // Returns the page that's currently selected. If `selectedSheet` refers to a
  // non-existent entry, return an empty sheet.

  PageConfig get selected => _sheets[selectedSheet]!;
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
      return AppState.init(
          ss,
          Map.fromEntries(sheets.entries
              .map((e) => MapEntry(e.key, PageConfig.fromJson(e.value)))));
    }
    return null;
  }

  // Adds a new row to the end of the currently selected sheet.

  void _appendRow(AppendRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.appendRow(event.newRow);
    developer.log("new state: ${tmp.selected.content}",
        name: "Model.appendRow");
    emit(tmp);
  }

  // Removes the row specified by the index from the currently selected sheet.

  void _deleteRow(DeleteRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.removeRow(event.index);
    emit(tmp);
  }

  // This event is received when a child widget wants to change the type of a
  // row. This also needs to handle the case when the list of rows is empty.

  void _updateRow(UpdateRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.updateRow(event.index, event.newRow);
    emit(tmp);
  }

  void _moveRow(MoveRow event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp._sheets[tmp.selectedSheet]!.moveRow(event.oldIndex, event.newIndex);
    emit(tmp);
  }

  void _selectSheet(SelectSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    if (!tmp._sheets.containsKey(event.name)) {
      tmp._sheets[event.name] = PageConfig();
    }
    tmp.selectedSheet = event.name;
    emit(tmp);
  }

  void _renameSelectedSheet(RenameSelectedSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    // If the new name doesn't exist, then we can proceed. If it does exist,
    // we ignore the request.
    //
    // TODO: We should report the error.

    if (!tmp._sheets.containsKey(event.newName)) {
      PageConfig conf = tmp._sheets.remove(tmp.selectedSheet)!;

      tmp.selectedSheet = event.newName;
      tmp._sheets[event.newName] = conf;
      emit(tmp);
    } else {
      developer.log("can't rename sheet ... ${event.newName} already exists",
          name: "Model.renameSheet");
    }
  }

  // Adds a new, empty sheet to the application state. The title will be of
  // the form "Untitled#", where the number will be determined based on the
  // availability.

  void _addSheet(AddSheet event, Emitter<AppState> emit) {
    AppState tmp = AppState.init(state.selectedSheet, state._sheets);

    tmp.selectedSheet = tmp.nextUntitled();
    tmp._sheets[tmp.selectedSheet] = PageConfig();
    emit(tmp);
  }
}
