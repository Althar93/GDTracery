extends Reference

class_name Tracery
        
class Modifiers extends Reference:
    
    static func _isConsonant( character : String ) -> bool:
        var lowerCaseCharacter = character.to_lower()
        match lowerCaseCharacter:
            "a": return false
            "e": return false
            "i": return false
            "o": return false
            "u": return false
            _  : return true
            
    static func _endsWithConY( string : String ) -> bool:
        var lastCharacter           = string[ string.length() - 1 ]
        var secondToLastCharacter   = string[ string.length() - 2 ]
        
        if lastCharacter == "y":
            return _isConsonant( secondToLastCharacter )
        else:
            return false
            
class UniversalModifiers extends Modifiers:

    static func getModifiers():
        var modifiers = {
            "a"             :   [ UniversalModifiers, "a" ],
            "beeSpeak"      :   [ UniversalModifiers, "beeSpeak" ],
            "capitalize"    :   [ UniversalModifiers, "capitalize" ],
            "capitalizeAll" :   [ UniversalModifiers, "capitalizeAll" ],
            "comma"         :   [ UniversalModifiers, "comma" ],
            "inQuotes"      :   [ UniversalModifiers, "inQuotes" ],
            "s"             :   [ UniversalModifiers, "s" ],
            "ed"            :   [ UniversalModifiers, "ed" ]
        }
        return modifiers
    
    static func a( string : String ) -> String:
        var firstCharacter = string[ 0 ]
        
        if !_isConsonant( firstCharacter ):
            return "an " + string
        else:
            return "a" + string
        
    static func beeSpeak( string : String ) -> String:
        return string.replace( "s", "zzz" )
        
    static func capitalize( string : String ) -> String:
        var firstCharacter = string[ 0 ]
        
        return firstCharacter.to_upper() + string.substr( 1, string.length() - 1 )
        
    static func capitalizeAll( string : String ) -> String:
        assert( false )
        return string
        
    static func comma( string : String ) -> String:
        var lastCharacter = string[ string.length() - 1 ]
        
        match lastCharacter:
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
                
    static func inQuotes( string : String ) -> String:
        return "\"" + string + "\""
        
    static func s( string : String ) -> String:
        var lastCharacter           = string[ string.length() - 1 ]
        var secondToLastCharacter   = string[ string.length() - 2 ]
        
        match lastCharacter :
            "y":
                # rays, convoys
                if !_isConsonant( secondToLastCharacter ):
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
        
    static func ed( string : String ) -> String:
        var lastCharacter           = string[ string.length() - 1 ]
        var secondToLastCharacter   = string[ string.length() - 2 ]
        var rest                    = ""
        
        var index = string.find( " " )
        if index > 0 :
            string = string.substr( index, string.length() )
            rest   = string.substr( 0, index )
            
        match lastCharacter:
            "y": 
                # rays, convoys
                if _isConsonant( secondToLastCharacter ):
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
    
    var _modifierLookup     : Dictionary            = {}        # Modifier function table
    var _rules              : Dictionary            = {}        # The rules
    var _saveData           : Dictionary            = {}        # The saved data
    var _rng                : RandomNumberGenerator = null      # The random number generator
    
    var _expansionRegex     : RegEx                 = null      # The expansion regex
    var _saveSymbolRegex    : RegEx                 = null      # The save symbol regex
    
    func _init( rules : Dictionary ):
        # Expansion regex
        _expansionRegex = RegEx.new()
        _expansionRegex.compile( "(?<!\\[|:)(?!\\])#.+?(?<!\\[|:)#(?!\\])" )
        
        # Save symbol regex
        _saveSymbolRegex = RegEx.new()
        _saveSymbolRegex.compile( "\\[.+?\\]" )
        
        # Default random number generator
        _rng = RandomNumberGenerator.new()
        
        # Randomize seed
        _rng.randomize()
        
        # Populate the rules list
        _rules = rules.duplicate( true )
                
    func addModifier( key : String, object : Object, function : String ) -> void:
        _modifierLookup[ key ] = [ object, function ]
        
    func addModifiers( modifiers : Dictionary ) -> void:
        for k in modifiers.keys():
            _modifierLookup[ k ] = modifiers[ k ]
            
    func setRng( rng : RandomNumberGenerator ) -> void:
        _rng = rng
        
    func flatten( rule : String ) -> String:
        var expansionMatches = _expansionRegex.search_all( rule )
        
        if expansionMatches.empty():
            _resolveSaveSymbols( rule )

        for matchResult in expansionMatches:
            # Get hold of the match value
            var matchValue = matchResult.strings[0]
            
            # Resolve save symbols
            _resolveSaveSymbols( matchValue )
            
            # Remove the # surrounding the symbol name
            var matchName = matchValue.replace( "#", "" )
            
            # Remove the save symbols
            matchName = _saveSymbolRegex.sub( matchName, "", true )
            
            # Take match name until the first '.' if it exists
            var dotIndex = matchName.find( "." )
            if dotIndex >= 0:
                matchName = matchName.substr( 0, dotIndex )
                
            # Get modifiers
            var modifiers = _getModifiers( matchValue )

            # Look for the selected rule in either the rules, saved data or as a standalone rule
            var selectedRule = matchName
            if _rules.has( matchName ):
                selectedRule = _rules[ matchName ]
            elif _saveData.has( matchName ):
                selectedRule = _saveData[ matchName ]
                
            # A rule is either an array or a single entry/string
            if typeof( selectedRule ) == TYPE_ARRAY:
                var randIndex   = _rng.randi() % selectedRule.size()
                var chosen      = selectedRule[ randIndex ] as String
                var resolved    = flatten( chosen )
                
                resolved = _applyModifiers( resolved, modifiers )
                
                rule = rule.replace( matchValue, resolved )
            else:
                var resolved    = flatten( selectedRule )
                
                resolved = _applyModifiers( resolved, modifiers )
                
                rule = rule.replace( matchValue, resolved )
                
        # Done
        return rule
        
    func _resolveSaveSymbols( rule : String ) -> void:
        var saveMatches = _saveSymbolRegex.search_all( rule )
        for matchResult in saveMatches:
            var matchValue = matchResult.strings[0]
            
            var save = matchValue.replace( "[", "" ).replace( "]", "" )
            
            var saveSplit = save.split(":")
                
            if saveSplit.size() == 2:
                var name = saveSplit[0]
                var data = flatten( saveSplit[1] )
                _saveData[ name ] = data
            else:
                var name = save
                var data = flatten( "#" + save + "#" )
                _saveData[ name ] = data
                
    func _getModifiers( symbol : String ) -> Array:
        var modifiers = symbol.replace( "#", "" ).split( "." )
        modifiers.remove( 0 )
        return modifiers
        
    func _applyModifiers( resolved : String, modifiers : Array ) -> String:
        for m in modifiers:
            if _modifierLookup.has( m ):
                var object   = _modifierLookup[ m ][ 0 ]
                var function = _modifierLookup[ m ][ 1 ]
                resolved     = object.call( function, resolved )
        return resolved
