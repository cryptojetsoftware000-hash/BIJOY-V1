import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIJOY Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _previous = '';
  String _operator = '';
  bool _startNewNumber = true;

  void _tap(String value) {
    setState(() {
      if (value == 'C') {
        _clear();
      } else if (value == '⌫') {
        _backspace();
      } else if (value == '=') {
        _calculate();
      } else if (_isOperator(value)) {
        _setOperator(value);
      } else if (value == '.') {
        _addDecimal();
      } else {
        _addNumber(value);
      }
    });
  }

  void _clear() {
    _display = '0';
    _previous = '';
    _operator = '';
    _startNewNumber = true;
  }

  void _backspace() {
    if (_startNewNumber || _display.length == 1) {
      _display = '0';
      _startNewNumber = true;
      return;
    }
    _display = _display.substring(0, _display.length - 1);
  }

  void _addNumber(String number) {
    if (_startNewNumber || _display == '0') {
      _display = number;
      _startNewNumber = false;
    } else {
      _display += number;
    }
  }

  void _addDecimal() {
    if (_startNewNumber) {
      _display = '0.';
      _startNewNumber = false;
      return;
    }
    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _setOperator(String op) {
    if (_operator.isNotEmpty && !_startNewNumber) {
      _calculate();
    }
    _previous = _display;
    _operator = op;
    _startNewNumber = true;
  }

  void _calculate() {
    if (_operator.isEmpty || _previous.isEmpty) return;

    final double first = double.tryParse(_previous) ?? 0;
    final double second = double.tryParse(_display) ?? 0;
    double result;

    switch (_operator) {
      case '+':
        result = first + second;
        break;
      case '-':
        result = first - second;
        break;
      case '×':
        result = first * second;
        break;
      case '÷':
        if (second == 0) {
          _display = 'Error';
          _previous = '';
          _operator = '';
          _startNewNumber = true;
          return;
        }
        result = first / second;
        break;
      default:
        return;
    }

    _display = _formatResult(result);
    _previous = '';
    _operator = '';
    _startNewNumber = true;
  }

  bool _isOperator(String value) {
    return value == '+' || value == '-' || value == '×' || value == '÷';
  }

  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) return 'Error';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _button(String text, {bool operator = false, bool danger = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          height: 72,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger
                  ? Colors.redAccent
                  : operator
                      ? const Color(0xFF1565C0)
                      : Colors.blueGrey.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _tap(text),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FA),
      appBar: AppBar(
        title: const Text(
          'BIJOY Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _operator.isEmpty ? 'Ready' : '$_previous $_operator',
                      style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: Column(
                children: [
                  _row([
                    _button('C', danger: true),
                    _button('⌫'),
                    _button('÷', operator: true),
                    _button('×', operator: true),
                  ]),
                  _row([
                    _button('7'),
                    _button('8'),
                    _button('9'),
                    _button('-', operator: true),
                  ]),
                  _row([
                    _button('4'),
                    _button('5'),
                    _button('6'),
                    _button('+', operator: true),
                  ]),
                  _row([
                    _button('1'),
                    _button('2'),
                    _button('3'),
                    _button('=', operator: true),
                  ]),
                  _row([
                    _button('0', flex: 2),
                    _button('.'),
                    _button('=', operator: true),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
