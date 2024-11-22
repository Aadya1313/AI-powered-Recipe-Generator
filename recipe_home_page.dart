import 'package:flutter/material.dart';
import 'package:my_app/services/recipe_service.dart';

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RecipeHomePageState createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _dietaryController = TextEditingController();
  final List<String> _inputIngredients = [];
  Map<String, dynamic>? _generatedRecipe;
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = false; // Track loading state

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim().toLowerCase();
    if (ingredient.isNotEmpty && !_inputIngredients.contains(ingredient)) {
      setState(() {
        _inputIngredients.add(ingredient);
        _ingredientController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingredient is empty or already added")),
      );
    }
  }

  Future<void> _generateRecipe() async {
    if (_inputIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one ingredient")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      String ingredients = _inputIngredients.join(', ');
      String cuisineType = _cuisineController.text.trim();
      String dietaryRestrictions = _dietaryController.text.trim();

      // Call the updated generateCompleteRecipe method
      Map<String, dynamic> recipe = await _recipeService.generateCompleteRecipe(
        ingredients,
        cuisineType: cuisineType.isNotEmpty ? cuisineType : null,
        dietaryRestrictions:
            dietaryRestrictions.isNotEmpty ? dietaryRestrictions : null,
      );

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        _generatedRecipe = recipe; // Update the generated recipe
      });
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate recipe: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Enter an ingredient',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cuisineController,
              decoration: const InputDecoration(
                labelText: 'Enter cuisine type (optional)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dietaryController,
              decoration: const InputDecoration(
                labelText: 'Enter dietary restrictions (optional)',
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8.0,
              children: _inputIngredients
                  .map((ingredient) => Chip(label: Text(ingredient)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateRecipe,
              child: _isLoading
                  ? const CircularProgressIndicator() // Loading indicator
                  : const Text('Generate Recipe'),
            ),
            const SizedBox(height: 20),
            if (_generatedRecipe != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipe: ${_generatedRecipe?['name'] ?? 'Unnamed Recipe'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_generatedRecipe?['image'] != null)
                      Image.network(_generatedRecipe?['image'] ?? ''),
                    const SizedBox(height: 10),
                    const Text('Ingredients:', style: TextStyle(fontSize: 16)),
                    ...(_generatedRecipe?['ingredients'] as List<dynamic>)
                        .map<Widget>((ingredient) => Text('- $ingredient')),
                    const SizedBox(height: 10),
                    const Text('Instructions:', style: TextStyle(fontSize: 16)),
                    Text(_generatedRecipe?['instructions'] ?? 'N/A'),
                    const SizedBox(height: 10),
                    Text(
                      'Cooking Time: ${_generatedRecipe?['cooking_time'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Servings: ${_generatedRecipe?['servings'] ?? '1 serving'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
