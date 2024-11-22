import 'package:flutter/material.dart';
import 'package:my_app/models/recipe.dart';

class RecipeProvider with ChangeNotifier {
  final List<Recipe> _recipes = [
    Recipe(
      name: "Pasta Primavera",
      ingredients: ["pasta", "tomato", "bell pepper", "zucchini"],
      instructions: "Boil pasta, sauté vegetables, mix, and serve hot.",
    ),
    Recipe(
      name: "Veggie Stir-fry",
      ingredients: ["broccoli", "carrot", "bell pepper", "soy sauce"],
      instructions: "Stir-fry vegetables in soy sauce, and serve with rice.",
    ),
    Recipe(
      name: "Tomato Soup",
      ingredients: ["tomato", "onion", "garlic", "basil"],
      instructions: "Blend ingredients and cook until warm. Serve with bread.",
    ),
  ];

  List<Recipe> getRecipesByIngredients(List<String> inputIngredients) {
    return _recipes.where((recipe) {
      return recipe.ingredients
          .every((ingredient) => inputIngredients.contains(ingredient));
    }).toList();
  }
}
