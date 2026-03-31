import 'package:flutter/material.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final int maxRating;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingBarWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        final icon = Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: isFilled ? Colors.amber : Colors.grey,
        );

        if (interactive && onRatingChanged != null) {
          return GestureDetector(
            onTap: () => onRatingChanged!(starIndex.toDouble()),
            child: icon,
          );
        }

        return icon;
      }),
    );
  }
}
