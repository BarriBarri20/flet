import 'dart:convert';

import 'package:flet/src/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../flet_app_services.dart';
import '../models/app_state.dart';
import '../models/control.dart';
import '../models/controls_view_model.dart';
import '../utils/borders.dart';
import '../utils/buttons.dart';
import '../utils/colors.dart';
import '../utils/gradient.dart';
import 'create_control.dart';

class DataTableControl extends StatefulWidget {
  final Control? parent;
  final Control control;
  final List<Control> children;
  final bool parentDisabled;

  const DataTableControl(
      {Key? key,
      this.parent,
      required this.control,
      required this.children,
      required this.parentDisabled})
      : super(key: key);

  @override
  State<DataTableControl> createState() => _DataTableControlState();
}

class _DataTableControlState extends State<DataTableControl> {
  @override
  Widget build(BuildContext context) {
    debugPrint("DataTableControl build: ${widget.control.id}");

    bool disabled = widget.control.isDisabled || widget.parentDisabled;

    var ws = FletAppServices.of(context).ws;

    var datatable = StoreConnector<AppState, ControlsViewModel>(
        distinct: true,
        converter: (store) => ControlsViewModel.fromStore(
            store, widget.children.where((c) => c.isVisible).map((c) => c.id)),
        builder: (content, viewModel) {
          var bgColor = widget.control.attrString("bgColor");
          var border = parseBorder(Theme.of(context), widget.control, "border");
          var borderRadius = parseBorderRadius(widget.control, "borderRadius");
          var gradient =
              parseGradient(Theme.of(context), widget.control, "gradient");
          var horizontalLines = parseBorderSide(
              Theme.of(context), widget.control, "horizontalLines");
          var verticalLines = parseBorderSide(
              Theme.of(context), widget.control, "verticalLines");
          var defaultDecoration = Theme.of(context).dataTableTheme.decoration ??
              const BoxDecoration();

          BoxDecoration? decoration;
          if (bgColor != null ||
              border != null ||
              borderRadius != null ||
              gradient != null) {
            decoration = (defaultDecoration as BoxDecoration).copyWith(
                color: HexColor.fromString(Theme.of(context), bgColor ?? ""),
                border: border,
                borderRadius: borderRadius,
                gradient: gradient);
          }

          TableBorder? tableBorder;
          if (horizontalLines != BorderSide.none ||
              verticalLines != BorderSide.none) {
            tableBorder = TableBorder(
                horizontalInside: horizontalLines,
                verticalInside: verticalLines);
          }

          return DataTable(
              decoration: decoration,
              border: tableBorder,
              checkboxHorizontalMargin:
                  widget.control.attrDouble("checkboxHorizontalMargin"),
              columnSpacing: widget.control.attrDouble("columnSpacing"),
              dataRowColor: parseMaterialStateColor(
                  Theme.of(context), widget.control, "dataRowColor"),
              dataRowHeight: widget.control.attrDouble("dataRowHeight"),
              dataTextStyle: parseTextStyle(
                  Theme.of(context), widget.control, "dataTextStyle"),
              headingRowColor: parseMaterialStateColor(
                  Theme.of(context), widget.control, "headingRowColor"),
              headingRowHeight: widget.control.attrDouble("headingRowHeight"),
              headingTextStyle: parseTextStyle(
                  Theme.of(context), widget.control, "headingTextStyle"),
              dividerThickness: widget.control.attrDouble("dividerThickness"),
              horizontalMargin: widget.control.attrDouble("horizontalMargin"),
              showBottomBorder:
                  widget.control.attrBool("showBottomBorder", false)!,
              showCheckboxColumn:
                  widget.control.attrBool("showCheckboxColumn", false)!,
              sortAscending: widget.control.attrBool("sortAscending", false)!,
              sortColumnIndex: widget.control.attrInt("sortColumnIndex"),
              onSelectAll: widget.control.attrBool("onSelectAll", false)!
                  ? (selected) {
                      ws.pageEventFromWeb(
                          eventTarget: widget.control.id,
                          eventName: "select_all",
                          eventData:
                              selected != null ? selected.toString() : "");
                    }
                  : null,
              columns: viewModel.controlViews
                  .where((c) => c.control.type == "c")
                  .map((column) {
                var labelCtrls = column.children.where((c) => c.name == "l");
                return DataColumn(
                    numeric: column.control.attrBool("numeric", false)!,
                    tooltip: column.control.attrString("tooltip"),
                    onSort: column.control.attrBool("onSort", false)!
                        ? (columnIndex, ascending) {
                            ws.pageEventFromWeb(
                                eventTarget: column.control.id,
                                eventName: "sort",
                                eventData: json.encode(
                                    {"i": columnIndex, "a": ascending}));
                          }
                        : null,
                    label: createControl(
                        column.control, labelCtrls.first.id, disabled));
              }).toList(),
              rows: viewModel.controlViews
                  .where((c) => c.control.type == "r")
                  .map((row) {
                return DataRow(
                    key: ValueKey(row.control.id),
                    selected: row.control.attrBool("selected", false)!,
                    color: parseMaterialStateColor(
                        Theme.of(context), row.control, "color"),
                    onSelectChanged:
                        row.control.attrBool("onSelectChanged", false)!
                            ? (selected) {
                                ws.pageEventFromWeb(
                                    eventTarget: row.control.id,
                                    eventName: "select_changed",
                                    eventData: selected != null
                                        ? selected.toString()
                                        : "");
                              }
                            : null,
                    onLongPress: row.control.attrBool("onLongPress", false)!
                        ? () {
                            ws.pageEventFromWeb(
                                eventTarget: row.control.id,
                                eventName: "long_press",
                                eventData: "");
                          }
                        : null,
                    cells: row.children
                        .map((cell) => DataCell(
                              createControl(
                                  row.control, cell.childIds.first, disabled),
                              placeholder: cell.attrBool("placeholder", false)!,
                              showEditIcon:
                                  cell.attrBool("showEditIcon", false)!,
                              onDoubleTap: cell.attrBool("onDoubleTap", false)!
                                  ? () {
                                      ws.pageEventFromWeb(
                                          eventTarget: cell.id,
                                          eventName: "double_tap",
                                          eventData: "");
                                    }
                                  : null,
                              onLongPress: cell.attrBool("onLongPress", false)!
                                  ? () {
                                      ws.pageEventFromWeb(
                                          eventTarget: cell.id,
                                          eventName: "long_press",
                                          eventData: "");
                                    }
                                  : null,
                              onTap: cell.attrBool("onTap", false)!
                                  ? () {
                                      ws.pageEventFromWeb(
                                          eventTarget: cell.id,
                                          eventName: "tap",
                                          eventData: "");
                                    }
                                  : null,
                              onTapCancel: cell.attrBool("onTapCancel", false)!
                                  ? () {
                                      ws.pageEventFromWeb(
                                          eventTarget: cell.id,
                                          eventName: "tap_cancel",
                                          eventData: "");
                                    }
                                  : null,
                              onTapDown: cell.attrBool("onTapDown", false)!
                                  ? (details) {
                                      ws.pageEventFromWeb(
                                          eventTarget: cell.id,
                                          eventName: "tap_down",
                                          eventData: json.encode({
                                            "kind": details.kind?.name,
                                            "lx": details.localPosition.dx,
                                            "ly": details.localPosition.dy,
                                            "gx": details.globalPosition.dx,
                                            "gy": details.globalPosition.dy,
                                          }));
                                    }
                                  : null,
                            ))
                        .toList());
              }).toList());
        });

    return constrainedControl(
        context, datatable, widget.parent, widget.control);
  }
}
