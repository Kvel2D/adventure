
import haxegon.*;

typedef ValChancePair = {
    v: Dynamic, // value
    c: Float    // chance that value is picked
};

@:publicFields
class Chance {
// NOTE: force unindent

static function pick(pairs: Array<ValChancePair>): Dynamic {
    var total = 0.0;
    for (e in pairs) {
        total += e.c;
    }
    for (i in 1...pairs.length) {
        pairs[i].c += pairs[i - 1].c;
    }

    var k = Random.float(0, total);

    for (e in pairs) {
        if (k <= e.c) {
            return e.v;
        }
    }

    trace('pick() failed');
    return pairs[0].v;
}

}