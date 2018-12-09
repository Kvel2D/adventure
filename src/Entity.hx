
import haxegon.*;

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

static var all = new Array<Int>();
static var id_max: Int = 0;
// NOTE: only use NONE for initializing and clearing entity references
// don't "==/!= NONE", check for component existence instead
static inline var NONE = -1;

static var position = new Map<Int, Position>();
static var name = new Map<Int, String>();
static var description = new Map<Int, String>();
static var draw_tile = new Map<Int, Int>();
static var draw_char = new Map<Int, DrawChar>();
static var equipment = new Map<Int, Equipment>();
static var armor = new Map<Int, Armor>();
static var weapon = new Map<Int, Weapon>();
static var item = new Map<Int, Item>();
static var use = new Map<Int, Use>();
static var combat = new Map<Int, Combat>();
static var drop_item = new Map<Int, DropItem>();
static var talk = new Map<Int, String>();
static var give_copper_on_death = new Map<Int, GiveCopper>();

static function make(): Int {
    var e = id_max;
    id_max++;

    all.push(e);

    return e;
}

static function remove(e: Int) {
    all.remove(e);

    position.remove(e);
    name.remove(e);
    description.remove(e);
    draw_tile.remove(e);
    draw_char.remove(e);
    equipment.remove(e);
    armor.remove(e);
    weapon.remove(e);
    item.remove(e);
    use.remove(e);
    combat.remove(e);
    drop_item.remove(e);
    talk.remove(e);
    give_copper_on_death.remove(e);
}

static function print(e: Int) {
    trace('id=$e');
    trace('position=${position[e]}');
    trace('name=${name[e]}');
    trace('description=${description[e]}');
    trace('draw_tile=${draw_tile[e]}');
    trace('draw_char=${draw_char[e]}');
    trace('equipment=${equipment[e]}');
    trace('armor=${armor[e]}');
    trace('weapon=${weapon[e]}');
    trace('item=${item[e]}');
    trace('use=${use[e]}');
    trace('combat=${combat[e]}');
    trace('drop_item=${drop_item[e]}');
    trace('talk=${talk[e]}');
    trace('give_copper_on_death=${give_copper_on_death[e]}');
}

static function validate(e: Int) {
    var error = false;
    // Dependencies
    if (equipment.exists(e) && !weapon.exists(e) && !armor.exists(e)) {
        trace('Missing dependency: Equipment needs Weapon or Armor.');
        error = true;
    }
    if (use.exists(e) && !name.exists(e) && !item.exists(e)) {
        trace('Missing dependency: Use needs Name or Item.');
        error = true;
    }
    if (equipment.exists(e) && !position.exists(e)) {
        trace('Missing *initial* dependency: Equipment needs Position on creation.');
        error = true;
    }
    if (item.exists(e) && !position.exists(e)) {
        trace('Missing *initial* dependency: Item needs Position on creation.');
        error = true;
    }

    // Conflicts
    if (armor.exists(e) && weapon.exists(e)) {
        trace('Conflict: Armor and Weapon.');
        error = true;
    }

    if (error) {
        trace('For entity [$e]');
    }
}

//
// Position stuff
//
static var position_map = Data.int_2d_vector(Main.map_width, Main.map_height, Entity.NONE);

static function set_position(e: Int, x: Int, y: Int) {
    // Clear old position
    if (position.exists(e)) {
        var pos = position[e];
        position_map[pos.x][pos.y] = Entity.NONE;
    }

    // Write new position
    if (position_map[x][y] != Entity.NONE) {
        trace('position already occupied');
    }
    position[e] = {
        x: x,
        y: y,
    };
    position_map[x][y] = e;
}

static function remove_position(e: Int) {
    // Clear old position
    if (position.exists(e)) {
        var pos = position[e];
        position_map[pos.x][pos.y] = Entity.NONE;
    }

    position.remove(e);
}

static function at(x: Int, y: Int): Int {
    return position_map[x][y];
}

function new() {}
}