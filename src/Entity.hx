
import haxegon.*;

using Lambda;

enum ArmorType {
    ArmorType_Head;
    ArmorType_Chest;
    ArmorType_Legs;
}

enum WeaponType {
    WeaponType_Sword;
}

typedef Combat = {
    var health: Int;
    var attack: Int;
    var message: String;
}

typedef Use = {
    var name: String;
    var charges_max: Int;
}

typedef Equipment = {
    var name: String;
    var equipped: Bool;
}

typedef Armor = {
    var type: ArmorType;
    var defense: Int;
}

typedef Weapon = {
    var type: WeaponType;
    var attack: Int;
}

typedef GiveCopper = {
    var chance: Int;
    var min: Int;
    var max: Int;
}

typedef Item = {
    var name: String;
    var picked_up: Bool;
}


@:publicFields
class Entity {
// NOTE: force unindent

var type: String;
var id: Int = 0;
static var id_max: Int = 0;
var x: Int = 0;
var y: Int = 0;

// 
// Type specific
//
static var draw_char = [
    'snail' => 'S',
    'bear' => 'B',
    'fountain' => 'F',
    'item' => 'I',
];

static var draw_char_color = [
    'snail' => Col.RED,
    'bear' => Col.RED,
];

static var description = [
    'snail' => 'A green snail with a brown shell.',
    'bear' => 'A brown bear, looks cute.',
    'fountain' => 'A beautiful fountain. Water flowing through it looks magical.',
];

static var talk = [
    'snail' => 'You try talking to the Snail, it doesn\'t respond.',
    'bear' => 'You try talking to the Bear, it roars angrily at you.',
];

static var combat = [
    'snail' => {health: 2, attack: 1, message: 'Snail silently defends itself.'},
    'bear' => {health: 2, attack: 2, message: 'Bear roars angrily at you.'},
];

static var give_copper_on_death = [
    'snail' => {chance: 50, min: 1, max: 1},
    'bear' => {chance: 50, min: 1, max: 2},
];

static var use = [
    'fountain' => {name: 'heal 2', charges_max: 1},
];

//
// Subtype specific
//

static var armor_name = [
    ArmorType_Head => ['no helmet', 'leather helmet', 'copper helmet', 'iron helmet', 'obsidian helmet'],
    ArmorType_Chest => ['no chestplate', 'leather chestplate', 'copper chestplate', 'iron chestplate', 'obsidian chestplate'],
    ArmorType_Legs => ['no pants', 'leather pants', 'copper pants', 'iron pants', 'obsidian pants'],
];
static var armor_tile = [
    ArmorType_Head => [Tile.Head0, Tile.Head1, Tile.Head2, Tile.Head3, Tile.Head4],
    ArmorType_Chest => [Tile.Chest0, Tile.Chest1, Tile.Chest2, Tile.Chest3, Tile.Chest4],
    ArmorType_Legs => [Tile.Legs0, Tile.Legs1, Tile.Legs2, Tile.Legs3, Tile.Legs4],
];

static var weapon_name = [
    WeaponType_Sword => ['no weapon', 'wooden sword', 'copper sword', 'iron sword', 'obsidian sword'],
];
static var weapon_tile = [
    WeaponType_Sword => [Tile.Sword1, Tile.Sword2, Tile.Sword3, Tile.Sword4],
];


// 
// Instance specific
//
static var use_charges = new Map<Int, Int>();
static var stacks = new Map<Int, Int>();
static var equipment = new Map<Int, Equipment>();
static var armor = new Map<Int, Armor>();
static var weapon = new Map<Int, Weapon>();
static var draw_tile = new Map<Int, Int>();
static var item = new Map<Int, Item>();

function equipped_or_picked_up(): Bool {
    return (equipment.exists(id) && equipment[id].equipped) || (item.exists(id) && item[id].picked_up);
}

static function make(x: Int, y: Int, type: String): Entity {
    var e = new Entity();
    e.type = type;
    e.id = id_max;
    id_max++;
    e.x = x;
    e.y = y;

    if (use.exists(type)) {
        var entity_use = use[type];
        use_charges[e.id] = entity_use.charges_max;
    }

    all.push(e);

    return e;
}

static function make_armor(x: Int, y: Int, armor_type: ArmorType) {
    var e = make(x, y, 'armor');

    var level = Random.int(1, 4);

    Entity.equipment[e.id] = {
        name: armor_name[armor_type][level],
        equipped: false,
    };
    Entity.armor[e.id] = {
        type: armor_type, 
        defense: level * 4
    };
    Entity.draw_tile[e.id] = armor_tile[armor_type][level];
}

static function make_sword(x: Int, y: Int) {
    var e = make(x, y, 'weapon');

    var level = Random.int(1, 4);

    var weapon_type = WeaponType_Sword;

    Entity.equipment[e.id] = {
        name: weapon_name[weapon_type][level],
        equipped: false,
    };
    Entity.weapon[e.id] = {
        type: weapon_type, 
        attack: Main.PLAYER_BASE_ATTACK + level
    };
    Entity.draw_tile[e.id] = weapon_tile[weapon_type][level];
}

static function make_potion(x: Int, y: Int) {
    var e = make(x, y, 'potion');

    Entity.item[e.id] = {
        name: "Healing potion",
        picked_up: false,
    };
    Entity.draw_tile[e.id] = Tile.Potion;
}

function print() {
    trace('type=$type');
    trace('id=$id');
    trace('x=$y');
    trace('y=$y');
    if (Entity.draw_char.exists(type)) {
        trace('draw_char=${Entity.draw_char[type]}');
    }
    if (Entity.equipment.exists(id)) {
        trace('equipment=${Entity.equipment[id]}');
    }
    if (Entity.armor.exists(id)) {
        trace('armor=${Entity.armor[id]}');
    }
    if (Entity.weapon.exists(id)) {
        trace('weapon=${Entity.weapon[id]}');
    }
    if (Entity.use.exists(type)) {
        trace('use=${Entity.use[type]}');
        trace('use_charges=${Entity.use_charges[id]}');
    }
    if (Entity.description.exists(type)) {
        trace('description=${Entity.description[type]}');
    }
    if (Entity.talk.exists(type)) {
        trace('talk=${Entity.talk[type]}');
    }
}

static var all: Array<Entity> = [];

static function at(x, y): Entity {
    for (e in all) {
        if (e.x == x && e.y == y && !e.equipped_or_picked_up()) {
            return e;
            break;
        }
    }

    return null;
}

function new() {}
}