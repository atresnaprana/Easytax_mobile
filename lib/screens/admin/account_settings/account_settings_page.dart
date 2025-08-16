import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/account_model.dart';
import '../../../utils/constants.dart';
import 'add_account_setting_page.dart';
import 'edit_account_setting_page.dart';
import 'view_account_setting_page.dart';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  List<AccountSettingEntry> _allApiEntriesMaster = [];
  List<AccountSettingEntry> _processedClientSideEntries = [];
  List<AccountSettingEntry> _displayedEntries = [];

  bool _isLoadingApi = false;
  String? _error;

  final int _clientPageSize = 15;
  int _clientCurrentPage = 1;
  bool _clientHasMoreDataToDisplay = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _activeClientSearchQuery = '';

  int _sortColumnIndex = 1; // Default sort by Account No
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchApiDataFromServer();
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

  Future<void> _fetchApiDataFromServer() async {
    if (!mounted || _isLoadingApi) return;
    setState(() {
      _isLoadingApi = true;
      _error = null;
      _allApiEntriesMaster.clear();
      _processedClientSideEntries.clear();
      _displayedEntries.clear();
      _clientCurrentPage = 1;
      _clientHasMoreDataToDisplay = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse('$baseUrl/api/API/getdataAccount');
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
                  (item) => AccountSettingEntry.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
        _applyClientFiltersAndSortAndPaginate();
      } else {
        throw Exception(
          'Failed to load accounts. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  void _applyClientFiltersAndSortAndPaginate() {
    if (!mounted) return;

    List<AccountSettingEntry> currentlyProcessedList;

    if (_activeClientSearchQuery.isEmpty) {
      currentlyProcessedList = List.from(_allApiEntriesMaster);
    } else {
      final query = _activeClientSearchQuery.toLowerCase();
      currentlyProcessedList =
          _allApiEntriesMaster.where((account) {
            return account.accountNo.toString().contains(query) ||
                account.accountName.toLowerCase().contains(query);
          }).toList();
    }

    currentlyProcessedList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.id.compareTo(b.id);
          break;
        case 1:
          compareResult = a.accountNo.compareTo(b.accountNo);
          break;
        case 2:
          compareResult = a.accountName.toLowerCase().compareTo(
            b.accountName.toLowerCase(),
          );
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

  void _updatePaginatedUiList() {
    if (!mounted) return;
    int startIndex = (_clientCurrentPage - 1) * _clientPageSize;
    int endIndex = startIndex + _clientPageSize;
    List<AccountSettingEntry> nextPageItems = [];
    if (startIndex < _processedClientSideEntries.length) {
      if (endIndex > _processedClientSideEntries.length) {
        endIndex = _processedClientSideEntries.length;
      }
      nextPageItems = _processedClientSideEntries.sublist(startIndex, endIndex);
    }
    setState(() {
      if (_clientCurrentPage == 1) {
        _displayedEntries = nextPageItems;
      } else {
        _displayedEntries.addAll(nextPageItems);
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

  void _viewAccount(AccountSettingEntry account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAccountSettingPage(account: account),
      ),
    );
  }

  void _editAccount(AccountSettingEntry account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountSettingPage(account: account),
      ),
    );
    if (result == true && mounted) {
      _fetchApiDataFromServer();
    }
  }

  void _deleteAccount(AccountSettingEntry account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete account "${account.accountName}" (${account.accountNo})?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoadingApi = true);
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('auth_token');
        if (token == null || token.isEmpty)
          throw Exception('Authentication required.');

        final url = Uri.parse(
          '$baseUrl/api/API/DeleteAccount',
        ).replace(queryParameters: {'id': account.id.toString()});
        final headers = {'Authorization': 'Bearer $token'};

        final response = await http
            .post(url, headers: headers)
            .timeout(Duration(seconds: 30));

        if (!mounted) return;
        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchApiDataFromServer();
        } else {
          String serverMessage = response.reasonPhrase ?? 'Delete Failed';
          try {
            var errorData = json.decode(response.body);
            serverMessage =
                errorData['message'] ??
                errorData['title'] ??
                errorData['error'] ??
                serverMessage;
          } catch (_) {}
          throw Exception(
            'Failed to delete account. Server: ${response.statusCode} - $serverMessage',
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
      } finally {
        if (mounted) setState(() => _isLoadingApi = false);
      }
    }
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAccountSettingPage()),
    );
    if (result == true && mounted) {
      _fetchApiDataFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Settings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Account No. or Name',
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
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add New Account',
        child: Icon(Icons.add),
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
    if (_displayedEntries.isEmpty && !_isLoadingApi) {
      return Center(
        child: Text(
          _activeClientSearchQuery.isNotEmpty
              ? 'No accounts found matching "$_activeClientSearchQuery".'
              : 'No accounts to display.',
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
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          DataColumn(
            label: Text('ID'),
            numeric: true,
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Acc. No'),
            numeric: true,
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Account Name'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            _displayedEntries
                .map(
                  (account) => DataRow(
                    cells: [
                      DataCell(Text(account.id.toString())),
                      DataCell(Text(account.accountNo.toString())),
                      DataCell(Text(account.accountName)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue,
                              ),
                              tooltip: 'Edit',
                              onPressed: () => _editAccount(account),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete',
                              onPressed: () => _deleteAccount(account),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelectChanged: (selected) {
                      if (selected ?? false) _viewAccount(account);
                    },
                  ),
                )
                .toList(),
        showCheckboxColumn: false,
      ),
    );
  }

  Widget _buildPaginationControlsClientSide() {
    if (_clientHasMoreDataToDisplay) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreClientSide,
            child: Text(
              'Load More (${_processedClientSideEntries.length - _displayedEntries.length} remaining)',
            ),
          ),
        ),
      );
    } else if (_allApiEntriesMaster.isNotEmpty && !_isLoadingApi) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text("End of list", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox.shrink();
  }
}
