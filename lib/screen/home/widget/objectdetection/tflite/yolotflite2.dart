import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/tflite/stats.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class CameraView extends StatefulWidget {
  /// Callback to pass results after inference to [HomeView]
  final Function(List<Recognition> recognitions) resultsCallback;

  /// Callback to inference stats to [HomeView]
  final Function(Stats stats) statsCallback;

  /// Constructor
  const CameraView(this.resultsCallback, this.statsCallback);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with WidgetsBindingObserver {
  /// List of available cameras
  List<CameraDescription> cameras;

  /// Controller
  CameraController cameraController;

  /// true when inference is ongoing
  bool predicting;

  /// Instance of [Classifier]
  Classifier classifier;

  /// Instance of [IsolateUtils]
  IsolateUtils isolateUtils;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    WidgetsBinding.instance.addObserver(this);

    // Spawn a new isolate
    isolateUtils = IsolateUtils();
    await isolateUtils.start();

    // Camera initialization
    initializeCamera();

    // Create an instance of classifier to load model and labels
    classifier = Classifier();

    // Initially predicting = false
    predicting = false;
  }

  /// Initializes the camera by setting [cameraController]
  void initializeCamera() async {
    cameras = await availableCameras();

    // cameras[0] for rear-camera
    cameraController =
        CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

    cameraController.initialize().then((_) async {
      // Stream of image passed to [onLatestImageAvailable] callback
      await cameraController.startImageStream(onLatestImageAvailable);

      /// previewSize is size of each image frame captured by controller
      ///
      /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
      Size previewSize = cameraController.value.previewSize;

      /// previewSize is size of raw input image to the model
      CameraViewSingleton.inputImageSize = previewSize;

      // the display width of image on screen is
      // same as screenWidth while maintaining the aspectRatio
      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio = screenSize.width / previewSize.height;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return e
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    }

// AspectRatio widget maintains the aspect ratio of its child widget
    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }

  /// Callback function which will be called for every new image frame.
  ///
  /// This function will call [predictImage] if [predicting] is false.
  void onLatestImageAvailable(CameraImage cameraImage) async {
    if (!predicting) {
      predicting = true;
      Stats stats = Stats();
      // Process image in a new isolate
      List<dynamic> result = await isolateUtils.processImage(
          cameraImage, cameraController.description.sensorOrientation);

      List<Recognition> recognitions = result[0];
      List<dynamic> predictorStats = result[1];

      stats.add("Preprocessing", predictorStats[0]);
      stats.add("Inference", predictorStats[1]);

      widget.resultsCallback(recognitions);
      widget.statsCallback(stats);

      predicting = false;
    }
  }

  @override
  void dispose() {
// Stop image stream
    cameraController?.stopImageStream();
    // Dispose controller and isolate
    cameraController?.dispose();
    isolateUtils?.stop();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Singleton class to hold variables
class CameraViewSingleton {
  static Size inputImageSize;
  static Size screenSize;
  static double ratio;
}
/// Callback function which takes in a [CameraImage] and performs inference on it.
///
/// Returns a [List] containing [List] of [Recognition] and [List] of inference stats.
///
/// [CameraImage] is passed to [runInference] function of [Classifier]
Future<List<dynamic>> predictImage(
    CameraImage cameraImage, int sensorOrientation) async {
// Preprocessing
  TensorImage tensorImage = TensorImage.fromCameraImage(cameraImage);
  ImageProcessor imageProcessor =
  ImageProcessorBuilder().add(ResizeOp(320, 320, ResizeMethod.BILINEAR))
      .build();

  tensorImage = imageProcessor.process(tensorImage);
  TensorBuffer buffer = tensorImage.getBuffer();

// Inference
  List<Recognition> recognitions =
  await classifier.classifyImage(buffer, sensorOrientation);

// Return results and inference stats
  return [recognitions, classifier.stats];
}

/// Helper class to handle starting and stopping of isolates
class IsolateUtils {
  Isolate _isolate;
  ReceivePort _receivePort;

  /// Start isolate
  Future<void> start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
  }

  /// Stop isolate
  void stop() {
    _isolate?.kill();
    _isolate = null;
  }

  /// Process image in isolate
  Future<List<dynamic>> processImage(
      CameraImage cameraImage, int sensorOrientation) async {
// Send message to isolate
    _receivePort.send([cameraImage, sensorOrientation]);
    // Wait for response from isolate
    List<dynamic> result = await _receivePort.first;

    return result;
  }

  /// Entry point for isolate
  static void _isolateEntry(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    Classifier classifier;

    receivePort.listen((message) async {
      // Extract image and sensorOrientation from message
      CameraImage cameraImage = message[0];
      int sensorOrientation = message[1];

      // Initialize classifier
      if (classifier == null) {
        classifier = Classifier();
        await classifier.loadModel();
      }

      // Perform inference on image
      List<dynamic> result =
      await predictImage(cameraImage, sensorOrientation, classifier);

      // Send results back to main isolate
      sendPort.send(result);
    });
  }}
/// Helper class to handle loading and running of TensorFlow Lite model
class Classifier {
  Interpreter _interpreter;
  List<String> _labels;
  List<double> _stats = [];

  /// Load model and labels
  Future<void> loadModel() async {
    try {
// Load model
      var interpreterOptions = InterpreterOptions();
      _interpreter = Interpreter.fromAsset('model.tflite', options: interpreterOptions);
      // Load labels
      String labels = await rootBundle.loadString('assets/labels.txt');
      _labels = labels.trim().split('\n');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  /// Perform inference on input buffer
  Future<List<Recognition>> classifyImage(TensorBuffer inputBuffer, int sensorOrientation) async {
    try {
// Get input shape
      List<int> inputShape = _interpreter.getInputTensor(0).shape;
      // Create output buffer
      var outputBuffer = TensorBuffer.createFixedSize(
          inputShape.sublist(0, inputShape.length - 1)..add(_labels.length),
          DataType.FLOAT32);

      // Run inference
      var startTime = DateTime.now().millisecondsSinceEpoch;
      _interpreter.runForMultipleInputs([inputBuffer], {0: [0, sensorOrientation]}, [outputBuffer.buffer]);
      var endTime = DateTime.now().millisecondsSinceEpoch;

      // Calculate inference stats
      double preprocessTime = inputBuffer.stats.preprocessTime.toDouble() / 1000000.0;
      double inferenceTime = (endTime - startTime - inputBuffer.stats.preprocessTime) / 1000.0;
      _stats = [preprocessTime, inferenceTime];

      // Get results from output buffer
      List<Recognition> recognitions = getRecognitions(outputBuffer.getDoubleList());

      return recognitions;
    } catch (e) {
      print('Error running inference: $e');
      return [];
    }
  }

  /// Convert output buffer to a list of Recognitions
  List<Recognition> getRecognitions(List<double> output) {
    List<Recognition> recognitions = [];
    for (int i = 0; i < output.length; i++) {
      String label = _labels[i];
      double confidence = output[i];

      if (confidence > 0.5) {
        recognitions.add(Recognition(label, confidence));
      }
    }

    return recognitions;
  }

  /// Get inference stats
  List<double> get stats => _stats;
}

/// Class to represent a recognition result
class Recognition {
  final String label;
  final double confidence;

  Recognition(this.label, this.confidence);
}
















