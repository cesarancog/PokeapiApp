
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokemon API Viewer',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const PokemonPage(),
    );
  }
}

// Pokemon data model
class Pokemon {
  final String name;
  final int id;
  final int height;
  final int weight;
  final String? sprite;
  final List<String> abilities;
  final List<String> types;

  const Pokemon({
    required this.name,
    required this.id,
    required this.height,
    required this.weight,
    required this.sprite,
    required this.abilities,
    required this.types,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    if (json['name'] is! String ||
        json['id'] is! int ||
        json['height'] is! int ||
        json['weight'] is! int ||
        json['abilities'] is! List ||
        json['types'] is! List) {
      throw const FormatException(
        'The Pokemon data has an unexpected format.',
      );
    }

    final abilities = (json['abilities'] as List).map((item) {
      if (item is! Map || item['ability'] is! Map) {
        throw const FormatException('Invalid ability data.');
      }

      final name = item['ability']['name'];
      if (name is! String) {
        throw const FormatException('Invalid ability name.');
      }

      return name;
    }).toList();

    final types = (json['types'] as List).map((item) {
      if (item is! Map || item['type'] is! Map) {
        throw const FormatException('Invalid type data.');
      }

      final name = item['type']['name'];
      if (name is! String) {
        throw const FormatException('Invalid Pokemon type.');
      }

      return name;
    }).toList();

    final sprites = json['sprites'];

    return Pokemon(
      name: json['name'],
      id: json['id'],
      height: json['height'],
      weight: json['weight'],
      sprite: sprites is Map
          ? sprites['front_default'] as String?
          : null,
      abilities: abilities,
      types: types,
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final TextEditingController controller =
      TextEditingController(text: 'pikachu');

  Pokemon? pokemon;
  String? errorMessage;
  bool loading = false;

  Future<void> getPokemon() async {
    final pokemonName = controller.text.trim().toLowerCase();

    if (pokemonName.isEmpty || loading) return;

    setState(() {
      loading = true;
      pokemon = null;
      errorMessage = null;
    });

    try {
      final uri = Uri.https(
        'pokeapi.co',
        '/api/v2/pokemon/${Uri.encodeComponent(pokemonName)}',
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        throw Exception(
          'Pokemon "$pokemonName" was not found. Check the name and try again.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: HTTP ${response.statusCode}. Please try again later.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'The server returned an invalid response.',
        );
      }

      final result = Pokemon.fromJson(decoded);

      if (!mounted) return;

      setState(() {
        pokemon = result;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        errorMessage =
            'The request took too long. Please check your connection and try again.';
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        errorMessage =
            'Unable to connect to the Pokemon API. Please check your internet connection.';
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unable to process Pokemon data: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getPokemon();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Pokemon API Viewer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore Pokemon',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Search for a Pokemon using its name or ID.'),
            const SizedBox(height: 16),

            TextField(
              controller: controller,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Pokemon name or ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => getPokemon(),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : getPokemon,
                icon: const Icon(Icons.search),
                label: const Text('Search Pokemon'),
              ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading Pokemon information...'),
                    ],
                  ),
                ),
              )
            else if (errorMessage != null)
              _buildError()
            else if (pokemon != null)
              _buildPokemonDetails()
            else
              const Center(
                child: Text('Search for a Pokemon to begin.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : getPokemon,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonDetails() {
    final p = pokemon!;

    return Column(
      children: [
        Card(
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                if (p.sprite != null && p.sprite!.isNotEmpty)
                  Image.network(
                    p.sprite!,
                    width: 180,
                    height: 180,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.catching_pokemon, size: 100),
                  )
                else
                  const Icon(Icons.catching_pokemon, size: 100),

                Text(
                  p.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                Text(
                  'Pokemon ID: ${p.id}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          children: [
            _info('Height', '${p.height}'),
            _info('Weight', '${p.weight}'),
          ],
        ),

        _list('Abilities', p.abilities),
        _list('Pokemon Types', p.types),
      ],
    );
  }

  Widget _info(String title, String value) {
    return Card(
      color: Colors.white,
      child: Center(
        child: Text(
          '$title\n$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _list(String title, List<String> items) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('None')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) {
                  return Chip(label: Text(item));
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
