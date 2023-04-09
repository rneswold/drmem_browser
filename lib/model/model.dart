import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:drmem_browser/sheet/sheet.dart';
import 'model_events.dart';

// Holds the configuration for one sheet of parameters.

class PageConfig {
  final List<BaseRow> _content = [];

  List<BaseRow> get rows => _content;

  void appendRow(BaseRow row) => _content.add(row);

  void moveRow(int oIdx, int nIdx) {
    if (oIdx >= 0 &&
        oIdx < _content.length &&
        nIdx >= 0 &&
        nIdx < _content.length) {
      final newIndex = oIdx < nIdx ? nIdx - 1 : nIdx;
      final BaseRow element = _content.removeAt(oIdx);

      _content.insert(newIndex, element);
    }
  }

  void removeRow(int index) {
    if (index >= 0 && index < _content.length) {
      _content.removeAt(index);
    }
  }

  void updateRow(int index, BaseRow row) {
    if (index >= 0 && index < _content.length) {
      _content[index] = row;
    } else {
      _content.add(row);
    }
  }
}

// Holds the state of the app's data model. This model consists of the set of
// DrMem nodes we know about and our local database of sheets that were
// configured. It also keeps track of the last sheet that was selected.

class AppState {
  UniqueKey id = UniqueKey();
  String selectedSheet;
  final Map<String, PageConfig> _sheets;

  AppState(this.selectedSheet, this._sheets);

  // Returns the page that's currently selected. If `selectedSheet` refers to a
  // non-existent entry, return an empty sheet.

  PageConfig get selected => _sheets[selectedSheet] ?? PageConfig();
}

// Defines the page's data model and handles events to modify it.

class Model extends Bloc<ModelEvent, AppState> {
  Model() : super(AppState("Untitled", {})) {
    on<AppendRow>(_appendRow);
    on<DeleteRow>(_deleteRow);
    on<UpdateRow>(_updateRow);
    on<MoveRow>(_moveRow);
    on<SelectSheet>(_selectSheet);
  }

  // Adds a new row to the end of the currently selected sheet.

  void _appendRow(AppendRow event, Emitter<AppState> emit) {
    AppState newState = AppState(state.selectedSheet, state._sheets);
    PageConfig pc = newState._sheets[newState.selectedSheet] ?? PageConfig();

    pc.appendRow(event.newRow);
    newState._sheets[newState.selectedSheet] = pc;
    emit(newState);
  }

  // Removes the row specified by the index from the currently selected sheet.

  void _deleteRow(DeleteRow event, Emitter<AppState> emit) {
    AppState newState = AppState(state.selectedSheet, state._sheets);
    PageConfig? pc = newState._sheets[newState.selectedSheet];

    if (pc != null) {
      pc.removeRow(event.index);
      emit(newState);
    } else {
      developer.log("tried to delete a row in a non-existent sheet");
    }
  }

  // This event is received when a child widget wants to change the type of a
  // row. This also needs to handle the case when the list of rows is empty.

  void _updateRow(UpdateRow event, Emitter<AppState> emit) {
    AppState newState = AppState(state.selectedSheet, state._sheets);
    PageConfig? pc = newState._sheets[newState.selectedSheet];

    if (pc != null) {
      pc.updateRow(event.index, event.newRow);
      emit(newState);
    } else {
      developer.log("tried to update a row in a non-existent sheet");
    }
  }

  void _moveRow(MoveRow event, Emitter<AppState> emit) {
    AppState newState = AppState(state.selectedSheet, state._sheets);
    PageConfig? pc = newState._sheets[newState.selectedSheet];

    if (pc != null) {
      pc.moveRow(event.oldIndex, event.newIndex);
      emit(newState);
    } else {
      developer.log("tried to move a row in a non-existent sheet");
    }
  }

  void _selectSheet(SelectSheet event, Emitter<AppState> emit) {
    AppState newState = AppState(event.name, state._sheets);

    emit(newState);
  }
}
