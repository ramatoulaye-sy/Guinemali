import 'package:flutter/material.dart';

class EmergencyPlanWidget extends StatelessWidget {
	final String instructions;
	final String safePlaces;
	final String escapeRoutes;
	final String medicalInfo;
	final VoidCallback? onOpenPlan;

	const EmergencyPlanWidget({
		super.key,
		required this.instructions,
		required this.safePlaces,
		required this.escapeRoutes,
		required this.medicalInfo,
		this.onOpenPlan,
	});

	Widget _buildRow(BuildContext context, {required IconData icon, required String title, required String value, required Color color}) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Icon(icon, color: color),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
							const SizedBox(height: 4),
							Text(value.isEmpty ? 'Non défini' : value, style: Theme.of(context).textTheme.bodyMedium),
						],
					),
				),
			],
		);
	}

	@override
	Widget build(BuildContext context) {
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								Icon(Icons.emergency, color: Colors.red.shade600),
								const SizedBox(width: 8),
								Text('Plan d\'Urgence', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
								const Spacer(),
								TextButton.icon(
									onPressed: onOpenPlan,
									icon: const Icon(Icons.open_in_new),
									label: const Text('Ouvrir'),
								),
							],
						),
						const SizedBox(height: 12),
						_divider(),
						const SizedBox(height: 12),
						_buildRow(context, icon: Icons.rule, title: 'Instructions', value: instructions, color: Colors.red.shade600),
						const SizedBox(height: 8),
						_buildRow(context, icon: Icons.location_on, title: 'Lieux sûrs', value: safePlaces, color: Colors.blue.shade600),
						const SizedBox(height: 8),
						_buildRow(context, icon: Icons.directions_run, title: 'Évacuation', value: escapeRoutes, color: Colors.green.shade600),
						const SizedBox(height: 8),
						_buildRow(context, icon: Icons.medical_services, title: 'Infos médicales', value: medicalInfo, color: Colors.orange.shade600),
					],
				),
			),
		);
	}

	Widget _divider() => Container(height: 1, width: double.infinity, color: Colors.grey.shade300);
}
