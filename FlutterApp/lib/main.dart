import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AdultMortalityApp());
}

class AdultMortalityApp extends StatelessWidget {
  const AdultMortalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adult Mortality Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // API URL - Replace with your deployed Render URL or local server
  final TextEditingController _apiUrlController = TextEditingController(
    text: 'https://summative-api.onrender.com', // Default production endpoint
  );

  // Form Controllers for all 17 features
  final Map<String, TextEditingController> _controllers = {
    'Year': TextEditingController(),
    'Status': TextEditingController(text: '0'),
    'infant_deaths': TextEditingController(),
    'Alcohol': TextEditingController(),
    'percentage_expenditure': TextEditingController(),
    'Hepatitis_B': TextEditingController(),
    'Measles': TextEditingController(),
    'BMI': TextEditingController(),
    'Polio': TextEditingController(),
    'Total_expenditure': TextEditingController(),
    'Diphtheria': TextEditingController(),
    'HIV_AIDS': TextEditingController(),
    'GDP': TextEditingController(),
    'Population': TextEditingController(),
    'thinness_1_19_years': TextEditingController(),
    'Income_composition_of_resources': TextEditingController(),
    'Schooling': TextEditingController(),
  };

  String? _predictionResult;
  String? _errorMessage;
  bool _isLoading = false;

  // Validation rules (ranges matching Pydantic schema)
  final Map<String, Map<String, double>> _fieldRanges = {
    'Year': {'min': 2000, 'max': 2025},
    'Status': {'min': 0, 'max': 1},
    'infant_deaths': {'min': 0, 'max': 1800},
    'Alcohol': {'min': 0.0, 'max': 20.0},
    'percentage_expenditure': {'min': 0.0, 'max': 20000.0},
    'Hepatitis_B': {'min': 0.0, 'max': 100.0},
    'Measles': {'min': 0, 'max': 250000},
    'BMI': {'min': 1.0, 'max': 90.0},
    'Polio': {'min': 0.0, 'max': 100.0},
    'Total_expenditure': {'min': 0.0, 'max': 30.0},
    'Diphtheria': {'min': 0.0, 'max': 100.0},
    'HIV_AIDS': {'min': 0.1, 'max': 50.0},
    'GDP': {'min': 0.0, 'max': 120000.0},
    'Population': {'min': 0.0, 'max': 1500000000.0},
    'thinness_1_19_years': {'min': 0.0, 'max': 30.0},
    'Income_composition_of_resources': {'min': 0.0, 'max': 1.0},
    'Schooling': {'min': 0.0, 'max': 25.0},
  };

  void _fillSampleData() {
    setState(() {
      _controllers['Year']!.text = '2015';
      _controllers['Status']!.text = '0';
      _controllers['infant_deaths']!.text = '64';
      _controllers['Alcohol']!.text = '1.5';
      _controllers['percentage_expenditure']!.text = '50.0';
      _controllers['Hepatitis_B']!.text = '72.0';
      _controllers['Measles']!.text = '500';
      _controllers['BMI']!.text = '22.5';
      _controllers['Polio']!.text = '65.0';
      _controllers['Total_expenditure']!.text = '5.5';
      _controllers['Diphtheria']!.text = '65.0';
      _controllers['HIV_AIDS']!.text = '3.5';
      _controllers['GDP']!.text = '1200.0';
      _controllers['Population']!.text = '35000000';
      _controllers['thinness_1_19_years']!.text = '7.5';
      _controllers['Income_composition_of_resources']!.text = '0.45';
      _controllers['Schooling']!.text = '8.5';
      _errorMessage = null;
      _predictionResult = null;
    });
  }

  Future<void> _makePrediction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    // 1. Check for missing values & validate ranges
    Map<String, dynamic> payload = {};

    for (var entry in _controllers.entries) {
      String key = entry.key;
      String valStr = entry.value.text.trim();

      if (valStr.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Missing input: Please enter a value for "$key".';
        });
        return;
      }

      num? numVal = num.tryParse(valStr);
      if (numVal == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid input: "$key" must be a valid number.';
        });
        return;
      }

      // Check range constraints
      var range = _fieldRanges[key];
      if (range != null) {
        if (numVal < range['min']! || numVal > range['max']!) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Out of range: "$key" must be between ${range['min']} and ${range['max']}.';
          });
          return;
        }
      }

      payload[key] = (key == 'Year' || key == 'Status' || key == 'infant_deaths' || key == 'Measles')
          ? numVal.toInt()
          : numVal.toDouble();
    }

    // 2. Make API Request
    try {
      String baseUrl = _apiUrlController.text.trim().replaceAll(RegExp(r'/$'), '');
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double predictedValue = (data['predicted_adult_mortality'] as num).toDouble();
        setState(() {
          _predictionResult = '$predictedValue deaths per 1,000 population';
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'API Error (${response.statusCode}): ${errorData['detail'] ?? response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: Could not reach API endpoint. Ensure server is online.\nError: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'African Adult Mortality Predictor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F766E),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amberAccent),
            tooltip: 'Fill Sample Data',
            onPressed: _fillSampleData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Banner
            Card(
              color: const Color(0xFFF0FDF4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFBBF7D0)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Color(0xFF0F766E), size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter national health & economic indicators to predict adult mortality (ages 15-60) per 1,000 population.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // API Endpoint Config
            TextField(
              controller: _apiUrlController,
              decoration: InputDecoration(
                labelText: 'API Base URL',
                hintText: 'e.g. https://summative-api.onrender.com or http://10.0.2.2:8000',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Input Predictor Variables (17)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _fillSampleData,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Auto-Fill Sample'),
                ),
              ],
            ),
            const Divider(),

            // 17 Form Fields Grid/List
            ..._controllers.keys.map((key) {
              var range = _fieldRanges[key];
              String hint = range != null ? '[${range['min']} - ${range['max']}]' : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _controllers[key],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: key.replaceAll('_', ' '),
                    helperText: hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Predict Button
            ElevatedButton(
              onPressed: _isLoading ? null : _makePrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Predict',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 24),

            // Display Area for Output / Errors
            if (_predictionResult != null)
              Card(
                color: const Color(0xFFECFDF5),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF059669), size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Predicted Adult Mortality Rate:',
                        style: TextStyle(fontSize: 14, color: Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _predictionResult!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null)
              Card(
                color: const Color(0xFFFEF2F2),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
