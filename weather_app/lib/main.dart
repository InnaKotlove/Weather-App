import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

void main() => runApp(WeatherApp());

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int temperature;
  var minTemperatureForecast = List.filled(7, 0);
  var maxTemperatureForecast = List.filled(7, 0);
  String location = 'San Francisco';
  int woeid = 2487956;
  String weather = 'clear';
  String abbrevation = '';
  var abbrevationForecast = List.filled(7, '');
  String errorMessage = '';
  Position _currentPosition;
  String _currentAddress;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String searchApiUrlLatLng =
      'https://www.metaweather.com/api/location/search/?lattlong=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  void fetchSearchLatLng(double lat, double long) async {
    try {
      print("Current position: $lat $long");
      var searchResult =
          await http.get(Uri.parse(searchApiUrlLatLng + '$lat,$long'));
      var result = json.decode(searchResult.body)[0];
      print(result);
      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
      print("Current address: ${result["title"]}");
    } catch (error) {
      print("$error");
      setState(() {
        errorMessage =
            "Sorry, we don`t have data about this city. Try another one";
      });
    }
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];
      print(result);
      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage =
            "Sorry, we don`t have data about this city. Try another one";
      });
    }
  }

  void fetchLocation() async {
    Future<Response> future =
        http.get(Uri.parse(locationApiUrl + woeid.toString()));
    Response locationResult = await future;
    var result = json.decode(locationResult.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];
    print(result);

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbrevation = data["weather_state_abbr"];
    });
  }

  void fetchLocationDay() async {
    var today = new DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          new DateFormat('y/M/d')
              .format(today.add(new Duration(days: i + 1)))
              .toString()));
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbrevationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    fetchSearch(input);
    _fetchWeatherData();
  }

  void _fetchWeatherData() {
    fetchLocation();
    fetchLocationDay();
  }

  void _getCurrentLocation() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      fetchSearchLatLng(_currentPosition.latitude, _currentPosition.longitude);
      _fetchWeatherData();
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/$weather.png'),
              fit: BoxFit.cover,
              colorFilter: new ColorFilter.mode(
                  Colors.black.withOpacity(0.6), BlendMode.dstATop),
            ),
          ),
          child: temperature == null
              ? Center(child: CircularProgressIndicator())
              : Scaffold(
                  appBar: AppBar(
                    actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: GestureDetector(
                          onTap: () {
                            _getCurrentLocation();
                          },
                          child: Icon(Icons.location_city, size: 36.0),
                        ),
                      )
                    ],
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                  ),
                  resizeToAvoidBottomInset: false,
                  backgroundColor: Colors.transparent,
                  body: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Center(
                            child: Image.network(
                              'https://www.metaweather.com/static/img/weather/png/' +
                                  abbrevation +
                                  '.png',
                              width: 100,
                            ),
                          ),
                          Center(
                            child: Text(
                              temperature.toString() + '°С',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 60.0),
                            ),
                          ),
                          Center(
                            child: Text(
                              location,
                              style: TextStyle(
                                  color: Colors.white, fontSize: 40.0),
                            ),
                          ),
                        ],
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            for (var i = 0; i < 7; i++)
                              forecastElement(
                                  i + 1,
                                  abbrevationForecast[i],
                                  minTemperatureForecast[i],
                                  maxTemperatureForecast[i]),
                          ],
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          Container(
                            width: 300,
                            child: TextField(
                              onSubmitted: (String input) {
                                onTextFieldSubmitted(input);
                              },
                              style:
                                  TextStyle(color: Colors.white, fontSize: 25),
                              decoration: InputDecoration(
                                hintText: 'Search another location...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 32.0, left: 32.0),
                            child: Text(errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize:
                                        Platform.isAndroid ? 15.0 : 20.0)),
                          )
                        ],
                      ),
                    ],
                  ),
                )),
    );
  }
}

Widget forecastElement(
    daysFromNow, abbrevation, minTemperature, maxTemperature) {
  var now = new DateTime.now();
  var oneDayFromNow = now.add(new Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              new DateFormat.E().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              new DateFormat.MMMd().format(oneDayFromNow),
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbrevation +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High:' + maxTemperature.toString() + '°С',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            Text(
              'Low:' + minTemperature.toString() + '°С',
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ],
        ),
      ),
    ),
  );
}