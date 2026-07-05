import 'package:flutter/material.dart';

class JointSlider extends StatelessWidget {
  final int jointIndex;
  final int minAngle;
  final int maxAngle;
  final int value;
  final bool isLocked;
  final bool isConnected;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const JointSlider({
    super.key,
    required this.jointIndex,
    required this.minAngle,
    required this.maxAngle,
    required this.value,
    required this.isLocked,
    required this.isConnected,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLocked || !isConnected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Joint ${jointIndex + 1}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDisabled ? Theme.of(context).disabledColor : null,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$minAngle°',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDisabled ? Theme.of(context).disabledColor : Colors.grey,
                ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Slider(
                value: value.toDouble().clamp(minAngle.toDouble(), maxAngle.toDouble()),
                min: minAngle.toDouble(),
                max: maxAngle.toDouble(),
                onChanged: isDisabled ? null : onChanged,
                onChangeEnd: isDisabled ? null : onChangeEnd,
              ),
            ),
          ),
          Text(
            '$maxAngle°',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDisabled ? Theme.of(context).disabledColor : Colors.grey,
                ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 40,
            child: Text(
              '$value°',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDisabled ? Theme.of(context).disabledColor : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
