import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/firmware/firmware_generator.dart';
import '../../../services/firmware/zip_exporter.dart';

class FirmwareScreen extends ConsumerWidget {
  const FirmwareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final customColors = Theme.of(context).extension<CustomColors>();

    if (activeProfile == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: customColors?.warning ?? Colors.orange,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: customColors?.warning ?? Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih profil aktif terlebih dahulu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan Profil'),
                onPressed: () {
                  context.go('/profile');
                },
              ),
            ],
          ),
        ),
      );
    }

    final firmwareCode = FirmwareGenerator.generate(activeProfile);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Preview Firmware: ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                activeProfile.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SingleChildScrollView(
                child: Text(
                  firmwareCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export & Download ZIP'),
              onPressed: () =>
                  _exportFirmware(context, activeProfile, firmwareCode),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFirmware(
    BuildContext context,
    activeProfile,
    String firmwareCode,
  ) async {
    try {
      final hasPermission = await PermissionHelper.requestStoragePermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin penyimpanan ditolak!')),
          );
        }
        return;
      }

      final zipPath = await ZipExporter.export(activeProfile, firmwareCode);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil! Disimpan di: $zipPath'),
            backgroundColor:
                Theme.of(context).extension<CustomColors>()?.success ??
                Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuat file firmware. Pastikan ruang penyimpanan cukup dan memiliki izin.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
