import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
import 'package:http/http.dart' as http;

Color boxColor = const Color.fromARGB(26, 204, 182, 255);
Color textColor = Color.fromARGB(255, 255, 188, 255);

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = '';
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  DateTime date = DateTime.now();

  String _addLeadPadding(int number) {
    return number < 10 ? '0$number' : '$number';
  }

  String _convertMilisecondToTime(int miliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(miliseconds * 1000);
    return '${date.hour > 12 ? date.hour - 12 : date.hour}:${_addLeadPadding(date.minute)} ${date.hour > 12 ? 'PM' : 'AM'}';
  }

  String _convertPressure(int pressure) {
    // hPa to atm
    return (pressure / 1013.25).toStringAsFixed(4).toString();
  }

  String _degToDirection(int degree) {
    if (degree >= 0 && degree < 45) {
      return 'N';
    } else if (degree >= 45 && degree < 90) {
      return 'NE';
    } else if (degree >= 90 && degree < 135) {
      return 'East';
    } else if (degree >= 135 && degree < 180) {
      return 'SE';
    } else if (degree >= 180 && degree < 225) {
      return 'South';
    } else if (degree >= 225 && degree < 270) {
      return 'SW';
    } else if (degree >= 270 && degree < 315) {
      return 'West';
    } else {
      return 'NW';
    }
  }

  Widget _buildWindDirection() {
    String direction = _degToDirection(weatherData!['wind']['deg']);
    return Row(
      children: [
        Text(
          '    $direction',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        _windIcon(direction),
      ],
    );
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    debugPrint('city: $city');
    debugPrint('date: $date');

    final apiKey = Credentials.apiKey;
    final baseUrl = Credentials.baseUrl;
    final url = '$baseUrl/weather?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });

        // Fetch minute forecast data
        final lat = weatherData!['coord']['lat'];
        final lon = weatherData!['coord']['lon'];
        final oneCallUrl =
            '$baseUrl/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&appid=$apiKey&units=metric';
        final oneCallResponse = await http.get(Uri.parse(oneCallUrl));

        if (oneCallResponse.statusCode == 200) {
          final oneCallData = json.decode(oneCallResponse.body);
          debugPrint("minute-forecast-debug: ${oneCallData['minutely']}");
        } else {
          debugPrint("Failed to load minute forecast data");
        }
      } else {
        setState(() {
          weatherData = null;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color.fromARGB(255, 23, 22, 37),
            content: Text(
              'City not found!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      debugPrint("weather-debug: ${weatherData.toString()}");
    } catch (e) {
      debugPrint("error-debug: ${e.toString()}");

      throw Exception('Failed to load weather data');
    }
  }

  Future<String> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        isLoading = false;
      });
      return Future.error('Location permission denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
        distanceFilter: 10,
      ),
    );

    debugPrint('placemarks: ${position.toString()}');
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String? city = placemarks[0].locality;
    return city!;
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() {
      isLoading = true;
    });

    // ask permission for location and get lat-lng
    try {
      cityName = await _determinePosition();
      await fetchWeather(cityName);
    } catch (e) {
      debugPrint('error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 23, 22, 37),
          content: Text(
            'Location permission denied!',
            style: TextStyle(color: textColor),
          ),
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
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
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter city name',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(100, 127, 77, 255),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
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
                CircularProgressIndicator(color: const Color(0xcf7f73ef))
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
                            ),
                            child: Row(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left part UI
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${weatherData!['name']}, ${weatherData!['sys']['country']}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        '${weatherData!['main']['temp'].toInt()}°C',
                                        style: TextStyle(
                                          fontSize: 44,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      SizedBox(height: 10),
                                      Text(
                                        'Feels like ${weatherData!['main']['feels_like']}°C',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right part UI
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _getWeatherIcon(
                                          weatherData!['weather'][0]['main'],
                                        ),
                                        color: textColor,
                                        size: 50,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        weatherData!['weather'][0]['description']
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                  'Wind Speed: ${(weatherData!['wind']['speed'] * 3.6).toStringAsFixed(2)} km/h',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                _buildWindDirection(),
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
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.thunderstorm_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                Text(
                                  'Chance of Rain: ${weatherData!['clouds']['all']}%',
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
                                  'Pressure: ${_convertPressure(weatherData!['main']['pressure'])} atm',
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

                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              final apiKey = Credentials.apiKey;
                              final baseUrl = Credentials.baseUrl;
                              debugPrint(apiKey);
                              debugPrint(baseUrl);
                              // get 24hours forecast of the current city
                              final forecastUrl =
                                  '$baseUrl/forecast/hourly?q=${weatherData!['name']}&appid=$apiKey&units=metric';

                              final response = await http.get(
                                Uri.parse(forecastUrl),
                              );
                              final forecastData = json.decode(response.body);
                              debugPrint(
                                'forecast-debug: ${forecastData.toString()}',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text('Show Forecast'),
                          ),

                          SizedBox(height: 20),
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
                        style: TextStyle(fontSize: 18, color: Colors.white54),
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
      floatingActionButton: FloatingActionButton(
        onPressed: fetchWeatherByLocation,
        tooltip: 'Get weather by location',
        child: Icon(Icons.location_on_outlined),
      ),
    );
  }

  Widget _buildMinuteForecast(List<dynamic> minuteData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minute Forecast',
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          ...minuteData.map((minute) {
            final time = DateTime.fromMillisecondsSinceEpoch(
              minute['dt'] * 1000,
            );
            final precipitation = minute['precipitation'];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour}:${_addLeadPadding(time.minute)}',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                Text(
                  '$precipitation mm',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getSunRiseSet(int time) {
    final date = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return date.hour < 12 ? Icons.wb_sunny : Icons.nightlight_round;
  }

  Icon _windIcon(String direction) {
    switch (direction) {
      case 'N':
        return Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 15);
      case 'NE':
        return Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15);
      case 'East':
        return Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15);
      case 'SE':
        return Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15);
      case 'South':
        return Icon(
          Icons.arrow_downward_rounded,
          color: Colors.white,
          size: 15,
        );
      case 'SW':
        return Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15);
      case 'West':
        return Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15);
      case 'NW':
        return Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15);
      default:
        return Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 15);
    }
  }

  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.cloudy_snowing;
      case 'drizzle':
      case 'rain':
        return Icons.beach_access_rounded;
      case 'atmosphere':
        return Icons.grain_outlined;
      default:
        return Icons.wb_cloudy_outlined;
    }
  }
}

String _getWeekday(int weekday) {
  switch (weekday) {
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    case 7:
      return 'Sun';
    default:
      return '';
  }
}

String _getMonth(int month) {
  switch (month) {
    case 1:
      return 'January';
    case 2:
      return 'February';
    case 3:
      return 'March';
    case 4:
      return 'April';
    case 5:
      return 'May';
    case 6:
      return 'June';
    case 7:
      return 'July';
    case 8:
      return 'August';
    case 9:
      return 'September';
    case 10:
      return 'October';
    case 11:
      return 'November';
    case 12:
      return 'December';
    default:
      return '';
  }
}
