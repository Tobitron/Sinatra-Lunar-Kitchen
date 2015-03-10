require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: "recipes")
    yield(connection)
  ensure
    connection.close
  end
end

  ALL_RECIPES = db_connection do |conn|
    conn.exec("SELECT id, name, instructions, description FROM recipes;").to_a
  end

class Recipe
  attr_reader(:id, :name, :instructions, :description)

  def initialize(id, name, instructions, description)
    @id = id
    @name = name
    @instructions = instructions
    @description = description
  end

  # returns an array of a recipe's ingredients using the recipe id
  def ingredients
    ingredients = db_connection do |conn|
      conn.exec("SELECT ingredients.name FROM recipes
                 JOIN ingredients ON ingredients.recipe_id = recipes.id
                  WHERE recipes.id = ($1)", [@id])
    end
    ingredients_list = []
    ingredients.to_a.each do |ingredient|
      ingredients_list << Ingredient.new(ingredient["name"])
    end
    ingredients_list
  end

  def self.find(params_id)
    all.each do |recipe|
      return recipe if recipe.id == params_id
    end
    return Recipe.new(params_id, "Recipe does not exist", "This recipe doesn't have any instructions.", "This recipe doesn't have a description." )
  end

  #return all recipe data
  def self.all
    recipes = []
    ALL_RECIPES.each do |recipe|
      if recipe != []
        id = recipe["id"]
        name = recipe["name"]
        instructions = recipe["instructions"]
        description = recipe["description"]
        recipes << Recipe.new(id, name, instructions, description)
      end
    end
    recipes
  end

end
