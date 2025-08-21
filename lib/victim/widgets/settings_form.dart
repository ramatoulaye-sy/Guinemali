import 'package:flutter/material.dart';

class SettingToggleItem {
	final String keyName;
	final String title;
	final String subtitle;
	final bool value;
	final ValueChanged<bool> onChanged;

	SettingToggleItem({
		required this.keyName,
		required this.title,
		required this.subtitle,
		required this.value,
		required this.onChanged,
	});
}

class SettingsForm extends StatelessWidget {
	final List<SettingToggleItem> toggles;
	final List<Widget> extras;

	const SettingsForm({
		super.key,
		this.toggles = const [],
		this.extras = const [],
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						...toggles.map((t) => Column(
							children: [
								SwitchListTile(
									title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
									subtitle: Text(t.subtitle),
									value: t.value,
									onChanged: t.onChanged,
									activeColor: Colors.red.shade600,
									contentPadding: EdgeInsets.zero,
								),
								if (t != toggles.last) const Divider(height: 1),
							],
						)),
						...extras,
					],
				),
			),
		);
	}
}
