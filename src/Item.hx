
enum ItemType {
    ItemType_Gold;
}

@:publicFields
class Item {

var type: ItemType;
var x: Int = 0;
var y: Int = 0;

function draw_char() {
    
}

static function gold(x: Int, y: Int): Entity {
    var e = new Item();
    e.x = x;
    e.y = y;

    all.push(e);

    return e;
}

static var all: Array<Item> = [];

static function at(x, y): Item {
    for (e in all) {
        if (e.x == x && e.y == y) {
            return e;
            break;
        }
    }

    return null;
}

function new() {}
}