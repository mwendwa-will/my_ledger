import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/currency_helper.dart';

class Numpad extends StatelessWidget {

  const Numpad({
    super.key,
    required this.onKeyPressed,
    required this.currencyCode,
  });
  final Function(String) onKeyPressed;
  final String currencyCode;

  Widget _buildButton(BuildContext context, String text, {VoidCallback? onPressed, bool isAccent = false, String? tooltip}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: InkWell(
          onTap: onPressed ?? () => onKeyPressed(text),
          customBorder: const CircleBorder(),
          child: Tooltip( // Wrap with Tooltip for accessibility
            message: tooltip ?? text,
            child: Ink(
              decoration: BoxDecoration(
                color: isAccent ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Center(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isAccent ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick amount buttons
        Row(
          children: [
            _buildButton(context, CurrencyHelper.format(5, currencyCode: currencyCode, decimalDigits: 0), onPressed: () => onKeyPressed('5'), tooltip: 'Quick add 5'),
            _buildButton(context, CurrencyHelper.format(10, currencyCode: currencyCode, decimalDigits: 0), onPressed: () => onKeyPressed('10'), tooltip: 'Quick add 10'),
            _buildButton(context, CurrencyHelper.format(25, currencyCode: currencyCode, decimalDigits: 0), onPressed: () => onKeyPressed('25'), tooltip: 'Quick add 25'),
            _buildButton(context, CurrencyHelper.format(50, currencyCode: currencyCode, decimalDigits: 0), onPressed: () => onKeyPressed('50'), tooltip: 'Quick add 50'),
          ],
        ),
        // Operator row
        Row(
          children: [
            _buildButton(context, '+', onPressed: () => onKeyPressed('+'), isAccent: true, tooltip: 'plus'),
            _buildButton(context, '-', onPressed: () => onKeyPressed('-'), isAccent: true, tooltip: 'minus'),
            _buildButton(context, '*', onPressed: () => onKeyPressed('*'), isAccent: true, tooltip: 'multiply'),
            _buildButton(context, '/', onPressed: () => onKeyPressed('/'), isAccent: true, tooltip: 'divide'),
          ],
        ),
        // Numpad buttons
        Row(
          children: [
            _buildButton(context, '1', tooltip: 'digit 1'),
            _buildButton(context, '2', tooltip: 'digit 2'),
            _buildButton(context, '3', tooltip: 'digit 3'),
          ],
        ),
        Row(
          children: [
            _buildButton(context, '4', tooltip: 'digit 4'),
            _buildButton(context, '5', tooltip: 'digit 5'),
            _buildButton(context, '6', tooltip: 'digit 6'),
          ],
        ),
        Row(
          children: [
            _buildButton(context, '7', tooltip: 'digit 7'),
            _buildButton(context, '8', tooltip: 'digit 8'),
            _buildButton(context, '9', tooltip: 'digit 9'),
          ],
        ),
        Row(
          children: [
            _buildButton(context, '(', onPressed: () => onKeyPressed('('), tooltip: 'open parenthesis'),
            _buildButton(context, ')', onPressed: () => onKeyPressed(')'), tooltip: 'close parenthesis'),
            _buildButton(
              context,
              '<-',
              onPressed: () => onKeyPressed('backspace'),
              tooltip: 'backspace',
            ),
          ],
        ),
        Row(
          children: [
            _buildButton(context, '.', tooltip: 'decimal point'),
            _buildButton(context, '0', tooltip: 'digit 0'),
            _buildButton(context, 'C', onPressed: () => onKeyPressed('clear'), tooltip: 'clear'),
          ],
        ),
      ],
    );
  }
}
