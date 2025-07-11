import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:dotted_border/dotted_border.dart';

import 'database_helper.dart';
import 'history_screen.dart';
import 'report_display.dart';
import 'scan_result.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';


const String kAppTitle = 'NeuroDetect AI';

const String kValidationModelPath = 'assets/model/mri_vs_non_mri_model.tflite';
const String kClassifModel1Path = 'assets/model/custom_v7223.tflite';
const String kClassifModel2Path = 'assets/model/resnet_c7223.tflite';
const String kGliomaGradeModelPath = 'assets/model/glioma_tumor_classifier.tflite';
const String kTumorDataPath = 'assets/tumor_data.json';

const List<String> kTumorClassLabels = ['Glioma', 'Meningioma', 'No tumor', 'Pituitary'];
const List<String> kGliomaGradeLabels = ['LGG', 'HGG']; // Low-Grade Glioma, High-Grade Glioma
const int kImageSize = 224; // Input size expected by the models


enum AnalysisMode { tumorClassification, gliomaGrading }
enum StatusType { info, success, warning, error }


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NeuroDetectApp());
}

class NeuroDetectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // --- Define Color Scheme ---
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
      primary: Colors.deepPurple[600]!,
      secondary: Colors.teal[500]!,
      background: Colors.grey[50]!,
      surface: Colors.white,
      surfaceVariant: Colors.deepPurple[50],
      outline: Colors.grey[300],
      error: Colors.redAccent[700]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.deepPurple[900],
      onError: Colors.white,
    );


    return MaterialApp(
      title: kAppTitle,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background,
        fontFamily: 'Poppins',

        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: colorScheme.primary),
        ),
        // --- Card Theme ---
        cardTheme: CardTheme(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        // --- Button Themes ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            shadowColor: colorScheme.primary.withOpacity(0.3),
            minimumSize: const Size(double.infinity, 54), // Full width button standard size
          ),
        ),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')
            )
        ),
        // --- Progress Indicator Theme ---
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: colorScheme.primary,
          linearTrackColor: colorScheme.primary.withOpacity(0.2),
        ),
        // --- Text Theme ---
        textTheme: TextTheme(
          // Define various text styles for consistency
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: colorScheme.primary, fontFamily: 'Poppins'),
          displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorScheme.primary, fontFamily: 'Poppins'),
          displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: 'Poppins'),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colorScheme.onBackground, fontFamily: 'Poppins'),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colorScheme.onBackground, fontFamily: 'Poppins'),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onBackground, fontFamily: 'Poppins'),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'Poppins'),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant, fontFamily: 'Poppins'),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant.withOpacity(0.8), fontFamily: 'Poppins'),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: colorScheme.onSurface, fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: colorScheme.onSurface.withOpacity(0.85), fontFamily: 'Poppins'),
          bodySmall: TextStyle(fontSize: 12, height: 1.3, color: colorScheme.onSurface.withOpacity(0.7), fontFamily: 'Poppins'),
          labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onPrimary, fontFamily: 'Poppins'), // Used in buttons
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withOpacity(0.7), fontFamily: 'Poppins'),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withOpacity(0.7), fontFamily: 'Poppins'), // Used in chart labels
        ),
        // --- Toggle Buttons Theme ---
        toggleButtonsTheme: ToggleButtonsThemeData(
          selectedColor: colorScheme.onPrimary,
          color: colorScheme.primary,
          fillColor: colorScheme.primary,
          selectedBorderColor: colorScheme.primary,
          borderColor: colorScheme.outline,
          borderRadius: BorderRadius.circular(10.0),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'),
          constraints: const BoxConstraints(minHeight: 44.0, minWidth: 110.0), // Consistent button size
        ),
        // --- Divider Theme ---
        dividerTheme: DividerThemeData(
          color: colorScheme.outline?.withOpacity(0.5),
          thickness: 1,
          space: 32, // Default space around dividers
        ),
      ),
      home: SplashScreen(), // Start with the splash screen
      routes: {
        '/home': (context) => BrainTumorClassifier(), // Define route to the main classifier screen
      },
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}


// --- Main Classifier Screen ---
class BrainTumorClassifier extends StatefulWidget {
  @override
  _BrainTumorClassifierState createState() => _BrainTumorClassifierState();
}

class _BrainTumorClassifierState extends State<BrainTumorClassifier> {

  // TFLite Interpreters
  Interpreter? _validationModel;
  Interpreter? _classifModel1;
  Interpreter? _classifModel2;
  Interpreter? _gliomaGradeModel;

  Map<String, dynamic>? _tumorData;
  String _statusMessage = "Initializing System...";
  StatusType _statusType = StatusType.info;
  bool _isProcessing = true;
  bool _modelsInitialized = false;
  File? _selectedImageFile;

  // Analysis Mode and Results
  AnalysisMode _currentMode = AnalysisMode.tumorClassification;
  List<double>? _ensembleProbs;
  String? _ensemblePrediction;
  Map<String, dynamic>? _diagnosisDetails;
  String? _gliomaGradeResult;
  // double? _gliomaGradeProbability;
  double? _predictedGradeConfidence;

  // UI State
  List<bool> _selectedMode = [true, false];
  late List<Color> _barColors = [];

  @override
  void initState() {
    super.initState();
    _initializeSystem();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final theme = Theme.of(context);
        _barColors = [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
          Colors.orange.shade600,
          Colors.lightBlue.shade500,
          theme.colorScheme.primary.withOpacity(0.7),
          theme.colorScheme.secondary.withOpacity(0.7),
        ];

        while (_barColors.length < kTumorClassLabels.length) {
          _barColors.add(_barColors[_barColors.length % 6].withOpacity(0.5));
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _validationModel?.close();
    _classifModel1?.close();
    _classifModel2?.close();
    _gliomaGradeModel?.close();
    DatabaseHelper().close();
    super.dispose();
  }

  // --- Initialization ---
  Future<void> _initializeSystem() async {

    setStateIfMounted(() { _isProcessing = true; _statusMessage = "Loading AI Models..."; _statusType = StatusType.info; });
    bool essentialLoaded = false;
    try {
      await _loadModels();
      await _loadMedicalData();
      if (_validationModel != null && _classifModel1 != null && _classifModel2 != null) {
        essentialLoaded = true; _modelsInitialized = true;
      } else {
        _modelsInitialized = false;
      }
      setStateIfMounted(() {
        _statusMessage = essentialLoaded ? "Select Analysis Mode and Upload Image" : "Essential models failed to load.";
        _statusType = essentialLoaded ? StatusType.info : StatusType.error;
        _isProcessing = false;
      });
    } catch (e) {
      print("Initialization Error: $e");
      setStateIfMounted(() {
        _statusMessage = "Initialization Error: ${e.toString()}";
        _statusType = StatusType.error;
        _modelsInitialized = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _loadModels() async {
    try {
      print("Loading Validation model: $kValidationModelPath");
      _validationModel = await Interpreter.fromAsset(kValidationModelPath, options: InterpreterOptions()..threads = 2);

      print("Loading Classif Model 1: $kClassifModel1Path");
      _classifModel1 = await Interpreter.fromAsset(kClassifModel1Path, options: InterpreterOptions()..threads = 2);

      print("Loading Classif Model 2: $kClassifModel2Path");
      _classifModel2 = await Interpreter.fromAsset(kClassifModel2Path, options: InterpreterOptions()..threads = 2);

      print("Loading Glioma Grade Model: $kGliomaGradeModelPath");
      try {
        _gliomaGradeModel = await Interpreter.fromAsset(kGliomaGradeModelPath, options: InterpreterOptions()..threads = 2);
      } catch (gliomaError) {
        print("WARNING: Failed to load Glioma Grade model ($kGliomaGradeModelPath): $gliomaError");
        _gliomaGradeModel = null;
      }

      if (_validationModel == null || _classifModel1 == null || _classifModel2 == null) {
        throw Exception("Essential classification/validation models failed to load.");
      }
      _verifyModelSpecs();
      print("Model loading attempted.");
    } catch (e) {
      throw Exception("Model Loading Failed: ${e.toString()}");
    }
  }

  void _verifyModelSpecs() {
    print("--- TFLite Model Verification ---");
    try {
      print("Validation Model Input: ${_validationModel?.getInputTensor(0).shape} Type: ${_validationModel?.getInputTensor(0).type}");
      print("Validation Model Output: ${_validationModel?.getOutputTensor(0).shape} Type: ${_validationModel?.getOutputTensor(0).type}");
      print("Classif Model 1 Input: ${_classifModel1?.getInputTensor(0).shape} Type: ${_classifModel1?.getInputTensor(0).type}");
      print("Classif Model 1 Output: ${_classifModel1?.getOutputTensor(0).shape} Type: ${_classifModel1?.getOutputTensor(0).type}");
      print("Classif Model 2 Input: ${_classifModel2?.getInputTensor(0).shape} Type: ${_classifModel2?.getInputTensor(0).type}");
      print("Classif Model 2 Output: ${_classifModel2?.getOutputTensor(0).shape} Type: ${_classifModel2?.getOutputTensor(0).type}");

      if (_gliomaGradeModel != null) {
        print("Glioma Model Input: ${_gliomaGradeModel?.getInputTensor(0).shape} Type: ${_gliomaGradeModel?.getInputTensor(0).type}");
        print("Glioma Model Output: ${_gliomaGradeModel?.getOutputTensor(0).shape} Type: ${_gliomaGradeModel?.getOutputTensor(0).type}");
      } else {
        print("Glioma Model: Not Loaded");
      }

      if (_classifModel1?.getOutputTensor(0).shape.last != kTumorClassLabels.length ||
          _classifModel2?.getOutputTensor(0).shape.last != kTumorClassLabels.length) {
        print("Warning: Classification model output shape mismatch with labels.");
      }
      if (_gliomaGradeModel != null && _gliomaGradeModel?.getOutputTensor(0).shape.last != 1) {
        print("Warning: Glioma grade model output shape is not [?, 1].");
      }
    } catch (e) {
      print("Error during model verification: $e");
    }
    print("--- End TFLite Model Verification ---");
  }

  Future<void> _loadMedicalData() async {
    try {
      final jsonData = await rootBundle.loadString(kTumorDataPath);
      _tumorData = jsonDecode(jsonData);
      print("[DEBUG] _tumorData loaded successfully.");
    } catch (e) {
      throw Exception("Failed to load $kTumorDataPath: ${e.toString()}");
    }
  }

  Future<void> _processMedicalImage() async {
    // 1. Check if ready to process based on current mode and loaded models
    bool canProceed = false;
    String modelErrorMsg = "";
    if (_currentMode == AnalysisMode.tumorClassification) {
      canProceed = _validationModel != null && _classifModel1 != null && _classifModel2 != null;
      if (!canProceed) modelErrorMsg = "Classification models not ready.";
    } else { // Glioma Grading mode
      canProceed = _validationModel != null && _gliomaGradeModel != null;
      if (!canProceed) modelErrorMsg = "Glioma Grade model unavailable.";
    }

    if (_isProcessing || !canProceed) {
      if (!canProceed) {
        setStateIfMounted(() {
          _statusMessage = modelErrorMsg;
          _statusType = StatusType.error;
        });
      }
      print("Cannot process: Processing=$_isProcessing, CanProceed=$canProceed, Mode=$_currentMode");
      return;
    }

    // 2. Pick Image
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    _clearResults();

    // 3. Set UI state to processing
    setStateIfMounted(() {
      _isProcessing = true;
      _selectedImageFile = File(imageFile.path);
      _statusMessage = "Processing Image...";
      _statusType = StatusType.info;
    });

    try {
      // 4. Read and Preprocess Image
      final imageBytes = await _selectedImageFile!.readAsBytes();
      final preprocessedInput = _preprocessImage(imageBytes); // Resize, normalize, format

      // 5. Validate Image (Is it an MRI?)
      setStateIfMounted(() => _statusMessage = "Validating Image as MRI...");
      final isMRI = await _validateMedicalImage(preprocessedInput);

      if (!isMRI) {
        // If not valid MRI, update status, clear results/image, and stop
        setStateIfMounted(() {
          _statusMessage = "Image rejected: Not a valid MRI scan.";
          _statusType = StatusType.error;
        });
        _clearResults();
        _selectedImageFile = null; // Clear image preview
        setStateIfMounted(() => _isProcessing = false);
        return;
      }

      // 6. Perform Analysis based on mode
      bool analysisSuccess = false;
      if (_currentMode == AnalysisMode.tumorClassification) {
        setStateIfMounted(() => _statusMessage = "Running Tumor Classification...");
        await _performEnsembleClassification(preprocessedInput);
        analysisSuccess = _ensemblePrediction != null;
      } else { // Glioma Grading mode
        setStateIfMounted(() => _statusMessage = "Running Glioma Grade Prediction...");
        await _performGliomaGrading(preprocessedInput);
        analysisSuccess = _gliomaGradeResult != null;
      }

      // 7. Save to History (only if analysis succeeded)
      if (analysisSuccess) {
        await _saveScanToHistory(isClassification: _currentMode == AnalysisMode.tumorClassification);
      } else {
        if (_statusType != StatusType.error) { // Avoid overwriting specific errors
          setStateIfMounted(() {
            _statusMessage = "Analysis could not be completed.";
            _statusType = StatusType.error;
          });
        }
      }

    } catch (e, stackTrace) {
      print("[ERROR] Analysis Error: $e");
      print("[ERROR] Stack Trace:\n$stackTrace");
      setStateIfMounted(() {
        _statusMessage = "Analysis Error: Please try again."; // User-friendly error
        _statusType = StatusType.error;
        _clearResults();
        _selectedImageFile = null;
      });
    } finally {
      // 8. Reset processing flag
      setStateIfMounted(() {
        _isProcessing = false;
      });
    }
  }

  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(image, width: kImageSize, height: kImageSize); // Resize

    var input = List.generate(1, (_) =>
        List.generate(kImageSize, (y) =>
            List.generate(kImageSize, (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            }, growable: false),
            growable: false),
        growable: false);
    return input;
  }


  Future<bool> _validateMedicalImage(List<dynamic> input) async {
    if (_validationModel == null) throw Exception("Validation model not initialized.");
    // Expected output shape [1, 1]
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    try {
      _validationModel!.run(input, output);
      final score = output[0][0];
      print("Validation Output Score: $score");
      // Thresholding: Assuming < 0.5 means it IS likely an MRI
      return score < 0.5;
    } catch (e) {
      print("Error running validation model: $e");
      return false; // Assume not valid on error
    }
  }


  Future<void> _performEnsembleClassification(List<List<List<List<double>>>> input) async {
    // --- Runs both classification models and averages their predictions ---
    if (_classifModel1 == null || _classifModel2 == null) {
      throw Exception("Classification models not initialized.");
    }
    final numClasses = kTumorClassLabels.length;
    final outputBuffer1 = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);
    final outputBuffer2 = List.filled(1 * numClasses, 0.0).reshape([1, numClasses]);

    try {
      _classifModel1!.run(input, outputBuffer1);
      _classifModel2!.run(input, outputBuffer2);
    } catch (e) {
      throw Exception("Error running TFLite classification models: $e");
    }

    final probs1 = outputBuffer1[0].cast<double>();
    final probs2 = outputBuffer2[0].cast<double>();

    final avgProbs = List<double>.filled(numClasses, 0.0);
    for (int i = 0; i < numClasses; i++) {
      avgProbs[i] = (probs1[i] + probs2[i]) / 2.0;
    }

    double maxProb = -1.0;
    int maxIndex = -1;
    for (int i = 0; i < avgProbs.length; i++) {
      if (avgProbs[i] > maxProb) {
        maxProb = avgProbs[i];
        maxIndex = i;
      }
    }

    if (maxIndex == -1) {
      throw Exception("Could not determine ensemble prediction.");
    }

    final predictionLabel = kTumorClassLabels[maxIndex];
    final details = _tumorData?[predictionLabel];

    print("[DEBUG] Ensemble Prediction Label: '$predictionLabel'");
    print("[DEBUG] Looked up details: Found? ${details != null}");


    setStateIfMounted(() {
      _ensembleProbs = avgProbs;
      _ensemblePrediction = predictionLabel;
      _diagnosisDetails = details ?? {};
      _statusMessage = "Classification Complete: $predictionLabel";
      _statusType = (predictionLabel.toLowerCase() == 'no tumor') ? StatusType.success : StatusType.warning;
    });
  }


  Future<void> _performGliomaGrading(List<List<List<List<double>>>> input) async {
    if (_gliomaGradeModel == null) {
      throw Exception("Glioma grading model not initialized or failed to load.");
    }

    final outputBuffer = List.filled(1 * 1, 0.0).reshape([1, 1]);

    try {

      _gliomaGradeModel!.run(input, outputBuffer);
    } catch (e) {
      throw Exception("Error running TFLite glioma grading model: $e");
    }


    final probabilityHGG = outputBuffer[0][0];
    print("Raw Glioma TFLite Output (Prob HGG): $probabilityHGG");


    final gradeLabel = (probabilityHGG > 0.5) ? kGliomaGradeLabels[1] : kGliomaGradeLabels[0]; // HGG or LGG

    double calculatedConfidence;
    if (gradeLabel == kGliomaGradeLabels[1]) {
      calculatedConfidence = probabilityHGG;
    } else {
      calculatedConfidence = 1.0 - probabilityHGG;
    }
    print("Predicted Grade: $gradeLabel, Confidence: $calculatedConfidence");


    setStateIfMounted(() {
      _gliomaGradeResult = gradeLabel;
      _predictedGradeConfidence = calculatedConfidence;
      _statusMessage = "Glioma Grade Prediction: $gradeLabel";
      _statusType = StatusType.info;
    });
  }

  Future<void> _saveScanToHistory({required bool isClassification}) async {
    final currentImageFile = _selectedImageFile;
    if (currentImageFile == null) {
      print("[HISTORY] Skipping save: No image selected.");
      return;
    }

    String? diagnosisLabel;
    Map<String, dynamic> reportDetailsMap = {};
    List<double>? probabilitiesToSave;


    if (isClassification) {
      if (_ensemblePrediction == null || _ensembleProbs == null) {
        print("[HISTORY] Skipping save: No classification prediction/probabilities available.");
        return;
      }
      diagnosisLabel = _ensemblePrediction;
      reportDetailsMap = _diagnosisDetails ?? {};
      probabilitiesToSave = _ensembleProbs;
      print("[HISTORY] Preparing to save classification: $diagnosisLabel");
    } else {
      double? rawProbabilityHGG = (_gliomaGradeResult == kGliomaGradeLabels[1])
          ? _predictedGradeConfidence
          : (1.0 - (_predictedGradeConfidence ?? 1.0));
      if (rawProbabilityHGG! > 1.0 || rawProbabilityHGG < 0.0) rawProbabilityHGG = 0.0;


      if (_gliomaGradeResult == null || _predictedGradeConfidence == null) {
        print("[HISTORY] Skipping save: No glioma grade result/confidence available.");
        return;
      }
      diagnosisLabel = _gliomaGradeResult;
      reportDetailsMap = {'grade_prediction': _gliomaGradeResult};
      probabilitiesToSave = [rawProbabilityHGG];
      print("[HISTORY] Preparing to save glioma grade: $diagnosisLabel (Raw P(HGG): ${probabilitiesToSave.first})");
    }

    try {

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFileName = p.basename(currentImageFile.path);
      final safeFileName = "${timestamp}_${originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_')}";
      final savedImagePath = p.join(appDir.path, safeFileName);

      await currentImageFile.copy(savedImagePath);
      print('[HISTORY] Image copied to: $savedImagePath');

      // Create ScanResult object
      final scan = ScanResult(
        timestamp: DateTime.now(),
        imagePath: savedImagePath,
        diagnosis: diagnosisLabel!,
        probabilities: probabilitiesToSave,
        reportDetails: reportDetailsMap,
      );


      await DatabaseHelper().insertScan(scan);
      print("[HISTORY] Scan result saved successfully to database ($diagnosisLabel).");

    } catch (e, stackTrace) {
      print("[ERROR] Error saving scan to history or copying image: $e");
      print("[ERROR] History Save Stack Trace:\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Could not save scan to history.'),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    bool showResults = (_currentMode == AnalysisMode.tumorClassification && _ensemblePrediction != null) ||
        (_currentMode == AnalysisMode.gliomaGrading && _gliomaGradeResult != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(kAppTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: "View Scan History",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: "Settings",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())),
          ),
          const SizedBox(width: 8), // Spacing
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Select Analysis Mode", style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              _buildModeSelector(),
              const SizedBox(height: 24),
              Text("Upload MRI Image", style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              _buildImagePreview(),
              const SizedBox(height: 24),
              _buildUploadButton(),
              const SizedBox(height: 24),
              _buildDiagnosisOutput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    final theme = Theme.of(context);
    return Center(
      child: ToggleButtons(
        isSelected: _selectedMode,
        onPressed: (int index) {
          if (_selectedMode[index] || _isProcessing) return;
          setStateIfMounted(() {
            for (int i = 0; i < _selectedMode.length; i++) {
              _selectedMode[i] = i == index;
            }
            _currentMode = (index == 0) ? AnalysisMode.tumorClassification : AnalysisMode.gliomaGrading;
            _clearResults();
            _statusMessage = "Ready for ${_currentMode == AnalysisMode.tumorClassification ? 'Tumor Classification' : 'Glioma Grading'}";
            _statusType = StatusType.info;
          });
        },
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tumor Type', style: TextStyle(color: _selectedMode[0] ? theme.colorScheme.onPrimary : theme.colorScheme.primary))
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Glioma Grade', style: TextStyle(color: _selectedMode[1] ? theme.colorScheme.onPrimary : theme.colorScheme.primary))
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5), // Light background
          borderRadius: BorderRadius.circular(16),
        ),
        child: _selectedImageFile != null
            ? Image.file(
          _selectedImageFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(theme), // Show error if image fails to load
        )
            : _buildImageUploadPlaceholder(theme),
      ),
    );
  }

  Widget _buildImageUploadPlaceholder(ThemeData theme) {
    return DottedBorder(
      color: theme.colorScheme.primary.withOpacity(0.6),
      strokeWidth: 2,
      dashPattern: const [8, 6],
      borderType: BorderType.RRect,
      radius: const Radius.circular(16),
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 60,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              "Tap to select MRI image",
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.9)
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 8),
          Text(
            "Error loading image",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final theme = Theme.of(context);
    bool canRunClassification = _validationModel != null && _classifModel1 != null && _classifModel2 != null;
    bool canRunGlioma = _validationModel != null && _gliomaGradeModel != null;
    bool isReadyForCurrentMode = (_currentMode == AnalysisMode.tumorClassification && canRunClassification) ||
        (_currentMode == AnalysisMode.gliomaGrading && canRunGlioma);
    bool modelsLoadError = !canRunClassification && !canRunGlioma; // If neither mode is possible
    bool gliomaModelError = _currentMode == AnalysisMode.gliomaGrading && !canRunGlioma; // Specific error for glioma mode

    String buttonText;
    IconData buttonIcon;
    bool enabled = !_isProcessing && isReadyForCurrentMode;

    if (_isProcessing) {
      buttonText = "Analyzing...";
      buttonIcon = Icons.hourglass_empty_rounded;
    } else if (modelsLoadError) {
      buttonText = "Model Loading Error";
      buttonIcon = Icons.error_outline_rounded;
      enabled = false;
    } else if (gliomaModelError) {
      buttonText = "Glioma Model Unavailable";
      buttonIcon = Icons.error_outline_rounded;
      enabled = false;
    } else if (_currentMode == AnalysisMode.tumorClassification) {
      buttonText = "Analyze Tumor Type";
      buttonIcon = Icons.biotech_rounded;
    } else {
      buttonText = "Predict Glioma Grade";
      buttonIcon = Icons.biotech_rounded;
    }

    return ElevatedButton.icon(
      icon: _isProcessing
          ? SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator( strokeWidth: 3, color: theme.colorScheme.onPrimary),
      )
          : Icon(buttonIcon, size: 24),
      label: Text(buttonText),
      onPressed: enabled ? _processMedicalImage : null,
    );
  }

  Widget _buildDiagnosisOutput() {
    final theme = Theme.of(context);
    bool showResults = (_currentMode == AnalysisMode.tumorClassification && _ensemblePrediction != null) ||
        (_currentMode == AnalysisMode.gliomaGrading && _gliomaGradeResult != null);
    bool showStatus = _statusMessage.isNotEmpty && !_isProcessing;
    bool showLoading = _isProcessing && _modelsInitialized; // Show loading only if models are init

    Widget content;

    if (showLoading) {
      content = Container(
          key: const ValueKey('progress'),
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 20),
                Text(_statusMessage, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              ],
            ),
          ));
    } else if (showResults) {
      content = Container(
          key: const ValueKey('results'),
          child: _buildResultContent());
    } else if (showStatus && _statusType != StatusType.info) {
      content = Container(
          key: const ValueKey('status_only'),
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: _buildStatusMessage()
      );
    }
    else {
      content = Container(key: const ValueKey('initial_status'), child: _buildStatusMessage());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(Tween(begin: 0.95, end: 1.0)),
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildResultContent() {
    final theme = Theme.of(context);
    bool hasResults = (_currentMode == AnalysisMode.tumorClassification && _ensemblePrediction != null) ||
        (_currentMode == AnalysisMode.gliomaGrading && _gliomaGradeResult != null);

    return Column(
      key: const ValueKey('result_content_column'),
      children: [
        _buildStatusMessage(),
        const SizedBox(height: 16),
        if (hasResults)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _currentMode == AnalysisMode.tumorClassification
                  ? _buildEnsembleResultDisplay()
                  : _buildGliomaGradeResultDisplay(),
            ),
          )
        else if (!_isProcessing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0),
            child: Text(
              "Analysis results will appear here.",
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildEnsembleResultDisplay() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isNoTumor = _ensemblePrediction?.toLowerCase() == 'no tumor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Tumor Confidence",
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),
        _buildProbabilityChart("Confidence", _ensembleProbs, kTumorClassLabels),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Text(
          "Predicted Condition:",
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
            _ensemblePrediction ?? 'N/A',
            textAlign: TextAlign.center,
            style: textTheme.displaySmall?.copyWith(

              color: isNoTumor ? Colors.green.shade700 : theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            )
        ),
        const SizedBox(height: 24),


        if (_diagnosisDetails != null && _diagnosisDetails!.isNotEmpty && !isNoTumor)
          ReportDisplayWidget(
              diagnosisDetails: _diagnosisDetails!,
              title: "Details:"
          ),

        if (isNoTumor)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 2),
                Text(
                  "No tumor detected based on analysis.",
                  style: textTheme.bodyLarge?.copyWith(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildGliomaGradeResultDisplay() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          "Glioma Grade Prediction:",
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Text(
          _gliomaGradeResult ?? 'N/A',
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Confidence Score:",
          textAlign: TextAlign.center,
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          _predictedGradeConfidence != null
              ? "${(_predictedGradeConfidence! * 100).toStringAsFixed(1)}%"
              : "N/A",
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600
          ),
        ),
        const SizedBox(height: 24),
        const Divider(), // Separator
        // Disclaimer text
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            "Disclaimer: This prediction (LGG/HGG) is based on the provided image analysis and requires confirmation through comprehensive clinical evaluation and histopathology.",
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildProbabilityChart(String title, List<double>? probabilities, List<String> labels) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final List<Color> currentBarColors = (_barColors.isNotEmpty)
        ? _barColors
        : List.generate(labels.length, (i) => theme.colorScheme.primary.withOpacity(max(0.3, 1.0 - i * 0.1)));


    if (probabilities == null || probabilities.isEmpty || probabilities.length != labels.length) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          "Confidence scores unavailable",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    int maxProbIndex = 0;
    double maxProbValue = -1.0;
    for(int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProbValue) {
        maxProbValue = probabilities[i];
        maxProbIndex = i;
      }
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          minY: 0.0,
          // --- Grid Lines ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline!.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false), // Hide chart border
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide left axis numbers
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top axis titles
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right axis numbers
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    String shortLabel = labels[index];
                    if (shortLabel.toLowerCase() == "meningioma") shortLabel = "Mening.";
                    else if (shortLabel.toLowerCase() == "pituitary") shortLabel = "Pituit.";
                    else if (shortLabel.toLowerCase() == "no tumor") shortLabel = "No Tumor";
                    else if (shortLabel.length > 7) shortLabel = "${shortLabel.substring(0, 6)}.";

                    final isMaxProb = index == maxProbIndex;
                    final labelStyle = textTheme.labelSmall?.copyWith(
                      fontWeight: isMaxProb ? FontWeight.bold : FontWeight.w500,
                      color: isMaxProb ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                    );

                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6.0,
                      child: Text(shortLabel, style: labelStyle, textAlign: TextAlign.center),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          barGroups: List.generate(labels.length, (index) {
            final isMaxProb = index == maxProbIndex;
            final barColor = currentBarColors[index % currentBarColors.length];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: probabilities[index],
                  color: isMaxProb ? barColor : barColor.withOpacity(0.6),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  gradient: LinearGradient(
                    colors: [
                      barColor.withOpacity(isMaxProb ? 0.7 : 0.5),
                      barColor.withOpacity(isMaxProb ? 1.0 : 0.8),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.85),
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String label = labels[group.x.toInt()];
                String value = (rod.toY * 100).toStringAsFixed(1);
                return BarTooltipItem(
                  '$label\n', // Label on first line
                  textTheme.bodyMedium!.copyWith( color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$value%',
                      style: textTheme.bodyMedium!.copyWith( color: Colors.yellowAccent.shade400, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final theme = Theme.of(context);
    IconData statusIcon;
    Color statusColor;
    Color backgroundColor;
    Color borderColor;

    switch (_statusType) {
      case StatusType.info:
        statusIcon = Icons.info_outline_rounded;
        statusColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.surfaceVariant;
        borderColor = theme.colorScheme.primary.withOpacity(0.3);
        break;
      case StatusType.success:
        statusIcon = Icons.check_circle_outline_rounded;
        statusColor = Colors.green.shade700;
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        break;
      case StatusType.warning:
        statusIcon = Icons.warning_amber_rounded;
        statusColor = Colors.orange.shade800;
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        break;
      case StatusType.error:
        statusIcon = Icons.error_outline_rounded;
        statusColor = theme.colorScheme.error;
        backgroundColor = theme.colorScheme.error.withOpacity(0.1);
        borderColor = theme.colorScheme.error.withOpacity(0.4);
        break;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        key: ValueKey(_statusMessage + _statusType.toString()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.start,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearResults() {
    setStateIfMounted(() {
      _diagnosisDetails = null;
      _ensemblePrediction = null;
      _ensembleProbs = null;
      _gliomaGradeResult = null;
      _predictedGradeConfidence = null; // Reset predicted confidence
    });
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}