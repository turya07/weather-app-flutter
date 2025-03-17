import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
import 'package:http/http.dart' as http;

Color boxColor = const Color.fromARGB(26, 204, 182, 255);
Color textColor = Colors.white;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = '';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String _addLeadPadding(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  String _convertMilisecondToTime(int miliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(miliseconds * 1000);
    return '${date.hour > 12 ? date.hour - 12 : date.hour}:${_addLeadPadding(date.minute)} ${date.hour > 12 ? 'PM' : 'AM'}';
  }

  String _degToDirection(int degree) {
    if (degree >= 0 && degree < 45) {
      return 'N';
    } else if (degree >= 45 && degree < 90) {
      return 'NE';
    } else if (degree >= 90 && degree < 135) {
      return 'E';
    } else if (degree >= 135 && degree < 180) {
      return 'SE';
    } else if (degree >= 180 && degree < 225) {
      return 'S';
    } else if (degree >= 225 && degree < 270) {
      return 'SW';
    } else if (degree >= 270 && degree < 315) {
      return 'W';
    } else {
      return 'NW';
    }
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    final apiKey = Credentials.apiKey;
    final baseUrl = Credentials.baseUrl;
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        weatherData = null;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 23, 22, 37),
          content: Text('City not found!', style: TextStyle(color: textColor)),
        ),
      );
    }
    debugPrint("weather-debug: ${weatherData.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xD1120133),
      drawerScrimColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/logo.png'), height: 30),
            SizedBox(width: 10),
            Text(
              'Weather App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: Color.fromARGB(230, 18, 1, 51),
      ),
      body: RefreshIndicator(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(250, 18, 1, 51),
                Color.fromARGB(249, 25, 6, 63),
                Color.fromARGB(249, 125, 10, 207),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter city name',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(100, 127, 77, 255),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: textColor),
                      onPressed: () {
                        if (cityName.isNotEmpty) {
                          fetchWeather(cityName);
                        }
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      cityName = value;
                    });
                  },
                ),
              ),
              if (isLoading)
                RefreshProgressIndicator()
              else if (weatherData != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(20),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: boxColor,
                              //     blurRadius: 20,
                              //     spreadRadius: 2,
                              //   ),
                              // ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 10,
                                    children: [
                                      Icon(
                                        _getWeatherIcon(
                                          weatherData!['weather'][0]['main'],
                                        ),
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      Text(
                                        '${weatherData!['main']['temp'].toInt()}°C',
                                        style: TextStyle(
                                          fontSize: 50,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    weatherData!['weather'][0]['main'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(100),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: boxColor,
                              //     blurRadius: 10,
                              //     spreadRadius: 1,
                              //   ),
                              // ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.air_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Text(
                                  'Wind Speed: ${weatherData!['wind']['speed']} km/h ${_degToDirection(weatherData!['wind']['deg'])}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(100),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: boxColor,
                              //     blurRadius: 10,
                              //     spreadRadius: 1,
                              //   ),
                              // ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Text(
                                  'Humidity: ${weatherData!['main']['humidity']}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(100),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: boxColor,
                              //     blurRadius: 10,
                              //     spreadRadius: 1,
                              //   ),
                              // ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.thermostat_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Text(
                                  'Pressure: ${weatherData!['main']['pressure'] / 1000} atm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: boxColor,
                              borderRadius: BorderRadius.circular(20),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: boxColor,
                              //     blurRadius: 20,
                              //     spreadRadius: 2,
                              //   ),
                              // ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getSunRiseSet(
                                        weatherData!['sys']['sunrise'],
                                      ),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    Text(
                                      _convertMilisecondToTime(
                                        weatherData!['sys']['sunrise'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Icon(
                                      _getSunRiseSet(
                                        weatherData!['sys']['sunset'],
                                      ),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    Text(
                                      _convertMilisecondToTime(
                                        weatherData!['sys']['sunset'],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Search for a city to get weather information.',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor.withValues(alpha: 160),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        onRefresh: () async {
          if (cityName.isNotEmpty) await fetchWeather(cityName);
        },
      ),
    );
  }

  IconData _getSunRiseSet(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return date.hour < 12 ? Icons.wb_sunny : Icons.nightlight_round;
  }

  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.beach_access_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }
}
