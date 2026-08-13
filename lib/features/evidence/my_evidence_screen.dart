import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/evidence_service.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/secure_app_bar.dart';

/// List of all evidence captured by the current officer.
class MyEvidenceScreen extends StatefulWidget {
  const MyEvidenceScreen({super.key});

  @override
  State<MyEvidenceScreen> createState() => _MyEvidenceScreenState();
}

class _MyEvidenceScreenState extends State<MyEvidenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvidenceService>().loadEvidence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evidenceService = context.watch<EvidenceService>();

    return Scaffold(
      appBar: const SecureAppBar(title: 'My Evidence'),
      body: GradientBackground(
        child: evidenceService.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BFA6)),
              )
            : evidenceService.evidenceList.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: () => evidenceService.loadEvidence(),
                    color: const Color(0xFF00BFA6),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: evidenceService.evidenceList.length,
                      itemBuilder: (context, index) {
                        final record =
                            evidenceService.evidenceList[index];
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
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.secureCamera),
        child: const Icon(Icons.camera_alt_rounded),
      ),
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
              Icons.folder_open_rounded,
              size: 40,
              color: Color(0xFF6B7A8D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Evidence Yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your first piece of evidence\nusing the secure camera.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.secureCamera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Start Capture'),
          ),
        ],
      ),
    );
  }
}
