import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/api_service.dart';
import '../../models/evidence_record.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/secure_app_bar.dart';

/// Screen to display evidence fetched from the cloud backend.
class CloudEvidenceScreen extends StatefulWidget {
  final String title;
  final String? userId; // If provided, fetches evidence for this specific user.
  final bool showBottomNav;

  const CloudEvidenceScreen({
    super.key,
    required this.title,
    this.userId,
    this.showBottomNav = false,
  });

  @override
  State<CloudEvidenceScreen> createState() => _CloudEvidenceScreenState();
}

class _CloudEvidenceScreenState extends State<CloudEvidenceScreen> {
  List<EvidenceRecord> _evidenceList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _fetchEvidence() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      List<EvidenceRecord> list;
      
      if (widget.userId != null) {
        list = await apiService.getUserEvidence(widget.userId!);
      } else {
        list = await apiService.getAllEvidence();
      }

      setState(() {
        _evidenceList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA6)))
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load evidence', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _fetchEvidence,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _evidenceList.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: _fetchEvidence,
                    color: const Color(0xFF00BFA6),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _evidenceList.length,
                      itemBuilder: (context, index) {
                        final record = _evidenceList[index];
                        return EvidenceCard(
                          record: record,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.evidenceDetails,
                              arguments: record.captureId,
                            );
                          },
                        );
                      },
                    ),
                  );

    if (widget.showBottomNav) {
      return GradientBackground(child: body);
    }

    return Scaffold(
      appBar: SecureAppBar(title: widget.title),
      body: GradientBackground(child: body),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2940),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off,
              size: 40,
              color: Color(0xFF6B7A8D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Cloud Evidence Found',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
