import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/profile_provider.dart';
import '../../../providers/pose_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(profileProvider).activeProfile;
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Profil Aktif',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          title: Text(activeProfile?.name ?? 'Belum ada profil aktif'),
          subtitle: activeProfile != null 
              ? Text('${activeProfile.board} · ${activeProfile.jointCount} Joint')
              : const Text('Tap untuk mengatur profil'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.go('/profile');
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Data Aplikasi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          iconColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever),
          title: const Text('Reset Semua Data'),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset Semua Data'),
                content: const Text(
                  'Apakah Anda yakin ingin menghapus semua profil robot dan rekam pose? '
                  'Tindakan ini tidak dapat dibatalkan.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () {
                      ref.read(poseProvider.notifier).clearAll();
                      ref.read(profileProvider.notifier).clearAll();
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Semua data berhasil direset')),
                        );
                      }
                    },
                    child: const Text('Reset Data'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
