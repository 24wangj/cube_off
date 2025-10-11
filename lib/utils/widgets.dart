import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: textColor ?? Colors.white,
      ),
      child: Text(text),
    );
  }
}

class TwoColumnTable extends StatelessWidget {
  final List<List<Widget>> rows; // Each inner list must have exactly 2 widgets
  final bool boldLeft;
  final String title;

  const TwoColumnTable({
    super.key,
    required this.rows,
    this.boldLeft = false,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (title.isNotEmpty) ...[SmallHeader(text: title)],
          for (int i = 0; i < rows.length; i++) ...[
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DefaultTextStyle(
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontWeight: boldLeft
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: rows[i][0],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: DefaultTextStyle(
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontWeight: boldLeft
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: rows[i][1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1)
              Divider(
                color: Colors.grey.withAlpha(50),
                thickness: 1,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }
}

class SmallHeader extends StatelessWidget {
  final String text;

  const SmallHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
