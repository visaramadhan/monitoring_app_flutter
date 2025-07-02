import 'package:flutter/material.dart';

class ScrollableDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double? columnSpacing;
  final double? dataRowHeight;
  final double? headingRowHeight;
  final bool showCheckboxColumn;
  final MaterialStateProperty<Color?>? headingRowColor;
  final TextStyle? headingTextStyle;

  const ScrollableDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.columnSpacing,
    this.dataRowHeight,
    this.headingRowHeight,
    this.showCheckboxColumn = true,
    this.headingRowColor,
    this.headingTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: columns,
              rows: rows,
              columnSpacing: columnSpacing ?? 56.0,
              dataRowHeight: dataRowHeight ?? 56.0,
              headingRowHeight: headingRowHeight ?? 56.0,
              showCheckboxColumn: showCheckboxColumn,
              headingRowColor: headingRowColor,
              headingTextStyle: headingTextStyle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
                verticalInside: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}