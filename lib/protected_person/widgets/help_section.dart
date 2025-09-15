import 'package:flutter/material.dart';

class HelpSection extends StatelessWidget {
	final String title;
	final String description;
	final List<String> steps;
	final IconData icon;

	const HelpSection({
		super.key,
		required this.title,
		required this.description,
		this.steps = const [],
		this.icon = Icons.help_outline,
	});

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
								Icon(icon, color: Colors.red.shade600),
								const SizedBox(width: 8),
								Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
							],
						),
						const SizedBox(height: 8),
						Text(description),
						if (steps.isNotEmpty) ...[
							const SizedBox(height: 12),
							Text('Étapes :', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
							const SizedBox(height: 8),
							...steps.map((s) => Padding(
								padding: const EdgeInsets.only(bottom: 6),
								child: Row(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										const Icon(Icons.check_circle, size: 18, color: Colors.green),
										const SizedBox(width: 8),
										Expanded(child: Text(s)),
									],
								),
							)),
						],
					],
				),
			),
		);
	}
}
