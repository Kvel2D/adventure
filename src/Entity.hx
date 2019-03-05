
import haxegon.*;
import Spells;

using MathExtensions;

enum EquipmentType {
    EquipmentType_Weapon;
    EquipmentType_Head;
    EquipmentType_Chest;
    EquipmentType_Legs;
}

enum ItemType {
    ItemType_Normal;
    ItemType_Ring;
}

enum AggressionType {
    AggressionType_Aggressive; // attack if player is close
    AggressionType_Neutral; // attack only in response
    AggressionType_NeutralToAggressive; // attack only in response
    AggressionType_Passive; // never attack
}

enum MoveType {
    MoveType_Astar;
    MoveType_Straight;
    MoveType_Random;
    MoveType_StayAway;
}

enum MoveTarget {
    MoveTarget_FriendlyOverPlayer;
    MoveTarget_EnemyOnly;
    MoveTarget_PlayerOnly;
    MoveTarget_EnemyOverPlayer;
}

enum CombatTarget {
    CombatTarget_FriendlyThenPlayer;
    CombatTarget_Enemy;
}

enum DropTable {
    DropTable_Default;
    DropTable_LockedChest;
}

typedef Combat = {
    var health: Int;
    var health_max: Int;
    var attack: Int;
    var message: String;
    var aggression: AggressionType;
    var attacked_by_player: Bool;
    var range_squared: Int;
    var target: CombatTarget;
}

typedef Use = {
    var spells: Array<Spell>;
    var charges: Int;
    var consumable: Bool;
    var flavor_text: String;
    var need_target: Bool;
    var draw_charges: Bool;
}

typedef Equipment = {
    var type: EquipmentType;
    var spells: Array<Spell>;
}

typedef Item = {
    var type: ItemType;
    var spells: Array<Spell>;
}

typedef Position = {
    var x: Int;
    var y: Int;
}

typedef DropEntity = {
    var drop_func: Int->Int->Int; 
}

typedef DrawChar = {
    var char: String;
    var color: Int;
}

typedef Move = {
    var type: MoveType;
    var cant_move: Bool;
    var successive_moves: Int;
    var chase_dst: Int;
    var target: MoveTarget;
}

typedef Locked = {
    var color: Int;
    var need_key: Bool;
}

typedef Unlocker = {
    var color: Int;
}

typedef DrawOnMinimap = {
    var color: Int;
    var seen: Bool;
}

typedef Buy = {
    var cost: Int;
}

typedef EntityType = {
    var name: String;
    var description: String;
    var draw_tile: Int;
    var draw_char: DrawChar;
    var equipment: Equipment;
    var item: Item;
    var use: Use;
    var combat: Combat;
    var drop_entity: DropEntity;
    var talk: String;
    var move: Move;
    var locked: Locked;
    var unlocker: Unlocker;
    var draw_on_minimap: DrawOnMinimap;
    var buy: Buy;
}

@:publicFields
class Entity {
// force unindent

static var all = new Array<Int>();
static var id_max: Int = 0;
// NOTE: only use NONE for initializing and clearing entity references
// don't "==/!= NONE", check for component existence instead
static inline var NONE = -1;
static inline var DURATION_INFINITE = -1;
static inline var DURATION_LEVEL = -2;
static inline var NULL_INT = -1;
static inline var NULL_STRING = 'null';


static var position = new Map<Int, Position>();
static var name = new Map<Int, String>();
static var description = new Map<Int, String>();
static var draw_tile = new Map<Int, Int>();
static var draw_char = new Map<Int, DrawChar>();
static var equipment = new Map<Int, Equipment>();
static var item = new Map<Int, Item>();
static var use = new Map<Int, Use>();
static var combat = new Map<Int, Combat>();
static var drop_entity = new Map<Int, DropEntity>();
static var talk = new Map<Int, String>();
static var move = new Map<Int, Move>();
static var locked = new Map<Int, Locked>();
static var unlocker = new Map<Int, Unlocker>();
static var draw_on_minimap = new Map<Int, DrawOnMinimap>();
static var buy = new Map<Int, Buy>();

static function make(): Int {
    var e = id_max;
    id_max++;

    all.push(e);

    return e;
}

static function copy(e: Int, x: Int, y: Int): Int {
    var copy = make();

    set_position(copy, x, y);
    if (name.exists(e)) {
        name[copy] = name[e];
    }
    if (description.exists(e)) {
        description[copy] = description[e];
    }
    if (draw_tile.exists(e)) {
        draw_tile[copy] = draw_tile[e];
    }
    if (draw_char.exists(e)) {
        var e_draw_char = draw_char[e];
        draw_char[copy] = {
            char: e_draw_char.char,
            color: e_draw_char.color,
        };
    }
    if (equipment.exists(e)) {
        var e_equipment = equipment[e];
        equipment[copy] = {
            type: e_equipment.type,
            spells: [for (spell in e_equipment.spells) Spells.copy(spell)],
        };
    }
    if (item.exists(e)) {
        var e_item = item[e];
        item[copy] = {
            type: e_item.type,
            spells: [for (spell in e_item.spells) Spells.copy(spell)],
        };
    }
    if (use.exists(e)) {
        var e_use = use[e];
        use[copy] = {
            spells: [for (spell in e_use.spells) Spells.copy(spell)],
            charges: e_use.charges,
            consumable: e_use.consumable,
            flavor_text: e_use.flavor_text,
            need_target: e_use.need_target,
            draw_charges: e_use.draw_charges,
        };
    }
    if (combat.exists(e)) {
        var e_combat = combat[e];
        combat[copy] = {
            health: e_combat.health,
            health_max: e_combat.health_max,
            attack: e_combat.attack,
            message: e_combat.message,
            aggression: e_combat.aggression,
            attacked_by_player: e_combat.attacked_by_player,
            range_squared: e_combat.range_squared,
            target: e_combat.target,
        };
    }
    if (drop_entity.exists(e)) {
        var e_drop_entity = drop_entity[e];
        drop_entity[copy] = {
            drop_func: e_drop_entity.drop_func,
        };
    }
    if (talk.exists(e)) {
        talk[copy] = talk[e];
    }
    if (move.exists(e)) {
        var e_move = move[e];
        move[copy] = {
            type: e_move.type,
            cant_move: e_move.cant_move,
            successive_moves: e_move.successive_moves,
            chase_dst: e_move.chase_dst,
            target: e_move.target,
        };
    }
    if (locked.exists(e)) {
        var e_locked = locked[e];
        locked[copy] = {
            color: e_locked.color,
            need_key: e_locked.need_key,
        };
    }
    if (unlocker.exists(e)) {
        var e_unlocker = unlocker[e];
        unlocker[copy] = {
            color: e_unlocker.color,
        };
    }
    if (draw_on_minimap.exists(e)) {
        var e_draw_on_minimap = draw_on_minimap[e];
        draw_on_minimap[copy] = {
            color: e_draw_on_minimap.color,
            seen: e_draw_on_minimap.seen,
        };
    }
    if (buy.exists(e)) {
        var e_buy = buy[e];
        buy[copy] = {
            cost: e_buy.cost,
        };
    }

    validate(copy);

    return copy;
}

static function make_type(x: Int, y: Int, type: EntityType): Int {
    var e = make();

    set_position(e, x, y);
    if (type.name != NULL_STRING) {
        name[e] = type.name;
    }
    if (type.description != NULL_STRING) {
        description[e] = type.description;
    }
    if (type.draw_tile != NULL_INT) {
        draw_tile[e] = type.draw_tile;
    }
    if (type.draw_char != null) {
        draw_char[e] = {
            char: type.draw_char.char,
            color: type.draw_char.color,
        };
    }
    if (type.equipment != null) {
        equipment[e] = {
            type: type.equipment.type,
            spells: [for (spell in type.equipment.spells) Spells.copy(spell)],
        };
    }
    if (type.item != null) {
        item[e] = {
            type: type.item.type,
            spells: [for (spell in type.item.spells) Spells.copy(spell)],
        };
    }
    if (type.use != null) {
        use[e] = {
            spells: [for (spell in type.use.spells) Spells.copy(spell)],
            charges: type.use.charges,
            consumable: type.use.consumable,
            flavor_text: type.use.flavor_text,
            need_target: type.use.need_target,
            draw_charges: type.use.draw_charges,
        };
    }
    if (type.combat != null) {
        combat[e] = {
            health: type.combat.health,
            health_max: type.combat.health_max,
            attack: type.combat.attack,
            message: type.combat.message,
            aggression: type.combat.aggression,
            attacked_by_player: type.combat.attacked_by_player,
            range_squared: type.combat.range_squared,
            target: type.combat.target,
        };
    }
    if (type.drop_entity != null) {
        drop_entity[e] = {
            drop_func: type.drop_entity.drop_func,
        };
    }
    if (type.talk != NULL_STRING) {
        talk[e] = type.talk;
    }
    if (type.move != null) {
        move[e] = {
            type: type.move.type,
            cant_move: type.move.cant_move,
            successive_moves: type.move.successive_moves,
            chase_dst: type.move.chase_dst,
            target: type.move.target,
        };
    }
    if (type.locked != null) {
        locked[e] = {
            color: type.locked.color,
            need_key: type.locked.need_key,
        };
    }
    if (type.unlocker != null) {
        unlocker[e] = {
            color: type.unlocker.color,
        };
    }
    if (type.draw_on_minimap != null) {
        draw_on_minimap[e] = {
            color: type.draw_on_minimap.color,
            seen: type.draw_on_minimap.seen,
        };
    }
    if (type.buy != null) {
        buy[e] = {
            cost: type.buy.cost,
        };
    }

    validate(e);

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
    item.remove(e);
    use.remove(e);
    combat.remove(e);
    drop_entity.remove(e);
    talk.remove(e);
    move.remove(e);
    locked.remove(e);
    unlocker.remove(e);
    draw_on_minimap.remove(e);
    buy.remove(e);
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
    trace('item=${item[e]}');
    trace('use=${use[e]}');
    trace('combat=${combat[e]}');
    trace('drop_entity=${drop_entity[e]}');
    trace('talk=${talk[e]}');
    trace('move=${move[e]}');
    trace('locked=${locked[e]}');
    trace('unlocker=${unlocker[e]}');
    trace('draw_on_minimap=${draw_on_minimap[e]}');
    trace('buy=${buy[e]}');
}

static function validate(e: Int) {
    var error = false;
    // Dependencies
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
    if (draw_on_minimap.exists(e) && !position.exists(e)) {
        trace('Missing dependency: DrawOnMinimap needs Position.');
        error = true;
    }
    if (buy.exists(e) && !(item.exists(e) || equipment.exists(e))) {
        trace('Missing dependency: Buy needs Item or Equipment.');
        error = true;
    }

    // Conflicts
    if (item.exists(e) && equipment.exists(e)) {
        trace('Conflict: Item and Equipment.');
        error = true;
    }
    if (locked.exists(e) && unlocker.exists(e)) {
        trace('Conflict: Locked and Unlocker.');
        error = true;
    }
    if (locked.exists(e) && item.exists(e)) {
        trace('Conflict: Locked and Item.');
        error = true;
    }
    if (locked.exists(e) && equipment.exists(e)) {
        trace('Conflict: Locked and Equipment.');
        error = true;
    }

    if (error) {
        trace('For entity:');
        print(e);
    }
}

static var position_map = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, Entity.NONE);

static function set_position(e: Int, x: Int, y: Int) {
    if (position.exists(e)) {
        // Clear old position
        var pos = position[e];
        position_map[pos.x][pos.y] = Entity.NONE;
    }

    if (position_map[x][y] != Entity.NONE) {
        trace('new position occupied');
        trace('entity 1:');
        print(e);
        trace('entity 2:');
        print(position_map[x][y]);
    }

    // Write new position
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

function new() {}
}