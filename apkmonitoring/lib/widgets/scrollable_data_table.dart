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
  final double? horizontalMargin;
  final bool sortAscending;
  final int? sortColumnIndex;

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
    this.horizontalMargin,
    this.sortAscending = true,
    this.sortColumnIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
                horizontalMargin: horizontalMargin ?? 24.0,
                sortAscending: sortAscending,
                sortColumnIndex: sortColumnIndex,
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
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.grey.shade50;
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced version with more features
class EnhancedScrollableDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final List<Widget>? actions;
  final bool showSearch;
  final Function(String)? onSearch;
  final bool showRowsPerPage;
  final int? rowsPerPage;
  final Function(int?)? onRowsPerPageChanged;
  final bool showPagination;
  final int? currentPage;
  final int? totalRows;
  final Function(int)? onPageChanged;
  final double? columnSpacing;
  final double? dataRowHeight;
  final double? headingRowHeight;
  final bool showCheckboxColumn;
  final MaterialStateProperty<Color?>? headingRowColor;
  final TextStyle? headingTextStyle;

  const EnhancedScrollableDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.title,
    this.actions,
    this.showSearch = false,
    this.onSearch,
    this.showRowsPerPage = false,
    this.rowsPerPage,
    this.onRowsPerPageChanged,
    this.showPagination = false,
    this.currentPage,
    this.totalRows,
    this.onPageChanged,
    this.columnSpacing,
    this.dataRowHeight,
    this.headingRowHeight,
    this.showCheckboxColumn = true,
    this.headingRowColor,
    this.headingTextStyle,
  }) : super(key: key);

  @override
  State<EnhancedScrollableDataTable> createState() => _EnhancedScrollableDataTableState();
}

class _EnhancedScrollableDataTableState extends State<EnhancedScrollableDataTable> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        if (widget.title != null || widget.actions != null || widget.showSearch)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Actions Row
                if (widget.title != null || widget.actions != null)
                  Row(
                    children: [
                      if (widget.title != null)
                        Expanded(
                          child: Text(
                            widget.title!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      if (widget.actions != null)
                        Row(children: widget.actions!),
                    ],
                  ),
                
                // Search Bar
                if (widget.showSearch) ...[
                  if (widget.title != null || widget.actions != null)
                    SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari data...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: widget.onSearch,
                  ),
                ],
              ],
            ),
          ),

        // Data Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: widget.title != null || widget.actions != null || widget.showSearch
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )
                : BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: widget.title != null || widget.actions != null || widget.showSearch
                ? BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  )
                : BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: widget.columns,
                    rows: widget.rows,
                    columnSpacing: widget.columnSpacing ?? 56.0,
                    dataRowHeight: widget.dataRowHeight ?? 56.0,
                    headingRowHeight: widget.headingRowHeight ?? 56.0,
                    showCheckboxColumn: widget.showCheckboxColumn,
                    headingRowColor: widget.headingRowColor,
                    headingTextStyle: widget.headingTextStyle,
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
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.grey.shade50;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Footer Section
        if (widget.showRowsPerPage || widget.showPagination)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Rows per page
                if (widget.showRowsPerPage) ...[
                  Text('Baris per halaman:'),
                  SizedBox(width: 8),
                  DropdownButton<int>(
                    value: widget.rowsPerPage ?? 10,
                    items: [5, 10, 25, 50, 100].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: widget.onRowsPerPageChanged,
                  ),
                ],

                Spacer(),

                // Pagination
                if (widget.showPagination) ...[
                  Text('${widget.currentPage ?? 1} dari ${((widget.totalRows ?? 0) / (widget.rowsPerPage ?? 10)).ceil()}'),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: (widget.currentPage ?? 1) > 1
                        ? () => widget.onPageChanged?.call((widget.currentPage ?? 1) - 1)
                        : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: (widget.currentPage ?? 1) < ((widget.totalRows ?? 0) / (widget.rowsPerPage ?? 10)).ceil()
                        ? () => widget.onPageChanged?.call((widget.currentPage ?? 1) + 1)
                        : null,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}