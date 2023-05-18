import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier2 {
  Interpreter interpreter;
  List<String> labels;

  // Future<void> loadModel() async {
  //   try {
  //     final modelFile = await loadModelFile('assets/yolov5.tflite');
  //     final labelsFile = await loadLabelsFile('assets/labelmap.txt');
  //     interpreter = Interpreter.fromBuffer(modelFile);
  //     labels = await labelsFile.readAsLines();
  //     print('Model loaded successfully');
  //   } on Exception catch (e) {
  //     print('Failed to load model: $e');
  //   }
  // }
  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions()..threads = 4;
      final modelFile = await rootBundle.load('assets/yolov5.tflite');
      interpreter = await Interpreter.fromBuffer(modelFile.buffer.asUint8List(), options: interpreterOptions);
      print('Model loaded successfully');
    } on Exception catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> loadLabels() async {
    try {
      final labelsFile = await rootBundle.loadString('assets/labelmap.txt');
      labels = LineSplitter().convert(labelsFile);
      print('Labels loaded successfully');
    } on Exception catch (e) {
      print('Failed to load labels: $e');
    }
  }

  Future<List<Recognition>> predict(CameraImage image) async {
    if (interpreter == null || labels == null) {
      throw Exception('Model not loaded');
    }

    TensorImage tensorImage = TensorImage.fromImage(image);
    ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(416, 416, ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255))
        .build();
    tensorImage = imageProcessor.process(tensorImage);
    TensorBuffer outputBuffer = TensorBufferFloat32.fromShape([1, 52, 52, 3 * (5 + labels.length)]);
    interpreter.run(tensorImage.buffer, outputBuffer.buffer);

    List<Recognition> recognitions = [];
    for (var i = 0; i < 3; i++) {
      var boxes = decodeOutput(outputBuffer, i, labels.length);
      for (var box in boxes) {
        var rect = Rect.fromLTRB(
          box.xMin * image.width,
          box.yMin * image.height,
          box.xMax * image.width,
          box.yMax * image.height,
        );
        recognitions.add(
          Recognition(
            id: recognitions.length,
            label: labels[box.label],
            score: box.score,
            location: rect,
          ),
        );
      }
    }
    return recognitions;
  }

  void close() {
    if (interpreter != null) {
      interpreter.close();
    }
  }
}

class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) resultsCallback;
  final Function(Stats stats) statsCallback;

  const CameraView(this.resultsCallback, this.statsCallback);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  List<CameraDescription> cameras;
  CameraController cameraController;
  bool isDetecting = false;
  Classifier2 classifier = Classifier2();
  Stats stats = Stats();
  Timer timer;

  @override
  void initState() {
    super.initState();
    classifier.loadModel().then((_) {
      initializeCamera();
    });
    WidgetsBindinginstance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    classifier.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initializeCamera();
    } else if (state == AppLifecycleState.paused) {
      cameraController?.dispose();
      timer?.cancel();
    }
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    try {
      await cameraController.initialize();
      cameraController.startImageStream((image) {
        if (!isDetecting) {
          isDetecting = true;
          classifyImage(image);
        }
      });
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        widget.statsCallback(stats);
        stats = Stats();
      });
    } on CameraException catch (e) {
      print(e);
    }
  }

  Future<void> classifyImage(CameraImage image) async {
    try {
      List<Recognition> recognitions = await classifier.predict(image);
      widget.resultsCallback(recognitions);
      isDetecting = false;
      stats.totalFrames++;
    } on Exception catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    }
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return OverflowBox(
      maxHeight: deviceRatio > 1 ? size.width : size.height / deviceRatio,
      maxWidth: deviceRatio > 1 ? size.width * deviceRatio : size.height,
      child: CameraPreview(cameraController),
    );
  }
}

class Recognition {
  final int id;
  final String label;
  final double score;
  final Rect location;

  Recognition({this.id, this.label, this.score, this.location});

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}

class Stats {
  int totalFrames = 0;
  int framesPerSecond = 0;
  DateTime timestamp = DateTime.now();

  void calculateFPS() {
    final now = DateTime.now();
    final difference = now.difference(timestamp).inMilliseconds;
    framesPerSecond = (totalFrames / (difference / 1000)).round();
  }

  @override
  String toString() {
    return 'Stats(totalFrames: $totalFrames, framesPerSecond: $framesPerSecond)';
  }
}

class BoundingBox {
  final int label;
  final double score;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  BoundingBox({
    this.label,
    this.score,
    this.xMin,
    this.yMin,
    this.xMax,
    this.yMax,
  });

  @override
  String toString() {
    return 'BoundingBox(label: $label, score: $score, xMin: $xMin, yMin: $yMin, xMax: $xMax, yMax: $yMax)';
  }
}

List<BoundingBox> decodeOutput(TensorBuffer outputBuffer, int anchorIndex, int numClasses) {
  List<BoundingBox> boxes = [];
  List<double> anchors = getAnchors(anchorIndex);
  int gridSize = outputBuffer.shape[1];
  int numAnchors = anchors.length ~/ 2;

  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      for (int k = 0; k < numAnchors; k++) {
        double boxScore = outputBuffer.getDoubleList([0, i, j, k, 4]);
        if (boxScore > detectionThreshold) {
          double x = outputBuffer.getDoubleList([0, i, j, k, 0]);
          double y = outputBuffer.getDoubleList([0, i, j, k, 1]);
          double width = outputBuffer.getDoubleList([0, i, j, k, 2]);
          double height = outputBuffer.getDoubleList([0, i, j, k, 3]);
          double centerX = j + x;
          double centerY = i + y;

          double anchorWidth = anchors[k * 2];
          double anchorHeight = anchors[k * 2 + 1];

          double scaledWidth = width * anchorWidth;
          double scaledHeight = height * anchorHeight;

          double left = centerX - scaledWidth / 2;
          double top = centerY - scaledHeight / 2;
          double right = centerX + scaledWidth / 2;
          double bottom = centerY + scaledHeight / 2;

          // clip bounding box coordinates to image size
          left = max(0.0, left);
          top = max(0.0, top);
          right = min(gridSize.toDouble() - 1.0, right);
          bottom = min(gridSize.toDouble() - 1.0, bottom);

          int labelIndex = 5;
          double maxScore = outputBuffer.getDoubleList([0, i, j, k, labelIndex]);
          int label = 0;
          for (int l = 1; l < numClasses; l++) {
            double currentScore = outputBuffer.getDoubleList([0, i, j, k, labelIndex + l]);
            if (currentScore > maxScore) {
              maxScore = currentScore;
              label = l;
            }
          }

          BoundingBox box = BoundingBox(
            label: label,
            score: maxScore,
            xMin: left / gridSize,
            yMin: top / gridSize,
            xMax: right / gridSize,
            yMax: bottom / gridSize,
          );

          boxes.add(box);
        }
      }}
  }

  return boxes;
}

List<double> getAnchors(int anchorIndex) {
  switch (anchorIndex) {
    case 0:
      return anchors0;
    case 1:
      return anchors1;
    case 2:
      return anchors2;
    default:
      throw ArgumentError('Invalid anchor index: $anchorIndex');
  }
}

const anchors0 = [
  0.57273,
  0.677385,
  1.87446,
  2.06253,
  3.33843,
  5.47434,
  7.88282,
  3.52778,
  9.77052,
  9.16828,
];

const anchors1 = [
  1.07794,
  1.78188,
  2.71042,
  5.12484,
  8.09892,
  9.65916,
];

const anchors2 = [
  3.68625,
  2.16375,
  4.84053,
  6.11653,
  11.6983,
  10.8294,
];





