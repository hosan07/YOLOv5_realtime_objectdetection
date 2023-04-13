import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:objectdetection/screen/home/widget/weather/weather_ko.dart';

import '../../../../constants/gaps.dart';

class Weather extends StatefulWidget {
  @override
  _WeatherState createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  Map<String, dynamic> weatherData = {};
  final _openweatherkey ='2834387742b25d5393a21e88fee8246a';
  @override
  void initState() {
    super.initState();
    getPosition();
  }

  Future<void> getPosition() async {
    var currentPosition = await Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    var lastPosition = await Geolocator
        .getLastKnownPosition();
    print(currentPosition);
    print(lastPosition);
    getWeatherData(
        lat: currentPosition.latitude.toString(),
        lon: currentPosition.longitude.toString());
  }
  Future<void> getWeatherData({
    @required String lat,
    @required String lon,
  }) async {
    String str ='http://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_openweatherkey';
    print(str);
    final response = await http.get(Uri.parse(str));

    if (response.statusCode == 200) {
      var data = response.body;
      var dataJson = jsonDecode(data); // string to json
      setState(() {
        weatherData = dataJson;
      });
      print('data = $data');
      print('${dataJson['main']['temp']}');
    } else {
      print('response status code = ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8FEFD9),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              'https://openweathermap.org/img/w/${weatherData['weather'][0]['icon']}.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Gaps.h20,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gaps.v8,
                Text(
                  '${(weatherData['main']['temp'] - 273.15).toStringAsFixed(0)}°C',
                  style: TextStyle(fontSize: 35),
                ),
                Gaps.v3,
                Text(
                  '${weatherData['name']}',
                  style: TextStyle(fontSize: 22),
                ),
                Gaps.v3,
                Row(
                  children: [
                    Text(
                      '최고 ${(weatherData['main']['temp_max'] - 273.15).toStringAsFixed(0)}°',
                      style: TextStyle(fontSize: 20),
                    ),
                    Gaps.h10,
                    Text(
                      '최저 ${(weatherData['main']['temp_min'] - 273.15).toStringAsFixed(0)}°',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                Gaps.v3,
                Text(
                      '풍속 ${weatherData['wind']['speed']}m/s',
                      style: TextStyle(fontSize: 20)
                    ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}
