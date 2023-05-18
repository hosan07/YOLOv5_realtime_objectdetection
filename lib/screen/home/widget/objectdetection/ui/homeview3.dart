import 'dart:ffi';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:io' ;
import 'dart:isolate';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';



/// Individual bounding box
class BoxWidget extends StatelessWidget {

  final Recognition result;

  const BoxWidget({Key key, this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color = Colors.primaries[
    (result.label.length + result.label.codeUnitAt(0) + result.id) %
        Colors.primaries.length];

    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        width: result.renderLocation.width,
        height: result.renderLocation.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" " + result.score.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);

    // Camera initialization
    initializeCamera();

    // Create an instance of classifier to load model and labels
    classifier = Classifier();

    // Initially predicting = false
    predicting = false;

    // Spawn a new isolate
    isolateUtils = IsolateUtils();
    isolateUtils.start();
  }

  /// Initializes the camera by setting [cameraController]
  void initializeCamera() async {
    cameras = await availableCameras();

    // cameras[0] for rear-camera
    cameraController = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);

    cameraController.initialize().then((_) async {
      // Stream of image passed to [onLatestImageAvailable] callback
      await cameraController.startImageStream(onLatestImageAvailable);

      /// previewSize is size of each image frame captured by controller
      ///
      /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
      ffi.Size previewSize = cameraController.value.previewSize;


      /// previewSize is size of raw input image to the model
      CameraViewSingleton.inputImageSize = previewSize;

      // the display width of image on screen is
      // same as screenWidth while maintaining the aspectRatio
      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;

      if (Platform.isAndroid) {
        // On Android Platform image is initially rotated by 90 degrees
        // due to the Flutter Camera plugin
        CameraViewSingleton.ratio = screenSize.width / previewSize.height;
      } else {
        // For iOS
        CameraViewSingleton.ratio = screenSize.width / previewSize.width;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
        aspectRatio: cameraController.value.aspectRatio,
        child: CameraPreview(cameraController));
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    if (classifier.interpreter != null && classifier.labels != null) {
      // If previous inference has not completed then return
      if (predicting) {
        return;
      }
      setState(() {
        predicting = true;
      });

      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      // Data to be passed to inference isolate
      var isolateData = IsolateData(
          cameraImage, classifier.interpreter.address, classifier.labels);

      // We could have simply used the compute method as well however
      // it would be as in-efficient as we need to continuously passing data
      // to another isolate.

      /// perform inference in separate isolate
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to HomeView
      widget.resultsCallback(inferenceResults["recognitions"]);

      // pass stats to HomeView
      widget.statsCallback((inferenceResults["stats"] as Stats)
        ..totalElapsedTime = uiThreadInferenceElapsedTime);
      //widget.imageCallback(inferenceResults["image"]);

      // set predicting to false to allow new frames
      setState(() {
        predicting = false;
      });
    }
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        await cameraController.startImageStream(onLatestImageAvailable);
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }
}

class CameraViewSingleton {
  static double ratio;
  static Size screenSize;
  static Size inputImageSize;
  static Size get actualPreviewSize =>
      Size(screenSize.width, screenSize.width * ratio);
}


class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<Recognition> results;

  /// Realtime stats
  Stats stats;

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Camera View
          CameraView(resultsCallback, statsCallback),
          // Bounding boxes
          boundingBoxes(results),

          // Heading
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'Object Detection Flutter',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent.withOpacity(0.6),
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (_, ScrollController scrollController) => Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BORDER_RADIUS_BOTTOM_SHEET),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up,
                            size: 48, color: Colors.orange),
                        (stats != null)
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              StatsRow('Inference time:',
                                  '${stats.inferenceTime} ms'),
                              StatsRow('Total prediction time:',
                                  '${stats.totalElapsedTime} ms'),
                              StatsRow('Pre-processing time:',
                                  '${stats.preProcessingTime} ms'),
                              StatsRow('Frame',
                                  '${CameraViewSingleton.inputImageSize?.width} X ${CameraViewSingleton.inputImageSize?.height}'),
                            ],
                          ),
                        )
                            : Container()
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
        result: e,
      ))
          .toList(),
    );
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
    });
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  StatsRow(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}

class ImageUtils {
  static Future<List<int>> convertImagetoPng(CameraImage image) async {
    try {
      imageLib.Image img;
      if (image.format.group == ImageFormatGroup.yuv420) {
        img = _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        img = _convertBGRA8888(image);
      }

      imageLib.PngEncoder pngEncoder = new imageLib.PngEncoder();

      // Convert to png
      List<int> png = pngEncoder.encodeImage(img);
      return png;
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
  }

  // CameraImage BGRA8888 -> PNG
  // Color
  static imageLib.Image _convertBGRA8888(CameraImage image) {
    return imageLib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imageLib.Format.bgra,
    );
  }

  // CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
  // Black
  static imageLib.Image _convertYUV420(CameraImage image) {
    var img = imageLib.Image(image.width, image.height); // Create Image buffer

    Plane plane = image.planes[0];
    const int shift = (0xFF << 24);

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < image.width; x++) {
      for (int planeOffset = 0;
      planeOffset < image.height * image.width;
      planeOffset += image.width) {
        final pixelColor = plane.bytes[planeOffset + x];
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        // Calculate pixel color
        var newVal =
        shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

        img.data[planeOffset + x] = newVal;
      }
    }

    return img;
  }

  static void saveImage(imageLib.Image image, [String i = "0"]) async {
    List<int> jpeg = imageLib.JpegEncoder().encodeImage(image);
    final appDir = await getExternalStorageDirectory();
    final appPath = appDir.path;
    final fileOnDevice = File('$appPath/out$i.jpg');
    await fileOnDevice.writeAsBytes(jpeg, flush: true);
    print('Saved $appPath/out$i.jpg');
  }
}


typedef convert_func = Pointer<Uint32> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int);

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  // ignore: unused_field
  Isolate _isolate;
  ReceivePort _receivePort = ReceivePort();
  SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  void start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    final DynamicLibrary convertImageLib = Platform.isAndroid
        ? DynamicLibrary.open("libconvertImage.so")
        : DynamicLibrary.process();
    // Load the convertImage() function from the library
    Convert conv = convertImageLib
        .lookup<NativeFunction<convert_func>>('convertImage')
        .asFunction<Convert>();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      if (isolateData != null) {
        Classifier classifier = Classifier(
            interpreter:
            Interpreter.fromAddress(isolateData.interpreterAddress),
            labels: isolateData.labels);
        //imageLib.Image image =
        //   ImageUtils.convertImagetoPng(isolateData.cameraImage);
        imageLib.Image image;
        if (Platform.isAndroid) {
          // Allocate memory for the 3 planes of the image
          Pointer<Uint8> p =
          allocate(count: isolateData.cameraImage.planes[0].bytes.length);
          Pointer<Uint8> p1 =
          allocate(count: isolateData.cameraImage.planes[1].bytes.length);
          Pointer<Uint8> p2 =
          allocate(count: isolateData.cameraImage.planes[2].bytes.length);

          // Assign the planes data to the pointers of the image
          Uint8List pointerList =
          p.asTypedList(isolateData.cameraImage.planes[0].bytes.length);
          Uint8List pointerList1 =
          p1.asTypedList(isolateData.cameraImage.planes[1].bytes.length);
          Uint8List pointerList2 =
          p2.asTypedList(isolateData.cameraImage.planes[2].bytes.length);
          pointerList.setRange(
              0,
              isolateData.cameraImage.planes[0].bytes.length,
              isolateData.cameraImage.planes[0].bytes);
          pointerList1.setRange(
              0,
              isolateData.cameraImage.planes[1].bytes.length,
              isolateData.cameraImage.planes[1].bytes);
          pointerList2.setRange(
              0,
              isolateData.cameraImage.planes[2].bytes.length,
              isolateData.cameraImage.planes[2].bytes);

          // Call the convertImage function and convert the YUV to RGB
          Pointer<Uint32> imgP = conv(
              p,
              p1,
              p2,
              isolateData.cameraImage.planes[1].bytesPerRow,
              isolateData.cameraImage.planes[1].bytesPerPixel,
              isolateData.cameraImage.planes[0].bytesPerRow,
              isolateData.cameraImage.height);

          // Get the pointer of the data returned from the function to a List
          List imgData = imgP.asTypedList(
              (isolateData.cameraImage.planes[0].bytesPerRow *
                  isolateData.cameraImage.height));
          // Generate image from the converted data
          image = imageLib.Image.fromBytes(isolateData.cameraImage.height,
              isolateData.cameraImage.width, imgData);

          // Free the memory space allocated
          // from the planes and the converted data
          free(p);
          free(p1);
          free(p2);
          free(imgP);
        } else if (Platform.isIOS) {
          image = imageLib.Image.fromBytes(
            isolateData.cameraImage.planes[0].bytesPerRow,
            isolateData.cameraImage.height,
            isolateData.cameraImage.planes[0].bytes,
            format: imageLib.Format.bgra,
          );
        }
        Map<String, dynamic> results = classifier.predict(image);

        isolateData.responsePort.send(results);
      }
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  List<String> labels;
  SendPort responsePort;

  IsolateData(
      this.cameraImage,
      this.interpreterAddress,
      this.labels,
      );
}

/// Classifier
class Classifier {
  /// Instance of Interpreter
  Interpreter _interpreter;

  //Interpreter Options (Settings)
  final int numThreads = 4;
  final bool isNNAPI = false;
  final bool isGPU = true;

  /// Labels file loaded as list
  List<String> _labels;

  static const String MODEL_FILE_NAME = "yolov4-416-fp32.tflite";
  static const String LABEL_FILE_NAME = "coco.txt";

  /// Input size of image (heixght = width = 300)
  static const int INPUT_SIZE = 416;

  /// Confidence Probabilty score threshold
  static const double THRESHOLD = 0.5;

  /// Non-maximum suppression threshold
  static double mNmsThresh = 0.6;

  /// [ImageProcessor] used to pre-process the image
  ImageProcessor imageProcessor;

  /// Padding the image to transform into square
  int padSize;

  /// Shapes of output tensors
  List<List<int>> _outputShapes;

  /// Types of output tensors
  List<TfLiteType> _outputTypes;

  /// Number of results to show
  static const int NUM_RESULTS = 10;

  Classifier({
    Interpreter interpreter,
    List<String> labels,
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
  }

  /// Loads interpreter from asset
  void loadModel({Interpreter interpreter}) async {
    try {
      //Still working on it
      /*InterpreterOptions myOptions = new InterpreterOptions();
      myOptions.threads = numThreads;
      if (isNNAPI) {
        NnApiDelegate nnApiDelegate;
        bool androidApiThresholdMet = true;
        if (androidApiThresholdMet) {
          nnApiDelegate = new NnApiDelegate();
          myOptions.addDelegate(nnApiDelegate);
          myOptions.useNnApiForAndroid = true;
        }
      }
      if (isGPU) {
        GpuDelegateV2 gpuDelegateV2 = new GpuDelegateV2();
        myOptions.addDelegate(gpuDelegateV2);
      }*/

      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: InterpreterOptions()..threads = numThreads, //myOptions,
          );

      var outputTensors = _interpreter.getOutputTensors();
      //print("the length of the ouput Tensors is ${outputTensors.length}");
      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        //print(tensor.toString());
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Loads labels from assets
  void loadLabels({List<String> labels}) async {
    try {
      _labels =
          labels ?? await FileUtil.loadLabels("assets/" + LABEL_FILE_NAME);
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  /// Pre-process the image
  /// Only does something to the image if it doesn't meet the specified input sizes.
  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    if (imageProcessor == null) {
      imageProcessor = ImageProcessorBuilder()
          .add(ResizeWithCropOrPadOp(padSize, padSize))
          .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
          .build();
    }
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  // non-maximum suppression
  List<Recognition> nms(
      List<Recognition> list) // Turned from Java's ArrayList to Dart's List.
  {
    List<Recognition> nmsList = new List<Recognition>();

    for (int k = 0; k < _labels.length; k++) {
      // 1.find max confidence per class
      PriorityQueue<Recognition> pq = new HeapPriorityQueue<Recognition>();
      for (int i = 0; i < list.length; ++i) {
        if (list[i].label == _labels[k]) {
          // Changed from comparing #th class to class to string to string
          pq.add(list[i]);
        }
      }

      // 2.do non maximum suppression
      while (pq.length > 0) {
        // insert detection with max confidence
        List<Recognition> detections = pq.toList(); //In Java: pq.toArray(a)
        Recognition max = detections[0];
        nmsList.add(max);
        pq.clear();
        for (int j = 1; j < detections.length; j++) {
          Recognition detection = detections[j];
          Rect b = detection.location;
          if (boxIou(max.location, b) < mNmsThresh) {
            pq.add(detection);
          }
        }
      }
    }

    return nmsList;
  }

  double boxIou(Rect a, Rect b) {
    return boxIntersection(a, b) / boxUnion(a, b);
  }

  double boxIntersection(Rect a, Rect b) {
    double w = overlap((a.left + a.right) / 2, a.right - a.left,
        (b.left + b.right) / 2, b.right - b.left);
    double h = overlap((a.top + a.bottom) / 2, a.bottom - a.top,
        (b.top + b.bottom) / 2, b.bottom - b.top);
    if ((w < 0) || (h < 0)) {
      return 0;
    }
    double area = (w * h);
    return area;
  }

  double boxUnion(Rect a, Rect b) {
    double i = boxIntersection(a, b);
    double u = ((((a.right - a.left) * (a.bottom - a.top)) +
        ((b.right - b.left) * (b.bottom - b.top))) -
        i);
    return u;
  }

  double overlap(double x1, double w1, double x2, double w2) {
    double l1 = (x1 - (w1 / 2));
    double l2 = (x2 - (w2 / 2));
    double left = ((l1 > l2) ? l1 : l2);
    double r1 = (x1 + (w1 / 2));
    double r2 = (x2 + (w2 / 2));
    double right = ((r1 < r2) ? r1 : r2);
    return right - left;
  }

  /// Runs object detection on the input image
  Map<String, dynamic> predict(imageLib.Image image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;

    if (_interpreter == null) {
      return null;
    }
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // Initliazing TensorImage as the needed model input type
    // of TfLiteType.float32. Then, creating TensorImage from image
    TensorImage inputImage = TensorImage(TfLiteType.float32);
    inputImage.loadImage(image);
    TensorImage original = TensorImage(TfLiteType.float32);
    original.loadImage(image);
    // Do not use static methods, fromImage(Image) or fromFile(File),
    // of TensorImage unless the desired input TfLiteDataType is Uint8.
    // Create TensorImage from image
    //TensorImage inputImage = TensorImage.fromImage(image);

    // Pre-process TensorImage
    inputImage = getProcessedImage(inputImage);
    //getProcessedImage(inputImage);

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // TensorBuffers for output tensors
    TensorBuffer outputLocations = TensorBufferFloat(
        _outputShapes[0]); // The location of each detected object

    List<List<List<double>>> outputClassScores = new List.generate(
        _outputShapes[1][0],
            (_) => new List.generate(_outputShapes[1][1],
                (_) => new List.filled(_outputShapes[1][2], 0.0),
            growable: false),
        growable: false);

    // Inputs object for runForMultipleInputs
    // Use [TensorImage.buffer] or [TensorBuffer.buffer] to pass by reference
    List<Object> inputs = [inputImage.buffer];

    // Outputs map
    Map<int, Object> outputs = {
      0: outputLocations.buffer,
      1: outputClassScores,
    };

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    print(inputs[0].runtimeType);
    print(inputs[0].toString());
    // run inference
    _interpreter.runForMultipleInputs(inputs, outputs);

    var inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    // Using bounding box utils for easy conversion of tensorbuffer to List<Rect>
    List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputLocations,
      //valueIndex: [1, 0, 3, 2], Commented out because default order is needed.
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.CENTER,
      coordinateType: CoordinateType.PIXEL,
      height: INPUT_SIZE,
      width: INPUT_SIZE,
    );

    //print(locations.length);

    List<Recognition> recognitions = [];

    var gridWidth = _outputShapes[0][1];
    //print("gridWidth = $gridWidth");

    for (int i = 0; i < gridWidth; i++) {
      // Since we are given a list of scores for each class for
      // each detected Object, we are interested in finding the class
      // with the highest output score

      var maxClassScore = 0.00;
      var labelIndex = -1;

      for (int c = 0; c < _labels.length; c++) {
        // output[0][i][c] is the confidence score of c class
        if (outputClassScores[0][i][c] > maxClassScore) {
          labelIndex = c;
          maxClassScore = outputClassScores[0][i][c];
        }
      }
      // Prediction score
      var score = maxClassScore;

      var label;
      if (labelIndex != -1) {
        // Label string
        label = _labels.elementAt(labelIndex);
      } else {
        label = null;
      }
      // Makes sure the confidence is above the
      // minimum threshold score for each object.
      if (score > THRESHOLD) {
        // inverse of rect
        // [locations] corresponds to the image size 300 X 300
        // inverseTransformRect transforms it our [inputImage]

        Rect rectAti = Rect.fromLTRB(
            max(0, locations[i].left),
            max(0, locations[i].top),
            min(INPUT_SIZE + 0.0, locations[i].right),
            min(INPUT_SIZE + 0.0, locations[i].bottom));

        // Gets the coordinates based on the original image if anything was done to it.
        Rect transformedRect = imageProcessor.inverseTransformRect(
            rectAti, image.height, image.width);

        recognitions.add(
          Recognition(i, label, score, transformedRect),
        );
      }
    } // End of for loop and added all recognitions
    List<Recognition> recognitionsNMS = nms(recognitions);
    var predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;

    return {
      "recognitions": recognitionsNMS,
      "stats": Stats(
          totalPredictTime: predictElapsedTime,
          inferenceTime: inferenceTimeElapsed,
          preProcessingTime: preProcessElapsedTime)
    };
  }

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  /// Gets the loaded labels
  List<String> get labels => _labels;
}

class Recognition implements Comparable<Recognition> {
  /// Index of the result
  int _id;

  /// Label of the result
  String _label;

  /// Confidence [0.0, 1.0]
  double _score;

  /// Location of bounding box rect
  ///
  /// The rectangle corresponds to the raw input image
  /// passed for inference
  Rect _location;

  Recognition(this._id, this._label, this._score, [this._location]);

  int get id => _id;

  String get label => _label;

  double get score => _score;

  Rect get location => _location;

  /// Returns bounding box rectangle corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where rectangle is rendered on
  /// the screen
  Rect get renderLocation {
    // ratioX = screenWidth / imageInputWidth
    // ratioY = ratioX if image fits screenWidth with aspectRatio = constant

    double ratioX = CameraViewSingleton.ratio;
    double ratioY = ratioX;

    double transLeft = max(0.1, location.left * ratioX);
    double transTop = max(0.1, location.top * ratioY);
    double transWidth = min(
        location.width * ratioX, CameraViewSingleton.actualPreviewSize.width);
    double transHeight = min(
        location.height * ratioY, CameraViewSingleton.actualPreviewSize.height);

    Rect transformedRect =
    Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    return transformedRect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: ${(score * 100).toStringAsPrecision(3)}, location: $location)';
  }

  @override
  int compareTo(Recognition other) {
    if (this.score == other.score) {
      return 0;
    } else if (this.score > other.score) {
      return -1;
    } else {
      return 1;
    }
  }
}

class Stats {
  /// Total time taken in the isolate where the inference runs
  int totalPredictTime;

  /// [totalPredictTime] + communication overhead time
  /// between main isolate and another isolate
  int totalElapsedTime;

  /// Time for which inference runs
  int inferenceTime;

  /// Time taken to pre-process the image
  int preProcessingTime;

  Stats(
      {this.totalPredictTime,
        this.totalElapsedTime,
        this.inferenceTime,
        this.preProcessingTime});

  @override
  String toString() {
    return 'Stats{totalPredictTime: $totalPredictTime, totalElapsedTime: $totalElapsedTime, inferenceTime: $inferenceTime, preProcessingTime: $preProcessingTime}';
  }
}