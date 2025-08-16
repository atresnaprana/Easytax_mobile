import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user_model.dart';
import '../../../utils/constants.dart';
import 'add_user_page.dart';
import 'edit_user_page.dart';

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  List<UserEntry> _allApiEntriesMaster = [];
  List<UserEntry> _processedClientSideEntries = [];
  List<UserEntry> _displayedEntries = [];

  bool _isLoadingApi = false;
  String? _error;
  String _packageInfo = '';

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
      _displayedEntries.clear();
      _clientCurrentPage = 1;
      _clientHasMoreDataToDisplay = false;
      _packageInfo = '';
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final url = Uri.parse('$baseUrl/api/API/getdatauser');
      final headers = {'Authorization': 'Bearer $token'};

      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 45));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        _packageInfo = responseData['pkg'] ?? 'N/A';
        final List<dynamic> customerData = responseData['customerdt'] ?? [];
        _allApiEntriesMaster =
            customerData
                .map((item) => UserEntry.fromJson(item as Map<String, dynamic>))
                .toList();
        _applyClientFiltersAndSortAndPaginate();
      } else {
        throw Exception('Failed to load users. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  void _applyClientFiltersAndSortAndPaginate() {
    if (!mounted) return;
    List<UserEntry> clientProcessedList;
    if (_activeClientSearchQuery.isEmpty) {
      clientProcessedList = List.from(_allApiEntriesMaster);
    } else {
      final query = _activeClientSearchQuery.toLowerCase();
      clientProcessedList =
          _allApiEntriesMaster
              .where(
                (user) =>
                    user.customerName.toLowerCase().contains(query) ||
                    user.email.toLowerCase().contains(query) ||
                    user.phone1.contains(query),
              )
              .toList();
    }

    clientProcessedList.sort((a, b) {
      int compareResult = 0;
      switch (_sortColumnIndex) {
        case 0:
          compareResult = a.customerName.toLowerCase().compareTo(
            b.customerName.toLowerCase(),
          );
          break;
        case 1:
          compareResult = a.email.toLowerCase().compareTo(
            b.email.toLowerCase(),
          );
          break;
        case 2:
          compareResult = (a.registerDate ?? DateTime(1900)).compareTo(
            b.registerDate ?? DateTime(1900),
          );
          break;
        case 3:
          compareResult = a.phone1.compareTo(b.phone1);
          break;
      }
      return _sortAscending ? compareResult : -compareResult;
    });

    _processedClientSideEntries = clientProcessedList;
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
    List<UserEntry> nextPageItems = [];
    if (startIndex < _processedClientSideEntries.length) {
      endIndex =
          endIndex > _processedClientSideEntries.length
              ? _processedClientSideEntries.length
              : endIndex;
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

  void _viewUser(UserEntry user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'View user: ${user.customerName} (Detail View Not Implemented)',
        ),
      ),
    );
  }

  void _editUser(UserEntry user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserPage(user: user)),
    );
    if (result == true && mounted) {
      _fetchApiDataAndProcessClientSide();
    }
  }

  void _deleteUser(UserEntry user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Confirm Deactivation'),
            content: Text(
              'Are you sure you want to deactivate user "${user.customerName}"? This action is similar to deleting.',
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                child: Text('Deactivate', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    _updateUserStatus(user, isActivating: false);
  }

  void _activateUser(UserEntry user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Confirm Activation'),
            content: Text(
              'Are you sure you want to activate user "${user.customerName}"?',
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                child: Text('Activate', style: TextStyle(color: Colors.green)),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    _updateUserStatus(user, isActivating: true);
  }

  Future<void> _updateUserStatus(
    UserEntry user, {
    required bool isActivating,
  }) async {
    if (!mounted) return;
    setState(() => _isLoadingApi = true);

    final action = isActivating ? "Activation" : "Deactivation";
    final url =
        isActivating
            ? Uri.parse(
              '$baseUrl/api/API/ActivateUser',
            ).replace(queryParameters: {'id': user.id.toString()})
            : Uri.parse(
              '$baseUrl/api/API/DeleteUser',
            ).replace(queryParameters: {'id': user.id.toString()});

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null || token.isEmpty)
        throw Exception('Authentication required.');

      final headers = {'Authorization': 'Bearer $token'};
      final response = await http
          .post(url, headers: headers)
          .timeout(Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${user.customerName} ${action.toLowerCase()}d successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _fetchApiDataAndProcessClientSide();
      } else {
        String serverMessage = response.reasonPhrase ?? '$action Failed';
        try {
          var errorData = json.decode(response.body);
          serverMessage =
              errorData['message'] ??
              errorData['title'] ??
              errorData['error'] ??
              serverMessage;
        } catch (_) {}
        throw Exception(
          'Failed to ${action.toLowerCase()} user. Server: ${response.statusCode} - $serverMessage',
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during user $action: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  void _navigateToAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserPage()),
    );
    if (result == true && mounted) {
      _fetchApiDataAndProcessClientSide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Settings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name, Email, or Phone',
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
          if (_packageInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Package: $_packageInfo",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          Expanded(child: _buildDataArea()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPage,
        tooltip: 'Add New User',
        child: Icon(Icons.person_add_alt_1),
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
              ? 'No users found for "$_activeClientSearchQuery".'
              : 'No users to display.',
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
            label: Text('Name'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Email'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Reg. Date'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(
            label: Text('Phone'),
            onSort: (ci, asc) => _onSort(ci, asc),
          ),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            _displayedEntries.map((user) {
              bool isUserActive = user.activeFlag == '1';
              return DataRow(
                cells: [
                  DataCell(Text(user.customerName)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.formattedRegisterDate)),
                  DataCell(Text(user.phone1)),
                  DataCell(
                    Text(
                      user.status,
                      style: TextStyle(
                        color: isUserActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () => _editUser(user),
                        ),
                        if (isUserActive)
                          IconButton(
                            icon: Icon(
                              Icons.cancel,
                              size: 20,
                              color: Colors.red,
                            ),
                            tooltip: 'Deactivate',
                            onPressed: () => _deleteUser(user),
                          ),
                        if (!isUserActive)
                          IconButton(
                            icon: Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Colors.teal,
                            ),
                            tooltip: 'Activate User',
                            onPressed: () => _activateUser(user),
                          ),
                      ],
                    ),
                  ),
                ],
                onSelectChanged: (selected) {
                  if (selected ?? false) _viewUser(user);
                },
              );
            }).toList(),
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
