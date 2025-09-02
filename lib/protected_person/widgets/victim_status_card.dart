import 'package:flutter/material.dart';

class VictimStatusCard extends StatelessWidget {
	final bool gpsActive;
	final bool audioActive;
	final bool online;
	final bool syncing;
	final int pendingItems;
	final int failedItems;
	final EdgeInsetsGeometry padding;

	const VictimStatusCard({
		super.key,
		required this.gpsActive,
		required this.audioActive,
		required this.online,
		required this.syncing,
		this.pendingItems = 0,
		this.failedItems = 0,
		this.padding = const EdgeInsets.all(16),
	});

	Color _statusColor(bool active) => active ? Colors.green : Colors.grey;

	Widget _buildChip({
		required IconData icon,
		required String label,
		required Color color,
	}) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.1),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: color.withValues(alpha: 0.6)),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 18, color: color),
					const SizedBox(width: 6),
					Text(
						label,
						style: TextStyle(
							color: color,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Card(
			margin: EdgeInsets.zero,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			elevation: 2,
			child: Padding(
				padding: padding,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Icon(Icons.shield, color: Colors.red.shade600),
								const SizedBox(width: 8),
								Text(
									'Statut de Sécurité',
									style: Theme.of(context).textTheme.titleMedium?.copyWith(
										fontWeight: FontWeight.bold,
									),
								),
							],
						),
						const SizedBox(height: 12),
						Wrap(
							spacing: 8,
							runSpacing: 8,
							children: [
								_buildChip(
									icon: Icons.location_on,
									label: gpsActive ? 'GPS actif' : 'GPS inactif',
									color: _statusColor(gpsActive),
								),
								_buildChip(
									icon: Icons.mic,
									label: audioActive ? 'Audio actif' : 'Audio inactif',
									color: _statusColor(audioActive),
								),
								_buildChip(
									icon: online ? Icons.wifi : Icons.wifi_off,
									label: online ? 'En ligne' : 'Hors-ligne',
									color: online ? Colors.green : Colors.orange,
								),
								_buildChip(
									icon: syncing ? Icons.sync : Icons.sync_disabled,
									label: syncing ? 'Synchronisation…' : 'Sync en pause',
									color: syncing ? Colors.blue : Colors.grey,
								),
								if (pendingItems > 0)
									_buildChip(
										icon: Icons.pending_actions,
										label: 'En attente: $pendingItems',
										color: Colors.amber,
									),
								if (failedItems > 0)
									_buildChip(
										icon: Icons.error_outline,
										label: 'Échecs: $failedItems',
										color: Colors.red,
									),
						],
						),
					],
				),
			),
		);
	}
}
