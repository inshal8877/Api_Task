import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wilson_api_task/detail_page.dart';
import 'package:wilson_api_task/login.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp( MaterialApp(
    title: "Wilson Api App",
    home: HomePage(),
  ));
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return HomeScreen();
            } else {
              return LoginForm();
            }
          },
        ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDataFromCache();
    fetchData();

    super.initState();
  }

  void _onListItemTap(int index) {
    final data = _data[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          imageUrl: data['avatar'],
          email: data['email'],
          first_name: data['first_name'],
          last_name: data['last_name'],
        ),
      ),
    );
  }

  Future<void> fetchData() async {
    final url = 'https://reqres.in/api/users?page=2'; // Replace with your API endpoint
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body)['data'];
        setState(() {
          _data = jsonData;
          _isLoading = false;
          _saveDataToCache(jsonData);
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: Icon(Icons.logout))
        ],
        title: const Text('API Data in ListView'),
      ),
      body: _data.isEmpty
          ? const Center(
        child: CircularProgressIndicator(),
      ):ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () => _onListItemTap(index),
            title:Row(
              children: [
                Text(_data[index]['first_name']),
                SizedBox(width: 5),
                Text(_data[index]['last_name']),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewData, // Function to call when the button is pressed
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _fetchDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedData');
    if (cachedData != null) {
      final jsonData = json.decode(cachedData);
      setState(() {
        _data = jsonData;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDataToCache(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cachedData', json.encode(data));
  }

  void _addNewData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Post New Data'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _postDataToAPI();
              setState(() {
                _saveDataToCache(_data); // Save the updated list to cache
              });
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }


  Future<void> _postDataToAPI() async {
    final url = 'https://reqres.in/api/users';
    final data = {
      'name': 'Inshal',
    };
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data is uploaded successfully and returned with unique id')));
        fetchData();
      } else {
        throw Exception('Failed to add new data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

