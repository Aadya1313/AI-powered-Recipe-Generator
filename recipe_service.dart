import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class RecipeService {
  final String huggingFaceApiKey = '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';
  final String spoonacularApiKey = '954704a604514fb0a179c66ec92aabd0';

  final Logger _logger = Logger('RecipeService');

  RecipeService() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final logMessage = '[${record.level.name}] '
          '${record.time}: '
          '${record.loggerName}: '
          '${record.message}';
      _outputLog(logMessage);
    });
  }

  void _outputLog(String message) {
    debugPrint(message);
  }

  // Generate recipe using Hugging Face model (GPT-Neo-2.7B)
  Future<String> generateRecipeUsingAI(String ingredients,
      {String? cuisineType, String? dietaryRestrictions}) async {
    _logger.info('Starting AI recipe generation for ingredients: $ingredients');

    String prompt = '''
    Create a detailed vegetarian recipe using the following ingredients: $ingredients.

    Please structure the recipe as follows:
    - Recipe Name: A unique, descriptive title.
    - Ingredients: Provide a list of ingredients with exact measurements, each on a new line.
    - Instructions: Step-by-step cooking instructions, each step on a new line.
    - Total Cooking Time: Total time required to prepare and cook the recipe (in minutes).
    - Serving Size: Number of servings.

    The recipe should be simple, clear, and suitable for beginners.
    Cuisine Style: ${cuisineType ?? "Indian"}
    Dietary Requirements: ${dietaryRestrictions ?? "vegetarian"}
    ''';

    try {
      final response = await http
          .post(
            Uri.parse(
                'https://api-inference.huggingface.co/models/EleutherAI/gpt-neo-2.7B'),
            headers: {
              'Authorization': 'Bearer $huggingFaceApiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'inputs': prompt,
              'options': {
                'max_length': 800,
                'temperature': 0.5,
                'num_return_sequences': 1,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger
            .info('Recipe generation successful. Received response from AI.');
        return data[0]['generated_text'];
      } else {
        _logger.severe(
            'Failed to generate recipes. Response code: ${response.statusCode}');
        throw Exception('Failed to generate recipes: ${response.body}');
      }
    } catch (e) {
      _logger.severe('Error during AI recipe generation: $e');
      rethrow;
    }
  }

  // Fetch additional recipe data from Spoonacular API
  Future<Map<String, dynamic>> fetchRecipeDetails(String ingredients) async {
    _logger.info(
        'Fetching recipe details from Spoonacular API for ingredients: $ingredients');

    final uri = Uri.parse(
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredients&number=1&apiKey=$spoonacularApiKey');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          _logger.info('Received recipe data from Spoonacular API.');
          return data[0];
        } else {
          _logger.warning('No recipes found for ingredients: $ingredients');
          return {};
        }
      } else {
        _logger.severe(
            'Failed to fetch recipe details. Response code: ${response.statusCode}');
        throw Exception('Failed to fetch recipe details');
      }
    } catch (e) {
      _logger.severe('Error during fetching recipe details: $e');
      rethrow;
    }
  }

  // Parse AI-generated recipe into structured format
  Map<String, dynamic> parseAIRecipe(String aiRecipe) {
    final recipe = {
      'name': '',
      'ingredients': <String>[],
      'instructions': '',
      'cooking_time': '',
      'servings': ''
    };

    final nameMatch = RegExp(r'Recipe Name:\s*(.*)').firstMatch(aiRecipe);
    final ingredientsMatch =
        RegExp(r'Ingredients:\s*((?:-.*\n)+)').firstMatch(aiRecipe);
    final instructionsMatch =
        RegExp(r'Instructions:\s*((?:\d+\..*\n)+)').firstMatch(aiRecipe);
    final cookingTimeMatch =
        RegExp(r'Total Cooking Time:\s*(\d+) minutes').firstMatch(aiRecipe);
    final servingsMatch = RegExp(r'Serving Size:\s*(\d+)').firstMatch(aiRecipe);

    recipe['name'] = nameMatch?.group(1) ?? 'Unnamed Recipe';
    recipe['ingredients'] = ingredientsMatch != null
        ? ingredientsMatch
            .group(1)!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList()
        : ['No ingredients provided'];
    recipe['instructions'] = instructionsMatch != null
        ? instructionsMatch
            .group(1)!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .join('\n')
        : 'No instructions provided';
    recipe['cooking_time'] = cookingTimeMatch?.group(1) ?? 'N/A';
    recipe['servings'] = servingsMatch?.group(1) ?? 'N/A';

    return recipe;
  }

  // Combine AI-generated recipe and Spoonacular data
  Future<Map<String, dynamic>> generateCompleteRecipe(
    String ingredients, {
    String? cuisineType,
    String? dietaryRestrictions,
  }) async {
    try {
      String aiRecipe = await generateRecipeUsingAI(ingredients,
          cuisineType: cuisineType, dietaryRestrictions: dietaryRestrictions);
      Map<String, dynamic> spoonacularData =
          await fetchRecipeDetails(ingredients);

      // Parse the AI response to get structured data
      Map<String, dynamic> parsedRecipe = parseAIRecipe(aiRecipe);

      return {
        'name': parsedRecipe['name'] ??
            spoonacularData['title'] ??
            'Unnamed Recipe',
        'image': spoonacularData['image'] ?? '',
        'ingredients': parsedRecipe['ingredients'].isNotEmpty
            ? parsedRecipe['ingredients']
            : spoonacularData['usedIngredients']
                    ?.map((ing) => ing['original'])
                    .toList() ??
                ['Ingredients not provided'],
        'instructions':
            parsedRecipe['instructions'] ?? 'Instructions not provided',
        'cooking_time': parsedRecipe['cooking_time'] ??
            spoonacularData['readyInMinutes']?.toString() ??
            'N/A',
        'servings': parsedRecipe['servings'] ??
            spoonacularData['servings']?.toString() ??
            'N/A',
      };
    } catch (e) {
      _logger.severe('Error combining AI recipe and Spoonacular data: $e');
      return {
        'name': 'Error generating recipe',
        'image': '',
        'ingredients': ['Failed to generate ingredients'],
        'instructions': 'Failed to generate instructions',
        'cooking_time': 'N/A',
        'servings': 'N/A',
      };
    }
  }
}
