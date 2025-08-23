import 'package:flutter/material.dart';

class AlertItem {
	final String id;
	final String type;
	final String status;
	final String dangerLevel;
	final String timestamp;
	final double? latitude;
	final double? longitude;
	final String? description;

	AlertItem({
		required this.id,
		required this.type,
		required this.status,
		required this.dangerLevel,
		required this.timestamp,
		this.latitude,
		this.longitude,
		this.description,
	});
}

class AlertHistoryList extends StatelessWidget {
	final List<AlertItem> items;
	final String filter; // all, active, resolved, cancelled
	final ValueChanged<String>? onFilterChanged;
	final ValueChanged<AlertItem>? onTapItem;

	const AlertHistoryList({
		super.key,
		required this.items,
		this.filter = 'all',
		this.onFilterChanged,
		this.onTapItem,
	});

	List<AlertItem> get _filteredItems {
		if (filter == 'all') return items;
		return items.where((a) {
			switch (filter) {
				case 'active':
					return a.status == 'active';
				case 'resolved':
					return a.status == 'resolue';
				case 'cancelled':
					return a.status == 'fausse_alerte';
				default:
					return true;
			}
		}).toList();
	}

	Color _statusColor(String status) {
		switch (status) {
			case 'active':
				return Colors.red;
			case 'resolue':
				return Colors.green;
			case 'fausse_alerte':
				return Colors.orange;
			default:
				return Colors.grey;
		}
	}

	String _statusLabel(String status) {
		switch (status) {
			case 'active':
				return 'Active';
			case 'resolue':
				return 'Résolue';
			case 'fausse_alerte':
				return 'Annulée';
			default:
				return status;
		}
	}

	Color _dangerColor(String level) {
		switch (level) {
			case 'faible':
				return Colors.green;
			case 'moyen':
				return Colors.orange;
			case 'eleve':
				return Colors.red;
			case 'critique':
				return Colors.purple;
			default:
				return Colors.grey;
		}
	}

	String _formatTs(String ts) {
		try {
			final d = DateTime.parse(ts);
			final now = DateTime.now();
			final diff = now.difference(d);
			if (diff.inDays > 0) return 'Il y a ${diff.inDays} j';
			if (diff.inHours > 0) return 'Il y a ${diff.inHours} h';
			if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes} min';
			return "À l'instant";
		} catch (_) {
			return ts;
		}
	}

	Widget _chip(Color color, String label) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.1),
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: color),
			),
			child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			children: [
				SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: Row(
						children: [
							_filterChip(context, 'Toutes', 'all', Icons.all_inclusive),
							const SizedBox(width: 8),
							_filterChip(context, 'Actives', 'active', Icons.warning),
							const SizedBox(width: 8),
							_filterChip(context, 'Résolues', 'resolved', Icons.check_circle),
							const SizedBox(width: 8),
							_filterChip(context, 'Annulées', 'cancelled', Icons.cancel),
						],
					),
				),
				const SizedBox(height: 12),
				Expanded(
					child: _filteredItems.isEmpty
							? _emptyState(context)
							: ListView.builder(
								padding: const EdgeInsets.only(bottom: 8),
								itemCount: _filteredItems.length,
								itemBuilder: (context, i) => _alertTile(context, _filteredItems[i]),
							),
					),
			],
		);
	}

	Widget _filterChip(BuildContext context, String label, String value, IconData icon) {
		final isSelected = filter == value;
		return FilterChip(
			label: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
					const SizedBox(width: 4),
					Text(label),
				],
			),
			selected: isSelected,
			onSelected: (_) => onFilterChanged?.call(value),
			selectedColor: Colors.red.shade600,
			checkmarkColor: Colors.white,
			backgroundColor: Colors.grey.shade200,
			labelStyle: TextStyle(
				color: isSelected ? Colors.white : Colors.black87,
				fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
			),
		);
	}

	Widget _emptyState(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(Icons.history, size: 48, color: Colors.grey.shade400),
					const SizedBox(height: 8),
					Text('Aucune alerte', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
				],
			),
		);
	}

	Widget _alertTile(BuildContext context, AlertItem a) {
		return Card(
			margin: const EdgeInsets.only(bottom: 8),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			elevation: 2,
			child: ListTile(
				onTap: () => onTapItem?.call(a),
				title: Text(a.type, style: const TextStyle(fontWeight: FontWeight.w700)),
				subtitle: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						if (a.description != null && a.description!.isNotEmpty)
							Text(a.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
						const SizedBox(height: 6),
						Row(
							children: [
								_chip(_statusColor(a.status), _statusLabel(a.status)),
								const SizedBox(width: 6),
								_chip(_dangerColor(a.dangerLevel), a.dangerLevel),
								const Spacer(),
								Row(
									children: [
										Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
										const SizedBox(width: 4),
										Text(_formatTs(a.timestamp), style: TextStyle(color: Colors.grey.shade700)),
									],
								),
							],
						),
					],
				),
			),
		);
	}
}
