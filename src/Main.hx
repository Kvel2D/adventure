
import haxe.Timer;
import haxegon.*;
import Entity;
import Spells;
import Entities;
import GenerateWorld;
import GUI;

using MathExtensions;

typedef DamageNumber = {
    value: Int,
    x_offset: Int,
    time: Int,
    color: Int,
};

@:publicFields
class Main {
// force unindent

static inline var screen_width = 1600;
static inline var screen_height = 1000;
static inline var tilesize = 8;
static inline var map_width = 150;
static inline var map_height = 150;
static inline var view_width = 31;
static inline var view_height = 31;
static inline var world_scale = 4;
static inline var minimap_scale = 2;
static inline var minimap_x = 0;
static inline var minimap_y = 100;
static inline var room_size_min = 10;
static inline var room_size_max = 20;

static inline var ui_x = tilesize * view_width * world_scale + 13;
static inline var player_stats_y = 0;
static inline var equipment_y = 120;
static inline var equipment_amount = 4;
static inline var inventory_y = 180;
static inline var inventory_width = 4;
static inline var inventory_height = 2;
static inline var spells_list_y = 320;
static inline var message_history_y = 600;
static inline var message_history_length_max = 20;
static inline var turn_delimiter = '------------------------------';
static inline var hovered_tooltip_wordwrap = 400;
static inline var ui_wordwrap = 600;
static inline var draw_char_size = 32;
static inline var ui_text_size = 14;
static inline var player_hud_text_size = 8;
static inline var charges_text_size = 8;

static inline var max_rings = 3;

static var walls = Data.create2darray(map_width, map_height, false);
static var rooms: Array<Room>;
static var visited_room = new Array<Bool>();
var tile_canvas_state = Data.create2darray(view_width, view_height, Tile.None);
var los = Data.create2darray(view_width, view_height, false);

var damage_numbers = new Array<DamageNumber>();

var noclip = false;
var nolos = false;
var show_things = false;
var movespeed_mod = 0;
var dropchance_mod = 0;
var copperchance_mod = 0;
static var increase_drop_level = false;

var show_dev_buttons = true;
var noclip_DEV = false;
var nolos_DEV = false;
var full_minimap_DEV = false;
var frametime_graph_DEV = false;
var draw_invisible_entities = true;

static var player_x = 0;
static var player_y = 0;
var player_x_old = -1;
var player_y_old = -1;
var player_health = 10;
var copper_count = 0;
var player_room = -1;

var player_health_max = 10;
var player_health_max_mod = 0;
var player_attack = [
ElementType_Physical => 1,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
var player_attack_mod = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
var player_defense = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
var player_defense_mod = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];

var player_equipment = [
EquipmentType_Head => Entity.NONE,
EquipmentType_Chest => Entity.NONE,
EquipmentType_Legs => Entity.NONE,
EquipmentType_Weapon => Entity.NONE,
];
var player_spells = new Array<Spell>();
var inventory = Data.create2darray(inventory_width, inventory_height, Entity.NONE);

var attack_target = Entity.NONE;
var interact_target = Entity.NONE;
var interact_target_x: Int;
var interact_target_y: Int;

var message_history = [for (i in 0...message_history_length_max) turn_delimiter];
var added_message_this_turn = false;

var four_dxdy: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

// Used by all generation functions, don't need to pass it around everywhere
static var current_level = 0;


function init() {
    Gfx.resizescreen(screen_width, screen_height, true);
    Core.showstats = true;
    Text.font = 'pixelfj8';
    Gfx.loadtiles('tiles', tilesize, tilesize);
    Gfx.createimage('tiles_canvas', tilesize * view_width, tilesize * view_height);
    Gfx.createimage('frametime_canvas', 100, 50);
    Gfx.createimage('frametime_canvas2', 100, 50);

    Entities.read_name_corpus();
    LOS.calculate_rays();

    generate_level();

    //
    // Test entities in first room
    //
    var first_room = rooms[0];
    for (i in 0...4) {
        var x = 3;
        var y = 3;
        Entities.random_armor(first_room.x + x + 0, first_room.y + y + i);
        Entities.random_armor(first_room.x + x + 1, first_room.y + y + i);
        Entities.random_armor(first_room.x + x + 2, first_room.y + y + i);
    }
    Entities.test_potion(first_room.x + 5, first_room.y + 7);
}

function generate_level() {
    // Remove all entities, except inventory items and equipped equipment
    // NOTE: if new entities are added which don't have a position need to change this
    for (e in Entity.position.keys()) {
        Entity.remove(e);
    }

    var removed_spells = new Array<Spell>();
    // Remove level-specific spells
    for (spell in player_spells) {
        if (spell.duration == Entity.LEVEL_DURATION) {
            removed_spells.push(spell);
        }
    }
    for (spell in removed_spells) {
        player_spells.remove(spell);
    }

    // Fill world with walls
    for (x in 0...map_width) {
        for (y in 0...map_height) {
            walls[x][y] = true;
        }
    }

    // Generate and connect rooms
    rooms = GenerateWorld.generate_via_digging();
    GenerateWorld.connect_rooms(rooms, Random.float(0.5, 2));
    // NOTE: need to increment room dimensions because connections have one dimension of 0 and rooms are really one bigger as well
    for (r in rooms) {
        r.width++;
        r.height++;
    }

    visited_room = [for (i in 0...rooms.length) false];

    // Clear walls inside rooms
    for (r in rooms) {
        for (x in r.x...(r.x + r.width)) {
            for (y in r.y...(r.y + r.height)) {
                walls[x][y] = false;
            }
        }
    }

    // Set start position to first room, before generating entities so that generation uses the new player position in collision checks
    player_x = rooms[0].x;
    player_y = rooms[0].y;

    // Place stairs at the center of a random room(do this before generating entities to avoid overlaps)
    var random_room_i = 0;
    while (random_room_i == 0 || rooms[random_room_i].is_connection) {
        random_room_i = Random.int(0, rooms.length - 1);
    }
    var r = rooms[random_room_i];
    Entities.stairs(r.x + Math.floor(r.width / 2), r.y + Math.floor(r.height / 2));

    GenerateWorld.fill_rooms_with_entities();

    // Reset old pos to force los update, very small chance of player spawning in same position and los not updating
    player_x_old = -1;
    player_y_old = -1;
}

static var time_stamp = 0.0;
static function timer_start() {
    time_stamp = Timer.stamp();
}

static function timer_end() {
    var new_stamp = Timer.stamp();
    trace('${new_stamp - time_stamp}');
    time_stamp = new_stamp;
}

inline function screen_x(x) {
    return unscaled_screen_x(x) * world_scale;
}
inline function screen_y(y) {
    return unscaled_screen_y(y) * world_scale;
}
inline function unscaled_screen_x(x) {
    return (x - player_x + Math.floor(view_width / 2)) * tilesize;
}
inline function unscaled_screen_y(y) {
    return (y - player_y + Math.floor(view_height / 2)) * tilesize;
}

static inline function out_of_map_bounds(x, y) {
    return x < 0 || y < 0 || x >= map_width || y >= map_height;
}

inline function out_of_view_bounds(x, y) {
    return x < (player_x - Math.floor(view_width / 2)) || y < (player_y - Math.floor(view_height / 2)) || x > (player_x + Math.floor(view_width / 2)) || y > (player_y + Math.floor(view_height / 2));
}

function player_next_to(pos: Position): Bool {
    return Math.abs(player_x - pos.x) <= 1 && Math.abs(player_y - pos.y) <= 1;
}

function add_message(message: String) {
    message_history.insert(0, message);
    added_message_this_turn = true;
}

function add_damage_number(value: Int) {
    damage_numbers.push({
        value: value,
        x_offset: if (value > 0) {
            Random.int(-15, -5);
        } else {
            Random.int(20, 30);
        },
        time: 0,
        color: if (value > 0) {
            Col.GREEN;
        } else {
            Col.RED;
        },
    });
}

static function get_room_index(x: Int, y: Int): Int {
    for (i in 0...rooms.length) {
        var r = rooms[i];
        if (Math.point_box_intersect(x, y, r.x, r.y, r.width, r.height)) {
            return i;
        }
    }
    return -1;
}

inline function position_visible(x: Int, y: Int): Bool {
    return !los[x][y] || nolos || nolos_DEV;
}

function player_attack_total(): Map<ElementType, Int> {
    // Calculate attack totals for each element which is a sum of natural attack plus spell mods from spells(which can come from buffs, items, equipment)
    // Attack can't be negative

    // Natural attack + mod
    var attack_total = new Map<ElementType, Int>();
    for (element in Type.allEnums(ElementType)) {
        attack_total[element] = player_attack[element] + player_attack_mod[element];

        // Attack can't be negative
        if (attack_total[element] < 0) {
            attack_total[element] = 0;
        }
    }

    return attack_total;
}

function player_defense_total(): Map<ElementType, Int> {
    var defense_total = new Map<ElementType, Int>();
    for (element in Type.allEnums(ElementType)) {
        defense_total[element] = player_defense[element] + player_defense_mod[element];

        // Defense can't be negative
        if (defense_total[element] < 0) {
            defense_total[element] = 0;
        }
    }

    return defense_total;
}

// TODO: make sure that get_free_map() is used to get the min required area, instead of full map. Also try to use a cached free_map instead of creating new one everytime
static function get_free_map(x1: Int, y1: Int, width: Int, height: Int, include_player: Bool = true, include_entities: Bool = true, free_map: Array<Array<Bool>> = null): Array<Array<Bool>> {
    // Entities
    if (free_map == null) {
        free_map = Data.create2darray(width, height, true);
    } else {
        for (x in 0...free_map.length) {
            for (y in 0...free_map[x].length) {
                free_map[x][y] = true;
            }
        }
    }

    if (include_entities) {
        for (pos in Entity.position) {
            if (Math.point_box_intersect(pos.x, pos.y, x1, y1, width, height)) {
                free_map[pos.x - x1][pos.y - y1] = false;
            }
        }
    }

    // Walls or out of bounds cells
    for (x in x1...(x1 + width)) {
        for (y in y1...(y1 + width)) {
            if (out_of_map_bounds(x, y) || walls[x][y]) {
                free_map[x - x1][y - y1] = false;
            }
        }
    }

    if (include_player && Math.point_box_intersect(player_x, player_y, x1, y1, width, height)) {
        free_map[player_x - x1][player_y - y1] = false;
    }

    return free_map;
}

var astar_closed = Data.create2darray(room_size_max, room_size_max, false);
var astar_open = Data.create2darray(room_size_max, room_size_max, false);
var g_score = Data.create2darray(room_size_max, room_size_max, 0);
var f_score = Data.create2darray(room_size_max, room_size_max, 0);
var astar_prev = new Array<Array<Vec2i>>();

function astar(x1:Int, y1:Int, x2:Int, y2:Int):Array<Vec2i> {
    inline function heuristic_score(x1:Int, y1:Int, x2:Int, y2:Int):Int {
        return Std.int(Math.abs(x2 - x1) + Math.abs(y2 - y1));
    }

    var room = rooms[player_room];

    inline function out_of_bounds(x, y) {
        return x < 0 || y < 0 || x >= room.width || y >= room.height;
    }

    x1 -= room.x;
    x2 -= room.x;

    y1 -= room.y;
    y2 -= room.y;

    var move_map = get_free_map(room.x, room.y, room.width, room.height);
    move_map[x2][y2] = true; // destination cell needs to be "free" for the algorithm to find paths correctly
    move_map[x1][y1] = true; 

    var infinity = 10000000;
    for (x in 0...room.width) {
        for (y in 0...room.height) {
            astar_closed[x][y] = false;
        }
    }
    for (x in 0...room.width) {
        for (y in 0...room.height) {
            astar_open[x][y] = false;
        }
    }
    astar_open[x1][y1] = true;
    var astar_open_length = 1;

    if (astar_prev.length == 0) {
        for (x in 0...room_size_max) {
            var arr = new Array<Vec2i>();
            for (y in 0...room_size_max) {
                arr.push({x: -1, y: -1});
            }
            astar_prev.push(arr);
        }
    } else {
        for (x in 0...room.width) {
            for (y in 0...room.height) {
                astar_prev[x][y].x = -1;
                astar_prev[x][y].y = -1;
            }
        }
    }

    for (x in 0...room.width) {
        for (y in 0...room.height) {
            g_score[x][y] = infinity;
        }
    }
    g_score[x1][y1] = 0;

    for (x in 0...room.width) {
        for (y in 0...room.height) {
            f_score[x][y] = infinity;
        }
    }
    f_score[x1][y1] = heuristic_score(x1, y1, x2, y2);

    while (astar_open_length != 0) {
        var current = function(): Vec2i {
            var lowest_score = infinity;
            var lowest_node: Vec2i = {x: x1, y: y1};
            for (x in 0...room.width) {
                for (y in 0...room.height) {
                    if (astar_open[x][y] && f_score[x][y] <= lowest_score) {
                        lowest_node.x = x;
                        lowest_node.y = y;
                        lowest_score = f_score[x][y];
                    }
                }
            }
            return lowest_node;
        }();

        if (current.x == x2 && current.y == y2) {
            var x = current.x;
            var y = current.y;
            var current = {x: x, y: y};
            var temp = {x: x, y: y};
            var path:Array<Vec2i> = [{x: current.x, y: current.y}];
            while (astar_prev[current.x][current.y].x != -1) {
                temp.x = current.x;
                temp.y = current.y;
                current.x = astar_prev[temp.x][temp.y].x;
                current.y = astar_prev[temp.x][temp.y].y;
                path.push({x: current.x, y: current.y});
            }
            return path;
        }

        astar_open[current.x][current.y] = false;
        astar_open_length--;
        astar_closed[current.x][current.y] = true;
        for (dx_dy in four_dxdy) {
            var neighbor_x = current.x + dx_dy.x;
            var neighbor_y = current.y + dx_dy.y;
            if (out_of_bounds(neighbor_x, neighbor_y) || !move_map[neighbor_x][neighbor_y]) {
                continue;
            }

            if (astar_closed[neighbor_x][neighbor_y]) {
                continue;
            }
            var tentative_g_score = g_score[current.x][current.y] + 1;
            if (!astar_open[neighbor_x][neighbor_y]) {
                astar_open[neighbor_x][neighbor_y] = true;
                astar_open_length++;
            } else if (tentative_g_score >= g_score[neighbor_x][neighbor_y]) {
                continue;
            }

            astar_prev[neighbor_x][neighbor_y].x = current.x;
            astar_prev[neighbor_x][neighbor_y].y = current.y;
            g_score[neighbor_x][neighbor_y] = tentative_g_score;
            f_score[neighbor_x][neighbor_y] = g_score[neighbor_x][neighbor_y] + heuristic_score(neighbor_x, neighbor_y, x2, y2);
        }
    }

    return new Array<Vec2i>();
}

function drop_entity_from_entity(e: Int, dropping_entity_name: String) {
    var drop_entity = Entity.drop_entity[e];
    var pos = Entity.position[e];

    var chance = drop_entity.chance + dropchance_mod;
    if (chance < 0) {
        chance = 0;
    } else if (chance > 100) {
        chance = 100;
    }

    if (Random.chance(chance)) {
        Entity.remove_position(e);
        var drop = Entities.entity_from_table(pos.x, pos.y, drop_entity.table);
        var drop_name = if (Entity.equipment.exists(drop)) {
            Entity.equipment[drop].name;
        } else if (Entity.item.exists(drop)) {
            Entity.item[drop].name;
        } else {
            'unnamed_drop';
        }

        add_message('$dropping_entity_name drops $drop_name.');
    }
}

function try_open_entity(e: Int) {
    // Look for same color unlocker in inventory
    var locked = Entity.locked[e];

    var locked_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_locked';
    }

    function drop_from_locked() {
        if (Entity.drop_entity.exists(e) && Entity.position.exists(e)) {
            drop_entity_from_entity(e, locked_name);
            Entity.remove(e);
        }
    }

    if (locked.need_key) {
        // Normal locked need a matching key, search for it in inventory
        for (y in 0...inventory_height) {
            for (x in 0...inventory_width) {
                if (Entity.unlocker.exists(inventory[x][y]) && !Entity.position.exists(inventory[x][y]) && Entity.unlocker[inventory[x][y]].color == locked.color) {
                    // Found unlocker, remove unlocker and unlock locked entity
                    add_message('You unlock $locked_name.');
                    Entity.remove(inventory[x][y]);

                    drop_from_locked();

                    return;
                }
            }
        }

        add_message('Need matching key to unlock $locked_name.');
    } else {
        // Unlocked lockeds don't need a key
        add_message('You open $locked_name.');
        drop_from_locked();
    }
}

function use_entity(e: Int) {
    var use = Entity.use[e];

    if (use.charges > 0) {
        use.charges--;

        // Save name before pushing spell onto player
        for (spell in use.spells) {
            spell.origin_name = if (Entity.item.exists(e)) {
                Entity.item[e].name;
            } else if (Entity.name.exists(e)) {
                Entity.name[e];
            } else {
                'unnamed_origin';
            }
            player_spells.push(Spells.copy(spell));
        }
    }

    // Change color to gray if out of charges
    if (use.charges == 0 && Entity.draw_char.exists(e)) {
        Entity.draw_char[e].color = Col.GRAY;
    }

    // Consumables disappear when all charges are used
    if (use.consumable && use.charges == 0) {
        Entity.remove(e);
    }
}

function equip_entity(e: Int) {
    var e_equipment = Entity.equipment[e];
    var old_e = player_equipment[e_equipment.type];

    // Remove entity from map
    if (Entity.equipment.exists(old_e) && !Entity.position.exists(old_e)) {
        // If there's equipment in slot, swap position with new equipment
        add_message('You unequip ${Entity.equipment[old_e].name}.');

        var e_pos = Entity.position[e];
        Entity.remove_position(e);
        Entity.set_position(old_e, e_pos.x, e_pos.y);
    } else {
        Entity.remove_position(e);
    }

    add_message('You equip ${Entity.equipment[e].name}.');

    player_equipment[e_equipment.type] = e;
}

function move_entity_into_inventory(e: Int) {
    var item = Entity.item[e];

    // Clear picked up entity from any inventory slots if it was there before, if this is not done and there is an empty slot before the old slot of the new entity, then inventory will have two references to this item
    for (y in 0...inventory_height) {
        for (x in 0...inventory_width) {
            if (inventory[x][y] == e) {
                inventory[x][y] = Entity.NONE;
            }
        }
    }

    if (item.type == ItemType_Ring) {
        // Entity is a ring, need to check that there are ring slots available
        var ring_count = 0;
        for (y in 0...inventory_height) {
            for (x in 0...inventory_width) {
                if (Entity.item.exists(inventory[x][y]) && !Entity.position.exists(inventory[x][y])) {
                    var other_item = Entity.item[inventory[x][y]];
                    if (other_item.type == ItemType_Ring) {
                        ring_count++;

                        if (ring_count >= max_rings) {
                            add_message('Can\'t have more than $max_rings rings.');
                            return;
                        }
                    }
                }
            }
        }
    }

    // Flip loop order so that rows are filled first
    for (y in 0...inventory_height) {
        for (x in 0...inventory_width) {
            // Inventory slot is free if it points to entity that is not an item(removed) or an entity that is an item but has position(dropped on map)
            var doesnt_exist = !Entity.item.exists(inventory[x][y]);
            var not_in_inventory = Entity.item.exists(inventory[x][y]) && Entity.position.exists(inventory[x][y]);
            if (doesnt_exist || not_in_inventory) {
                inventory[x][y] = e;

                add_message('You pick up ${Entity.item[e].name}.');
                Entity.remove_position(e);

                return;
            }
        }
    }
    add_message('Inventory is full.');
}

function drop_entity_from_player(e: Int) {
    // Search for free position around player
    var free_map = get_free_map(player_x - 1, player_y - 1, 3, 3);

    var free_x: Int = -1;
    var free_y: Int = -1;
    for (dx in -1...2) {
        for (dy in -1...2) {
            var x = player_x + dx;
            var y = player_y + dy;
            if (!out_of_map_bounds(x, y) && free_map[dx + 1][dy + 1]) {
                free_x = x;
                free_y = y;
                break;
            }
        }
    }

    if (free_x != -1 && free_y != -1) {
        var name = 'unnamed_drop_from_player';

        if (Entity.item.exists(e)) {
            name = Entity.item[e].name;
        } else if (Entity.equipment.exists(e)) {
            name = Entity.equipment[e].name;
        }

        add_message('You drop ${name}.');
        Entity.set_position(e, free_x, free_y);
    } else {
        add_message('No space to drop item.');
    }
}

function move_entity(e: Int) {
    var move = Entity.move[e];

    if (move.cant_move) {
        move.cant_move = false;
        return;
    }

    var pos = Entity.position[e];

    if (!player_next_to(pos)) {

        switch (move.type) {
            case MoveType_Astar: {
                var path = astar(pos.x, pos.y, player_x, player_y);

                if (path.length > 2) {
                    var room = rooms[player_room];
                    Entity.set_position(e, path[path.length - 2].x + room.x, path[path.length - 2].y + room.y);
                }
            }
            case MoveType_Straight: {
                var dx = player_x - pos.x;
                var dy = player_y - pos.y;
                var free_map = get_free_map(pos.x - 1, pos.y - 1, 3, 3);

                if (!free_map[1 + Math.sign(dx)][1]) {
                    dx = 0;
                }
                if (!free_map[1][1 + Math.sign(dy)]) {
                    dy = 0;
                }

                // Select dx or dy if need to move diagonally
                if (dy != 0 && dx != 0) {
                    if (Random.bool()) {
                        dx = 0;
                    } else {
                        dy = 0;
                    }
                }

                if (dx != 0 || dy != 0) {
                    Entity.set_position(e, pos.x + Math.sign(dx), pos.y + Math.sign(dy));
                }
            }
            case MoveType_Random: {
                if (Random.chance(Entity.random_move_chance)) {
                    var random_dxdy = Random.pick(four_dxdy);
                    var dx = random_dxdy.x;
                    var dy = random_dxdy.y;
                    var free_map = get_free_map(pos.x - 1, pos.y - 1, 3, 3);

                    if (!free_map[1 + Math.sign(dx)][1]) {
                        dx = 0;
                    }
                    if (!free_map[1][1 + Math.sign(dy)]) {
                        dy = 0;
                    }

                    if (dx != 0 || dy != 0) {
                        Entity.set_position(e, pos.x + Math.sign(dx), pos.y + Math.sign(dy));
                    }
                }
            }
        }
    } else {
        // Next to player
    }
}

function entity_attack_player(e: Int) {
    // If on map, must be next to player
    if (Entity.position.exists(e)) {
        var pos = Entity.position[e];
        if (Math.dst2(player_x, player_y, pos.x, pos.y) > 2) {
            return;
        }
    }

    var combat = Entity.combat[e];

    var should_attack = switch (combat.aggression) {
        case AggressionType_Aggressive: true;
        case AggressionType_Neutral: combat.attacked_by_player;
        case AggressionType_Passive: false;
    }

    combat.attacked_by_player = false;

    var defense_total = player_defense_total();
    function defense_to_absorb(def: Int): Int {
        // 82 def = absorb at least 8, absorb 9 20% of the time
        var absorb: Int = Math.floor(def / 10);
        if (Random.chance((def % 10) * 10)) {
            absorb++;
        }
        return absorb;
    }

    var damage_total = 0;
    var absorb_total = 0;
    for (element in Type.allEnums(ElementType)) {
        if (combat.attack.exists(element) && combat.attack[element] != 0) {
            var absorb = defense_to_absorb(defense_total[element]);
            var damage = Std.int(Math.max(0, combat.attack[element] - absorb));

            player_health -= damage;
            damage_total += damage;
            absorb_total += Std.int(Math.min(absorb, combat.attack[element]));
        }
    }

    var target_name = 'unnamed_target';
    if (Entity.name.exists(e)) {
        target_name = Entity.name[e];
    }
    if (damage_total != 0) {
        add_message('You take ${damage_total} damage from $target_name.');
        add_damage_number(-damage_total);
    }
    if (absorb_total != 0) {
        add_message('Your armor absorbs ${absorb_total} damage.');
    }

    // Can't move and attack in same turn
    if (Entity.move.exists(e)) {
        var move = Entity.move[e];
        move.cant_move = true;
    }
}

function player_attack_entity(e: Int, attacks: Map<ElementType, Int>) {
    var combat = Entity.combat[e];

    var damage_to_entity = 0;
    for (element in Type.allEnums(ElementType)) {
        var absorb = if (combat.absorb.exists(element)) {
            combat.absorb[element];
        } else {
            0;
        }
        damage_to_entity += Std.int(Math.max(0, attacks[element] - absorb));
    }

    combat.health -= damage_to_entity;
    combat.attacked_by_player = true;

    var target_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_target';
    }
    add_message('You attack $target_name for $damage_to_entity.');
    add_message(combat.message);

    if (combat.health <= 0) {
        add_message('You slay $target_name.');

        // Some entities drop copper
        if (Entity.give_copper_on_death.exists(e)) {
            var give_copper = Entity.give_copper_on_death[e];

            var chance = give_copper.chance + copperchance_mod;
            if (chance < 0) {
                chance = 0;
            } else if (chance > 100) {
                chance = 100;
            }

            if (Random.chance(chance)) {
                var drop_amount = Random.int(give_copper.min, give_copper.max);
                if (drop_amount > 0) {
                    copper_count += drop_amount;
                    add_message('$target_name drops $drop_amount copper.');
                }
            }
        }
    }

    if (combat.health <= 0) {
        // Drop entities if can and entity is on map
        if (Entity.drop_entity.exists(e) && Entity.position.exists(e)) {
            drop_entity_from_entity(e, target_name);
        }

        Entity.remove(e);
    }
}

function draw_entity(e: Int, x: Float, y: Float) {
    if (Entity.draw_char.exists(e)) {
        // Draw char
        var draw_char = Entity.draw_char[e];
        Text.display(x, y, draw_char.char, draw_char.color);
    } else if (Entity.draw_tile.exists(e)) {
        // Draw tile
        Gfx.drawtile(x, y, 'tiles', Entity.draw_tile[e]);
    } else if (draw_invisible_entities) {
        // Draw invisible entities as question mark
        Gfx.drawtile(x, y, 'tiles', Tile.None);
    }

    // Draw use charges if more than one charge
    if (Entity.use.exists(e)) {
        var use = Entity.use[e];

        if (use.charges > 1) {
            Text.size = charges_text_size;
            Text.display(x, y, '${use.charges}', Col.WHITE);
            Text.size = draw_char_size;
        }
    }
}

function do_spell(spell: Spell, effect_message: Bool = true) {
    // NOTE: some infinite spells(buffs from items) are printed, some aren't
    // for example: printing that a sword increases ice attack every turn is NOT useful
    // printing that the sword is damaging the player every 5 turns IS useful
    switch (spell.type) {
        case SpellType_ModHealth: {
            player_health += spell.value;

            add_message('${spell.origin_name} heals you for ${spell.value} health.');
            add_damage_number(spell.value);
        }
        case SpellType_ModHealthMax: {
            if (spell.duration_type == SpellDuration_Permanent) {
                player_health_max += spell.value;
            } else {
                player_health_max_mod += spell.value;
            }
            
            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your max health by ${spell.value}.');
            }
        }
        case SpellType_ModAttack: {
            if (spell.duration_type == SpellDuration_Permanent) {
                player_attack[spell.element] += spell.value;

                // Attack can't be negative
                if (player_attack[spell.element] < 0) {
                    player_attack[spell.element] = 0;
                }
            } else {
                player_attack_mod[spell.element] += spell.value;
            }

            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your ${spell.element} attack by ${spell.value}.');
            }
        }
        case SpellType_ModDefense: {
            if (spell.duration_type == SpellDuration_Permanent) {
                player_defense[spell.element] += spell.value;
            } else {
                player_defense_mod[spell.element] += spell.value;
            }

            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your ${spell.element} defense by ${spell.value}.');
            }
        }
        case SpellType_UncoverMap: {
            // Mark all rooms visited
            for (i in 0...visited_room.length) {
                visited_room[i] = true;
            }

            add_message('${spell.origin_name} uncovers the map.');
        }
        case SpellType_RandomTeleport: {
            // Teleport to random position in a random room different from current one and not a connection room
            var destination = player_room;
            while (destination == player_room || rooms[destination].is_connection) {
                destination = Random.int(0, rooms.length - 1);
            }

            var r = rooms[destination];
            var positions = GenerateWorld.room_free_positions_shuffled(r);
            var pos = positions.pop();
            player_x = pos.x;
            player_y = pos.y;
            player_room = destination;

            add_message('You are teleported to a random room.');
        }
        case SpellType_SafeTeleport: {
            // Teleport to first room, which is always empty
            var destination = 0;

            var r = rooms[destination];
            var positions = GenerateWorld.room_free_positions_shuffled(r);
            var pos = positions.pop();

            player_x = pos.x;
            player_y = pos.y;
            player_room = destination;

            add_message('You are teleported to a safe place.');
        }
        case SpellType_Nolos: {
            nolos = true;
        }
        case SpellType_Noclip: {
            noclip = true;
        }
        case SpellType_ShowThings: {
            show_things = true;
        }
        case SpellType_NextFloor: {
            current_level++;
            generate_level();
            add_message('You go up to the next floor.');
        }
        case SpellType_ModMoveSpeed: {
            movespeed_mod += spell.value;
        }
        case SpellType_ModDropChance: {
            dropchance_mod += spell.value;
        }
        case SpellType_ModCopperDrop: {
            copperchance_mod += spell.value;
        }
        case SpellType_AoeDamage: {
            for (e in Entity.combat.keys()) {
                if (Entity.position.exists(e)) {
                    var pos = Entity.position[e];

                    if (Math.abs(player_x - pos.x) <= 2 && Math.abs(player_y - pos.y) <= 2) {
                        player_attack_entity(e, [spell.element => spell.value]);
                    }
                }
            }
        }
        case SpellType_ModDropLevel: {
            increase_drop_level = true;
        }
    }
}

function update() {
    var update_start = Timer.stamp();

    var player_acted = false;

    // Space key skips turn
    if (Input.justpressed(Key.SPACE)) {
        player_acted = true;
    }

    // 
    // Player movement
    //
    var player_dx = 0;
    var player_dy = 0;
    var up = Input.delaypressed(Key.W, 5) || Input.justpressed(Key.W);
    var down = Input.delaypressed(Key.S, 5) || Input.justpressed(Key.S);
    var left = Input.delaypressed(Key.A, 5) || Input.justpressed(Key.A);
    var right = Input.delaypressed(Key.D, 5) || Input.justpressed(Key.D);
    if (up && !down) {
        player_dy = -1;
    }
    if (down && !up) {
        player_dy = 1;
    }
    if (left && !right) {
        player_dx = -1;
    }
    if (right && !left) {
        player_dx = 1;
    }
    if (player_dx != 0 && player_dy != 0) {
        player_dy = 0;
    }
    if (player_dx != 0 || player_dy != 0) {
        // If movespeed is increased, try moving extra times in same direction
        var move_amount = 1 + movespeed_mod;

        for (i in 0...move_amount) {
            if (!out_of_map_bounds(player_x + player_dx, player_y + player_dy)) {
                var free_map = get_free_map(player_x + player_dx, player_y + player_dy, 1, 1);

                var noclipping_through_wall = walls[player_x + player_dx][player_y + player_dy] && (noclip || noclip_DEV);

                if (free_map[0][0] || noclipping_through_wall) {
                    player_x += player_dx;
                    player_y += player_dy;
                    player_acted = true;
                }
            }
        }
    }

    function get_view_x(): Int { return player_x - Math.floor(view_width / 2); }
    function get_view_y(): Int { return player_y - Math.floor(view_width / 2); }
    var view_x = get_view_x();
    var view_y = get_view_y();

    // Update LOS after movement
    if (player_x != player_x_old || player_y != player_y_old) {
        player_x_old = player_x;
        player_y_old = player_y;

        LOS.update_los(los);
    }

    //
    // Find entity under mouse
    //
    var mouse_map_x = Math.floor(Mouse.x / world_scale / tilesize + player_x - Math.floor(view_width / 2));
    var mouse_map_y = Math.floor(Mouse.y / world_scale / tilesize + player_y - Math.floor(view_height / 2));

    // Check for entities on map
    var hovered_map = Entity.NONE;
    if (!out_of_view_bounds(mouse_map_x, mouse_map_y) && !out_of_map_bounds(mouse_map_x, mouse_map_y)) {
        hovered_map = Entity.at(mouse_map_x, mouse_map_y);
    }

    // Check for entities anywhere, map/inventory/equipment
    var hovered_anywhere = Entity.NONE;
    var hovered_anywhere_x: Int = 0;
    var hovered_anywhere_y: Int = 0;
    if (Entity.position.exists(hovered_map)) {
        // Hovering over entity on map, must be visible
        var pos = Entity.position[hovered_map];
        if (!los[pos.x - view_x][pos.y - view_y]) {
            hovered_anywhere = hovered_map;
            hovered_anywhere_x = screen_x(pos.x);
            hovered_anywhere_y = screen_y(pos.y);
        }
    } else {
        // Check if hovering over inventory or equipment
        var mouse_inventory_x = Math.floor((Mouse.x - ui_x) / world_scale / tilesize);
        var mouse_inventory_y = Math.floor((Mouse.y - inventory_y) / world_scale / tilesize);
        var mouse_equip_x = Math.floor((Mouse.x - ui_x) / world_scale / tilesize);
        var mouse_equip_y = Math.floor((Mouse.y - equipment_y) / world_scale / tilesize);

        function hovering_inventory(x, y) {
            return x >= 0 && y >= 0 && x < inventory_width && y < inventory_height;
        }
        function hovering_equipment(x, y) {
            return y == 0 && x >= 0 && x < equipment_amount;
        }

        if (hovering_inventory(mouse_inventory_x, mouse_inventory_y)) {
            hovered_anywhere = inventory[mouse_inventory_x][mouse_inventory_y];
            hovered_anywhere_x = ui_x + mouse_inventory_x * tilesize * world_scale;
            hovered_anywhere_y = inventory_y + mouse_inventory_y * tilesize * world_scale;
        } else if (hovering_equipment(mouse_equip_x, mouse_equip_y)) {
            hovered_anywhere = player_equipment[Type.allEnums(EquipmentType)[mouse_equip_x]];
            hovered_anywhere_x = ui_x + mouse_equip_x * tilesize * world_scale;
            hovered_anywhere_y = equipment_y;
        }
    }

    // Print entity for debugging
    // TODO: remove this for release
    if (Input.justpressed(Key.P)) {
        Entity.print(hovered_anywhere);
    }

    //
    // Attack on left click
    //
    if (!player_acted && Mouse.leftclick() && Entity.position.exists(hovered_map)) {
        var pos = Entity.position[hovered_map];
        // Attack if entity is on map, visible and has Combat
        if (player_next_to(Entity.position[hovered_map]) && !los[pos.x - view_x][pos.y - view_y] && Entity.combat.exists(hovered_map)) {
            attack_target = hovered_map;
            player_acted = true;
        }
    }

    //
    // Render
    //
    // Tiles
    Gfx.scale(1, 1, 0, 0);
    Gfx.drawtoimage('tiles_canvas');
    for (x in 0...view_width) {
        for (y in 0...view_height) {
            var map_x = view_x + x;
            var map_y = view_y + y;

            var new_tile = Tile.None;
            if (out_of_map_bounds(map_x, map_y) || walls[map_x][map_y]) {
                new_tile = Tile.Black;
            } else {
                if (position_visible(x, y)) {
                    new_tile = Tile.Ground;
                } else {
                    new_tile = Tile.DarkerGround;
                }
            }

            if (new_tile != tile_canvas_state[x][y]) {
                Gfx.drawtile(unscaled_screen_x(map_x), unscaled_screen_y(map_y), 'tiles', new_tile);
                tile_canvas_state[x][y] = new_tile;
            }
        }
    }
    Gfx.drawtoscreen();

    Gfx.scale(world_scale, world_scale, 0, 0);
    Gfx.clearscreen(Col.BLACK);
    Gfx.drawimage(0, 0, "tiles_canvas");

    // Entities
    Text.size = draw_char_size;
    for (e in Entity.position.keys()) {
        var pos = Entity.position[e];
        if (!out_of_view_bounds(pos.x, pos.y) && position_visible(pos.x - view_x, pos.y - view_y)) {
            draw_entity(e, screen_x(pos.x), screen_y(pos.y));
        }
    }

    // Player, draw as parts of each equipment
    for (equipment_type in Type.allEnums(EquipmentType)) {
        var e = player_equipment[equipment_type];

        var equipment_tile = if (Entity.draw_tile.exists(e)) {
            Entity.draw_tile[e];
        } else {
            switch (equipment_type) {
                case EquipmentType_Weapon: Tile.None;
                case EquipmentType_Head: Tile.Head0;
                case EquipmentType_Chest: Tile.Chest0;
                case EquipmentType_Legs: Tile.Legs0;
            }
        }

        var x_offset = if (equipment_type == EquipmentType_Weapon) {
            // Draw sword a bit to the side
            0.3 * tilesize * world_scale;
        } else {
            0;
        }

        if (equipment_tile != Tile.None) {
            Gfx.drawtile(screen_x(player_x) + x_offset, screen_y(player_y), 'tiles', equipment_tile); 
        }
    }

    // Health above player
    Gfx.scale(1, 1, 0, 0);
    Text.size = player_hud_text_size;
    Text.display(screen_x(player_x), screen_y(player_y) - 10, '${player_health}/${player_health_max + player_health_max_mod}');

    // Damage numbers
    var removed_damage_numbers = new Array<DamageNumber>();
    for (n in damage_numbers) {
        Text.display(screen_x(player_x) + n.x_offset, screen_y(player_y) - n.time / 5, '${n.value}', n.color);

        n.time++;
        if (n.time > 180) {
            removed_damage_numbers.push(n);
        }
    }
    for (n in removed_damage_numbers) {
        damage_numbers.remove(n);
    }

    // DEAD indicator
    // TODO: need a real transition
    if (player_health <= 0) {
        Text.size = 100;
        Text.display(100, 100, 'DEAD', Col.RED);
    }

    //
    // UI
    //
    Gfx.scale(1, 1, 0, 0);
    Text.size = ui_text_size;

    // Player stats
    var player_stats = "";
    player_stats += 'PLAYER';
    player_stats += '\nPosition: ${player_x} ${player_y}';
    player_stats += '\nHealth: ${player_health}/${player_health_max + player_health_max_mod}';
    var attack_total = player_attack_total();
    player_stats += '\nAttack: P:${attack_total[ElementType_Physical]} F:${attack_total[ElementType_Fire]} I:${attack_total[ElementType_Ice]} S:${attack_total[ElementType_Shadow]} L:${attack_total[ElementType_Light]}';
    var defense_total = player_defense_total();
    player_stats += '\nDefense: P:${defense_total[ElementType_Physical]} F:${defense_total[ElementType_Fire]} I:${defense_total[ElementType_Ice]} S:${defense_total[ElementType_Shadow]} L:${defense_total[ElementType_Light]}';
    player_stats += '\nCopper: ${copper_count}';
    Text.display(ui_x, player_stats_y, player_stats);

    //
    // Equipment
    //
    Text.size = ui_text_size;
    Text.display(ui_x, equipment_y - Text.height() - 2, 'EQUIPMENT');
    Gfx.scale(world_scale, world_scale, 0, 0);
    Text.size = draw_char_size;
    var armor_i = 0;
    for (equipment_type in Type.allEnums(EquipmentType)) {
        // Slot border
        Gfx.drawbox(ui_x + armor_i * tilesize * world_scale, equipment_y, tilesize * world_scale, tilesize * world_scale, Col.WHITE);

        // Equipment
        var e = player_equipment[equipment_type];
        if (Entity.equipment.exists(e) && !Entity.position.exists(e)) {
            draw_entity(e, ui_x + armor_i * tilesize * world_scale, equipment_y);
        }

        armor_i++;
    }

    //
    // Inventory
    //
    Gfx.scale(1, 1, 0, 0);
    Text.size = ui_text_size;
    Text.display(ui_x, inventory_y - Text.height() - 2, 'INVENTORY');
    Gfx.scale(world_scale, world_scale, 0, 0);
    Text.size = draw_char_size;
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            // Slot border
            Gfx.drawbox(ui_x + x * tilesize * world_scale, inventory_y + y * tilesize * world_scale, tilesize * world_scale, tilesize * world_scale, Col.WHITE);
            
            // Item
            var e = inventory[x][y];
            if (Entity.item.exists(e) && !Entity.position.exists(e)) {
                draw_entity(e, ui_x + x * tilesize * world_scale, inventory_y + y * tilesize * world_scale);
            }
        }
    }

    //
    // Active spells list
    //
    Gfx.scale(1, 1, 0, 0);
    Text.size = ui_text_size;
    var active_spells = 'SPELLS';
    for (s in player_spells) {
        active_spells += '\n' + Spells.get_description(s);
    }
    Text.wordwrap = ui_wordwrap;
    Text.display(ui_x, spells_list_y, active_spells);

    //
    // Hovered entity tooltip
    //
    Text.wordwrap = hovered_tooltip_wordwrap;
    function get_tooltip(e: Int): String {
        var tooltip = "";
        if (Entity.name.exists(e)) {
            tooltip += 'Id: ${e}';
            tooltip += '\nName: ${Entity.name[e]}';
        }
        if (Entity.combat.exists(e)) {
            var entity_combat = Entity.combat[e];
            tooltip += '\nHealth: ${entity_combat.health}';
            tooltip += '\nAttack: P:${entity_combat.attack[ElementType_Physical]} F:${entity_combat.attack[ElementType_Fire]} I:${entity_combat.attack[ElementType_Ice]} S:${entity_combat.attack[ElementType_Shadow]} L:${entity_combat.attack[ElementType_Light]}';
            tooltip += '\nAbsorb: P:${entity_combat.absorb[ElementType_Physical]} F:${entity_combat.absorb[ElementType_Fire]} I:${entity_combat.absorb[ElementType_Ice]} S:${entity_combat.absorb[ElementType_Shadow]} L:${entity_combat.absorb[ElementType_Light]}';
        }
        if (Entity.description.exists(e)) {
            tooltip += '\n${Entity.description[e]}';
        }
        if (Entity.equipment.exists(e)) {
            var equipment = Entity.equipment[e];
            tooltip += '\nEquipment name: ${equipment.name}';
            tooltip += '\nEquipment type: ${equipment.type}';
            if (equipment.spells.length > 0) {
                tooltip += '\nEquip effects:';
                for (s in equipment.spells) {
                    tooltip += '\n    ' + Spells.get_description(s);
                }
            }
        }
        if (Entity.use.exists(e)) {
            var use = Entity.use[e];
            tooltip += '\nUse effects:';
            for (s in use.spells) {
                tooltip += '\n    ' + Spells.get_description(s);
            }
        }
        if (Entity.item.exists(e) && Entity.item[e].spells.length > 0) {
            var item = Entity.item[e];
            tooltip += '\nCarry effect:';
            for (s in item.spells) {
                tooltip += '\n    ' + Spells.get_description(s);
            }
        }

        return tooltip;
    }
    var entity_tooltip = get_tooltip(hovered_anywhere);
    if (Entity.equipment.exists(hovered_anywhere) && Entity.position.exists(hovered_anywhere)) {
        // Show comparison tooltip for equipment on the ground
        var equipped = player_equipment[Entity.equipment[hovered_anywhere].type];

        if (Entity.equipment.exists(equipped) && !Entity.position.exists(equipped)) {
            entity_tooltip += '\n\nCURRENTLY EQUIPPED:\n' + get_tooltip(equipped);
        }
    }
    
    if (interact_target == Entity.NONE) {
        // Only show tooltip if interact menu isn't open
        Gfx.fillbox(hovered_anywhere_x + tilesize * world_scale, hovered_anywhere_y, hovered_tooltip_wordwrap, Text.height(entity_tooltip), Col.GRAY);
        Text.display(hovered_anywhere_x + tilesize * world_scale, hovered_anywhere_y, entity_tooltip, Col.WHITE);
    }

    //
    // Interact menu
    //

    // Set interact target on right click
    if (!player_acted && Mouse.rightclick()) {
        interact_target = hovered_anywhere;
        interact_target_x = hovered_anywhere_x;
        interact_target_y = hovered_anywhere_y;
    }

    // Stop interaction if entity too far away or is not visible
    if (Entity.position.exists(interact_target)) {
        var pos = Entity.position[interact_target];
        if (!player_next_to(Entity.position[interact_target]) || !position_visible(pos.x - view_x, pos.y - view_y)) {
            interact_target = Entity.NONE;
        }
    }

    // Interaction buttons
    if (!player_acted) {
        var done_interaction = false;
        GUI.x = interact_target_x + tilesize * world_scale;
        GUI.y = interact_target_y;
        if (Entity.talk.exists(interact_target)) {
            if (GUI.auto_text_button('Talk')) {
                add_message(Entity.talk[interact_target]);
                done_interaction = true;
            }
        }
        if (Entity.use.exists(interact_target)) {
            if (GUI.auto_text_button('Use')) {
                use_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.equipment.exists(interact_target)) {
            if (Entity.position.exists(interact_target)) {
                // Can equip if is equipment and is on map
                if (GUI.auto_text_button('Equip')) {
                    equip_entity(interact_target);

                    done_interaction = true;
                }
            } else {
                // Can unequip if is equipment and not on map
                if (GUI.auto_text_button('Unequip')) {
                    drop_entity_from_player(interact_target);

                    done_interaction = true;
                }
            }
        }
        if (Entity.item.exists(interact_target)) {
            if (Entity.position.exists(interact_target)) {
                // Can be picked up if on map
                if (GUI.auto_text_button('Pick up')) {
                    move_entity_into_inventory(interact_target);

                    done_interaction = true;
                }
            } else {
                // Can be dropped up if not on map(in inventory)
                if (GUI.auto_text_button('Drop')) {
                    drop_entity_from_player(interact_target);

                    done_interaction = true;
                }
            }
        }
        if (Entity.locked.exists(interact_target)) {
            if (GUI.auto_text_button('Open')) {
                try_open_entity(interact_target);

                done_interaction = true;
            }
        }

        if (done_interaction) {
            interact_target = Entity.NONE;
            player_acted = true;
        } else if (Mouse.leftclick()) {
            // Clicked out of context menu
            interact_target = Entity.NONE;
        }
    }

    //
    // Messages
    //
    while (message_history.length > message_history_length_max) {
        message_history.pop();
    }
    var messages = "";
    for (message in message_history) {
        messages = message + '\n' + messages;
    }
    Text.wordwrap = ui_wordwrap;
    Text.display(ui_x, message_history_y + 50, messages);

    //
    // Developer options
    //
    GUI.x = ui_x - 250;
    GUI.y = 0;
    if (GUI.auto_text_button('Toggle dev')) {
        show_dev_buttons = !show_dev_buttons;
    }
    if (show_dev_buttons) {
        if (GUI.auto_text_button('To first room')) {
            player_x = rooms[0].x;
            player_y = rooms[0].y;
            player_acted = true;
        }
        if (GUI.auto_text_button('Toggle full map')) {
            full_minimap_DEV = !full_minimap_DEV;
        }
        if (GUI.auto_text_button('Toggle noclip')) {
            noclip_DEV = !noclip_DEV;
        }
        if (GUI.auto_text_button('Toggle los')) {
            nolos_DEV = !nolos_DEV;
        }
        if (GUI.auto_text_button('Toggle frametime graph')) {
            frametime_graph_DEV = !frametime_graph_DEV;
        }
        if (GUI.auto_text_button('Next level')) {
            current_level++;
            generate_level();
            // Update view, since moving to next level changes player position
            view_x = get_view_x();
            view_y = get_view_y();
        }
    }

    //
    // Update seen status for entities drawn on minimap
    //
    for (e in Entity.draw_on_minimap.keys()) {
        var draw_on_minimap = Entity.draw_on_minimap[e];

        if (!draw_on_minimap.seen && Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (!out_of_view_bounds(pos.x, pos.y) && position_visible(pos.x - view_x, pos.y - view_y)) {
                draw_on_minimap.seen = true;
            }
        }
    }

    //
    // Minimap
    //

    // Draw rooms
    for (i in 0...rooms.length) {
        if (visited_room[i] || full_minimap_DEV) {
            var r = rooms[i];
            Gfx.drawbox(minimap_x + r.x * minimap_scale, minimap_y + r.y * minimap_scale, (r.width) * minimap_scale, (r.height) * minimap_scale, Col.WHITE);
        }
    }

    // Draw seen things
    for (e in Entity.draw_on_minimap.keys()) {
        var draw_on_minimap = Entity.draw_on_minimap[e];

        if ((draw_on_minimap.seen || show_things || full_minimap_DEV) && Entity.position.exists(e)) {
            var pos = Entity.position[e];
            Gfx.drawbox(minimap_x + pos.x * minimap_scale, minimap_y + pos.y * minimap_scale, minimap_scale, minimap_scale, draw_on_minimap.color);
        }
    }

    // Draw player
    Gfx.drawbox(minimap_x + player_x * minimap_scale, minimap_y + player_y * minimap_scale, minimap_scale, minimap_scale, Col.RED);

    //
    // End of turn
    //
    if (player_acted) {
        // Clear interact target if done something
        interact_target = Entity.NONE;

        // Recalculate player room if room changed
        if (player_room != -1) {
            var old_room = rooms[player_room];
            if (!Math.point_box_intersect(player_x, player_y, old_room.x, old_room.y, old_room.width, old_room.height)) {
                player_room = get_room_index(player_x, player_y);
            }

            // Mark current room and adjacent rooms as visited
            if (player_room != -1) {
                visited_room[player_room] = true;
                for (i in rooms[player_room].adjacent_rooms) {
                    visited_room[i] = true;
                }
            }
        } else {
            player_room = get_room_index(player_x, player_y);
        }

        // Clear temporary spell effects
        player_health_max_mod = 0;
        for (element in Type.allEnums(ElementType)) {
            player_attack_mod[element] = 0;
            player_defense_mod[element] = 0;
        }
        nolos = false;
        noclip = false;
        show_things = false;
        movespeed_mod = 0;
        dropchance_mod = 0;
        copperchance_mod = 0;
        increase_drop_level = false;

        //
        // Process spells
        //
        var active_spells = [for (i in 0...(Spells.last_prio + 1)) new Array<Spell>()];

        function process_spell(spell: Spell): Bool {
            var spell_over = false;
            var active = false;

            function decrement_duration() {
                // Spell is active every interval, until duration reaches zero
                spell.interval_current++;
                if (spell.interval_current >= spell.interval) {
                    spell.interval_current = 0;
                    active = true;

                    if (spell.duration != Entity.INFINITE_DURATION && spell.duration != Entity.LEVEL_DURATION) {
                        spell.duration--;
                        if (spell.duration == 0) {
                            spell_over = true;
                        }
                    }
                }
            }

            switch (spell.duration_type) {
                case SpellDuration_Permanent: {
                    spell_over = true;
                    active = true;
                }
                case SpellDuration_EveryTurn: {
                    // Every turn spells activate every turn
                    decrement_duration();
                }
                case SpellDuration_EveryAttack: {
                    // Every attack spells activate only when attacking
                    if (attack_target != Entity.NONE) {
                        decrement_duration();
                    }
                }
            }

            if (active) {
                var prio = Spells.prios[spell.type];
                active_spells[prio].push(spell);
            }

            return spell_over;
        }

        function process_spell_list(list: Array<Spell>) {
            var expired_spells = new Array<Spell>();
            for (spell in list) {
                var spell_over = process_spell(spell);

                if (spell_over) {
                    expired_spells.push(spell);
                }
            }
            for (spell in expired_spells) {
                if (spell.duration_type != SpellDuration_Permanent) {
                    add_message('Spell ${spell.type} wore off.');
                }
                list.remove(spell);
            }
        }

        // Inventory spells
        for (x in 0...inventory_width) {
            for (y in 0...inventory_height) {
                var e = inventory[x][y];

                if (Entity.item.exists(e) && !Entity.position.exists(e) && Entity.item[e].spells.length > 0) {
                    process_spell_list(Entity.item[e].spells);
                }
            }
        }

        // Equipment spells
        for (equipment_type in Type.allEnums(EquipmentType)) {
            var e = player_equipment[equipment_type];

            if (Entity.equipment.exists(e) && !Entity.position.exists(e) && Entity.equipment[e].spells.length > 0) {
                process_spell_list(Entity.equipment[e].spells);
            }
        }

        // Player spells
        process_spell_list(player_spells);

        // Do spells in order of their priority, first 0th prio spells, then 1st, etc...
        for (i in 0...(Spells.last_prio + 1)) {
            for (spell in active_spells[i]) {
                do_spell(spell);
            }
        }

        // Limit health to health_max
        if (player_health > player_health_max + player_health_max_mod) {
            player_health = player_health_max + player_health_max_mod;
        }

        // Player attacks entity
        if (attack_target != Entity.NONE) {
            player_attack_entity(attack_target, player_attack_total());
            attack_target = Entity.NONE;
        }

        // Entities attack player
        for (e in Entity.combat.keys()) {
            entity_attack_player(e);
        }

        // Player dies if inside wall and not noclipping
        if (walls[player_x][player_y] && !(noclip || noclip_DEV)) {
            player_health = 0;
        }

        // NOTE: can die from entity attacks or spells
        if (player_health <= 0) {
            add_message('You died.');
        }

        // Entities chase player if they are in the same room
        for (e in Entity.move.keys()) {
            if (Entity.position.exists(e)) {
                var pos = Entity.position[e];
                if (pos.room == player_room) {
                    move_entity(e);
                }
            }
        }

        // Mark the end of turn
        if (added_message_this_turn) {
            add_message(turn_delimiter);
            added_message_this_turn = false;
        }
    }

    if (frametime_graph_DEV) {
        var frame_time = Math.max(1 / 60.0, Timer.stamp() - update_start);

        Gfx.drawtoimage('frametime_canvas2');
        Gfx.drawimage(-1, 0, 'frametime_canvas');
        Gfx.drawtoimage('frametime_canvas');
        Gfx.drawimage(0, 0, 'frametime_canvas2');
        Gfx.fillbox(99, 0, 1, 50, Col.BLUE);
        Gfx.fillbox(99, 50 * (1 - frame_time / (1 / 30.0)), 1, 1, Col.WHITE);
        Gfx.drawtoscreen();
        Gfx.drawimage(400, 100, 'frametime_canvas');
    }
}
}
