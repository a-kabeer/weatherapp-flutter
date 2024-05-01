import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String day = '';
  Map<String, dynamic> weatherData = {};
  String error = '';
  bool isLoading = true;
  String? imageUrl;
  String? mainCondition;
  String? mainDayCondition;
  String? mainNightCondition;

  bool nightTime = false;

  @override
  void initState() {
    super.initState();
    _getCityName();
    updateDateTime();
  }

  void updateDateTime() {
    final now = DateTime.now();
    setState(() {
      day = DateFormat('EEEE').format(now);
    });
  }

  Future<void> _getCityName() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            error = 'Location permission denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error =
              'Location permissions are permanently denied, we cannot request permissions.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String apiKey = '64b5c8fe1b4f4d39aaa6d43e65083542';
      var url = Uri.parse(
          'https://api.opencagedata.com/geocode/v1/json?q=${position.latitude},${position.longitude}&key=$apiKey');

      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var city = data['results'][0]['components']['city'];
        String cityName = city.split(' ')[0];
        _jsonData(cityName);
      }
    } catch (e) {
      setState(() {
        error = 'Failed to fetch city name: $e';
      });
    }
  }

  getWeatherDayAnimation(String? mainDayCondition) {
    if (mainDayCondition == null) return 'assets/json/sunny.json';
    switch (mainDayCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'haze':
      case 'smoke':
      case 'dust':
      case 'fog':
        return 'assets/json/cloudy.json';
      case 'rainy':
      case 'drizzle':
      case 'shower rain':
        return 'assets/json/rainy.json';
      case 'thunderstorm':
        return 'assets/json/thunder.json';
      case 'clear':
        return 'assets/json/sunny.json';
      default:
        return 'assets/json/sunny.json';
    }
  }

  getWeatherNightAnimation(String? mainNightCondition) {
    if (mainNightCondition == null) return 'assets/json/night.json';
    switch (mainNightCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'haze':
      case 'smoke':
      case 'dust':
      case 'fog':
        return 'assets/json/ncloudy.json';
      case 'rainy':
      case 'drizzle':
      case 'shower rain':
        return 'assets/json/nrainy.json';
      case 'thunderstorm':
        return 'assets/json/nthunder.json';
      case 'clear':
        return 'assets/json/night.json';
      default:
        return 'assets/json/night.json';
    }
  }

  _jsonData(String cityName) async {
    setState(() => isLoading = true);

    String key = '81917c0d92842ca32dde2a7a09de1327';
    var url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$key&units=metric');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        weatherData = jsonDecode(response.body);
        isLoading = false;
        imageUrl =
            'http://openweathermap.org/img/wn/${weatherData['weather'][0]['icon']}.png';
        mainCondition = weatherData['weather'][0]['main'];
        nightTime = isNightTime(weatherData);
        
      });
    } else {
      setState(() {
        error = 'Failed to load data';
        isLoading = false;
      });
    }
  }

  bool isNightTime(Map<String, dynamic> weatherData) {
    DateTime nowUtc = DateTime.now().toUtc();

    int timezoneOffset = weatherData['timezone'];
    DateTime localCurrentTime = nowUtc.add(Duration(seconds: timezoneOffset));

    int sunriseUtcSeconds = weatherData['sys']['sunrise'];
    int sunsetUtcSeconds = weatherData['sys']['sunset'];
    DateTime localSunriseTime = DateTime.fromMillisecondsSinceEpoch(
            sunriseUtcSeconds * 1000,
            isUtc: true)
        .add(Duration(seconds: timezoneOffset));
    DateTime localSunsetTime = DateTime.fromMillisecondsSinceEpoch(
            sunsetUtcSeconds * 1000,
            isUtc: true)
        .add(Duration(seconds: timezoneOffset));

    return localCurrentTime.isBefore(localSunriseTime) ||
        localCurrentTime.isAfter(localSunsetTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            _getCityName();
          });
          return _getCityName();
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: nightTime
                  ? [Colors.indigo, Colors.black]
                  : [Colors.blue, Colors.lightBlueAccent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : error.isNotEmpty
                      ? Center(
                          child: Text(error,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18)))
                      : SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (weatherData.isNotEmpty)
                                Text('Weather in ${weatherData['name']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )),
                              const SizedBox(height: 10),
                              if (weatherData.isNotEmpty &&
                                  weatherData['weather'][0]['icon'] != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                        '${weatherData['weather'][0]['main']}', // Now displays temperature in Celsius
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.white)),
                                    const Spacer(),
                                    Image.network(
                                      imageUrl ?? '',
                                      width: 50,
                                      height: 50,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              if (weatherData.isNotEmpty &&
                                  weatherData['main'] != null)
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                          '${weatherData['main']['temp'].round()}°C',
                                          style: TextStyle(
                                              fontSize: 42,
                                              color: Colors.white)),
                                      Text(
                                          'feels like ${weatherData['main']['feels_like'].round()}°C',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white))
                                    ],
                                  ),
                                ),
                              Center(
                                  child: nightTime
                                      ? Lottie.asset(getWeatherNightAnimation(
                                          mainNightCondition))
                                      : Lottie.asset(getWeatherDayAnimation(
                                          mainDayCondition))),
                              SizedBox(height: 10),
                              if (weatherData.isNotEmpty &&
                                  weatherData['wind'] != null)
                                Row(
                                  children: [
                                    Icon(Icons.air,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                        'Wind: ${weatherData['wind']['speed']} m/s',
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white)),
                                  ],
                                ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.water_drop,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                      'Humidity: ${weatherData['main']['humidity']}%',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.cloud,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                      'Cloudiness: ${weatherData['clouds']['all']}%',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                      nightTime
                                          ? Icons.nightlight_round
                                          : Icons.wb_sunny,
                                      color: Colors.white,
                                      size: 24),
                                  SizedBox(width: 10),
                                  Text(nightTime ? 'Night' : 'Day',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white)),
                                ],
                              ),
                              SizedBox(height: 30),
                              Center(
                                child: Text(day,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
