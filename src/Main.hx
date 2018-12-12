
import haxe.Timer;
import haxegon.*;
import Entity;
import GenerateWorld;
import GUI;

using MathExtensions;

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
static var previous_world_x = 20;
static var previous_world_y = 20;
static var draw_map = false;
static inline var map_scale = 4;

static var tiles = Data.create2darray(map_width, map_height, Tile.None);
static var walls = Data.create2darray(map_width, map_height, false);

static inline var player_base_attack = 1;
static var player_x = 0;
static var player_y = 0;
static var player_health_max = 10;
static var player_health = 10;
static var copper_count = 0;
static var player_room = -1;
static var need_to_update_los = true;

static var in_funtown = true;
static var noclip = false;
static var no_los = true;

static inline var equipment_y = 120;
static inline var equipment_width = 4;
static var player_armor = [
ArmorType_Head => Entity.NONE,
ArmorType_Chest => Entity.NONE,
ArmorType_Legs => Entity.NONE,
];
static var player_weapon = Entity.NONE;

static inline var message_history_y = 600;
static inline var message_history_length_max = 20;
static var message_history = [for (i in 0...message_history_length_max) turn_delimiter];
static var added_message_this_turn = false;

static inline var ui_x = tilesize * view_width * world_scale + 13;
static inline var player_stats_y = 0;

// Inventory
static inline var inventory_y = 180;
static inline var inventory_width = 4;
static inline var inventory_height = 4;
static inline var inventory_size = inventory_width * inventory_height;
static var inventory = Data.create2darray(inventory_width, inventory_height, Entity.NONE);

static var interact_target = Entity.NONE;
static var interact_target_x: Int;
static var interact_target_y: Int;
static var player_acted = false;

static var canvas_dx = 0;
static var canvas_dy = 0;
static var tile_canvas_state = Data.create2darray(view_width, view_height, Tile.None);

static var rooms: Array<Room>;

static var los: Array<Array<Bool>>;

static inline var turn_delimiter = '------------------------------';

static var prev = new Array<Array<Vec2i>>();

static inline var room_size_min = 10;
static inline var room_size_max = 20;

function init() {
    Core.showstats = true;
    Gfx.resizescreen(screen_width, screen_height, true);
    Text.font = 'pixelFJ8';
    Gfx.loadtiles('tiles', tilesize, tilesize);
    Gfx.createimage('tiles_canvas', tilesize * view_width, tilesize * view_height);

    for (x in 0...room_size_max) {
        var arr = new Array<Vec2i>();
        for (y in 0...room_size_max) {
            arr.push({x: -1, y: -1});
        }
        prev.push(arr);
    }

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            walls[x][y] = true;
        }
    }

    walls[2][4] = true;
    walls[2][5] = true;
    walls[2][6] = true;
    walls[3][6] = true;

    rooms = GenerateWorld.generate_via_digging();
    GenerateWorld.connect_rooms(rooms);
    for (r in rooms) {
        r.width++;
        r.height++;
    }

    // Add funtown room
    rooms.insert(0, {
        x: 1,
        y: 1,
        width: funtown_x,
        height: funtown_y,
        is_connection: false
    });

    // Clear walls for rooms
    for (r in rooms) {
        for (x in r.x...(r.x + r.width)) {
            for (y in r.y...(r.y + r.height)) {
                walls[x][y] = false;
            }
        }
    }

    // GenerateWorld.fill_rooms_with_entities();

    previous_world_x = rooms[1].x;
    previous_world_y = rooms[1].y;

    if (in_funtown) {
        player_x = funtown_x;
        player_y = funtown_y;
    } else {
        player_x = previous_world_x;
        player_y = previous_world_y;
    }

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            if (walls[x][y]) {
                tiles[x][y] = Tile.Wall;
            } else {
                tiles[x][y] = Tile.Ground;
            }
        }
    }

    LOS.calculate_rays();
    los = LOS.get_los();


    MakeEntity.snail(10, 3);
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

    // MakeEntity.sword(6, 7);
    MakeEntity.potion(6, 8);

    // MakeEntity.chest(2, 15);

    // for (i in 0...15) {
    //     var x = 0;
    //     var y = 0;
    //     MakeEntity.potion(x + i, y);
    // }

    player_room = get_room_index(player_x, player_y);
}

// TODO: change to be able to grab free_map only for portion of map
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

static function add_message(message: String) {
    message_history.insert(0, message);
    added_message_this_turn = true;
}

static function use_entity(e: Int) {
    var use = Entity.use[e];

    var display_name = 'noname';
    if (Entity.item.exists(e)) {
        display_name = Entity.item[e].name;
    } else if (Entity.name.exists(e)) {
        display_name = Entity.name[e];
    }

    if (use.charges > 0) {
        use.charges--;

        switch (use.type) {
            case UseType_Heal: {
                player_health += use.value;

                if (player_health > player_health_max) {
                    player_health = player_health_max;
                }

                add_message('${display_name} heals you for ${use.value} health.');
            }
        }
    }

    // Chance color to gray if out of charges
    if (use.charges == 0 && Entity.draw_char.exists(e)) {
        Entity.draw_char[e].color = Col.GRAY;
    }

    // Consumables disappear when all charges are used
    if (use.consumable && use.charges == 0) {
        Entity.remove(e);
    }
}

static function equip_entity(e: Int) {
    var old_e = Entity.NONE;
    if (Entity.armor.exists(e)) {
        var old_armor = Entity.armor[e];
        old_e = player_armor[old_armor.type];
    } else if (Entity.weapon.exists(e)) {
        old_e = player_weapon;
    }

    // Remove new equipment from map
    var e_pos = Entity.position[e];
    var drop_x = e_pos.x;
    var drop_y = e_pos.y;
    Entity.remove_position(e);

    // Unequip old equipment
    if (Entity.equipment.exists(old_e)) {
        add_message('You take off ${Entity.equipment[old_e].name}.');
        Entity.set_position(old_e, drop_x, drop_y);
    }

    add_message('You put on ${Entity.equipment[e].name}.');

    if (Entity.armor.exists(e)) {
        var armor = Entity.armor[e];
        player_armor[armor.type] = e;
    } else if (Entity.weapon.exists(e)) {
        player_weapon = e;
    }
}

static function pick_up_entity(e: Int) {
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

static function player_attack(): Int {
    // Weapon is valid if it's a weapon and it doesn't have a position(not on map)
    if (Entity.weapon.exists(player_weapon) && !Entity.position.exists(player_weapon)) {
        return Entity.weapon[player_weapon].attack;
    } else {
        return player_base_attack;
    }
}

static function player_defense(): Int {
    // Armor is valid if it's an armor and it doesn't have a position(not on map)
    var total = 0;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (Entity.armor.exists(player_armor[armor_type]) && !Entity.position.exists(player_armor[armor_type])) {
            var armor = Entity.armor[player_armor[armor_type]];
            total += armor.defense;
        }
    }
    return total;
}

static function player_defense_absorb(): Int {
    // Each 10 points of defense absorbs 1 dmg per fight
    return Math.floor(player_defense() / 10);
}

static function player_next_to(pos: Position): Bool {
    return Math.dst2(pos.x, pos.y, player_x, player_y) <= 2;
}

static var closed = Data.create2darray(room_size_max, room_size_max, false);
static var open = Data.create2darray(room_size_max, room_size_max, false);
static var g_score = Data.create2darray(room_size_max, room_size_max, 0);
static var f_score = Data.create2darray(room_size_max, room_size_max, 0);
static var dx_dys: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

static function a_star(x1:Int, y1:Int, x2:Int, y2:Int):Array<Vec2i> {
    inline function heuristic_score(x1:Int, y1:Int, x2:Int, y2:Int):Int {
        return Std.int(Math.abs(x2 - x1) + Math.abs(y2 - y1));
    }
    function path(prev:Array<Array<Vec2i>>, x:Int, y:Int):Array<Vec2i> {
        var current = {x: x, y: y};
        var temp = {x: x, y: y};
        var path:Array<Vec2i> = [{x: current.x, y: current.y}];
        while (prev[current.x][current.y].x != -1) {
            temp.x = current.x;
            temp.y = current.y;
            current.x = prev[temp.x][temp.y].x;
            current.y = prev[temp.x][temp.y].y;
            path.push({x: current.x, y: current.y});
        }
        return path;
    }

    var room = rooms[player_room];

    inline function out_of_bounds(x, y) {
        return x < 0 || y < 0 || x >= room.width || y >= room.height;
    }

    trace(room.width);
    
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
            closed[x][y] = false;
        }
    }
    for (x in 0...room.width) {
        for (y in 0...room.height) {
            open[x][y] = false;
        }
    }
    open[x1][y1] = true;

    timer_start();
    var open_length = 1;
    for (x in 0...room.width) {
        for (y in 0...room.height) {
            prev[x][y].x = -1;
            prev[x][y].y = -1;
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

    trace(1);
    timer_end();

    timer_start();

    trace('1 -$x1 $y1');
    trace('2 =$x2 $y2');

    while (open_length != 0) {
        var current = function(): Vec2i {
            var lowest_score = infinity;
            var lowest_node: Vec2i = {x: x1, y: y1};
            for (x in 0...room.width) {
                for (y in 0...room.height) {
                    if (open[x][y] && f_score[x][y] <= lowest_score) {
                        lowest_node.x = x;
                        lowest_node.y = y;
                        lowest_score = f_score[x][y];
                    }
                }
            }
            return lowest_node;
        }();

        trace(current);

        if (current.x == x2 && current.y == y2) {
            trace(2);
            timer_end();
            return path(prev, current.x, current.y);
        }

        open[current.x][current.y] = false;
        open_length--;
        closed[current.x][current.y] = true;
        for (dx_dy in dx_dys) {
            var neighbor_x = current.x + dx_dy.x;
            var neighbor_y = current.y + dx_dy.y;
            if (out_of_bounds(neighbor_x, neighbor_y) || !move_map[neighbor_x][neighbor_y]) {
                continue;
            }

            if (closed[neighbor_x][neighbor_y]) {
                continue;
            }
            var tentative_g_score = g_score[current.x][current.y] + 1;
            if (!open[neighbor_x][neighbor_y]) {
                open[neighbor_x][neighbor_y] = true;
                open_length++;
            } else if (tentative_g_score >= g_score[neighbor_x][neighbor_y]) {
                continue;
            }

            prev[neighbor_x][neighbor_y].x = current.x;
            prev[neighbor_x][neighbor_y].y = current.y;
            g_score[neighbor_x][neighbor_y] = tentative_g_score;
            f_score[neighbor_x][neighbor_y] = g_score[neighbor_x][neighbor_y] + heuristic_score(neighbor_x, neighbor_y, x2, y2);
        }
    }
    return new Array<Vec2i>();
}


static function entity_chase_player(e: Int) {
    var chase_player = Entity.chase_player[e];
    var pos = Entity.position[e];

    if (Math.dst2(pos.x, pos.y, player_x, player_y) > 2) {
        var path = a_star(pos.x, pos.y, player_x, player_y);
        trace(path);

        if (path.length > 2) {
            var room = rooms[player_room];
            Entity.set_position(e, path[path.length - 2].x + room.x, path[path.length - 2].y + room.y);

            // If moved, then entity's turn is over and can't attack
            if (Entity.combat.exists(e)) {
                Entity.combat[e].can_attack = false;
            }
        }
    } else {
        // trace('stop');
    }
}

static function entity_attack(e: Int) {
    var entity_combat = Entity.combat[e];

    if (!entity_combat.can_attack) {
        return;
    }

    var defense_absorb_left = player_defense_absorb();

    var damage_taken = 0;
    var damage_absorbed = 0;

    if (defense_absorb_left > 0) {
        defense_absorb_left -= entity_combat.attack;
        damage_absorbed += entity_combat.attack;

        if (defense_absorb_left < 0) {
            // Fix for negative absorb
            player_health += defense_absorb_left;
            damage_taken -= defense_absorb_left;
            damage_absorbed += defense_absorb_left;
        }
    } else {
        player_health -= entity_combat.attack;
        damage_taken += entity_combat.attack;
    }

    var target_name = 'noname';
    if (Entity.name.exists(e)) {
        target_name = Entity.name[e];
    }
    if (damage_taken != 0) {
        add_message('You take ${damage_taken} damage from $target_name.');
    }
    if (damage_absorbed != 0) {
        add_message('Your armor absorbs ${damage_absorbed} damage.');
    }
    
    if (player_health <= 0) {
        add_message('You died.');
    }
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

static var time_stamp = 0.0;
static function timer_start() {
    time_stamp = Timer.stamp();
}

static function timer_end() {
    var new_stamp = Timer.stamp();
    trace('${new_stamp - time_stamp}');
    time_stamp = new_stamp;
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
    

    for (e in Entity.combat.keys()) {
        // Can attack by default even if not on map
        var combat = Entity.combat[e];
        combat.can_attack = true;

        // If on map, must be next to player
        if (Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (Math.dst2(player_x, player_y, pos.x, pos.y) > 2) {
                combat.can_attack = false;
            }
        }
    }

    // Entities chase player only if they are in the same room
    for (e in Entity.chase_player.keys()) {
        if (Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (pos.room == player_room) {
                entity_chase_player(e);
            }
        }
    }

    for (e in Entity.combat.keys()) {
        entity_attack(e);
    }

    player_acted = true;

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
    player_acted = false;

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
            canvas_dx = player_dx;
            canvas_dy = player_dy;
            need_to_update_los = true;
            end_turn();
        } else {
            player_x -= player_dx;
            player_y -= player_dy;
        }
    }

    var view_x = player_x - Math.floor(view_width / 2);
    var view_y = player_y - Math.floor(view_height / 2);

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
            return y == 0 && x >= 0 && x < equipment_width;
        }

        if (hovering_inventory(mouse_inventory_x, mouse_inventory_y)) {
            hovered_anywhere = inventory[mouse_inventory_x][mouse_inventory_y];
            hovered_anywhere_x = ui_x + mouse_inventory_x * tilesize * world_scale;
            hovered_anywhere_y = inventory_y + mouse_inventory_y * tilesize * world_scale;
        } else if (hovering_equipment(mouse_equip_x, mouse_equip_y)) {
            hovered_anywhere = switch (mouse_equip_x) {
                case 0: player_weapon;
                case 1: player_armor[ArmorType_Head];
                case 2: player_armor[ArmorType_Chest];
                case 3: player_armor[ArmorType_Legs];
                default: Entity.NONE;
            }
            hovered_anywhere_x = ui_x + mouse_equip_x * tilesize * world_scale;
            hovered_anywhere_y = equipment_y;
        }
    }

    //
    // Attack on left click
    //
    if (Mouse.leftclick() && !player_acted && Entity.position.exists(hovered_map) && player_next_to(Entity.position[hovered_map]) && Entity.combat.exists(hovered_map)) {
        var entity_combat = Entity.combat[hovered_map];

        var damage_to_entity = player_attack();

        entity_combat.health -= damage_to_entity;

        var target_name = 'noname';
        if (Entity.name.exists(hovered_map)) {
            target_name = Entity.name[hovered_map];
        }
        add_message('You attack $target_name for $damage_to_entity.');
        add_message(entity_combat.message);

        if (entity_combat.health <= 0) {
            add_message('You slay $target_name.');

            // Some entities drop copper
            if (Entity.give_copper_on_death.exists(hovered_map)) {
                var give_copper = Entity.give_copper_on_death[hovered_map];

                if (Random.chance(give_copper.chance)) {
                    var drop_amount = Random.int(give_copper.min, give_copper.max);
                    copper_count += drop_amount;
                    add_message('$target_name drops $drop_amount copper.');
                }
            }
        }

        if (entity_combat.health <= 0) {
            if (Entity.drop_item.exists(hovered_map) && Entity.position.exists(hovered_map)) {
                var drop_item = Entity.drop_item[hovered_map];
                var pos = Entity.position[hovered_map];
                if (Random.chance(drop_item.chance)) {
                    add_message('$target_name drops ${drop_item.type}.');
                    Entity.remove_position(hovered_map);
                    MakeEntity.item(pos.x, pos.y, drop_item.type);
                }
            }

            Entity.remove(hovered_map);
        }

        end_turn();
    }

    //
    // Render
    //

    if (need_to_update_los) {
        need_to_update_los = false;

        los = LOS.get_los();

        if (no_los) {
            for (x in 0...los.length) {
                for (y in 0...los[x].length) {
                    los[x][y] = false;
                }
            }
        }
    }

    Gfx.scale(1, 1, 0, 0);
    Gfx.drawtoimage('tiles_canvas');
    for (x in 0...view_width) {
        for (y in 0...view_height) {
            var new_tile = Tile.None;
            var map_x = view_x + x;
            var map_y = view_y + y;

            if (!out_of_map_bounds(map_x, map_y) && !walls[map_x][map_y]) {
                if (los[x][y]) {
                    new_tile = Tile.DarkerGround;
                } else {
                    new_tile = Tile.Ground;
                }
            } else {
                new_tile = Tile.Black;
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
        if (!out_of_view_bounds(pos.x, pos.y) && !los[pos.x - view_x][pos.y - view_y]) {
            if (Entity.draw_char.exists(e)) {
                // Draw char
                var draw_char = Entity.draw_char[e];
                Text.display(screen_x(pos.x), screen_y(pos.y), draw_char.char, draw_char.color);
            } else if (Entity.draw_tile.exists(e)) {
                // Draw tile
                var tile = Entity.draw_tile[e];
                Gfx.drawtile(screen_x(pos.x), screen_y(pos.y), 'tiles', tile);
            }
        }
    }

    // Player, draw as parts of each equipment
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor_tile: Int;
        if (Entity.draw_tile.exists(player_armor[armor_type])) {
            armor_tile = Entity.draw_tile[player_armor[armor_type]];
        } else {
            armor_tile = switch (armor_type) {
                case ArmorType_Head: Tile.Head0;
                case ArmorType_Chest: Tile.Chest0;
                case ArmorType_Legs: Tile.Legs0;
            }
        }

        Gfx.drawtile(screen_x(player_x), screen_y(player_y), 'tiles', armor_tile); 
    }
    if (Entity.draw_tile.exists(player_weapon)) {
        var weapon_tile = Entity.draw_tile[player_weapon];
        Gfx.drawtile(screen_x(player_x) + 0.3 * tilesize * world_scale, screen_y(player_y), 'tiles', weapon_tile); 
    }

    //
    // UI
    //
    Gfx.scale(1, 1, 0, 0);
    Text.size = 12;

    // Player stats
    var player_stats = "";
    player_stats += 'PLAYER';
    player_stats += '\nHealth: ${player_health}/${player_health_max}';
    player_stats += '\nAttack: ${player_attack()}';
    player_stats += '\nDefense: ${player_defense()} (absorb ${player_defense_absorb()} damage per fight)';
    player_stats += '\nCopper: ${copper_count}';
    Text.display(ui_x, player_stats_y, player_stats);

    // Equipment
    Text.display(ui_x, equipment_y - Text.height(), 'EQUIPMENT');
    var tile_screen_size = tilesize * world_scale;
    for (i in 0...equipment_width) {
        Gfx.drawbox(ui_x + i * tile_screen_size, equipment_y, tile_screen_size, tile_screen_size, Col.WHITE);
    }
    Gfx.scale(world_scale, world_scale, 0, 0);
    if (Entity.draw_tile.exists(player_weapon)) {
        var tile = Entity.draw_tile[player_weapon];
        Gfx.drawtile(ui_x, equipment_y, 'tiles', tile);
    }
    var armor_i = 1;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (Entity.draw_tile.exists(player_armor[armor_type])) {
            var tile = Entity.draw_tile[player_armor[armor_type]];
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
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            if (Entity.draw_tile.exists(inventory[x][y]) && !Entity.position.exists(inventory[x][y])) {
                Gfx.drawtile(ui_x + x * tilesize * world_scale, inventory_y + y * tilesize * world_scale, 'tiles', Entity.draw_tile[inventory[x][y]]);
            }
        }
    }
    Gfx.scale(1, 1, 0, 0);

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
        entity_tooltip += '\nAttack: ${entity_combat.attack}';
    }
    if (Entity.description.exists(hovered_anywhere)) {
        entity_tooltip += '\n${Entity.description[hovered_anywhere]}';
    }
    if (Entity.equipment.exists(hovered_anywhere)) {
        entity_tooltip += '\nEquipment name: ${Entity.equipment[hovered_anywhere].name}';
    }
    if (Entity.weapon.exists(hovered_anywhere)) {
        entity_tooltip += '\nEquipment attack: ${Entity.weapon[hovered_anywhere].attack}';
    }
    if (Entity.armor.exists(hovered_anywhere)) {
        entity_tooltip += '\nEquipment defense: ${Entity.armor[hovered_anywhere].defense}';
    }
    Text.display(hovered_anywhere_x + tilesize * world_scale, hovered_anywhere_y, entity_tooltip);

    //
    // Interact menu
    //
    // Set interact target on right click
    if (Mouse.rightclick() && !player_acted) {
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

    GUI.x = ui_x;
    GUI.y = 400;
    if (in_funtown) {
        if (GUI.auto_text_button('To world')) {
            in_funtown = false;
            player_x = previous_world_x;
            player_y = previous_world_y;
            need_to_update_los = true;
            end_turn();
        }
    } else {
        if (GUI.auto_text_button('To funtown')) {
            in_funtown = true;
            previous_world_x = player_x;
            previous_world_y = player_y;
            player_x = funtown_x;
            player_y = funtown_y;
            need_to_update_los = true;
            end_turn();
        }
    }

    if (GUI.auto_text_button('Toggle map')) {
        draw_map = !draw_map;
    }
    if (GUI.auto_text_button('Toggle noclip')) {
        noclip = !noclip;
    }
    if (GUI.auto_text_button('Toggle los')) {
        no_los = !no_los;
    }
    
    if (draw_map) {
        for (r in rooms) {
            Gfx.drawbox(r.x * map_scale, r.y * map_scale, (r.width) * map_scale, (r.height) * map_scale, Col.WHITE);
        }

        Gfx.drawbox(player_x * map_scale, player_y * map_scale, map_scale, map_scale, Col.RED);
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
