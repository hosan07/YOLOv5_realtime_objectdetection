import 'package:flutter/cupertino.dart';

import '../../../../constants/gaps.dart';

class Weather extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final Function refreshData;

  Weather({@required this.weatherData, @required this.refreshData});

  @override
  Widget build(BuildContext context) {
    if (weatherData == null || weatherData['weather'] == null) {
      // weatherData가 null인 경우 또는 weatherData['weather']가 null인 경우에는 아무것도 그리지 않습니다.
      return SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.network(
          'https://openweathermap.org/img/w/${weatherData['weather'][0]['icon']}.png',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        Gaps.h20,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${(weatherData['main']['temp'] - 273.15).toStringAsFixed(0)}°C ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Gaps.v3,
                Text(
                  '${weatherData['name']} ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Gaps.v3,
            Row(
              children: [
                Text(
                  '최고 ${(weatherData['main']['temp_max'] - 273.15).toStringAsFixed(0)}° ',
                  style: TextStyle(fontSize: 15),
                ),
                Text(
                  '최저 ${(weatherData['main']['temp_min'] - 273.15).toStringAsFixed(0)}° ',
                  style: TextStyle(fontSize: 15),
                ),
                Text(
                    '풍속 ${weatherData['wind']['speed']}m/s',
                    style: TextStyle(fontSize: 15)
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}