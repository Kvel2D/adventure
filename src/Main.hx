
import haxe.Timer;
import haxegon.*;
import Entity;
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
// NOTE: force unindent

static inline var screen_width = 1600;
static inline var screen_height = 1000;
static inline var tilesize = 8;
static inline var map_width = 200;
static inline var map_height = 200;
static inline var view_width = 31;
static inline var view_height = 31;
static inline var world_scale = 4;
static inline var funtown_x = 15;
static inline var funtown_y = 15;
static inline var minimap_scale = 4;
static inline var room_size_min = 10;
static inline var room_size_max = 20;
static inline var turn_delimiter = '------------------------------';
static inline var hovered_tooltip_wordwrap = 250;

static inline var ui_x = tilesize * view_width * world_scale + 13;
static inline var player_stats_y = 0;
static inline var equipment_y = 120;
static inline var equipment_amount = 4;
static inline var inventory_y = 180;
static inline var inventory_width = 4;
static inline var inventory_height = 4;
static inline var spells_list_y = 320;
static inline var message_history_y = 600;
static inline var message_history_length_max = 20;
static inline var max_rings = 4;

static var walls = Data.create2darray(map_width, map_height, false);
static var tile_canvas_state = Data.create2darray(view_width, view_height, Tile.None);
static var rooms: Array<Room>;
static var los: Array<Array<Bool>>;
static var damage_numbers = new Array<DamageNumber>();

static var in_funtown = true;
static var noclip = false;
static var no_los = false;
static var draw_minimap = false;
static var draw_invisible_entities = true;

static var player_x = 0;
static var player_y = 0;
static var player_previous_world_x = 0;
static var player_previous_world_y = 0;
static var player_health = 10;
static var copper_count = 0;
static var player_room = -1;

static var player_health_max = 10;
static var player_health_max_mod = 0;
static var player_attack = [
ElementType_Physical => 1,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
static var player_attack_mod = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
static var player_defense = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];
static var player_defense_mod = [
ElementType_Physical => 0,
ElementType_Fire => 0,
ElementType_Ice => 0,
ElementType_Shadow => 0,
ElementType_Light => 0,
];

static var player_equipment = [
EquipmentType_Head => Entity.NONE,
EquipmentType_Chest => Entity.NONE,
EquipmentType_Legs => Entity.NONE,
EquipmentType_Weapon => Entity.NONE,
];
static var player_spells = new Array<Spell>();
static var inventory = Data.create2darray(inventory_width, inventory_height, Entity.NONE);

static var attack_target = Entity.NONE;
static var interact_target = Entity.NONE;
static var interact_target_x: Int;
static var interact_target_y: Int;
static var turn_is_over = false;
static var need_to_update_los = true;

static var message_history = [for (i in 0...message_history_length_max) turn_delimiter];
static var added_message_this_turn = false;

static var four_dxdy: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];


function init() {
    Gfx.resizescreen(screen_width, screen_height, true);
    Core.showstats = true;
    Text.font = 'pixelFJ8';
    Gfx.loadtiles('tiles', tilesize, tilesize);
    Gfx.createimage('tiles_canvas', tilesize * view_width, tilesize * view_height);

    //
    // Generate world
    //

    // Fil world with walls at the start
    for (x in 0...map_width) {
        for (y in 0...map_height) {
            walls[x][y] = true;
        }
    }

    // Generate and connect rooms
    rooms = GenerateWorld.generate_via_digging();
    GenerateWorld.connect_rooms(rooms);
    for (r in rooms) {
        r.width++;
        r.height++;
    }

    // Add Funtown room
    rooms.insert(0, {
        x: 1,
        y: 1,
        width: funtown_x,
        height: funtown_y,
        is_connection: false
    });

    // Clear walls inside rooms
    for (r in rooms) {
        for (x in r.x...(r.x + r.width)) {
            for (y in r.y...(r.y + r.height)) {
                walls[x][y] = false;
            }
        }
    }

    GenerateWorld.fill_rooms_with_entities();

    // Set start position to first room
    player_previous_world_x = rooms[1].x;
    player_previous_world_y = rooms[1].y;

    if (in_funtown) {
        player_x = funtown_x;
        player_y = funtown_y;
    } else {
        player_x = player_previous_world_x;
        player_y = player_previous_world_y;
    }

    LOS.calculate_rays();

    //
    // Funtown
    //
    walls[7][5] = true;
    walls[8][5] = true;
    walls[9][5] = true;
    walls[10][5] = true;
    walls[11][5] = true;
    walls[12][5] = true;

    MakeEntity.snail(10, 3);
    MakeEntity.ring(11, 3);
    MakeEntity.ring(12, 3);
    MakeEntity.ring(13, 3);
    MakeEntity.ring(14, 3);
    MakeEntity.ring(15, 3);
    // MakeEntity.snail(10, 4);
    // MakeEntity.snail(10, 5);
    // MakeEntity.bear(8, 8);

    // MakeEntity.fountain(8, 10);

    // for (i in 0...2) {
    //     var x = 7;
    //     var y = 5;
    //     MakeEntity.armor(x + 0, y + i, ArmorType_Head);
    //     MakeEntity.armor(x + 1, y + i, ArmorType_Chest);
    //     MakeEntity.armor(x + 2, y + i, ArmorType_Legs);
    // }

    MakeEntity.sword(6, 7);
    MakeEntity.test_potion(6, 8);

    // MakeEntity.chest(2, 15);

    for (i in 0...10) {
        var x = 1;
        var y = 1;
        MakeEntity.test_potion(x + i, y);
    }
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

static inline function screen_x(x) {
    return unscaled_screen_x(x) * world_scale;
}
static inline function screen_y(y) {
    return unscaled_screen_y(y) * world_scale;
}
static inline function unscaled_screen_x(x) {
    return (x - player_x + Math.floor(view_width / 2)) * tilesize;
}
static inline function unscaled_screen_y(y) {
    return (y - player_y + Math.floor(view_height / 2)) * tilesize;
}

static inline function out_of_map_bounds(x, y) {
    return x < 0 || y < 0 || x >= map_width || y >= map_height;
}

static inline function out_of_view_bounds(x, y) {
    return x < (player_x - Math.floor(view_width / 2)) || y < (player_y - Math.floor(view_height / 2)) || x > (player_x + Math.floor(view_width / 2)) || y > (player_y + Math.floor(view_height / 2));
}

static function player_next_to(pos: Position): Bool {
    return Math.abs(player_x - pos.x) <= 1 && Math.abs(player_y - pos.y) <= 1;
}

static function add_message(message: String) {
    message_history.insert(0, message);
    added_message_this_turn = true;
}

static function add_damage_number(value: Int) {
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

// TODO: need to think about wording
// the interval thing is only for heal over time/dmg over time
// attack bonuses/ health max bonuses are applied every turn
static function spell_description(spell: Spell): String {
    var string = '';
    var type = switch (spell.type) {
        case SpellType_ModHealth: 'change health';
        case SpellType_ModHealthMax: 'change max health';
        case SpellType_ModAttack: 'change attack';
        case SpellType_ModDefense: 'change defense';
    }
    var element = switch (spell.element) {
        case ElementType_Physical: 'physical';
        case ElementType_Fire: 'fire';
        case ElementType_Ice: 'ice';
        case ElementType_Shadow: 'shadow';
        case ElementType_Light: 'light';
    }

    var duration = if (spell.duration_type == SpellDuration_Permanent) {
        '';
    } else {
        var interval_name = if (spell.duration_type == SpellDuration_EveryTurn) {
            'turn';
        } else {
            'attack';
        }

        if (spell.duration == Entity.INFINITE) {
            if (spell.interval == 1) {
                'applied every ${interval_name}';
            } else {
                'applied every ${spell.interval} ${interval_name}s';
            }
        } else if (spell.interval == 1) {
            'for ${spell.duration * spell.interval} ${interval_name}s';
        } else {
            if (spell.interval == 1) {
                'for ${spell.duration} ${interval_name}s, applied every ${interval_name}';
            } else {
                'for ${spell.duration} ${interval_name}s, applied every ${spell.interval} ${interval_name}s';
            }
        }
    }

    // physical change attack 2 for 10 attacks
    // physical change attack 2 every 3 attacks for 9 attacks total
    return '$element $type ${spell.value} $duration (${spell.interval - spell.interval_current})';
}

// NOTE: breaks if player is next to world border
static function get_free_map(x1: Int, y1: Int, width: Int, height: Int, include_player: Bool = true, include_entities: Bool = true): Array<Array<Bool>> {
    // Entities
    var free_map = Data.create2darray(width, height, true);

    if (include_entities) {
        for (pos in Entity.position) {
            if (Math.point_box_intersect(pos.x, pos.y, x1, y1, width, height)) {
                free_map[pos.x - x1][pos.y - y1] = false;
            }
        }
    }

    // Walls
    for (x in x1...(x1 + width)) {
        for (y in y1...(y1 + width)) {
            if (walls[x][y]) {
                free_map[x - x1][y - y1] = false;
            }
        }
    }

    if (include_player && Math.point_box_intersect(player_x, player_y, x1, y1, width, height)) {
        free_map[player_x - x1][player_y - y1] = false;
    }

    return free_map;
}

static var astar_closed = Data.create2darray(room_size_max, room_size_max, false);
static var astar_open = Data.create2darray(room_size_max, room_size_max, false);
static var g_score = Data.create2darray(room_size_max, room_size_max, 0);
static var f_score = Data.create2darray(room_size_max, room_size_max, 0);
static var astar_prev = new Array<Array<Vec2i>>();

static function astar(x1:Int, y1:Int, x2:Int, y2:Int):Array<Vec2i> {
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

static function use_entity(e: Int) {
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
                'noname';
            }
            player_spells.push({
                type: spell.type,
                element: spell.element,
                duration_type: spell.duration_type,
                duration: spell.duration,
                interval: spell.interval,
                interval_current: spell.interval_current,
                value: spell.value,
                origin_name: spell.origin_name,
            });
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

static function equip_entity(e: Int) {
    var e_equipment = Entity.equipment[e];
    var old_e = player_equipment[e_equipment.type];

    // Remove new equipment from map
    var e_pos = Entity.position[e];
    var drop_x = e_pos.x;
    var drop_y = e_pos.y;
    Entity.remove_position(e);

    // Unequip old equipment
    if (Entity.equipment.exists(old_e) && !Entity.position.exists(old_e)) {
        add_message('You unequip ${Entity.equipment[old_e].name}.');
        Entity.set_position(old_e, drop_x, drop_y);
    }

    add_message('You equip ${Entity.equipment[e].name}.');

    player_equipment[e_equipment.type] = e;
}

static function pick_up_entity(e: Int) {
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

static function drop_entity(e: Int) {
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
        add_message('You drop ${Entity.item[e].name}.');

        Entity.set_position(e, free_x, free_y);
    } else {
        add_message('No space to drop item.');
    }
}

static function move_entity(e: Int) {
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

static function entity_attack_player(e: Int) {
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
        var absorb = def / 10;
        if (Random.chance(def % 10 * 10)) {
            absorb++;
        }
        return Math.floor(absorb);
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

    var target_name = 'noname';
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

static function player_attack_entity(e: Int) {
    // NOTE: what if player attack is negative?
    var combat = Entity.combat[e];

    var attack_total = player_attack_total();

    // TODO: apply resists
    var damage_to_entity = 0;
    for (element in Type.allEnums(ElementType)) {
        var absorb = if (combat.absorb.exists(element)) {
            combat.absorb[element];
        } else {
            0;
        }
        damage_to_entity += Std.int(Math.max(0, attack_total[element] - absorb));
    }

    combat.health -= damage_to_entity;
    combat.attacked_by_player = true;

    var target_name = 'noname';
    if (Entity.name.exists(e)) {
        target_name = Entity.name[e];
    }
    add_message('You attack $target_name for $damage_to_entity.');
    add_message(combat.message);

    if (combat.health <= 0) {
        add_message('You slay $target_name.');

        // Some entities drop copper
        if (Entity.give_copper_on_death.exists(e)) {
            var give_copper = Entity.give_copper_on_death[e];

            if (Random.chance(give_copper.chance)) {
                var drop_amount = Random.int(give_copper.min, give_copper.max);
                copper_count += drop_amount;
                add_message('$target_name drops $drop_amount copper.');
            }
        }
    }

    if (combat.health <= 0) {
        if (Entity.drop_item.exists(e) && Entity.position.exists(e)) {
            var drop_item = Entity.drop_item[e];
            var pos = Entity.position[e];
            if (Random.chance(drop_item.chance)) {
                add_message('$target_name drops ${drop_item.type}.');
                Entity.remove_position(e);
                MakeEntity.item(pos.x, pos.y, drop_item.type);
            }
        }

        Entity.remove(e);
    }
}

static function player_attack_total(): Map<ElementType, Int> {
    // Calculate attack totals for each element which is a sum of natural attack plus spell mods from spells(which can come from buffs, items, equipment)
    // Attack can't be negative

    // Natural attack + mod
    var attack_total = new Map<ElementType, Int>();
    for (element in Type.allEnums(ElementType)) {
        attack_total[element] = player_attack[element] + player_attack_mod[element];

        if (attack_total[element] < 0) {
            attack_total[element] = 0;
        }
    }

    return attack_total;
}

static function player_defense_total(): Map<ElementType, Int> {
    var defense_total = new Map<ElementType, Int>();
    for (element in Type.allEnums(ElementType)) {
        defense_total[element] = player_defense[element] + player_defense_mod[element];

        if (defense_total[element] < 0) {
            defense_total[element] = 0;
        }
    }

    return defense_total;
}

static function do_spell(spell: Spell): Bool {
    var spell_over = false;
    var active = false;

    function decrement_duration() {
        // Spell is active every interval, until duration reaches zero
        spell.interval_current++;
        if (spell.interval_current >= spell.interval) {
            spell.interval_current = 0;
            active = true;

            if (spell.duration != Entity.INFINITE) {
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
            // Every attack spells decrement duration only on turns with attacks
            if (attack_target != Entity.NONE) {
                decrement_duration();
            } else {
                active = true;
            }
        }
    }

    // NOTE: Temporary mods currently don't stack, the highest bonus gets applied 
    // NOTE: some infinite spells(buffs from items) are printed, some aren't
    // for example: printing that a sword increases ice attack every turn is NOT useful
    // printing that the sword is damaging the player every 5 turns IS useful
    if (active) {
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

                
                if (spell.duration != Entity.INFINITE) {
                    add_message('${spell.origin_name} increases your max health by ${spell.value}.');
                }
            }
            case SpellType_ModAttack: {
                if (spell.duration_type == SpellDuration_Permanent) {
                    player_attack[spell.element] += spell.value;

                    // Permanent attack mod can't make attack negative
                    if (player_attack[spell.element] < 0) {
                        player_attack[spell.element] = 0;
                    }
                } else {
                    player_attack_mod[spell.element] += spell.value;
                }

                if (spell.duration != Entity.INFINITE) {
                    add_message('${spell.origin_name} increases your ${spell.element} attack by ${spell.value}.');
                }
            }
            case SpellType_ModDefense: {
                if (spell.duration_type == SpellDuration_Permanent) {
                    player_defense[spell.element] += spell.value;
                } else {
                    player_defense_mod[spell.element] += spell.value;
                }

                if (spell.duration != Entity.INFINITE) {
                    add_message('${spell.origin_name} increases your ${spell.element} defense by ${spell.value}.');
                }
            }
        }
    }

    return spell_over;
}

static function end_turn() {
    // NOTE: do mob stuff here

    // Recalculate player room if room changed
    if (player_room != -1) {
        var old_room = rooms[player_room];
        if (!Math.point_box_intersect(player_x, player_y, old_room.x, old_room.y, old_room.width, old_room.height)) {
            player_room = get_room_index(player_x, player_y);
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

    // Cast inventory items' spells
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            var e = inventory[x][y];

            if (Entity.item.exists(e) && !Entity.position.exists(e) && Entity.item[e].spells.length > 0) {
                var item = Entity.item[e];
                var removed_spells = new Array<Spell>();
                for (spell in item.spells) {
                    var spell_over = do_spell(spell);

                    if (spell_over) {
                        removed_spells.push(spell);
                    }
                }
                for (spell in removed_spells) {
                    if (spell.duration_type != SpellDuration_Permanent) {
                        add_message('Spell ${spell.type} wore off.');
                    }
                    player_spells.remove(spell);
                }
            }
        }
    }

    // Cast equipment spells
    for (equipment_type in Type.allEnums(EquipmentType)) {
        var e = player_equipment[equipment_type];

        if (Entity.equipment.exists(e) && !Entity.position.exists(e) && Entity.equipment[e].spells.length > 0) {
            var equipment = Entity.equipment[e];
            var removed_spells = new Array<Spell>();
            for (spell in equipment.spells) {
                var spell_over = do_spell(spell);

                if (spell_over) {
                    removed_spells.push(spell);
                }
            }
            for (spell in removed_spells) {
                if (spell.duration_type != SpellDuration_Permanent) {
                    add_message('Spell ${spell.type} wore off.');
                }
                player_spells.remove(spell);
            }
        }
    }

    // Cast player spells
    var removed_spells = new Array<Spell>();
    for (spell in player_spells) {
        var spell_over = do_spell(spell);

        if (spell_over) {
            removed_spells.push(spell);
        }
    }
    for (spell in removed_spells) {
        if (spell.duration_type != SpellDuration_Permanent) {
            add_message('Spell ${spell.type} wore off.');
        }
        player_spells.remove(spell);
    }

    // Limit health
    if (player_health > player_health_max + player_health_max_mod) {
        player_health = player_health_max + player_health_max_mod;
    }

    // Player attacks entity
    if (attack_target != Entity.NONE) {
        player_attack_entity(attack_target);
        attack_target = Entity.NONE;
    }

    // Entities attack player
    for (e in Entity.combat.keys()) {
        entity_attack_player(e);
    }

    // NOTE: can die from entity attacks OR from health_max going negative from mods
    if (player_health <= 0) {
        add_message('You died.');
    }

    // Entities chase player only if they are in the same room
    for (e in Entity.move.keys()) {
        if (Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (pos.room == player_room) {
                move_entity(e);
            }
        }
    }

    turn_is_over = true;

    // Mark the end of turn
    if (added_message_this_turn) {
        add_message(turn_delimiter);
        added_message_this_turn = false;
    }
}

function update() {
    //
    // Update
    //
    turn_is_over = false;

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
        player_x += player_dx;
        player_y += player_dy;

        var free_map = get_free_map(player_x, player_y, 1, 1, false);
        if (free_map[0][0] || noclip) {
            need_to_update_los = true;
            end_turn();
        } else {
            player_x -= player_dx;
            player_y -= player_dy;
        }
    }

    var view_x = player_x - Math.floor(view_width / 2);
    var view_y = player_y - Math.floor(view_height / 2);

    // Update LOS after movement
    if (need_to_update_los) {
        need_to_update_los = false;

        los = LOS.get_los();
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

    //
    // Attack on left click
    //
    if (Mouse.leftclick() && !turn_is_over && Entity.position.exists(hovered_map)) {
        var pos = Entity.position[hovered_map];
        // Attack if entity is on map, visible and has Combat
        if (player_next_to(Entity.position[hovered_map]) && !los[pos.x - view_x][pos.y - view_y] && Entity.combat.exists(hovered_map)) {
            attack_target = hovered_map;
            end_turn();
        }
    }

    //
    // Render
    //
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
                if (los[x][y] && !no_los) {
                    new_tile = Tile.DarkerGround;
                } else {
                    new_tile = Tile.Ground;
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
    Text.size = 32;
    for (e in Entity.position.keys()) {
        var pos = Entity.position[e];
        if (!out_of_view_bounds(pos.x, pos.y) && (!los[pos.x - view_x][pos.y - view_y] || no_los)) {
            if (Entity.draw_char.exists(e)) {
                // Draw char
                var draw_char = Entity.draw_char[e];
                Text.display(screen_x(pos.x), screen_y(pos.y), draw_char.char, draw_char.color);
            } else if (Entity.draw_tile.exists(e)) {
                // Draw tile
                var tile = Entity.draw_tile[e];
                Gfx.drawtile(screen_x(pos.x), screen_y(pos.y), 'tiles', tile);
            } else if (draw_invisible_entities){

            }
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

    Gfx.scale(1, 1, 0, 0);
    Text.size = 10;

    // Health
    Text.display(screen_x(player_x), screen_y(player_y) - 15, '${player_health}/${player_health_max + player_health_max_mod}');

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

    //
    // UI
    //
    Gfx.scale(1, 1, 0, 0);
    Text.size = 12;

    // Player stats
    var player_stats = "";
    player_stats += 'PLAYER';
    player_stats += '\nPosition: ${player_x} ${player_y}';
    player_stats += '\nHealth: ${player_health}/${player_health_max + player_health_max_mod}';
    var attack_total = player_attack_total();
    player_stats += '\nAttack: P:${attack_total[ElementType_Physical]} F:${attack_total[ElementType_Fire]} I:${attack_total[ElementType_Ice]} S:${attack_total[ElementType_Shadow]} L:${attack_total[ElementType_Light]}';
    var defense_total = player_defense_total();
    player_stats += '\nDefense: P:${defense_total[ElementType_Physical]} F:${defense_total[ElementType_Fire]} I:${defense_total[ElementType_Ice]} S:${defense_total[ElementType_Shadow]} L:${defense_total[ElementType_Light]}';
    // TODO: display absorb amount
    player_stats += '\nCopper: ${copper_count}';
    Text.display(ui_x, player_stats_y, player_stats);

    // Equipment
    Text.display(ui_x, equipment_y - Text.height(), 'EQUIPMENT');
    var tile_screen_size = tilesize * world_scale;
    for (i in 0...equipment_amount) {
        Gfx.drawbox(ui_x + i * tile_screen_size, equipment_y, tile_screen_size, tile_screen_size, Col.WHITE);
    }
    Gfx.scale(world_scale, world_scale, 0, 0);
    var armor_i = 0;
    for (equipment_type in Type.allEnums(EquipmentType)) {
        if (Entity.draw_tile.exists(player_equipment[equipment_type])) {
            var tile = Entity.draw_tile[player_equipment[equipment_type]];
            Gfx.drawtile(ui_x + armor_i * tile_screen_size, equipment_y,  'tiles', tile);
        }
        armor_i++;
    }
    Gfx.scale(1, 1, 0, 0);

    //
    // Inventory
    //
    Text.display(ui_x, inventory_y - Text.height(), 'INVENTORY');
    // Inventory cells
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            Gfx.drawbox(ui_x + x * tile_screen_size, inventory_y + y * tile_screen_size, tile_screen_size, tile_screen_size, Col.WHITE);
        }
    }
    // Inventory entities
    Gfx.scale(world_scale, world_scale, 0, 0);
    Text.size = 32;
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            var e = inventory[x][y];
            if (!Entity.position.exists(e)) {
                if (Entity.draw_tile.exists(e)) {
                    Gfx.drawtile(ui_x + x * tilesize * world_scale, inventory_y + y * tilesize * world_scale, 'tiles', Entity.draw_tile[e]);
                } else if (Entity.draw_char.exists(e)) {
                    var draw_char = Entity.draw_char[e];
                    Text.display(ui_x + x * tilesize * world_scale, inventory_y + y * tilesize * world_scale, draw_char.char, draw_char.color);
                }
            }
        }
    }
    Gfx.scale(1, 1, 0, 0);
    Text.size = 12;

    //
    // Active spells list
    //
    var active_spells = 'SPELLS';
    for (s in player_spells) {
        active_spells += '\n' + spell_description(s);
    }
    Text.wordwrap = 600;
    Text.display(ui_x, spells_list_y, active_spells);
    Text.wordwrap = hovered_tooltip_wordwrap;

    //
    // Hovered entity tooltip
    //
    var entity_tooltip = "";
    if (Entity.name.exists(hovered_anywhere)) {
        entity_tooltip += 'Id: ${hovered_anywhere}';
        entity_tooltip += '\nName: ${Entity.name[hovered_anywhere]}';
    }
    if (Entity.combat.exists(hovered_anywhere)) {
        var entity_combat = Entity.combat[hovered_anywhere];
        entity_tooltip += '\nHealth: ${entity_combat.health}';
        entity_tooltip += '\nAttack: P:${entity_combat.attack[ElementType_Physical]} F:${entity_combat.attack[ElementType_Fire]} I:${entity_combat.attack[ElementType_Ice]} S:${entity_combat.attack[ElementType_Shadow]} L:${entity_combat.attack[ElementType_Light]}';
        entity_tooltip += '\nAbsorb: P:${entity_combat.absorb[ElementType_Physical]} F:${entity_combat.absorb[ElementType_Fire]} I:${entity_combat.absorb[ElementType_Ice]} S:${entity_combat.absorb[ElementType_Shadow]} L:${entity_combat.absorb[ElementType_Light]}';
    }
    if (Entity.description.exists(hovered_anywhere)) {
        entity_tooltip += '\n${Entity.description[hovered_anywhere]}';
    }
    if (Entity.equipment.exists(hovered_anywhere)) {
        var equipment = Entity.equipment[hovered_anywhere];
        entity_tooltip += '\nEquipment name: ${equipment.name}';
        entity_tooltip += '\nEquipment type: ${equipment.type}';
        if (equipment.spells.length > 0) {
            entity_tooltip += '\nSpells applied while equipped:';
            for (s in equipment.spells) {
                entity_tooltip += '\n-' + spell_description(s);
            }
        }
    }
    if (Entity.use.exists(hovered_anywhere)) {
        var use = Entity.use[hovered_anywhere];
        entity_tooltip += '\nSpells applied on use:';
        for (s in use.spells) {
            entity_tooltip += '\n-' + spell_description(s);
        }
    }
    if (Entity.item.exists(hovered_anywhere) && Entity.item[hovered_anywhere].spells.length > 0) {
        var item = Entity.item[hovered_anywhere];
        entity_tooltip += '\nSpells applied while carrying:';
        for (s in item.spells) {
            entity_tooltip += '\n-' + spell_description(s);
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
    if (Mouse.rightclick() && !turn_is_over) {
        interact_target = hovered_anywhere;
        interact_target_x = hovered_anywhere_x;
        interact_target_y = hovered_anywhere_y;
    }

    // Stop interaction if entity too far away or is not visible
    if (Entity.position.exists(interact_target)) {
        var pos = Entity.position[interact_target];
        if (!player_next_to(Entity.position[interact_target]) || los[pos.x - view_x][pos.y - view_y]) {
            interact_target = Entity.NONE;
        }
    }

    // Interaction buttons
    if (!turn_is_over) {
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
        if (Entity.equipment.exists(interact_target) && Entity.position.exists(interact_target)) {
            // Can equip if is equipment and is on map
            if (GUI.auto_text_button('Equip')) {
                equip_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.item.exists(interact_target)) {
            if (Entity.position.exists(interact_target)) {
                // Can be picked up if on map
                if (GUI.auto_text_button('Pick up')) {
                    pick_up_entity(interact_target);

                    done_interaction = true;
                }
            } else {
                // Can be dropped up if not on map(in inventory)
                if (GUI.auto_text_button('Drop')) {
                    drop_entity(interact_target);

                    done_interaction = true;
                }
            }
        }

        if (done_interaction) {
            interact_target = Entity.NONE;
            end_turn();
        } else if (Mouse.leftclick()) {
            // Clicked out of context menu
            interact_target = Entity.NONE;
        }
    }

    // Clear interact target if done something
    if (turn_is_over) {
        interact_target = Entity.NONE;
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
    Text.display(ui_x, message_history_y + 50, messages);

    GUI.x = ui_x - 200;
    GUI.y = 0;
    if (in_funtown) {
        if (GUI.auto_text_button('To world')) {
            in_funtown = false;
            player_x = player_previous_world_x;
            player_y = player_previous_world_y;
            need_to_update_los = true;
            end_turn();
        }
    } else {
        if (GUI.auto_text_button('To funtown')) {
            in_funtown = true;
            player_previous_world_x = player_x;
            player_previous_world_y = player_y;
            player_x = funtown_x;
            player_y = funtown_y;
            need_to_update_los = true;
            end_turn();
        }
    }

    if (GUI.auto_text_button('Toggle minimap')) {
        draw_minimap = !draw_minimap;
    }
    if (GUI.auto_text_button('Toggle noclip')) {
        noclip = !noclip;
    }
    if (GUI.auto_text_button('Toggle los')) {
        no_los = !no_los;
    }
    
    if (draw_minimap) {
        for (r in rooms) {
            Gfx.drawbox(r.x * minimap_scale, r.y * minimap_scale, (r.width) * minimap_scale, (r.height) * minimap_scale, Col.WHITE);
        }

        Gfx.drawbox(player_x * minimap_scale, player_y * minimap_scale, minimap_scale, minimap_scale, Col.RED);
    }

    if (Input.justpressed(Key.SPACE)) {
        end_turn();
    }

    if (player_health <= 0) {
        Text.size = 80;
        Text.display(100, 100, 'DEAD', Col.RED);
        Text.size = 12;
    }
}
}
