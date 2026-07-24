import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const AdultMortalityApp());
}

class AdultMortalityApp extends StatefulWidget {
  const AdultMortalityApp({super.key});

  @override
  State<AdultMortalityApp> createState() => _AdultMortalityAppState();
}

class _AdultMortalityAppState extends State<AdultMortalityApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adult Mortality Predictor',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F766E),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(color: Color(0xFF475569)),
        ),
      ),
      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
      ),
      home: PredictionScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const PredictionScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // API URL - Replace with your deployed Render URL or local server
  final TextEditingController _apiUrlController = TextEditingController(
    text: 'https://adult-mortality-api.onrender.com', // Default production endpoint
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

  // Index to cycle through different sample datasets
  int _sampleIndex = 0;

  // 5 different sample datasets representing various African country profiles
  final List<Map<String, String>> _sampleDatasets = [
    // Sample 1: Low-income country with high mortality risk
    {'Year': '2014', 'Status': '0', 'infant_deaths': '64', 'Alcohol': '1.5',
     'percentage_expenditure': '50.0', 'Hepatitis_B': '72.0', 'Measles': '500',
     'BMI': '22.5', 'Polio': '65.0', 'Total_expenditure': '5.5',
     'Diphtheria': '65.0', 'HIV_AIDS': '3.5', 'GDP': '1200.0',
     'Population': '35000000', 'thinness_1_19_years': '7.5',
     'Income_composition_of_resources': '0.45', 'Schooling': '8.5'},
    // Sample 2: Upper-middle income country with better health indicators
    {'Year': '2013', 'Status': '0', 'infant_deaths': '12', 'Alcohol': '8.2',
     'percentage_expenditure': '850.0', 'Hepatitis_B': '90.0', 'Measles': '50',
     'BMI': '28.0', 'Polio': '95.0', 'Total_expenditure': '8.0',
     'Diphtheria': '92.0', 'HIV_AIDS': '8.0', 'GDP': '6500.0',
     'Population': '54000000', 'thinness_1_19_years': '3.2',
     'Income_composition_of_resources': '0.65', 'Schooling': '13.0'},
    // Sample 3: High HIV/AIDS burden country
    {'Year': '2010', 'Status': '0', 'infant_deaths': '45', 'Alcohol': '4.0',
     'percentage_expenditure': '200.0', 'Hepatitis_B': '80.0', 'Measles': '1200',
     'BMI': '19.5', 'Polio': '78.0', 'Total_expenditure': '6.2',
     'Diphtheria': '75.0', 'HIV_AIDS': '15.0', 'GDP': '800.0',
     'Population': '18000000', 'thinness_1_19_years': '10.5',
     'Income_composition_of_resources': '0.38', 'Schooling': '6.5'},
    // Sample 4: Rapidly developing country with improving indicators
    {'Year': '2015', 'Status': '0', 'infant_deaths': '25', 'Alcohol': '6.5',
     'percentage_expenditure': '400.0', 'Hepatitis_B': '85.0', 'Measles': '150',
     'BMI': '24.0', 'Polio': '88.0', 'Total_expenditure': '7.0',
     'Diphtheria': '87.0', 'HIV_AIDS': '1.2', 'GDP': '3200.0',
     'Population': '48000000', 'thinness_1_19_years': '5.0',
     'Income_composition_of_resources': '0.55', 'Schooling': '10.5'},
    // Sample 5: Low-resource country with high infant mortality
    {'Year': '2008', 'Status': '0', 'infant_deaths': '120', 'Alcohol': '0.5',
     'percentage_expenditure': '15.0', 'Hepatitis_B': '55.0', 'Measles': '3000',
     'BMI': '18.0', 'Polio': '50.0', 'Total_expenditure': '3.5',
     'Diphtheria': '48.0', 'HIV_AIDS': '2.0', 'GDP': '350.0',
     'Population': '95000000', 'thinness_1_19_years': '12.0',
     'Income_composition_of_resources': '0.30', 'Schooling': '4.5'},
  ];

  void _fillSampleData() {
    setState(() {
      final sample = _sampleDatasets[_sampleIndex % _sampleDatasets.length];
      sample.forEach((key, value) {
        _controllers[key]!.text = value;
      });
      _sampleIndex++;
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
      ).timeout(const Duration(seconds: 60));

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
    final isDark = widget.isDarkMode;
    final primaryColor = isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    final cardBg = isDark ? const Color(0xFF1A2E2A) : const Color(0xFFF0FDF4);
    final cardBorder = isDark ? const Color(0xFF14B8A6) : const Color(0xFFBBF7D0);
    final cardTextColor = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF166534);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'African Adult Mortality Predictor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF0F766E),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.amberAccent,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.amberAccent),
            tooltip: 'Cycle Sample Country Profile',
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
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cardBorder, width: isDark ? 0.5 : 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: primaryColor, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter national health & economic indicators to predict adult mortality (ages 15-60) per 1,000 population.',
                        style: TextStyle(fontSize: 13, color: cardTextColor),
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
                hintText: 'e.g. https://adult-mortality-api.onrender.com or http://10.0.2.2:8000',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            const Text(
              'Input Predictor Variables (17)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
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
                color: cardBg,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primaryColor, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: primaryColor, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Predicted Adult Mortality Rate:',
                        style: TextStyle(fontSize: 14, color: cardTextColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _predictionResult!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null)
              Card(
                color: isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFEF2F2),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            fontSize: 14,
                          ),
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
