import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:yeley_frontend/commons/decoration.dart';
import 'package:yeley_frontend/commons/validators.dart';
import 'package:yeley_frontend/providers/users.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  String? _latitude;
  String? _longitude;

  String API_KEY = "AIzaSyAKbjkQTDmsvRWKkO3Yrqlqz1gnV6a4KeQ";

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getSuggestions(_controller.text);
    });
  }

  Future<void> _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$API_KEY';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _suggestions = (data['predictions'] as List).map((item) {
          return {
            'description': item['description'],
            'place_id': item['place_id'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> _onSuggestionSelected(String description) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$description&key=$API_KEY';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final result = data['results'][0];
        setState(() {
          _controller.text = result['formatted_address'];
          _postalCodeController.text = (result['address_components']
              .firstWhere((comp) => (comp['types'] as List).contains('postal_code'),
              orElse: () => {'long_name': ''}))['long_name'];
          _cityController.text = (result['address_components']
              .firstWhere((comp) => (comp['types'] as List).contains('locality'),
              orElse: () => {'long_name': ''}))['long_name'];
          _latitude = result['geometry']['location']['lat'].toString();
          _longitude = result['geometry']['location']['lng'].toString();
          _suggestions = [];
        });
      } else {
        throw Exception('No address found');
      }
    } else {
      throw Exception('Failed to load place details');
    }
  }

  void _onValidate() async {
    if (_formKey.currentState!.validate() && _latitude != null && _longitude != null) {
      List<Location> locations = [
        Location(
          latitude: double.parse(_latitude!),
          longitude: double.parse(_longitude!),
          timestamp: DateTime.now(),
        )
      ];
      await context.read<UsersProvider>().setAddress(
        _controller.text,
        context,
        _postalCodeController.text,
        _cityController.text,
        locations,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kScaffoldBackground,
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: kScaffoldBackground,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7.5),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        SizedBox(width: 17),
                        Text(
                          'Votre emplacement',
                          style: kBold18,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                              hintText: 'Adresse, ville ou code postal',
                              hintStyle: kRegular16,
                            ),
                            controller: _controller,
                            validator: Validator.isNotEmpty,
                            onChanged: (text) => _onSearchChanged(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                              '${_suggestions[index]['description']}'),
                          onTap: () {
                            _onSuggestionSelected(_suggestions[index]['description']);
                          },
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  context.watch<UsersProvider>().isSettingAddress
                      ? const Center(
                      child: CircularProgressIndicator(
                        color: kMainGreen,
                      ))
                      : Column(
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kMainBlue,
                                shape: const StadiumBorder()),
                            onPressed: () async {
                              await context
                                  .read<UsersProvider>()
                                  .getPhonePosition(context);
                            },
                            child: Text(
                              "Ma position",
                              style: kBold16.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 15),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kMainGreen,
                                shape: const StadiumBorder()),
                            onPressed: _onValidate,
                            child: Text("Valider",
                                style:
                                kBold16.copyWith(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
