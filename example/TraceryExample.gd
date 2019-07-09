extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# A simple grammar - or read from a JSON file
	var grammarTest = Dictionary()
	grammarTest["sentence"] 	= ["A #colour# #animal.capitalize#"]
	grammarTest["animal"] 		= ["dog", "cat", "mouse", "rat", "cow", "pig", "unicorn"]
	grammarTest["colour"]		= ["#tone# #baseColour#"]
	grammarTest["tone"] 		= ["dark", "light", "pale"]
	grammarTest["baseColour"] 	= ["red", "green", "blue", "yellow"]
	
	# Create our grammar
	var grammar = Tracery.Grammar.new( grammarTest )

	# Add the english modifiers
	grammar.addModifiers( Tracery.UniversalModifiers.getModifiers() )
	
	# Flatten / generate a couple of sentences
	for i in range( 0, 5 ):
		var sentence = grammar.flatten( "#sentence#" )
		print( sentence )
	
