extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Use a custom random number generator
	var rng = RandomNumberGenerator.new()
	
	# First example
	_example_1(rng)
		
	# Second example
	_example_2(rng)
	
	
func _example_1( rng : RandomNumberGenerator ) -> void :
	print("Example 1 :")
	
	# A simple grammar - or read from a JSON file
	var grammar_test = Dictionary()
	grammar_test["sentence"] = ["A #colour# #animal.capitalize#"]
	grammar_test["animal"] = ["dog", "cat", "mouse", "rat", "cow", "pig", "unicorn"]
	grammar_test["colour"] = ["#tone# #baseColour#"]
	grammar_test["tone"] = ["dark", "light", "pale"]
	grammar_test["baseColour"] = ["red", "green", "blue", "yellow"]
	
	# Create our grammar
	var grammar = Tracery.Grammar.new( grammar_test )

	# Use our custom random number generator
	grammar.rng = rng
	
	# Add the english modifiers
	grammar.add_modifiers(Tracery.UniversalModifiers.get_modifiers())
	
	# Flatten / generate a couple of sentences
	for i in range( 0, 5 ):
		var sentence = grammar.flatten("#sentence#")
		print(sentence)
		

func _example_2( rng : RandomNumberGenerator ) -> void :
	print("Example 2 :")
	
	# A second gramma examplle
	var grammar_test = Dictionary()
	grammar_test["baseColor"] = ["red", "yellow", "green", "blue"]
	grammar_test["colors"] = ["#baseColor# and #baseColor#"]
	
	# Create our grammar
	var grammar = Tracery.Grammar.new( grammar_test )
	
	# Use our custom random number generator
	grammar.rng = rng

	# Flatten / generate a couple of sentences
	for i in range( 0, 5 ):
		var sentence = grammar.flatten("#colors#")
		print(sentence)
