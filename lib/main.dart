import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // Add http package to pubspec.yaml http: ^1.4.0

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Anime Recommender Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MyHomePage(title: 'AI Anime Recommender'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//API code based off of code made by Alan Montoya Ugarte

class ApiFeature{
  final String _baseUrl = "http://localhost:11434/api/generate"; // e.g., http://localhost:11434/api/generate

  Future<String> fetchOllamaResponse(String promptText) async{
    final requestBody = {
      "model" : "llama3.2:1b",
      "prompt" : promptText,
      "stream" : false
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var responseString = jsonResponse['response'];
        // Parse the response string into a String
        return json.decode(responseString) as String;
      } else {
        // Handle server errors (e.g., 4xx, 5xx)
        throw Exception('Failed to load response from API: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Error connecting to API: $e');
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late ApiFeature apiService;
  late String requestPrompt;
  late Future<String> resultString;
  Map<String, bool> genres = {
    'Comedy': false,
    'Drama': false,
    'Action': false,
    'Sci-Fi': false,
    'Romance': false,
    'Adventure': false,
    'Fantasy': false,
    'Horror': false,
    'Mahou Shoujo': false,
    'Mecha': false,
    'Music': false,
    'Mystery': false,
    'Psychological': false,
  };

  String selectedSeasons = '1-2';
  String selectedEpisodes = '1-10';

  final List<String> seasonOptions = ['1-2', '3-5', '6+'];
  final List<String> episodeOptions = ['1-10', '11-20', '21+'];

  String setRequestPrompt(){
    List<String> selectedGenres = genres.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

    int minSeasons = selectedSeasons == '6+' ? 6 : int.parse(selectedSeasons.split('-')[0]);
    int maxSeasons = selectedSeasons == '6+' ? 100 : int.parse(selectedSeasons.split('-')[1]);

    int minEpisodes = selectedEpisodes == '21+' ? 21 : int.parse(selectedEpisodes.split('-')[0]);
    int maxEpisodes = selectedEpisodes == '21+' ? 999 : int.parse(selectedEpisodes.split('-')[1]);

    requestPrompt = "I'm stumped on what to watch tonight. Could you please recommend me some anime that have: $minEpisodes to $maxEpisodes, $minSeasons to $maxSeasons, and matches with at least one of these genres: ${selectedGenres.join(', ')}.";

    return requestPrompt;
  }

  void _generateRequest() {
    setState(() {
      

      resultString = apiService.fetchOllamaResponse(requestPrompt);

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Padding(

        padding: const EdgeInsets.all(16.0),
        child: Column(


          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            
            Text("Select Genres:", style: TextStyle(fontSize: 12)),
            ...genres.keys.map((genre) {
              return CheckboxListTile(
                title: Text(genre),
                value: genres[genre],
                onChanged: (bool? value) {
                  setState(() {
                    genres[genre] = value!;
                  });
                },
              );
            }),

            SizedBox(height: 10),

            Text("Select Season Count:", style: TextStyle(fontSize: 12)),
            DropdownButton<String>(
              value: selectedSeasons,
              items: seasonOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedSeasons = val!),
            ),

            SizedBox(height: 10),

            Text("Select Episode Count:", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: selectedEpisodes,
              items: episodeOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedEpisodes = val!),
            ),

            SizedBox(height: 20),
            Text("Recommended Shows:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Text('$resultString',
                style: Theme.of(context).textTheme.headlineMedium,)
              ),
            ),

          ],
        ),
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: _generateRequest,
        tooltip: 'Generate Request',
        child: const Icon(Icons.add),
      ), 
    );
  }
}
