import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String reportName;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.reportName,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  PDFViewController? _pdfViewController;
  bool _isSharing = false;

  Future<void> _shareOrSavePdf() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final fileToShare = File(widget.filePath);
      if (!await fileToShare.exists()) {
        throw Exception("File to share not found at ${widget.filePath}");
      }

      final box = context.findRenderObject() as RenderBox?;
      final shareResult = await Share.shareXFiles(
        [XFile(fileToShare.path)],
        text: 'Report: ${widget.reportName}',
        subject: widget.reportName,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );

      if (!mounted) return;

      if (shareResult.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File ready to be saved/shared!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save/Share cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportName),
        actions: <Widget>[
          _isSharing
              ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(Icons.share),
                tooltip: 'Share / Save a Copy',
                onPressed: _shareOrSavePdf,
              ),
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('${_currentPage + 1}/$_totalPages')),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.filePath,
            onRender: (pages) {
              if (mounted)
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
            },
            onError: (error) {
              if (mounted) setState(() => _errorMessage = error.toString());
            },
            onPageError: (page, error) {
              if (mounted)
                setState(() => _errorMessage = 'Error on page $page: $error');
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int? page, int? total) {
              if (mounted && page != null) setState(() => _currentPage = page);
            },
          ),
          if (!_isReady && _errorMessage.isEmpty)
            Center(child: CircularProgressIndicator())
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading PDF: $_errorMessage',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _totalPages > 1
              ? FloatingActionButton.extended(
                label: Text("${_currentPage + 1}/$_totalPages"),
                icon: Icon(Icons.pages),
                onPressed: () async {
                  if (_pdfViewController != null) {
                    int nextPage = (_currentPage + 1) % _totalPages;
                    await _pdfViewController!.setPage(nextPage);
                  }
                },
              )
              : null,
    );
  }
}
