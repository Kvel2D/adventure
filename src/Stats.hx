
import haxegon.*;

typedef Stat = {
    min: Float,
    max: Float,
    scaling: Float,
}

@:publicFields
class Stats {
// force unindent

// Random base in defined range
// + scaling * level
// varied by +-20%
static function get_unrounded(stat: Stat, level: Int): Float {
    var base = Random.float(stat.min, stat.max);
    var avg = base + stat.scaling * level;
    return Random.float(avg * 0.8, avg * 1.2); 
}

static function get(stat: Stat, level: Int): Int {
    return Std.int(Math.max(1, Math.round(get_unrounded(stat, level)))); 
}

}