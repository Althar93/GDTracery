class_name Tracery
extends Reference
		
		
class Modifiers extends Reference:
	
	
	static func _is_consonant( character : String ) -> bool:
		var lower_case_character = character.to_lower()
		match lower_case_character:
			"a": return false
			"e": return false
			"i": return false
			"o": return false
			"u": return false
			_  : return true
			
			
	static func _ends_with_con_y( string : String ) -> bool:
		var last_character = string[ string.length() - 1 ]
		var second_to_last_character = string[ string.length() - 2 ]
		
		if last_character == "y":
			return _is_consonant( second_to_last_character )
		else:
			return false
			
			
class UniversalModifiers extends Modifiers:
	
	
	static func get_modifiers():
		var modifiers = {
			"a" : [ UniversalModifiers, "_a" ],
			"beeSpeak" : [ UniversalModifiers, "_beeSpeak" ],
			"capitalize" : [ UniversalModifiers, "_capitalize" ],
			"capitalizeAll" : [ UniversalModifiers, "_capitalizeAll" ],
			"comma" : [ UniversalModifiers, "_comma" ],
			"inQuotes" : [ UniversalModifiers, "_inQuotes" ],
			"s" : [ UniversalModifiers, "_s" ],
			"ed" : [ UniversalModifiers, "_ed" ]
		}
		return modifiers
		
		
	static func _a( string : String ) -> String:
		var first_character = string[ 0 ]
		
		if !_is_consonant( first_character ):
			return "an " + string
		else:
			return "a" + string
			
		
	static func _bee_speak( string : String ) -> String:
		return string.replace( "s", "zzz" )
		
		
	static func _capitalize( string : String ) -> String:
		var first_character = string[ 0 ]
		
		return first_character.to_upper() + string.substr( 1, string.length() - 1 )
		
		
	static func _capitalize_all( string : String ) -> String:
		assert( false )
		return string
		
		
	static func _comma( string : String ) -> String:
		var last_character = string[ string.length() - 1 ]
		
		match last_character:
			",":
				return string
			".":
				return string
			"?":
				return string
			"!":
				return string
			_:
				return string + ","
			
				
	static func _in_quotes( string : String ) -> String:
		return "\"" + string + "\""
		
		
	static func _s( string : String ) -> String:
		var last_character = string[ string.length() - 1 ]
		var second_to_last_character = string[ string.length() - 2 ]
		
		match last_character :
			"y":
				# rays, convoys
				if !_is_consonant( second_to_last_character ):
					return string + "s"
				# harpies, cries
				else:
					return string.substr( 0, string.length() - 1 ) + "ies"
			"x":
				# oven, boxen, foxen
				return string.substr( 0, string.length() - 1 ) + "xen"
			"z":
				return string.substr( 0, string.length() - 1 ) + "zes"
			"h":
				return string.substr( 0, string.length() - 1 ) + "hes"
			_:
				return string + "s"
				
				
	static func _ed( string : String ) -> String:
		var last_character = string[ string.length() - 1 ]
		var second_to_last_character = string[ string.length() - 2 ]
		var rest = ""
		
		
		var index = string.find( " " )
		if index > 0 :
			string = string.substr( index, string.length() )
			rest = string.substr( 0, index )
			
			
		match last_character:
			"y": 
				# rays, convoys
				if _is_consonant( second_to_last_character ):
					return string.substr( 0, string.length() - 1 ) + "ied" + rest
				# harpies, cries
				else:
					return string + "ed" + rest
			"e":
				return string + "d" + rest
			_:
				return string + "ed" + rest
				
				
# Main grammar
class Grammar extends Reference:
	
	
	var rng : RandomNumberGenerator = null setget set_rng, get_rng # The random number generator
	
	var _modifier_lookup : Dictionary = {} # Modifier function table
	var _rules : Dictionary = {} # The rules
	var _save_data : Dictionary = {} # The saved data
	var _expansion_regex : RegEx = null # The expansion regex
	var _save_symbol_regex : RegEx = null # The save symbol regex
	
	
	func _init( rules : Dictionary ):
		# Expansion regex
		_expansion_regex = RegEx.new()
		_expansion_regex.compile( "(?<!\\[|:)(?!\\])#.+?(?<!\\[|:)#(?!\\])" )
		
		# Save symbol regex
		_save_symbol_regex = RegEx.new()
		_save_symbol_regex.compile( "\\[.+?\\]" )
		
		# Default random number generator
		rng = RandomNumberGenerator.new()
		
		# Randomize seed
		rng.randomize()
		
		# Populate the rules list
		_rules = rules.duplicate( true )
		
		
	func add_modifier( key : String, object : Object, function : String ) -> void:
		_modifier_lookup[ key ] = [ object, function ]
		
		
	func add_modifiers( modifiers : Dictionary ) -> void:
		for k in modifiers.keys():
			_modifier_lookup[ k ] = modifiers[ k ]
			
			
	func set_rng( rng : RandomNumberGenerator ) -> void:
		rng = rng
		
		
	func get_rng() -> RandomNumberGenerator:
		return rng
		
		
	func flatten( rule : String ) -> String:
		var expansion_matches = _expansion_regex.search_all( rule )
		
		if expansion_matches.empty():
			_resolve_save_symbols( rule )
			
		for match_result in expansion_matches:
			# Get hold of the match value
			var match_value = match_result.strings[0]
			
			# Resolve save symbols
			_resolve_save_symbols( match_value )
			
			# Remove the # surrounding the symbol name
			var match_name = match_value.replace( "#", "" )
			
			# Remove the save symbols
			match_name = _save_symbol_regex.sub( match_name, "", true )
			
			# Take match name until the first '.' if it exists
			var dot_index = match_name.find( "." )
			if dot_index >= 0:
				match_name = match_name.substr( 0, dot_index )
				
			# Get modifiers
			var modifiers = _get_modifiers( match_value )
			
			# Look for the selected rule in either the rules, saved data or as a standalone rule
			var selected_rule = match_name
			if _rules.has( match_name ):
				selected_rule = _rules[ match_name ]
			elif _save_data.has( match_name ):
				selected_rule = _save_data[ match_name ]
				
			# A rule is either an array or a single entry/string
			if typeof( selected_rule ) == TYPE_ARRAY:
				var rand_index  = rng.randi() % selected_rule.size()
				var chosen = selected_rule[ rand_index ] as String
				var resolved = flatten( chosen )
				
				resolved = _apply_modifiers( resolved, modifiers )
				
				rule = rule.replace( match_value, resolved )
			else:
				var resolved = flatten( selected_rule )
				
				resolved = _apply_modifiers( resolved, modifiers )
				
				rule = rule.replace( match_value, resolved )
				
		# Done
		return rule
		
		
	func _resolve_save_symbols( rule : String ) -> void:
		var save_matches = _save_symbol_regex.search_all( rule )
		for match_result in save_matches:
			var match_value = match_result.strings[0]
			
			var save = match_value.replace( "[", "" ).replace( "]", "" )
			
			var save_split = save.split(":")
				
			if save_split.size() == 2:
				var name = save_split[0]
				var data = flatten( save_split[1] )
				_save_data[ name ] = data
			else:
				var name = save
				var data = flatten( "#" + save + "#" )
				_save_data[ name ] = data
				
				
	func _get_modifiers( symbol : String ) -> Array:
		var modifiers = symbol.replace( "#", "" ).split( "." )
		modifiers.remove( 0 )
		return modifiers
		
		
	func _apply_modifiers( resolved : String, modifiers : Array ) -> String:
		for m in modifiers:
			if _modifier_lookup.has( m ):
				var object = _modifier_lookup[ m ][ 0 ]
				var function = _modifier_lookup[ m ][ 1 ]
				resolved = object.call( function, resolved )
		return resolved
