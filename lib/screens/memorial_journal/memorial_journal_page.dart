import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/journal_models.dart';
import '../../utils/constants.dart';
import 'add_memorial_journal_page.dart';
import 'view_memorial_journal_page.dart';

class MemorialJournalPage extends StatefulWidget {
  @override
  _MemorialJournalPageState createState() => _MemorialJournalPageState();
}

class _MemorialJournalPageState extends State<MemorialJournalPage> {
  List<MemorialJournalEntry> _allApiEntriesMaster = [];
  List<MemorialJournalEntry> _processedClientSideEntries = [];
  List<MemorialJournalEntry> _filteredEntries = [];
  bool _isLoadingApi = false;
  String? _error;
  DateTime? _startDate;
  DateTime? _endDate;
  final int _clientPageSize = 15;
  int _clientCurrentPage = 1;
  bool _clientHasMoreDataToDisplay = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeClientSearchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchApiDataAndProcessClientSide();
    _searchController.addListener(_onSearchChangedWithDebounce);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChangedWithDebounce);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChangedWithDebounce() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final newSearchQuery = _searchController.text.trim();
      if (_activeClientSearchQuery != newSearchQuery) {
        _activeClientSearchQuery = newSearchQuery;
        _applyClientFiltersAndSortAndPaginate();
      }
    });
  }

  Future<void> _fetchApiDataAndProcessClientSide() async {
    if (!mounted || _isLoadingApi) return;
    setState(() {
      _isLoadingApi = true;
      _error = null;
      _allApiEntriesMaster.clear();
      _processedClientSideEntries.clear();
      _filteredEntries.clear();
      _clientCurrentPage = 1;
      _clientHasMoreDataToDisplay = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse('$baseUrl/api/API/getdataJM');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _allApiEntriesMaster =
            data
                .map(
                  (item) => MemorialJournalEntry.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
        _applyClientFiltersAndSortAndPaginate();
      } else {
        throw Exception(
          'Failed to load entries. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  void _applyClientFiltersAndSortAndPaginate() {
    List<MemorialJournalEntry> currentlyProcessedList;

    if (_activeClientSearchQuery.isEmpty) {
      currentlyProcessedList = List.from(_allApiEntriesMaster);
    } else {
      final query = _activeClientSearchQuery.toLowerCase();
      currentlyProcessedList =
          _allApiEntriesMaster.where((entry) {
            return entry.transNo.toLowerCase().contains(query) ||
                entry.description.toLowerCase().contains(query);
          }).toList();
    }

    if (_startDate != null || _endDate != null) {
      currentlyProcessedList =
          currentlyProcessedList.where((entry) {
            final isAfterStartDate =
                _startDate == null || !entry.transDate.isBefore(_startDate!);
            final isBeforeEndDate =
                _endDate == null || !entry.transDate.isAfter(_endDate!);
            return isAfterStartDate && isBeforeEndDate;
          }).toList();
    }

    currentlyProcessedList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.transDate.compareTo(b.transDate);
          break;
        case 1:
          compareResult = a.transNo.compareTo(b.transNo);
          break;
        case 2:
          compareResult = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          break;
        case 3:
          compareResult = a.debit.compareTo(b.debit);
          break;
        case 4:
          compareResult = a.credit.compareTo(b.credit);
          break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });

    _processedClientSideEntries = currentlyProcessedList;

    setState(() {
      _clientCurrentPage = 1;
      _updatePaginatedUiList();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    if (!mounted) return;
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applyClientFiltersAndSortAndPaginate();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      });
      _applyClientFiltersAndSortAndPaginate();
    }
  }

  void _clearDateFilters() {
    if (!mounted) return;
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyClientFiltersAndSortAndPaginate();
  }

  void _updatePaginatedUiList() {
    int startIndex = (_clientCurrentPage - 1) * _clientPageSize;
    int endIndex = startIndex + _clientPageSize;
    List<MemorialJournalEntry> nextPageItems = [];

    if (startIndex < _processedClientSideEntries.length) {
      if (endIndex > _processedClientSideEntries.length) {
        endIndex = _processedClientSideEntries.length;
      }
      nextPageItems = _processedClientSideEntries.sublist(startIndex, endIndex);
    }

    setState(() {
      if (_clientCurrentPage == 1) {
        _filteredEntries = nextPageItems;
      } else {
        _filteredEntries.addAll(nextPageItems);
      }
      _clientHasMoreDataToDisplay =
          endIndex < _processedClientSideEntries.length;
    });
  }

  void _loadMoreClientSide() {
    if (!mounted || !_clientHasMoreDataToDisplay || _isLoadingApi) return;
    _clientCurrentPage++;
    _updatePaginatedUiList();
  }

  void _viewEntry(MemorialJournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMemorialJournalEntryPage(entryId: entry.id),
      ),
    );
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMemorialJournalEntryPage()),
    );
    if (result == true && mounted) {
      _fetchApiDataAndProcessClientSide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memorial Journal'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _isLoadingApi ? null : _fetchApiDataAndProcessClientSide,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Trans. No or Description',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _activeClientSearchQuery = '';
                            _applyClientFiltersAndSortAndPaginate();
                          },
                        )
                        : null,
              ),
            ),
          ),
          _buildDateFilterControls(),
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add Memorial Journal',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateFilterControls() {
    final formatter = DateFormat('dd MMM yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 18),
            label: Text(
              _startDate == null ? 'From Date' : formatter.format(_startDate!),
            ),
            onPressed: () => _selectDate(context, true),
          ),
          TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 18),
            label: Text(
              _endDate == null ? 'To Date' : formatter.format(_endDate!),
            ),
            onPressed: () => _selectDate(context, false),
          ),
          if (_startDate != null || _endDate != null)
            ActionChip(
              avatar: Icon(Icons.clear, size: 16),
              label: Text('Clear'),
              onPressed: _clearDateFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildDataArea() {
    if (_isLoadingApi && _allApiEntriesMaster.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('An error occurred: $_error'));
    }
    if (_filteredEntries.isEmpty) {
      return Center(
        child: Text(
          _activeClientSearchQuery.isNotEmpty ||
                  _startDate != null ||
                  _endDate != null
              ? 'No entries found for current filters.'
              : 'No entries to display.',
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [_buildDataTable(), _buildPaginationControlsClientSide()],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text('Date'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Trans No'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Description'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Debit'),
            numeric: true,
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Credit'),
            numeric: true,
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
        ],
        rows:
            _filteredEntries
                .map(
                  (entry) => DataRow(
                    cells: [
                      DataCell(Text(entry.formattedDate)),
                      DataCell(Text(entry.transNo)),
                      DataCell(Text(entry.description)),
                      DataCell(Text(entry.formattedDebit)),
                      DataCell(Text(entry.formattedCredit)),
                    ],
                    onSelectChanged: (selected) {
                      if (selected ?? false) _viewEntry(entry);
                    },
                  ),
                )
                .toList(),
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        showCheckboxColumn: false,
      ),
    );
  }

  Widget _buildPaginationControlsClientSide() {
    if (_clientHasMoreDataToDisplay) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _loadMoreClientSide,
          child: Text(
            'Load More (${_processedClientSideEntries.length - _filteredEntries.length} remaining)',
          ),
        ),
      );
    }
    if (_processedClientSideEntries.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("End of list", style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox.shrink();
  }
}
