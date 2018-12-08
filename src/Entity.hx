
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

enum UseType {
    UseType_Heal;
}

typedef Combat = {
    var health: Int;
    var attack: Int;
    var message: String;
}

typedef Use = {
    var type: UseType;
    var value: Int;
    var charges: Int;
    var consumable: Bool;
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

typedef Position = {
    var x: Int;
    var y: Int;
}

typedef DropItem = {
    var type: String;
    var chance: Int;
}

typedef DrawChar = {
    var char: String;
    var color: Int;
}

@:publicFields
class Entity {
// NOTE: force unindent

static var all: Array<Int> = [];
static var id_max: Int = 0;
static inline var NONE = -1;

static var position = new Map<Int, Position>();
static var name = new Map<Int, String>();
static var draw_tile = new Map<Int, Int>();
static var draw_char = new Map<Int, DrawChar>();
static var equipment = new Map<Int, Equipment>();
static var armor = new Map<Int, Armor>();
static var weapon = new Map<Int, Weapon>();
static var item = new Map<Int, Item>();
static var use = new Map<Int, Use>();
static var drop_item = new Map<Int, DropItem>();
static var description = new Map<Int, String>();
static var talk = new Map<Int, String>();
static var give_copper_on_death = new Map<Int, GiveCopper>();
static var combat = new Map<Int, Combat>();

static function equipped_or_picked_up(e: Int): Bool {
    return (equipment.exists(e) && equipment[e].equipped) || (item.exists(e) && item[e].picked_up);
}

static function make(x: Int, y: Int): Int {
    var e = id_max;
    id_max++;

    set_position(e, x, y);

    all.push(e);

    return e;
}

static function make_snail(x: Int, y: Int): Int {
    var e = make(x, y);

    name[e] = 'Snail';
    drop_item[e] = {
        type: 'potion', 
        chance: 100
    };
    draw_char[e] = {
        char: 'S',
        color: Col.RED
    };
    description[e] = 'A green snail with a brown shell.';
    talk[e] = 'You try talking to the Snail, it doesn\'t respond.';
    give_copper_on_death[e] = {
        chance: 50, 
        min: 1, 
        max: 1
    };
    combat[e] = {
        health: 2, 
        attack: 1, 
        message: 'Snail silently defends itself.'
    };

    return e;
}

static function make_bear(x: Int, y: Int) {
    var e = make(x, y);

    name[e] = 'Bear';
    draw_char[e] = {
        char: 'B',
        color: Col.RED
    };
    description[e] = 'A brown bear, looks cute.';
    talk[e] = 'You try talking to the Bear, it roars angrily at you.';
    give_copper_on_death[e] = {
        chance: 50, 
        min: 1, 
        max: 2
    };
    combat[e] = {
        health: 2, 
        attack: 2, 
        message: 'Bear roars angrily at you.'
    };
}

static function make_armor(x: Int, y: Int, armor_type: ArmorType) {
    var e = make(x, y);

    var level = Random.int(1, 4);

    var armor_name = [
    ArmorType_Head => ['leather helmet', 'copper helmet', 'iron helmet', 'obsidian helmet'],
    ArmorType_Chest => ['leather chestplate', 'copper chestplate', 'iron chestplate', 'obsidian chestplate'],
    ArmorType_Legs => ['leather pants', 'copper pants', 'iron pants', 'obsidian pants'],
    ];
    var armor_tile = [
    ArmorType_Head => [Tile.Head1, Tile.Head2, Tile.Head3, Tile.Head4],
    ArmorType_Chest => [Tile.Chest1, Tile.Chest2, Tile.Chest3, Tile.Chest4],
    ArmorType_Legs => [Tile.Legs1, Tile.Legs2, Tile.Legs3, Tile.Legs4],
    ];

    name[e] = 'Armor';
    equipment[e] = {
        name: armor_name[armor_type][level - 1],
        equipped: false,
    };
    armor[e] = {
        type: armor_type, 
        defense: level * 4
    };
    draw_tile[e] = armor_tile[armor_type][level - 1];
}

static function make_sword(x: Int, y: Int) {
    var e = make(x, y);

    var level = Random.int(1, 4);

    var weapon_type = WeaponType_Sword;

    var weapon_name = [
    WeaponType_Sword => ['wooden sword', 'copper sword', 'iron sword', 'obsidian sword'],
    ];
    var weapon_tile = [
    WeaponType_Sword => [Tile.Sword2, Tile.Sword3, Tile.Sword4],
    ];

    name[e] = 'Weapon';
    equipment[e] = {
        name: weapon_name[weapon_type][level - 1],
        equipped: false,
    };
    weapon[e] = {
        type: weapon_type, 
        attack: Main.PLAYER_BASE_ATTACK + level
    };
    draw_tile[e] = weapon_tile[weapon_type][level - 1];
}

static function make_fountain(x: Int, y: Int): Int {
    var e = make(x, y);
    
    name[e] = 'Fountain';
    use[e] = {
        type: UseType_Heal,
        value: 2, 
        charges: 1,
        consumable: false,
    };
    draw_char[e] = {
        char: 'F',
        color: Col.WHITE
    };
    description[e] = 'A beautiful fountain. Water flowing through it looks magical.';

    return e;
}

static function make_potion(x: Int, y: Int): Int {
    var e = make(x, y);

    name[e] = 'Potion';
    item[e] = {
        name: "Healing potion",
        picked_up: false,
    };
    use[e] = {
        type: UseType_Heal,
        value: 2,
        charges: 1,
        consumable: true,
    };
    draw_tile[e] = Tile.Potion;

    return e;
}

static function make_item(x: Int, y: Int, item_type: String) {
    if (item_type == 'armor') {
        make_armor(x, y, ArmorType_Head);
    } else if (item_type == 'weapon') {
        make_sword(x, y);
    } else if (item_type == 'potion') {
        var e = make_potion(x, y);
        var pos = Entity.position[e];
        var found = Entity.at(pos.x, pos.y);
        trace('make item');
    }
}

static function print(e: Int) {
    trace('id=$e');
    trace('name=${Entity.name[e]}');
    trace('position=${Entity.position[e]}');
    trace('draw_char=${Entity.draw_char[e]}');
    trace('equipment=${Entity.equipment[e]}');
    trace('armor=${Entity.armor[e]}');
    trace('weapon=${Entity.weapon[e]}');
    trace('combat=${Entity.combat[e]}');
    trace('use=${Entity.use[e]}');
    trace('description=${Entity.description[e]}');
    trace('talk=${Entity.talk[e]}');
    trace('give_copper_on_death=${Entity.give_copper_on_death[e]}');
}

//
// Position stuff
//
static var position_map = Data.int_2d_vector(Main.MAP_WIDTH, Main.MAP_HEIGHT, Entity.NONE);

static function set_position(e: Int, x: Int, y: Int) {
    // Clear old position
    if (Entity.position.exists(e)) {
        var pos = Entity.position[e];
        position_map[pos.x][pos.y] = Entity.NONE;
    }

    // Write new position
    Entity.position[e] = {
        x: x,
        y: y,
    };
    position_map[x][y] = e;
}

static function remove_position(e: Int) {
    // Clear old position
    if (Entity.position.exists(e)) {
        var pos = Entity.position[e];
        position_map[pos.x][pos.y] = Entity.NONE;
    }

    Entity.position.remove(e);
}

static function at(x: Int, y: Int): Int {
    var e = position_map[x][y];
    if (e != Entity.NONE) {
        return e;
    }

    return Entity.NONE;
}

static function remove(e: Int) {
    all.remove(e);
    remove_position(e);
    Entity.draw_tile.remove(e);
    Entity.equipment.remove(e);
    Entity.armor.remove(e);
    Entity.weapon.remove(e);
    Entity.use.remove(e);
    Entity.drop_item.remove(e);
}

function new() {}
}