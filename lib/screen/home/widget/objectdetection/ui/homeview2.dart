import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';


// Classifier class
class Classifier {
  Interpreter _interpreter;
  List<String> _labels;
  TensorImage _inputImage;
  TensorBuffer _outputBuffer;
  TensorProcessor _outputProcessor;
  int _inputImageWidth;
  int _inputImageHeight;

  // static const String MODEL_FILE_NAME = 'assets/yolov5.tflite';
  // static const String LABEL_FILE_NAME = 'assets/labelmap2.txt';
   static const String MODEL_FILE_NAME = 'assets/yolov2_tiny.tflite';
   static const String LABEL_FILE_NAME = 'assets/yolov2_tiny.txt';

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(MODEL_FILE_NAME);
      _labels = await FileUtil.loadLabels(LABEL_FILE_NAME);
      _inputImageWidth = _interpreter.getInputTensor(0).shape[2];
      _inputImageHeight = _interpreter.getInputTensor(0).shape[1];
      // _inputImage =
      //     TensorImage.fromEmpty([1, _inputImageHeight, _inputImageWidth, 3]);
      _inputImage = TensorImage();
      _outputBuffer = TensorBuffer.createFixedSize(
          _interpreter.getOutputTensor(0).shape, TfLiteType.float32);
      _outputProcessor = TensorProcessorBuilder().build();

    } catch (e) {
      print('Error while initializing the classifier: $e');
    }
  }
  List<Recognition> _postprocessOutput(TensorBuffer outputBuffer) {
    final numClasses = _labels.length;
    final gridSize = 16;
    final boxesPerCell = 3;
    final numCoords = 4;
    final numElementsPerBox = numClasses + numCoords + 1;
    final outputHeight = _inputImageHeight ~/ gridSize;
    final outputWidth = _inputImageWidth ~/ gridSize;
    final numBoxes = outputHeight * outputWidth * boxesPerCell;
    final outputList = outputBuffer.getDoubleList();
    final recognitions = <Recognition>[];

    for (var i = 0; i < numBoxes; i++) {
      final offset = i * numElementsPerBox;
      final confidence = outputList[offset + 4];

      if (confidence < 0.5) {
        continue;
      }

      final xPos = outputList[offset];
      final yPos = outputList[offset + 1];
      final width = outputList[offset + 2];
      final height = outputList[offset + 3];

      final x = xPos * gridSize;
      final y = yPos * gridSize;
      final w = math.exp(width) * gridSize * 4;
      final h = math.exp(height) * gridSize * 4;

      final left = (x - w / 2).truncate().clamp(0.0, _inputImageWidth.toInt());
      final top = (y - h / 2).truncate().clamp(0.0, _inputImageHeight.toInt());
      final right = (x + w / 2).truncate().clamp(0.0, _inputImageWidth.toInt());
      final bottom = (y + h / 2).truncate().clamp(0.0, _inputImageHeight.toInt());


      final rect = Rect.fromLTRB(left, top, right, bottom);

      final classProbabilities = outputList.sublist(offset + 5, offset + numElementsPerBox);
      final maxClassProbability = classProbabilities.reduce(math.max);
      final classId = classProbabilities.indexOf(maxClassProbability);

      final label = _labels[classId];

      recognitions.add(Recognition(label, confidence, rect));
    }

    return recognitions;
  }

  Future<List<Recognition>> predict(CameraImage image) async {
    try {
      // Preprocess the image
      // TensorImageUtil.imageToTensorImage(image, _inputImage);
      // _inputImage = TensorImageUtil.normalize(_inputImage, 0, 255);
      // Preprocess the image
      _inputImage.buffer.asUint8List()
          .addAll(image.planes[0].bytes);
      // Run inference
      _interpreter.run(_inputImage.buffer, _outputBuffer.buffer);
      // Postprocess the output
      List<Recognition> recognitions = _postprocessOutput(
        _outputBuffer);
      return recognitions;
    } catch (e) {
      print('Error while performing inference: $e');
      return [];
    }
  }

  void close() {
    _interpreter.close();
  }
}

// Recognition class
class Recognition {
  final String label;
  final double confidence;
  final Rect rect;

  Recognition(this.label, this.confidence, this.rect);
}

// Stats class
class Stats {
  int inferenceTime;
  int preProcessingTime;
  int totalElapsedTime;

  Stats({
    this.inferenceTime = 0,
    this.preProcessingTime = 0,
    this.totalElapsedTime = 0,
  });
}

// BoxWidget class
class BoxWidget extends StatelessWidget {
  final Rect boundingBox;
  final String label;
  final double confidence;
  final Size imageSize;

  BoxWidget({
    this.boundingBox,
    this.label,
    this.confidence,
    this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: boundingBox.left * imageSize.width,
      top: boundingBox.top * imageSize.height,
      width: boundingBox.width * imageSize.width,
      height: boundingBox.height * imageSize.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(confidence.toStringAsFixed(2))}%',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CameraView class
class CameraView extends StatefulWidget {
  final Classifier classifier;
  final Stats stats;

  CameraView({
     this.classifier,
     this.stats,
  });

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
   CameraController _cameraController;
   bool _isInitialized;
   int _cameraImageHeight;
   int _cameraImageWidth;
   Stopwatch stopwatch;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch()..start();
    _isInitialized = false;
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.high,imageFormatGroup: ImageFormatGroup.bgra8888);
    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialized = true;
        _cameraImageHeight = _cameraController.value.previewSize.height as int;
        _cameraImageWidth = _cameraController.value.previewSize.width as int;
      });
      _cameraController.startImageStream((CameraImage image) async {
        final stopwatch = Stopwatch()..start();
        final recognitions = await widget.classifier.predict(image);
        stopwatch.stop();
        widget.stats.inferenceTime = stopwatch.elapsedMilliseconds;
        setState(() {
          _cameraImageHeight = image.height;
          _cameraImageWidth = image.width;
        });
        _showInferenceResults(recognitions);
      });
    });
  }

  void _showInferenceResults(List<Recognition> recognitions) {
    widget.stats.inferenceTime = stopwatch.elapsedMilliseconds;
    setState(() {
      recognitions.forEach((recognition) {
        final boxWidget = BoxWidget(
          boundingBox: recognition.rect,
          label: recognition.label,
          confidence: recognition.confidence.toDouble(),
          imageSize: Size(_cameraImageWidth as double, _cameraImageHeight as double),
        );
        // Add the widget to the overlay
        Overlay.of(context).insert(boxWidget as OverlayEntry);
      });
    });

  }


  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container();
    }
    return AspectRatio(
      aspectRatio: _cameraController.value.aspectRatio,
      child: CameraPreview(_cameraController),
    );
  }
}

// CameraViewSingleton class
class CameraViewSingleton {
  static final CameraViewSingleton _cameraViewSingleton =
  CameraViewSingleton._internal();
   Classifier _classifier;
   Stats _stats;

  factory CameraViewSingleton() {
    return _cameraViewSingleton;
  }

  CameraViewSingleton._internal() {
    _classifier = Classifier();
    _stats = Stats();
    _initialize();
  }

  void _initialize() async {
    await _classifier.loadModel();
  }

  Widget getCameraView() {
    return CameraView(
      classifier: _classifier,
      stats: _stats,
    );
  }

  Stats getStats() {
    return _stats;
  }

  void close() {
    _classifier.close();
  }
}

// HomeView class
class HomeView2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CameraViewSingleton cameraViewSingleton = CameraViewSingleton();
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Object Detection'),
      ),
      body: Stack(
        children: [
          cameraViewSingleton.getCameraView(),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inference Time: ${cameraViewSingleton.getStats().inferenceTime} ms'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}