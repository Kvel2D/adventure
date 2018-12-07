
using Lambda;

typedef Combat = {
    var health: Int;
    var attack: Int;
    var message: String;
}

@:publicFields
class Entity {
// NOTE: force unindent

var type: String;
var x: Int = 0;
var y: Int = 0;

static var draw_char = [
    'snail' => 'S',
    'bear' => 'B',
    'fountain' => 'F',
];

static var examine = [
    'snail' => 'A green snail with a brown shell.',
    'bear' => 'You try talking to the Bear, it roars angrily at you.',
    'fountain' => 'A beautiful fountain. Water flowing through it looks magical.',
];

static var talk = [
    'snail' => 'You try talking to the Snail, it doesn\'t respond.',
    'bear' => 'You try talking to the Bear, it roars angrily at you.',
];

static var combat = [
    'snail' => {health: 2, attack: 1, message: 'Snail silently defends itself.'},
    'bear' => {health: 2, attack: 2, message: 'Bear roars angrily at you'},
];

static var use = [
    'fountain' => 'heal 2',
];


static function make(x: Int, y: Int, type: String): Entity {
    var e = new Entity();
    e.type = type;
    e.x = x;
    e.y = y;

    all.push(e);

    return e;
}

function print() {
    trace('type=$type');
    trace('x=$y');
    trace('x=$y');
    if (Entity.draw_char.exists(type)) {
        trace('draw_char=${Entity.draw_char[type]}');
    }
    if (Entity.combat.exists(type)) {
        trace('combat=${Entity.combat[type]}');
    }
    if (Entity.use.exists(type)) {
        trace('use=${Entity.use[type]}');
    }
    if (Entity.examine.exists(type)) {
        trace('examine=${Entity.examine[type]}');
    }
    if (Entity.talk.exists(type)) {
        trace('talk=${Entity.talk[type]}');
    }
}

static var all: Array<Entity> = [];

static function at(x, y): Entity {
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