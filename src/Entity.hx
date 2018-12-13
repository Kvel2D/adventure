
import haxegon.*;

using MathExtensions;

enum ArmorType {
    ArmorType_Head;
    ArmorType_Chest;
    ArmorType_Legs;
}

enum WeaponType {
    WeaponType_Sword;
}

enum ItemType {
    ItemType_Normal;
    ItemType_Ring;
}

enum UseType {
    UseType_Heal;
}

enum AggressionType {
    AggressionType_Aggressive; // attack if player is close
    AggressionType_Neutral; // attack only in response
    AggressionType_Passive; // never attack
}

enum MoveType {
    MoveType_Astar;
    MoveType_Straight;
    MoveType_Random;
}

enum ElementType {
    ElementType_Physical;
    ElementType_Fire;
    ElementType_Ice;
    ElementType_Shadow;
    ElementType_Light;
}

enum SpellType {
    SpellType_ModHealth;
    SpellType_ModHealthMax;
    SpellType_ModAttack;
}

enum SpellDuration {
    SpellDuration_Permanent;
    SpellDuration_EveryTurn;
    SpellDuration_EveryAttack;
}

typedef Spell = {
    var type: SpellType;
    var element: ElementType;
    var duration_type: SpellDuration;
    var duration: Int;
    var interval: Int;
    var interval_current: Int;
    var value: Int;
    var origin_name: String;
}

typedef Combat = {
    var health: Int;
    var attack: Int;
    var message: String;
    var aggression: AggressionType;
    var attacked_by_player: Bool;
}

typedef Use = {
    var spells: Array<Spell>;
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
    var element: ElementType;
}

typedef GiveCopper = {
    var chance: Int;
    var min: Int;
    var max: Int;
}

typedef Item = {
    var name: String;
    var type: ItemType;
    var spells: Array<Spell>;
}

typedef Position = {
    var x: Int;
    var y: Int;
    var room: Int;
}

typedef DropItem = {
    var type: String;
    var chance: Int;
}

typedef DrawChar = {
    var char: String;
    var color: Int;
}

typedef Move = {
    var type: MoveType;
    var cant_move: Bool;
}

@:publicFields
class Entity {
// NOTE: force unindent

static var all = new Array<Int>();
static var id_max: Int = 0;
// NOTE: only use NONE for initializing and clearing entity references
// don't "==/!= NONE", check for component existence instead
static inline var NONE = -1;
static inline var INFINITE = -1;

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
static var move = new Map<Int, Move>();

static function make(): Int {
    var e = id_max;
    id_max++;

    all.push(e);

    return e;
}

static function remove(e: Int) {
    all.remove(e);

    remove_position(e);
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
    move.remove(e);

    move.remove(e);
}

static function print(e: Int) {
    trace('----------------------------');
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
    trace('move=${move[e]}');
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
    if (move.exists(e) && !position.exists(e)) {
        trace('Missing dependency: Move needs Position.');
        error = true;
    }

    // Conflicts
    if (armor.exists(e) && weapon.exists(e)) {
        trace('Conflict: Armor and Weapon.');
        error = true;
    }
    if (item.exists(e) && equipment.exists(e)) {
        trace('Conflict: Item and Equipment.');
        error = true;
    }

    // Other
    if (position.exists(e) && Entity.position[e].room == -1) {
        trace('Error: Position.room = -1.');
        error = true;
    }

    if (error) {
        trace('For entity:');
        print(e);
    }
}

static var position_map = Data.create2darray(Main.map_width, Main.map_height, Entity.NONE);

static function set_position(e: Int, x: Int, y: Int) {
    var new_room = -1;

    if (position.exists(e)) {
        // Clear old position
        var pos = position[e];
        position_map[pos.x][pos.y] = Entity.NONE;

        // If didn't change rooms, can skip recalculating new room
        var old_room = Main.rooms[pos.room];
        if (Math.point_box_intersect(x, y, old_room.x, old_room.y, old_room.width + 1, old_room.height + 1)) {
            new_room = pos.room;
        }
    }

    // Need to recalculate room
    if (new_room == -1) {
        new_room = Main.get_room_index(x, y);
    }

    if (position_map[x][y] != Entity.NONE) {
        trace('new position occupied');
    }

    // Write new position
    position[e] = {
        x: x,
        y: y,
        room: new_room,
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