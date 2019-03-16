
import haxe.Timer;
import haxegon.*;
import Entity;
import Spells;
import Entities;
import GenerateWorld;
import Path;

using haxegon.MathExtensions;
using Lambda;

typedef DamageNumber = {
    value: Int,
    x_offset: Int,
    time: Int,
    color: Int,
};

enum GameState {
    GameState_Normal;
    GameState_Dead;
}

typedef EntityRenderData = {
    draw_tile: Int,
    draw_char: String,
    draw_char_color: Int,
    charges: Int,
    health_bar: String,
};

@:publicFields
class Main {
// force unindent

static inline var SCREEN_WIDTH = 1600;
static inline var SCREEN_HEIGHT = 1000;
static inline var TILESIZE = 8;
static inline var MAP_WIDTH = 125;
static inline var MAP_HEIGHT = 125;
static inline var VIEW_WIDTH = 31;
static inline var VIEW_HEIGHT = 31;
static inline var WORLD_SCALE = 4;
static inline var MINIMAP_SCALE = 4;
static inline var MINIMAP_X = 0;
static inline var MINIMAP_Y = 0;
static inline var ROOM_SIZE_MIN = 5;
static inline var ROOM_SIZE_MAX = 15;
static inline var RINGS_MAX = 2;
static inline var PLAYER_SPELLS_MAX = 10;

static inline var UI_X = TILESIZE * VIEW_WIDTH * WORLD_SCALE + 13;
static inline var PLAYER_STATS_Y = 0;
static inline var PLAYER_STATS_NUMBERS_OFFSET = 85;
static inline var EQUIPMENT_Y = 135;
static inline var EQUIPMENT_COUNT = 4;
static inline var INVENTORY_Y = 210;
static inline var INVENTORY_WIDTH = 4;
static inline var INVENTORY_HEIGHT = 2;
static inline var SPELL_LIST_Y = 300;
static inline var MESSAGES_Y = 600;
static inline var MESSAGES_LENGTH_MAX = 20;
static inline var TURN_DELIMITER = '------------------------------';
static inline var TOOLTIP_WORDWRAP = 400;
static inline var UI_WORDWRAP = 600;
static inline var DRAW_CHAR_TEXT_SIZE = 32;
static inline var UI_TEXT_SIZE = 14;
static inline var PLAYER_HP_HUD_TEXT_SIZE = 8;
static inline var CHARGES_TEXT_SIZE = 8;

var game_state = GameState_Normal;

static var walls = Data.create2darray(MAP_WIDTH, MAP_HEIGHT, false);
static var tiles = Data.create2darray(MAP_WIDTH, MAP_HEIGHT, Tile.None);
static var rooms: Array<Room>;
static var visited_room = new Array<Bool>();
static var room_on_minimap = new Array<Bool>();
var tiles_render_cache = Data.create2darray(VIEW_WIDTH, VIEW_HEIGHT, Tile.None);
var los = Data.create2darray(VIEW_WIDTH, VIEW_HEIGHT, false);
var need_to_update_messages_canvas = true;

var damage_numbers = new Array<DamageNumber>();

static inline var SHOW_SHOW_BUTTONS_BUTTON = false;
static inline var DRAW_INVISIBLE_ENTITIES = true;
var DEV_show_buttons = false;
var DEV_noclip = false;
var DEV_nolos = false;
var DEV_full_minimap = false;
var DEV_frametime_graph = false;
var DEV_nodeath = false;

static var stairs_x = 0;
static var stairs_y = 0;

static var location_spells = [for (x in 0...MAP_WIDTH) [for (y in 0...MAP_HEIGHT) new Array<Spell>()]];
var spells_this_turn = [for (i in 0...(Spells.last_prio + 1)) new Array<Spell>()];

var attack_target = Entity.NONE;
var interact_target = Entity.NONE;
var interact_target_x: Int;
var interact_target_y: Int;

var messages = [for (i in 0...MESSAGES_LENGTH_MAX) TURN_DELIMITER];
var added_message_this_turn = false;

static var four_dxdy: Array<Vec2i> = [{x: -1, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 0, y: -1}];

// Used by all generation functions, don't need to pass it around everywhere
static var current_level = 0;
static var increment_level = true;
static var current_floor = 0;

var start_targeting = false;
var targeting_for_use = false;
var use_entity_that_needs_target = Entity.NONE;
var use_target = Entity.NONE;

var game_stats = new Array<String>();
var copper_gains = new Array<Int>();
var copper_gained_this_floor = 0;

var equipment_render_cache: Map<EquipmentType, EntityRenderData> = [
EquipmentType_Head => null,
EquipmentType_Chest => null,
EquipmentType_Legs => null,
EquipmentType_Weapon => null,
];
var inventory_render_cache: Array<Array<EntityRenderData>> = Data.create2darray(Main.INVENTORY_WIDTH, Main.INVENTORY_HEIGHT, null);

function new() {
    Gfx.resizescreen(SCREEN_WIDTH, SCREEN_HEIGHT);
    // Core.showstats = true;
    Text.setfont('pixelfj8');
    Gfx.loadtiles('tiles', TILESIZE, TILESIZE);
    Gfx.createimage('tiles_canvas', TILESIZE * VIEW_WIDTH, TILESIZE * VIEW_HEIGHT);
    Gfx.createimage('frametime_canvas', 100, 50);
    Gfx.createimage('frametime_canvas2', 100, 50);
    Gfx.createimage('messages_canvas', UI_WORDWRAP, 320);
    Gfx.createimage('minimap_canvas_connections', MAP_WIDTH * MINIMAP_SCALE, MAP_HEIGHT * MINIMAP_SCALE);
    Gfx.createimage('minimap_canvas_rooms', MAP_WIDTH * MINIMAP_SCALE, MAP_HEIGHT * MINIMAP_SCALE);
    Gfx.createimage('minimap_canvas_full', MAP_WIDTH * MINIMAP_SCALE, MAP_HEIGHT * MINIMAP_SCALE);
    Gfx.createimage('ui_items_canvas', INVENTORY_WIDTH * TILESIZE * WORLD_SCALE, SCREEN_HEIGHT);

    Gfx.changetileset('tiles');

    // Draw equipment and inventory boxes
    Gfx.createimage('ui_canvas', UI_WORDWRAP, SCREEN_HEIGHT);
    Gfx.drawtoimage('ui_canvas');

    Gfx.scale(1);
    Text.change_size(UI_TEXT_SIZE);
    var player_stats_left_text = "";
    player_stats_left_text += '\nHealth:';
    player_stats_left_text += '\nAttack:';
    player_stats_left_text += '\nDefense:';
    player_stats_left_text += '\nShield:';
    player_stats_left_text += '\nCopper:\n ';
    Text.display(0, PLAYER_STATS_Y, player_stats_left_text);
    Text.display(0, EQUIPMENT_Y - Text.height() - 2, 'EQUIPMENT');
    Text.display(0, INVENTORY_Y - Text.height() - 2, 'INVENTORY');
    
    Gfx.scale(WORLD_SCALE);
    var armor_i = 0;
    for (equipment_type in Type.allEnums(EquipmentType)) {
        Gfx.drawbox(0 + armor_i * TILESIZE * WORLD_SCALE, EQUIPMENT_Y, TILESIZE * WORLD_SCALE, TILESIZE * WORLD_SCALE, Col.WHITE);
        armor_i++;
    }
    for (x in 0...INVENTORY_WIDTH) {
        for (y in 0...INVENTORY_HEIGHT) {
            Gfx.drawbox(0 + x * TILESIZE * WORLD_SCALE, INVENTORY_Y + y * TILESIZE * WORLD_SCALE, TILESIZE * WORLD_SCALE, TILESIZE * WORLD_SCALE, Col.WHITE);
        }
    }

    Gfx.drawtoscreen();

    Entities.read_name_corpus();
    LOS.calculate_rays();

    restart_game();
    generate_level();
}

function restart_game() {
    damage_numbers = new Array<DamageNumber>();
    
    for (e in Entity.all.copy()) {
        Entity.remove(e);
    }

    Player.spells = new Array<Spell>();
    spells_this_turn = [for (i in 0...(Spells.last_prio + 1)) new Array<Spell>()];

    current_level = 0;
    current_floor = 0;
    Player.health = 10;
    Player.copper_count = 0;
    Player.pure_absorb = 0;
    Player.damage_shield = 0;

    // Insert tutorial into messages
    var tutorial_text = [
    'TUTORIAL',
    TURN_DELIMITER,
    'WASD to move',
    'SPACE to skip a turn',
    TURN_DELIMITER,
    'Right-click on things to interact with them.',
    'You can interact with things on the map if they are next to you.',
    'You can interact with your equipment and items.',
    TURN_DELIMITER,
    'Left-click on enemies to attack them.',
    'Left-click on items and equipment on the ground to pick them up.',
    'Left-click on items in inventory to use them.',
    TURN_DELIMITER,
    'PLAYTEST NOTES',
    'Press F to toggle frametime graph. Let me know if the',
    'perfomance is bad!(above 16ms is bad)',
    'Press G to print game log. It\'s printed to the browser console,',
    'which is opened by ctrl+shift+J. I would appreciate if you copied', 
    'and sent me that log after you are done playing.',
    ];
    messages = [for (i in 0...MESSAGES_LENGTH_MAX) TURN_DELIMITER];
    var tutorial_i = tutorial_text.length; 
    for (line in tutorial_text) {
        messages[tutorial_i] = line;
        tutorial_i--;
    }

    Entities.generated_names = new Array<String>();
}

// Room is good if it's not a connection and isn't locked
static function random_good_room(): Int {
    var room_indices = [
    for (i in 1...rooms.length) { 
        if (!rooms[i].is_connection && !rooms[i].is_locked) {
            i;
        }
    }];
    return Random.pick(room_indices);
}

// NOTE: this is a copy, so can it's safe to modify components while iterating
static function entities_with(map: Map<Int, Dynamic>): Array<Int> {
    return [for (key in map.keys()) key];
}

function generate_level() {
    do {
        // Remove all entities, except inventory items and equipped equipment
        for (e in entities_with(Entity.position)) {
            Entity.remove(e);
        }

        // Remove level-specific player spells
        for (spell in Player.spells.copy()) {
            if (spell.duration == Entity.DURATION_LEVEL) {
                Player.spells.remove(spell);
            }
        }
        // Remove spells about to be casted
        for (list in spells_this_turn) {
            for (s in list.copy()) {
                if (s.duration == Entity.DURATION_LEVEL) {
                    list.remove(s);
                }
            }
        }
        // Remove location spells
        for (x in 0...MAP_WIDTH) {
            for (y in 0...MAP_HEIGHT) {
                if (location_spells[x][y].length > 0) {
                    location_spells[x][y] = new Array<Spell>();
                }
            }
        }

        // Clear wall and tile data
        for (x in 0...MAP_WIDTH) {
            for (y in 0...MAP_HEIGHT) {
                walls[x][y] = true;
                tiles[x][y] = Tile.Black;
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
        GenerateWorld.fatten_connections();

        var current_ground_tile = Tile.Ground[get_level_tile_index()];

        // Clear walls inside rooms
        for (r in rooms) {
            for (x in r.x...(r.x + r.width)) {
                for (y in r.y...(r.y + r.height)) {
                    walls[x][y] = false;
                    tiles[x][y] = current_ground_tile;
                }
            }
        }

        // Put random formations in rooms
        GenerateWorld.decorate_rooms_with_walls();

        visited_room = [for (i in 0...rooms.length) false];
        room_on_minimap = [for (i in 0...rooms.length) false];

        Gfx.drawtoimage('minimap_canvas_connections');
        Gfx.clearscreentransparent();
        Gfx.drawtoscreen();
        Gfx.drawtoimage('minimap_canvas_rooms');
        Gfx.clearscreentransparent();
        Gfx.drawtoscreen();

        Gfx.drawtoimage('minimap_canvas_full');
        Gfx.clearscreentransparent();
        for (i in 0...rooms.length) {
            var r = rooms[i];
            if (r.is_connection) {
                Gfx.fillbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.BLACK);
                Gfx.drawbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.WHITE);
            }
        }
        for (i in 0...rooms.length) {
            var r = rooms[i];
            if (!r.is_connection) {
                Gfx.fillbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.BLACK);
                Gfx.drawbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.WHITE);
            }
        }
        Gfx.drawtoscreen();

        // Set start position to first room, before generating entities so that generation uses the new player position in collision checks
        Player.room = 0;
        Player.x = rooms[0].x;
        Player.y = rooms[0].y;
        
        for (dx in 1...10) {
            Entities.random_weapon(Player.x + dx, Player.y);
            Entities.random_armor(Player.x + dx, Player.y + 1);
            Entities.random_scroll(Player.x + dx, Player.y + 2);
            Entities.random_potion(Player.x + dx, Player.y + 3);
            Entities.random_orb(Player.x + dx, Player.y + 4);
            Entities.random_ring(Player.x + dx, Player.y + 5);
        }

        // Place stairs at the center of a random room(do this before generating entities to avoid overlaps)
        var r = rooms[random_good_room()];
        stairs_x = r.x + Math.floor(r.width / 2);
        stairs_y = r.y + Math.floor(r.height / 2);
        Entities.stairs(stairs_x, stairs_y);

        // NOTE: we check for path from stairs to player but stairs can still spawn in walls(decoration in center of room) if it's at the edge, so just remove wall at stair location
        walls[stairs_x][stairs_y] = false;
        tiles[stairs_x][stairs_y] = current_ground_tile;
    } while (Path.astar_map(Player.x, Player.y, stairs_x, stairs_y).length == 0);

    GenerateWorld.fill_rooms_with_entities();

    // Reset old pos to force los update, very small chance of player spawning in same position and los not updating
    Player.x_old = -1;
    Player.y_old = -1;

    //
    // Save game stats for this floor
    //
    var floor_stats = 'floor=$current_floor hp=${Player.health}/${Player.health} attack=${Player.attack} defense=${Player.defense}';

    // Count enemies by name
    var enemy_counts = new Map<String, Int>();
    for (e in entities_with(Entity.combat)) {
        if (Entity.merchant.exists(e)) {
            continue;
        }

        var name = Entity.name[e];
        if (enemy_counts.exists(name)) {
            enemy_counts[name]++;
        } else {
            enemy_counts[name] = 1;
        }
    }

    var total_enemy_count = 0;
    for (enemy in enemy_counts.keys()) {
        total_enemy_count += enemy_counts[enemy];
    }

    floor_stats += '\n$total_enemy_count enemies=';

    var recorded_enemies = new Array<String>();
    for (e in entities_with(Entity.combat)) {
        if (Entity.merchant.exists(e)) {
            continue;
        }

        // Record each enemy only once
        var name = Entity.name[e];
        if (recorded_enemies.indexOf(name) != -1) {
            continue;
        }
        recorded_enemies.push(name);

        var combat = Entity.combat[e];
        var aggression = switch (combat.aggression) {
            case AggressionType_Aggressive: 'a';
            case AggressionType_NeutralToAggressive: 'nta';
            case AggressionType_Neutral: 'n';
            case AggressionType_Passive: 'p';
        }

        // Pad name
        var padded_name = name;
        while (padded_name.length < 15) {
            padded_name += ' ';
        }

        floor_stats += '\n${padded_name}c=${enemy_counts[name]}\ta=${combat.attack}\th=${combat.health}\tr^2=${combat.range_squared}\ta=${aggression}';
    }

    game_stats.push(floor_stats);

    copper_gains.push(copper_gained_this_floor);
    copper_gained_this_floor = 0;
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
    return unscaled_screen_x(x) * WORLD_SCALE;
}
inline function screen_y(y) {
    return unscaled_screen_y(y) * WORLD_SCALE;
}
inline function unscaled_screen_x(x) {
    return (x - Player.x + Math.floor(VIEW_WIDTH / 2)) * TILESIZE;
}
inline function unscaled_screen_y(y) {
    return (y - Player.y + Math.floor(VIEW_HEIGHT / 2)) * TILESIZE;
}
static inline function get_view_x(): Int { return Player.x - Math.floor(VIEW_WIDTH / 2); }
static inline function get_view_y(): Int { return Player.y - Math.floor(VIEW_WIDTH / 2); }

static inline function out_of_map_bounds(x, y) {
    return x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT;
}

inline function out_of_view_bounds(x, y) {
    return x < (Player.x - Math.floor(VIEW_WIDTH / 2)) || y < (Player.y - Math.floor(VIEW_HEIGHT / 2)) || x > (Player.x + Math.floor(VIEW_WIDTH / 2)) || y > (Player.y + Math.floor(VIEW_HEIGHT / 2));
}

static function get_drop_entity_level(): Int {
    return 
    if (Player.increase_drop_level) {
        current_level + 1;
    } else {
        current_level;
    }
}

static function get_level_tile_index(): Int {
    var level_tile_index = Math.round(current_floor / 3);
    if (level_tile_index >= Tile.Stairs.length) {
        level_tile_index = 0;
    }
    return level_tile_index;
}

function player_next_to(pos: Position): Bool {
    return Math.abs(Player.x - pos.x) <= 1 && Math.abs(Player.y - pos.y) <= 1;
}

function add_message(new_message: String) {
    messages.insert(0, new_message);
    added_message_this_turn = true;
    need_to_update_messages_canvas = true;
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
    return !los[x][y] || Player.nolos || DEV_nolos;
}

static function get_free_map(x1: Int, y1: Int, width: Int, height: Int, free_map: Array<Array<Bool>> = null, include_player: Bool = true, include_entities: Bool = true, include_doors: Bool = true): Array<Array<Bool>> {
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

    if (include_doors) {
        for (locked in entities_with(Entity.container)) {
            var pos = Entity.position[locked];
            if (Math.point_box_intersect(pos.x, pos.y, x1, y1, width, height) && Entity.name.exists(locked) && Entity.name[locked] == 'Door') {
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

    if (include_player && Math.point_box_intersect(Player.x, Player.y, x1, y1, width, height)) {
        free_map[Player.x - x1][Player.y - y1] = false;
    }

    return free_map;
}

function try_buy_entity(e: Int) {
    var cost = Entity.cost[e];

    if (Player.copper_count >= cost) {
        Player.copper_count -= cost;

        Entity.cost.remove(e);

        add_message('Purchase complete.');
    } else {
        add_message('You do not have enough copper.');
    }
}

function drop_entity_from_entity(e: Int) {
    var drop_entity = Entity.drop_entity[e];
    var pos = Entity.position[e];

    Entity.remove_position(e);

    var drop = drop_entity.drop_func(pos.x, pos.y);
    if (drop != Entity.NONE) {
        var drop_name = if (Entity.name.exists(drop)) {
            Entity.name[drop];
        } else {
            'unnamed_drop';
        }

        var dropping_entity_name = if (Entity.name.exists(e)) {
            Entity.name[e];
        } else {
            'unnamed_dropping_entity';
        }

        add_message('$dropping_entity_name drops $drop_name.');
    }
}

function try_open_entity(e: Int) {
    // Look for same color unlocker in inventory
    var locked = Entity.container[e];

    var locked_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_locked';
    }

    function drop_from_locked() {
        if (Entity.drop_entity.exists(e) && Entity.position.exists(e)) {
            drop_entity_from_entity(e);
        }
    }

    if (locked.locked) {
        // Normal locked need a matching key, search for it in inventory
        for (y in 0...INVENTORY_HEIGHT) {
            for (x in 0...INVENTORY_WIDTH) {
                if (Entity.unlocker.exists(Player.inventory[x][y]) && !Entity.position.exists(Player.inventory[x][y]) && Entity.unlocker[Player.inventory[x][y]].color == locked.color) {
                    // Found unlocker, remove unlocker and unlock locked entity
                    add_message('You unlock $locked_name.');
                    Entity.remove(Player.inventory[x][y]);

                    drop_from_locked();
                    Entity.remove(e);

                    return;
                }
            }
        }

        add_message('Need matching key to unlock $locked_name.');
    } else {
        // Unlocked lockeds don't need a key
        add_message('You open $locked_name.');
        drop_from_locked();
        Entity.remove(e);
    }
}

function use_entity(e: Int) {
    var use = Entity.use[e];

    if (use.charges > 0) {
        use.charges--;

        if (use.flavor_text.length > 0) {
            add_message(use.flavor_text);
        }

        // Save name before pushing spell onto player
        for (spell in use.spells) {
            spell.origin_name = if (Entity.name.exists(e)) {
                Entity.name[e];
            } else {
                'unnamed_origin';
            }
            Player.spells.push(Spells.copy(spell));

            // If too many player spells, remove older ones
            if (Player.spells.length > PLAYER_SPELLS_MAX) {
                add_message('Too many active spells, an old spell was removed.');
                Player.spells.shift();
            }
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
    var old_e = Player.equipment[e_equipment.type];

    // Remove entity from map
    if (Entity.equipment.exists(old_e) && !Entity.position.exists(old_e)) {
        // If there's equipment in slot, swap position with new equipment
        var unequip_name = if (Entity.name.exists(old_e)) {
            Entity.name[old_e];
        } else {
            'unnamed_unequip';
        }
        add_message('You unequip $unequip_name.');

        var e_pos = Entity.position[e];
        Entity.remove_position(e);
        Entity.set_position(old_e, e_pos.x, e_pos.y);
    } else {
        Entity.remove_position(e);
    }

    var equip_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_equip';
    }
    add_message('You equip ${Entity.name[e]}.');

    Player.equipment[e_equipment.type] = e;
}

function move_entity_into_inventory(e: Int) {
    var item = Entity.item[e];

    // Clear picked up entity from any inventory slots if it was there before, if this is not done and there is an empty slot before the old slot of the new entity, then inventory will have two references to this item
    for (y in 0...INVENTORY_HEIGHT) {
        for (x in 0...INVENTORY_WIDTH) {
            if (Player.inventory[x][y] == e) {
                Player.inventory[x][y] = Entity.NONE;
            }
        }
    }

    if (Entity.ring.exists(e)) {
        // Entity is a ring, need to check that there are ring slots available
        var ring_count = 0;
        for (y in 0...INVENTORY_HEIGHT) {
            for (x in 0...INVENTORY_WIDTH) {
                var other_e = Player.inventory[x][y];
                if (Entity.item.exists(other_e) && !Entity.position.exists(other_e)) {
                    var other_item = Entity.item[other_e];
                    if (Entity.ring.exists(other_e)) {
                        ring_count++;

                        if (ring_count >= RINGS_MAX) {
                            add_message('Can\'t have more than $RINGS_MAX rings.');
                            return;
                        }
                    }
                }
            }
        }
    }

    // Flip loop order so that rows are filled first
    for (y in 0...INVENTORY_HEIGHT) {
        for (x in 0...INVENTORY_WIDTH) {
            // Inventory slot is free if it points to entity that is not an item(removed) or an entity that is an item but has position(dropped on map)
            var doesnt_exist = !Entity.item.exists(Player.inventory[x][y]);
            var not_in_inventory = Entity.item.exists(Player.inventory[x][y]) && Entity.position.exists(Player.inventory[x][y]);
            if (doesnt_exist || not_in_inventory) {
                Player.inventory[x][y] = e;

                add_message('You pick up ${Entity.name[e]}.');
                Entity.remove_position(e);

                return;
            }
        }
    }
    add_message('Inventory is full.');
}

function free_position_around_player(): Vec2i {
    // Search for free position around player
    var free_map = get_free_map(Player.x - 1, Player.y - 1, 3, 3);

    var free_x: Int = -1;
    var free_y: Int = -1;
    for (dx in -1...2) {
        for (dy in -1...2) {
            var x = Player.x + dx;
            var y = Player.y + dy;
            if (!out_of_map_bounds(x, y) && free_map[dx + 1][dy + 1]) {
                return {x: x, y: y};
                break;
            }
        }
    }

    return {x: -1, y: -1};
}

function drop_entity_from_player(e: Int) {
    var pos = free_position_around_player();

    if (pos.x != -1 && pos.y != -1) {
        var drop_name = if (Entity.name.exists(e)) {
            Entity.name[e];
        } else {
            'unnamed_drop_from_player';
        }

        add_message('You drop ${drop_name}.');
        Entity.set_position(e, pos.x, pos.y);
    } else {
        add_message('No space to drop item.');
    }
}

function move_entity(e: Int) {
    var move = Entity.move[e];
    var pos = Entity.position[e];

    var prev_successive_moves = move.successive_moves;
    move.successive_moves = 0;
    
    // Entity must be in view to chase
    if (out_of_view_bounds(pos.x, pos.y)) {
        return;
    }

    // Can't move if attacked this turn or did something else
    if (move.cant_move) {
        move.cant_move = false;
        return;
    }

    // Skip moving sometimes as the number of successive moves goes up, this is so that monsters don't follow the player forever
    if (Random.chance(Std.int(Math.min(100, prev_successive_moves * prev_successive_moves * prev_successive_moves)))) {
        return;
    }

    // Moved, so increment successive moves count
    move.successive_moves = prev_successive_moves + 1;

    function random_move() {
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

    // Find target position
    var target_x = -1;
    var target_y = -1;
    if (move.type == MoveType_Astar || move.type == MoveType_Straight || move.type == MoveType_Straight) {

        // Find closest enemies and friendlies
        var enemy_x = -1;
        var enemy_y = -1;
        var friendly_x = -1;
        var friendly_y = -1;
        var closest_enemy_dst = 10000000.0;
        var closest_friendly_dst = 10000000.0;
        var player_dst = Math.dst2(Player.x, Player.y, pos.x, pos.y);

        for (other_e in entities_with(Entity.combat)) {
            // Skip itself
            if (other_e == e) {
                continue;
            }

            // Entity must have position and combat
            // NOTE: enemy/friendly is a reverse of combat target, an entity is FRIENDLY if it's combat target is ENEMY
            if (Entity.position.exists(other_e) && Entity.combat.exists(other_e)) {
                var other_pos = Entity.position[other_e];

                // Entity must be in view
                if (out_of_view_bounds(other_pos.x, other_pos.y)) {
                    continue;
                }

                var other_target = Entity.combat[other_e].target;
                var dst = Math.dst2(other_pos.x, other_pos.y, pos.x, pos.y);

                switch (other_target) {
                    case CombatTarget_Enemy: {
                        if (dst < closest_friendly_dst) {
                            closest_friendly_dst = dst;
                            friendly_x = other_pos.x;
                            friendly_y = other_pos.y;
                        }
                    }
                    case CombatTarget_FriendlyThenPlayer: {
                        if (dst < closest_enemy_dst) {
                            closest_enemy_dst = dst;
                            enemy_x = other_pos.x;
                            enemy_y = other_pos.y;
                        }
                    }
                }
            }
        }

        // Decide who to move to

        switch (move.target) {
            case MoveTarget_PlayerOnly: {
                if (!Player.invisible) {
                    target_x = Player.x;
                    target_y = Player.y;
                }
            }
            case MoveTarget_EnemyOnly: {
                if (enemy_x != -1 && enemy_y != -1) {
                    target_x = enemy_x;
                    target_y = enemy_y;
                }
            }
            case MoveTarget_FriendlyThenPlayer: {
                if (friendly_x != -1 && friendly_y != -1 && Math.dst(friendly_x, friendly_y, pos.x, pos.y) <= move.chase_dst) {
                    // Chase friendly if there's one and it's within chase dst
                    target_x = friendly_x;
                    target_y = friendly_y;
                } else if (!Player.invisible) {
                    // Otherwise chase player
                    target_x = Player.x;
                    target_y = Player.y;
                }
            }
            case MoveTarget_EnemyThenPlayer: {
                if (enemy_x != -1 && enemy_y != -1 && Math.dst(enemy_x, enemy_y, pos.x, pos.y) <= move.chase_dst) {
                    // Chase enemy if there's one and it's within chase dst
                    target_x = enemy_x;
                    target_y = enemy_y;
                } else if (!Player.invisible) {
                    // Otherwise chase player
                    target_x = Player.x;
                    target_y = Player.y;
                }
            }
        }
    }

    var actual_move_type = move.type;

    switch (move.type) {
        case MoveType_Astar: {
            if (target_x != -1 && target_y != -1 && Math.dst(target_x, target_y, pos.x, pos.y) < move.chase_dst) {
                var path = Path.astar_view(pos.x, pos.y, target_x, target_y);

                if (path.length > 2) {
                    Entity.set_position(e, path[path.length - 2].x + get_view_x(), path[path.length - 2].y + get_view_y());
                }
            }
        }
        case MoveType_Straight: {
            if (target_x != -1 && target_y != -1 && Math.dst(target_x, target_y, pos.x, pos.y) < move.chase_dst) {
                var dx = target_x - pos.x;
                var dy = target_y - pos.y;
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
        }
        case MoveType_Random: {
            if (Random.chance(50)) {
                random_move();
            }
        }
        case MoveType_StayAway: {
            // Randomly move but also stay away from player
            if (Math.dst(target_x, target_y, pos.x, pos.y) <= 4) {
                var dx = - (target_x - pos.x);
                var dy = - (target_y - pos.y);
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
            } else {
                if (Random.chance(50)) {
                    random_move();
                }
            }
        }
    }
}

function kill_entity(e: Int) {
    // Drop entities if can and entity is on map
    if (Entity.drop_entity.exists(e) && Entity.position.exists(e)) {
        drop_entity_from_entity(e);
    }

    // Merchant death makes all cost items free
    if (Entity.name.exists(e) && Entity.merchant.exists(e)) {
        for (e in entities_with(Entity.cost)) {
            Entity.cost.remove(e);
        }
        add_message('Shop items are now free.');
    }

    Entity.remove(e);
}

function entity_attack_entity(e: Int, target: Int) {
    var combat = Entity.combat[e];
    var target_combat = Entity.combat[target];
    
    var should_attack = switch (combat.aggression) {
        case AggressionType_Aggressive: true;
        case AggressionType_Neutral: true; // Neutral always attacks other entities
        case AggressionType_NeutralToAggressive: false;
        case AggressionType_Passive: false;
    }

    if (!should_attack) {
        return;
    }

    target_combat.health -= combat.attack;

    add_message(combat.message);
    
    var e_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_e';
    }
    var target_name = if (Entity.name.exists(target)) {
        Entity.name[target];
    } else {
        'unnamed_target_of_e';
    }
    if (combat.attack != 0) {
        add_message('$e_name attacks $target_name for ${combat.attack} damage.');
    }

    // Can't move and attack in same turn
    if (Entity.move.exists(e)) {
        var move = Entity.move[e];
        move.cant_move = true;
    }

    if (target_combat.health <= 0) {
        kill_entity(target);
    }
}

function entity_attack_player(e: Int): Bool {
    if (!Entity.combat.exists(e) || !Entity.position.exists(e)) {
        return false;
    }

    var combat = Entity.combat[e];
    
    // Must be next to player
    var pos = Entity.position[e];

    // Must be in view and visible, ok to be in another room as long as entity is visible, this way entities can't attack through walls but attacking around corners works the same way as player attacks
    if (out_of_view_bounds(pos.x, pos.y) || !position_visible(pos.x - get_view_x(), pos.y - get_view_y())) {
        return false;
    }

    // NeutralToAggressive become aggressive on attack and starts chasing
    if (combat.aggression == AggressionType_NeutralToAggressive && combat.attacked_by_player) {
        combat.aggression = AggressionType_Aggressive;

        Entity.move[e] = {
            type: MoveType_Astar,
            cant_move: false,
            successive_moves: 0,
            chase_dst: Main.VIEW_WIDTH, // chase forever
            target: MoveTarget_FriendlyThenPlayer,
        }
    }

    var should_attack = switch (combat.aggression) {
        case AggressionType_Aggressive: true;
        case AggressionType_Neutral: combat.attacked_by_player;
        case AggressionType_NeutralToAggressive: combat.attacked_by_player;
        case AggressionType_Passive: false;
    }
    combat.attacked_by_player = false;

    if (!should_attack) {
        return false;
    }

    var damage_taken = 0;
    var damage_absorbed = 0;

    var absorb = {
        // 82 def = absorb at least 8, absorb 9 20% of the time
        var total_defense = Player.defense + Player.defense_mod;
        var absorb: Int = Math.floor(total_defense / 10);
        if (Random.chance((total_defense % 10) * 10)) {
            absorb++;
        }
        absorb;
    };
    var damage = Std.int(Math.max(0, combat.attack - absorb));
    add_message(combat.message);

    var target_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_target';
    }

    damage_player(damage, ' from $target_name');

    // Can't move and attack in same turn
    if (Entity.move.exists(e)) {
        var move = Entity.move[e];
        move.cant_move = true;
    }

    return true;
}

function entity_attack(e: Int): Bool {
    if (!Entity.combat.exists(e) || !Entity.position.exists(e)) {
        return false;
    }

    var combat = Entity.combat[e];
    var pos = Entity.position[e];

    // Entity must be in view
    if (out_of_view_bounds(pos.x, pos.y)) {
        return false;
    }

    // Attack player if in range, prio player over friendlies
    if (combat.target == CombatTarget_FriendlyThenPlayer && Math.dst2(Player.x_old, Player.y_old, pos.x, pos.y) <= combat.range_squared) {
        return entity_attack_player(e);
    }

    // Find target entity of opposite faction
    var target_e = Entity.NONE;
    for (other_e in entities_with(Entity.combat)) {
        // Skip itself
        if (other_e == e) {
            continue;
        }

        // Target must have position, combat and have opposite target
        if (Entity.position.exists(other_e) && Entity.combat.exists(other_e) && Entity.combat[other_e].target != combat.target) {
            var other_pos = Entity.position[other_e];

            if (Math.dst2(other_pos.x, other_pos.y, pos.x, pos.y) <= combat.range_squared) {
                target_e = other_e;
                break;
            }
        }
    }

    if (target_e != Entity.NONE) {
        entity_attack_entity(e, target_e);
    }

    return false;
}

function player_attack_entity(e: Int, attack: Int, is_spell: Bool = true) {
    if (!Entity.combat.exists(e)) {
        return;
    }
    
    var combat = Entity.combat[e];

    if (is_spell) {
        attack += Player.spell_damage_mod;
    }

    combat.health -= attack;
    combat.attacked_by_player = true;

    var target_name = if (Entity.name.exists(e)) {
        Entity.name[e];
    } else {
        'unnamed_target';
    }
    add_message('You attack $target_name for $attack.');

    if (Player.health_leech) {
        Player.health += attack;
        if (Player.health > Player.health_max) {
            Player.health = Player.health_max;
        }
        add_message('Health leech heals you for $attack.');
    }

    if (combat.health <= 0) {
        add_message('You slay $target_name.');
    }

    if (combat.health <= 0) {
        kill_entity(e);
    }
}

function render_data_equals(d1: EntityRenderData, d2: EntityRenderData): Bool {
    return 
    d1.draw_tile == d2.draw_tile 
    && d1.draw_char == d2.draw_char 
    && d1.draw_char_color == d2.draw_char_color 
    && d1.charges == d2.charges 
    && d1.health_bar == d2.health_bar;
}

static function get_entity_render_data(e: Int): EntityRenderData {
    var draw_tile = -1;
    var draw_char = 'null';
    var draw_char_color = -1;
    if (Entity.draw_char.exists(e)) {
        draw_char = Entity.draw_char[e].char;
        draw_char_color = Entity.draw_char[e].color;
    } else if (Entity.draw_tile.exists(e)) {
        draw_tile = Entity.draw_tile[e];
    } else if (DRAW_INVISIBLE_ENTITIES) {
        // Draw invisible entities as question mark
        draw_tile = Tile.None;
    }

    var charges = -1;
    if (Entity.use.exists(e)) {
        var use = Entity.use[e];

        if (use.draw_charges) {
            charges = use.charges;
        }
    }

    var health_bar = 'null';
    if (Entity.combat.exists(e)) {
        var combat = Entity.combat[e];
        health_bar = '${combat.health}/${combat.health_max}';
    }

    return {
        draw_tile: draw_tile,
        draw_char: draw_char,
        draw_char_color: draw_char_color,
        charges: charges,
        health_bar: health_bar,
    };
}

// TODO: optimize this, currently perfomance is bad when there are many entities on screen each with charge indicator
function draw_entity(e: Int, x: Float, y: Float, render_data: EntityRenderData = null) {
    if (render_data == null) {
        render_data = get_entity_render_data(e);
    }

    if (render_data.draw_char != 'null') {
        // Draw char
        Text.change_size(DRAW_CHAR_TEXT_SIZE);
        Text.display(x, y, render_data.draw_char, render_data.draw_char_color);
    } else if (render_data.draw_tile != -1) {
        // Draw tile
        Gfx.drawtile(x, y, render_data.draw_tile);
    }

    // Draw use charges
    if (render_data.charges != -1) {
        Text.change_size(CHARGES_TEXT_SIZE);
        Text.display(x, y, '${render_data.charges}', Col.WHITE);
    }

    // Draw health bar
    if (render_data.health_bar != 'null') {
        Text.change_size(CHARGES_TEXT_SIZE);
        Text.display(x, y - 10, render_data.health_bar);
    }
}

function damage_player(damage: Int, from_text: String = '') {
    var actual_damage = damage;
    // Apply pure absorb
    if (Player.pure_absorb > actual_damage) {
        Player.pure_absorb -= actual_damage;
        actual_damage = 0;
    } else {
        actual_damage -= Player.pure_absorb;
        Player.pure_absorb = 0;
    }

    var absorb_amount = damage - actual_damage;

    Player.health -= actual_damage;

    if (actual_damage > 0) {
        add_message('You take ${actual_damage} damage${from_text}.');
        add_damage_number(-actual_damage);
    }

    if (absorb_amount > 0) {
        add_message('You absorb ${absorb_amount} damage${from_text}.');
    }
}

function do_spell(spell: Spell, effect_message: Bool = true) {
    // NOTE: some infinite spells(buffs from items) are printed, some aren't
    // for example: printing that a sword increases ice attack every turn is NOT useful
    // printing that the sword is damaging the player every 5 turns IS useful

    function teleport_player_to_room(room_i: Int): Bool {
        // Teleport to random position in a random room
        // NOTE: in very rare cases teleport location might not have a path to stairs, in which case teleport just fails, for example if the player creates a blockade with dropped items
        var r = rooms[room_i];
        var positions = GenerateWorld.room_free_positions_shuffled(r);
        var pos = positions.pop();

        // Check that there is a path to stairs
        var path = Path.astar_map(pos.x, pos.y, stairs_x, stairs_y);

        if (path.length > 0) {
            Player.x = pos.x;
            Player.y = pos.y;
            Player.room = room_i;
            return true;
        } else {
            return false;
        }
    }

    switch (spell.type) {
        case SpellType_ModHealth: {
            // Negative health changes are affected by player defences
            if (spell.value >= 0) {
                Player.health += spell.value;

                add_message('${spell.origin_name} heals you for ${spell.value} health.');
                add_damage_number(spell.value);
            } else {
                // NOTE: damage needs to be positive
                damage_player(-1 * spell.value, ' from ${spell.origin_name}');
            }
        }
        case SpellType_ModHealthMax: {
            if (spell.duration_type == SpellDuration_Permanent) {
                Player.health_max += spell.value;
                Player.health += spell.value;
            } else {
                Player.health_max_mod += spell.value;
            }
            
            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your max health by ${spell.value}.');
            }
        }
        case SpellType_ModAttack: {
            if (spell.duration_type == SpellDuration_Permanent) {
                Player.attack += spell.value;

                // Attack can't be negative
                if (Player.attack < 0) {
                    Player.attack = 0;
                }
            } else {
                Player.attack_mod += spell.value;
            }

            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your attack by ${spell.value}.');
            }
        }
        case SpellType_ModDefense: {
            if (spell.duration_type == SpellDuration_Permanent) {
                Player.defense += spell.value;
            } else {
                Player.defense_mod += spell.value;
            }

            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your defense by ${spell.value}.');
            }
        }
        case SpellType_UncoverMap: {
            Player.full_minimap = true;
        }
        case SpellType_RandomTeleport: {
            // Teleport to random room
            var teleport_success = teleport_player_to_room(random_good_room());

            if (teleport_success) {
                add_message('You are teleported to a random room.');
            } else {
                add_message('Teleport fails!');
            }
        }
        case SpellType_SafeTeleport: {
            // Teleport to first room, which is always empty
            var teleport_success = teleport_player_to_room(0);
            
            if (teleport_success) {
                add_message('You are teleported to a safe place.');
            } else {
                add_message('Teleport fails!');
            }
        }
        case SpellType_Nolos: {
            Player.nolos = true;
        }
        case SpellType_Noclip: {
            Player.noclip = true;
        }
        case SpellType_ShowThings: {
            Player.show_things = true;
        }
        case SpellType_HealthLeech: {
            Player.health_leech = true;
        }
        case SpellType_NextFloor: {
            if (increment_level) {
                current_level++;
            }
            increment_level = !increment_level;
            current_floor++;

            generate_level();
            add_message('You go up to the next floor.');
        }
        case SpellType_ModMoveSpeed: {
            Player.movespeed_mod += spell.value;
        }
        case SpellType_ModDropChance: {
            Player.dropchance_mod += spell.value;
        }
        case SpellType_ModCopperChance: {
            Player.copper_drop_mod += spell.value;
        }
        case SpellType_AoeDamage: {
            var view_x = get_view_x();
            var view_y = get_view_y();
            // AOE affects visible entities
            for (e in entities_with(Entity.combat)) {
                if (Entity.position.exists(e)) {
                    var pos = Entity.position[e];

                    if (!out_of_view_bounds(pos.x, pos.y) && position_visible(pos.x - view_x, pos.y - view_y)) {
                        player_attack_entity(e, spell.value);
                    }
                }
            }
        }
        case SpellType_Combust: {
            var target_pos = Entity.position[use_target];

            var combust_dst2 = 18; // 7x7 square around entity

            // Player gets damaged too if he's close to target
            if (Math.dst2(Player.x, Player.y, target_pos.x, target_pos.y) <= combust_dst2) {
                damage_player(spell.value, ' from Combustion blast');
            }
            
            var view_x = get_view_x();
            var view_y = get_view_y();
            // combust affects nearby entities
            for (e in entities_with(Entity.combat)) {
                if (Entity.position.exists(e)) {
                    var pos = Entity.position[e];

                    if (!out_of_view_bounds(pos.x, pos.y) && Math.dst2(pos.x, pos.y, target_pos.x, target_pos.y) <= combust_dst2) {
                        player_attack_entity(e, spell.value);
                    }
                }
            }
        }
        case SpellType_ModDropLevel: {
            Player.increase_drop_level = true;
        }
        case SpellType_ModLevelHealth: {
            for (e in entities_with(Entity.combat)) {
                Entity.combat[e].health += spell.value;

                // Negative mod can't bring health values below 1
                if (Entity.combat[e].health <= 0) {
                    Entity.combat[e].health = 1;
                }
            }
        }
        case SpellType_ModLevelAttack: {
            for (e in entities_with(Entity.combat)) {
                Entity.combat[e].attack += spell.value;

                // Negative mod can't bring attack values below 0
                if (Entity.combat[e].attack < 0) {
                    Entity.combat[e].attack = 0;
                }
            }
        }
        case SpellType_Invisibility: {
            Player.invisible = true;
        }
        case SpellType_EnergyShield: {
            if (Player.pure_absorb < spell.value) {
                Player.pure_absorb = spell.value;
            }
        }
        case SpellType_ModUseCharges: {
            if (Entity.use.exists(use_target)) {
                var can_add_charges = true;
                // Check that use doesn't contain copy or usecharges spells
                for (s in Entity.use[use_target].spells) {
                    if (s.type == SpellType_ModUseCharges || s.type == SpellType_CopyEntity) {
                        can_add_charges = false;
                        break;
                    }
                }
                if (can_add_charges) {
                    Entity.use[use_target].charges += spell.value;
                } else {
                    add_message('Can\'t add charges to this item.');
                }
            }
        }
        case SpellType_CopyEntity: {
            // Copy target must be an item and in inventory
            var pos = free_position_around_player();
            if (pos.x != -1 && pos.y != -1) {
                var copy = Entity.copy(use_target, pos.x, pos.y);
            } else {
                add_message('No space to drop copied item, it disappears into the Void.');
            }
        }
        case SpellType_Passify: {
            if (Entity.combat.exists(use_target)) {
                Entity.combat[use_target].aggression = AggressionType_Passive;
                add_message('You passify the enemy.');
            }
        }
        case SpellType_Sleep: {
            if (Entity.combat.exists(use_target)) {
                Entity.combat[use_target].aggression = AggressionType_NeutralToAggressive;
                Entity.move.remove(use_target);
                add_message('You put the enemy to sleep.');
            }
        }
        case SpellType_ImproveEquipment: {
            if (Entity.equipment.exists(use_target)) {
                for (s in Entity.equipment[use_target].spells) {
                    if (s.type == SpellType_ModAttack) {
                        s.value += spell.value;
                    } else if (s.type == SpellType_ModDefense) {
                        // NOTE: need to scale enchantment of defense to make it comparable to attack enchantment
                        s.value += spell.value * 4;
                    }
                }
                add_message('You improve equipment.');
            }
        }
        case SpellType_EnchantEquipment: {
            if (Entity.equipment.exists(use_target)) {
                var equipment = Entity.equipment[use_target];
                var spell = Spells.random_equipment_spell_equip(equipment.type);
                equipment.spells.push(spell);

                add_message('You enchant equipment.');
            }
        }
        case SpellType_SwapHealth: {
            if (Entity.combat.exists(use_target)) {
                var temp = Player.health;
                var combat = Entity.combat[use_target];
                Player.health = combat.health;
                if (Player.health > Player.health_max) {
                    Player.health = Player.health_max;
                }
                combat.health = temp;

                add_message('You swap yours and enemy health.');
            }
        }
        case SpellType_DamageShield: {
            if (spell.duration_type == SpellDuration_Permanent) {
                Player.damage_shield += spell.value;
            } else {
                Player.damage_shield_mod += spell.value;
            }

            if (spell.duration_type == SpellDuration_Permanent) {
                add_message('${spell.origin_name} increases your permanent damage shield by ${spell.value}.');
            }
        }
        case SpellType_SummonGolem: {
            var free_pos = free_position_around_player();

            if (free_pos.x != -1 && free_pos.y != -1) {
                Entities.golem(spell.value, free_pos.x, free_pos.y);
                add_message('You summon a golem, it smiles at you.');
            } else {
                add_message('No space to summon golem, spell fails!');
            }
        }
        case SpellType_SummonSkeletons: {
            var summon_count = 0;
            for (i in 0...3) {
                var free_pos = free_position_around_player();
                if (free_pos.x != -1 && free_pos.y != -1) {
                    Entities.skeleton(spell.value, free_pos.x, free_pos.y);
                    summon_count++;
                } else {
                    break;
                }
            }
            
            if (summon_count == 3) {
                add_message('You summon skeletons. Spooky!.');
            } else if (summon_count == 0) {
                add_message('No space to summon skeletons, spell fails!');
            } else {
                add_message('You summon skeletons but there was not enough space for all three.');
            }
        }
        case SpellType_SummonImp: {
            var free_pos = free_position_around_player();

            if (free_pos.x != -1 && free_pos.y != -1) {
                Entities.imp(spell.value, free_pos.x, free_pos.y);
                add_message('You summon a imp, it grins at you.');
            } else {
                add_message('No space to summon imp, spell fails!');
            }
        }
        case SpellType_ChainDamage: {
            // Jump starting from player and chain from mob to mob
            // Jump range is 2x2 diagonal
            // Don't chain to same mob twice
            function do_chain(source: Vec2i, enemies: Array<Int>, damage: Int) {
                var jump_e = Entity.NONE;
                for (e in enemies) {
                    if (Entity.position.exists(e) && Entity.combat.exists(e)) {
                        var pos = Entity.position[e];
                        var dst2 = Math.dst(pos.x, pos.y, source.x, source.y);

                        if (dst2 <= 8) {
                            jump_e = e;
                            break;
                        }
                    }
                }

                if (jump_e != Entity.NONE) {
                    // Remove jump target from enemies to not jump to same entity twice
                    enemies.remove(jump_e);

                    // NOTE: get entity position before attacking, because attack can kill entity
                    var jump_e_pos = Entity.position[jump_e];
                    var next_source: Vec2i = {x: jump_e_pos.x, y: jump_e_pos.y};
                    
                    player_attack_entity(jump_e, damage);
                    do_chain(next_source, enemies, damage * 2);
                }
            }

            do_chain({x: Player.x, y: Player.y}, entities_with(Entity.combat), spell.value);
        }
        case SpellType_ModCopper: {
            Player.copper_count += spell.value;
            copper_gained_this_floor += spell.value;
            if (Player.copper_count < 0) {
                Player.copper_count = 0;
            }
        }
        case SpellType_ModSpellDamage: {
            Player.spell_damage_mod += spell.value;
        }
        case SpellType_ModAttackByCopper: {
            Player.attack_mod += Math.ceil(Math.sqrt(Player.copper_count / 10));
        }
        case SpellType_ModDefenseByCopper: {
            Player.defense_mod += 5 * Math.ceil(Math.sqrt(Player.copper_count / 10));
        }
    }
}

function can_use_entity_on_target(e: Int): Bool {
    if (Entity.use.exists(use_entity_that_needs_target)) {
        return Spells.spell_can_be_used_on_target(Entity.use[use_entity_that_needs_target].spells[0].type, e);
    } else {
        return false;
    }
}

function print_game_stats() {
    var total_string = '\n\nGAME STATS:';
    for (i in 0...game_stats.length) {
        total_string += game_stats[i];

        if (i + 1 <= copper_gains.length - 1) {
            total_string += '\ncopper_gained=${copper_gains[i + 1]}\n\n';
        }
    }
    trace(total_string);
}

function render_world() {
    var view_x = get_view_x();
    var view_y = get_view_y();

    // Tiles
    Gfx.scale(1);
    Gfx.drawtoimage('tiles_canvas');
    for (x in 0...VIEW_WIDTH) {
        for (y in 0...VIEW_HEIGHT) {
            var map_x = view_x + x;
            var map_y = view_y + y;

            var new_tile = Tile.None;
            if (out_of_map_bounds(map_x, map_y) || walls[map_x][map_y]) {
                new_tile = Tile.Black;
            } else {
                if (position_visible(x, y)) {
                    new_tile = tiles[map_x][map_y];
                } else {
                    // NOTE: dark version of tiles is to the right on the tilesheet, hence the (+ 1)
                    new_tile = tiles[map_x][map_y] + 1;
                }
            }

            if (new_tile != tiles_render_cache[x][y]) {
                Gfx.drawtile(unscaled_screen_x(map_x), unscaled_screen_y(map_y), new_tile);
                tiles_render_cache[x][y] = new_tile;
            }
        }
    }
    Gfx.drawtoscreen();

    Gfx.clearscreen(Col.BLACK);
    Gfx.scale(WORLD_SCALE);
    Gfx.drawimage(0, 0, "tiles_canvas");

    // Entities
    Text.change_size(DRAW_CHAR_TEXT_SIZE);
    for (e in entities_with(Entity.position)) {
        var pos = Entity.position[e];
        if (!out_of_view_bounds(pos.x, pos.y) && position_visible(pos.x - view_x, pos.y - view_y)) {
            draw_entity(e, screen_x(pos.x), screen_y(pos.y));
        }
    }

    // Player, draw as parts of each equipment
    for (equipment_type in Type.allEnums(EquipmentType)) {
        var e = Player.equipment[equipment_type];

        // Check that equipment exists, is equipped and has a draw tile
        // Otherwise draw default equipment(naked)
        var equipment_tile = if (Entity.equipment.exists(e) && !Entity.position.exists(e) && Entity.draw_tile.exists(e)) {
            Entity.draw_tile[e];
        } else {
            switch (equipment_type) {
                case EquipmentType_Weapon: Tile.None;
                case EquipmentType_Head: Tile.Head[0];
                case EquipmentType_Chest: Tile.Chest[0];
                case EquipmentType_Legs: Tile.Legs[0];
            }
        }

        var x_offset = if (equipment_type == EquipmentType_Weapon) {
            // Draw sword a bit to the side
            0.3 * TILESIZE * WORLD_SCALE;
        } else {
            0;
        }

        var y_offset = switch (equipment_type) {
            case EquipmentType_Head: -2 * WORLD_SCALE;
            case EquipmentType_Legs: 3 * WORLD_SCALE;
            default: 0;
        }

        if (equipment_tile != Tile.None) {
            Gfx.drawtile(screen_x(Player.x) + x_offset, screen_y(Player.y) + y_offset, equipment_tile); 
        }
    }

    // Health above player
    Gfx.scale(1);
    Text.change_size(PLAYER_HP_HUD_TEXT_SIZE);
    Text.display(screen_x(Player.x), screen_y(Player.y) - 10, '${Player.health}/${Player.health_max + Player.health_max_mod}');

    // Damage numbers
    var removed_damage_numbers = new Array<DamageNumber>();
    for (n in damage_numbers) {
        Text.display(screen_x(Player.x) + n.x_offset, screen_y(Player.y) - n.time / 5, '${n.value}', n.color);

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
    Gfx.scale(1);
    Text.change_size(UI_TEXT_SIZE);

    //
    // Player stats
    //
    var player_stats_right_text = "";
    player_stats_right_text += '\n${Player.health}/${Player.health_max + Player.health_max_mod}';
    player_stats_right_text += '\n${Player.attack + Player.attack_mod}';
    player_stats_right_text += '\n${Player.defense + Player.defense_mod}';
    player_stats_right_text += '\n${Player.pure_absorb}';
    player_stats_right_text += '\n${Player.copper_count}';
    Text.display(UI_X + PLAYER_STATS_NUMBERS_OFFSET, PLAYER_STATS_Y, player_stats_right_text);

    Gfx.scale(1);
    Gfx.drawimage(UI_X, 0, 'ui_canvas');

    function draw_entity_selective(e: Int, x: Float, y: Float, current_data: EntityRenderData, new_data: EntityRenderData) {
        var entity_changed = ((current_data == null && new_data != null) 
            || (current_data != null && new_data != null && !render_data_equals(new_data, current_data)));
        var entity_removed = current_data != null && new_data == null;

        if (entity_changed || entity_removed) {
            // Erase area
            var box_pad = 1;
            Gfx.fillbox(x + box_pad, y + box_pad, TILESIZE * WORLD_SCALE- box_pad * 2, TILESIZE * WORLD_SCALE - box_pad * 2, Col.BLACK);
        }

        if (entity_changed) {
            draw_entity(e, x, y, new_data);
        }
    }

    //
    // Equipment and Inventory
    //
    Gfx.scale(WORLD_SCALE);
    Gfx.drawtoimage('ui_items_canvas');
    
    // Equipment
    var armor_i = 0;
    for (equipment_type in Type.allEnums(EquipmentType)) {
        var e = Player.equipment[equipment_type];

        var draw_x = armor_i * TILESIZE * WORLD_SCALE;
        var draw_y = EQUIPMENT_Y;

        var current_data = equipment_render_cache[equipment_type];
        
        var new_data = if (Entity.equipment.exists(e) && !Entity.position.exists(e)) {
            get_entity_render_data(e);
        } else {
            null;
        }

        draw_entity_selective(e, draw_x, draw_y, current_data, new_data);

        equipment_render_cache[equipment_type] = new_data;

        armor_i++;
    }

    // Inventory
    for (x in 0...INVENTORY_WIDTH) {
        for (y in 0...INVENTORY_HEIGHT) {
            var e = Player.inventory[x][y];

            var draw_x = x * TILESIZE * WORLD_SCALE;
            var draw_y = INVENTORY_Y + y * TILESIZE * WORLD_SCALE;

            var current_data = inventory_render_cache[x][y];
            
            var new_data = if (Entity.item.exists(e) && !Entity.position.exists(e)) {
                get_entity_render_data(e);
            } else {
                null;
            }

            draw_entity_selective(e, draw_x, draw_y, current_data, new_data);

            inventory_render_cache[x][y] = new_data;
        }
    }
    Gfx.drawtoscreen();
    Gfx.scale(1);
    Gfx.drawimage(UI_X, 0, 'ui_items_canvas');

    //
    // Active spells list
    //
    Gfx.scale(1);
    Text.change_size(UI_TEXT_SIZE);
    var active_spells = 'SPELLS';
    for (s in Player.spells) {
        active_spells += '\n' + Spells.get_description(s);
    }
    Text.wordwrap = UI_WORDWRAP;
    Text.display(UI_X, SPELL_LIST_Y, active_spells);

    // Use targeting icon
    if (targeting_for_use) {
        Text.display(Mouse.x, Mouse.y, 'LEFT CLICK TARGET');
    }

    //
    // Messages
    //

    // Remove old messages 
    while (messages.length > MESSAGES_LENGTH_MAX) {
        messages.pop();
    }
    
    Text.wordwrap = UI_WORDWRAP;
    if (need_to_update_messages_canvas) {
        need_to_update_messages_canvas = false;
        Gfx.drawtoimage('messages_canvas');
        Gfx.clearscreen();
        var messages_text = "";
        for (message in messages) {
            messages_text = message + '\n' + messages_text;
        }
        Text.display(0, 0, messages_text);
        Gfx.drawtoscreen();
    }
    Gfx.drawimage(UI_X, MESSAGES_Y + 50, 'messages_canvas');

    //
    // Minimap
    //
    
    // Update seen status for entities drawn on minimap
    for (e in entities_with(Entity.draw_on_minimap)) {
        var draw_on_minimap = Entity.draw_on_minimap[e];

        if (!draw_on_minimap.seen && Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (!out_of_view_bounds(pos.x, pos.y) && position_visible(pos.x - view_x, pos.y - view_y)) {
                draw_on_minimap.seen = true;
            }
        }
    }

    // Draw rooms

    // Draw connections first, then rooms
    // Draw rooms filled in to cover up intersecting connections
    Gfx.drawtoimage('minimap_canvas_connections');
    for (i in 0...rooms.length) {
        var r = rooms[i];
        if (visited_room[i] && r.is_connection && !room_on_minimap[i]) {
            room_on_minimap[i] = true;
            Gfx.fillbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.BLACK);
            Gfx.drawbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.WHITE);
        }
    }
    Gfx.drawtoimage('minimap_canvas_rooms');
    for (i in 0...rooms.length) {
        var r = rooms[i];
        if (visited_room[i] && !r.is_connection && !room_on_minimap[i]) {
            room_on_minimap[i] = true;
            Gfx.fillbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.BLACK);
            Gfx.drawbox(MINIMAP_X + r.x * MINIMAP_SCALE, MINIMAP_Y + r.y * MINIMAP_SCALE, (r.width) * MINIMAP_SCALE, (r.height) * MINIMAP_SCALE, Col.WHITE);
        }
    }
    Gfx.drawtoscreen();

    if (Player.full_minimap || DEV_full_minimap) {
        Gfx.drawimage(0, 0, 'minimap_canvas_full');
    } else {
        Gfx.drawimage(0, 0, 'minimap_canvas_connections');
        Gfx.drawimage(0, 0, 'minimap_canvas_rooms');
    }
    

    // Draw seen things
    for (e in entities_with(Entity.draw_on_minimap)) {
        var draw_on_minimap = Entity.draw_on_minimap[e];

        if ((draw_on_minimap.seen || Player.show_things || DEV_full_minimap) && Entity.position.exists(e)) {
            var pos = Entity.position[e];
            Gfx.fillbox(MINIMAP_X + pos.x * MINIMAP_SCALE, MINIMAP_Y + pos.y * MINIMAP_SCALE, MINIMAP_SCALE * 1.5, MINIMAP_SCALE * 1.5, draw_on_minimap.color);
        }
    }

    // Draw player
    Gfx.fillbox(MINIMAP_X + Player.x * MINIMAP_SCALE, MINIMAP_Y + Player.y * MINIMAP_SCALE, MINIMAP_SCALE, MINIMAP_SCALE, Col.RED);

    Text.change_size(UI_TEXT_SIZE);
    var meta = openfl.Lib.current.stage.application.meta;
    var version = meta['version'];
    Text.display(0, SCREEN_HEIGHT - Text.height() * 2, '${version}');
}

var move_timer = 0;
var move_timer_max = 5;

function update_normal() {
    var update_start = Timer.stamp();

    var turn_ended = false;

    // Space key skips turn
    if (Input.justpressed(Key.SPACE)) {
        turn_ended = true;
    }

    // 
    // Player movement
    //
    var player_dx = 0;
    var player_dy = 0;
    var up = Input.pressed(Key.W);
    var down = Input.pressed(Key.S);
    var left = Input.pressed(Key.A);
    var right = Input.pressed(Key.D);

    if (!up && !down && !left && !right) {
        move_timer = 0;
    } else {
        if (move_timer >= 5) {
            move_timer = 0;
        }

        if (move_timer == 0) {
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
        }
        
        move_timer++;
    }

    if (player_dx != 0) {
        // If movespeed is increased, try moving extra times in same direction
        var move_amount = 1 + Player.movespeed_mod;

        for (i in 0...move_amount) {
            if (!out_of_map_bounds(Player.x + player_dx, Player.y + 0)) {
                var free_map = get_free_map(Player.x + player_dx, Player.y + 0, 1, 1);

                var noclipping_through_wall = walls[Player.x + player_dx][Player.y + 0] && (Player.noclip || DEV_noclip);

                if (free_map[0][0] || noclipping_through_wall) {
                    Player.x += player_dx;
                    Player.y += 0;
                    turn_ended = true;
                }
            }
        }
    }

    if (player_dy != 0) {
        // If movespeed is increased, try moving extra times in same direction
        var move_amount = 1 + Player.movespeed_mod;

        for (i in 0...move_amount) {
            if (!out_of_map_bounds(Player.x + 0, Player.y + player_dy)) {
                var free_map = get_free_map(Player.x + 0, Player.y + player_dy, 1, 1);

                var noclipping_through_wall = walls[Player.x + 0][Player.y + player_dy] && (Player.noclip || DEV_noclip);

                if (free_map[0][0] || noclipping_through_wall) {
                    Player.x += 0;
                    Player.y += player_dy;
                    turn_ended = true;
                }
            }
        }
    }

    var view_x = get_view_x();
    var view_y = get_view_y();

    // Update LOS after movement
    if (Player.x != Player.x_old || Player.y != Player.y_old) {
        LOS.update_los(los);
    }

    //
    // Find entity under mouse
    //
    var mouse_map_x = Math.floor(Mouse.x / WORLD_SCALE / TILESIZE + Player.x - Math.floor(VIEW_WIDTH / 2));
    var mouse_map_y = Math.floor(Mouse.y / WORLD_SCALE / TILESIZE + Player.y - Math.floor(VIEW_HEIGHT / 2));

    // Check for entities on map
    var hovered_map = Entity.NONE;
    if (!out_of_view_bounds(mouse_map_x, mouse_map_y) && !out_of_map_bounds(mouse_map_x, mouse_map_y)) {
        hovered_map = Entity.position_map[mouse_map_x][mouse_map_y];
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
        var mouse_inventory_x = Math.floor((Mouse.x - UI_X) / WORLD_SCALE / TILESIZE);
        var mouse_INVENTORY_Y = Math.floor((Mouse.y - INVENTORY_Y) / WORLD_SCALE / TILESIZE);
        var mouse_equip_x = Math.floor((Mouse.x - UI_X) / WORLD_SCALE / TILESIZE);
        var mouse_equip_y = Math.floor((Mouse.y - EQUIPMENT_Y) / WORLD_SCALE / TILESIZE);

        function hovering_inventory(x, y) {
            return x >= 0 && y >= 0 && x < INVENTORY_WIDTH && y < INVENTORY_HEIGHT;
        }
        function hovering_equipment(x, y) {
            return y == 0 && x >= 0 && x < EQUIPMENT_COUNT;
        }

        if (hovering_inventory(mouse_inventory_x, mouse_INVENTORY_Y)) {
            hovered_anywhere = Player.inventory[mouse_inventory_x][mouse_INVENTORY_Y];
            hovered_anywhere_x = UI_X + mouse_inventory_x * TILESIZE * WORLD_SCALE;
            hovered_anywhere_y = INVENTORY_Y + mouse_INVENTORY_Y * TILESIZE * WORLD_SCALE;
        } else if (hovering_equipment(mouse_equip_x, mouse_equip_y)) {
            hovered_anywhere = Player.equipment[Type.allEnums(EquipmentType)[mouse_equip_x]];
            hovered_anywhere_x = UI_X + mouse_equip_x * TILESIZE * WORLD_SCALE;
            hovered_anywhere_y = EQUIPMENT_Y;
        }
    }

    render_world();

    //
    // Hovered entity tooltip
    //
    Text.wordwrap = TOOLTIP_WORDWRAP;
    function get_tooltip(e: Int): String {
        var tooltip = "";
        if (Entity.name.exists(e)) {
            // tooltip += 'Id: ${e}';
            tooltip += '${Entity.name[e]}\n';
        }
        if (Entity.combat.exists(e)) {
            var entity_combat = Entity.combat[e];
            tooltip += '\nHealth: ${entity_combat.health}';
            tooltip += '\nAttack: ${entity_combat.attack}';
            // actual numbers drawn later, because they need to be colored
        }
        if (Entity.description.exists(e)) {
            // tooltip += '\n${Entity.description[e]}';
        }
        if (Entity.equipment.exists(e)) {
            var equipment = Entity.equipment[e];
            if (equipment.spells.length > 0) {
                tooltip += '\n';
                for (s in equipment.spells) {
                    tooltip += '\n' + Spells.get_description(s);
                }
            }
        }
        if (Entity.item.exists(e) && Entity.item[e].spells.length > 0) {
            var item = Entity.item[e];
            for (s in item.spells) {
                tooltip += '\n' + Spells.get_description(s);
            }
        }
        if (Entity.use.exists(e)) {
            var use = Entity.use[e];
            tooltip += '\nUse';
            if (use.consumable) {
                tooltip += ' (consumable)';
            }
            for (s in use.spells) {
                tooltip += '\n' + Spells.get_description(s);
            }
        }
        
        if (Entity.cost.exists(e)) {
            tooltip += '\nCost: ${Entity.cost[e]} copper.';
        }
        return tooltip;
    }

    // Only show tooltip if interact menu isn't open
    if (interact_target == Entity.NONE) {
        var entity_tooltip = get_tooltip(hovered_anywhere);

        if (entity_tooltip != "" && !Entity.combat.exists(hovered_anywhere)) {
            // if (!Entity.position.exists(hovered_anywhere)) {
                Gfx.fillbox(hovered_anywhere_x + TILESIZE * WORLD_SCALE, hovered_anywhere_y, Text.width(entity_tooltip) + 10, Text.height(entity_tooltip), Col.DARKBROWN);
            // }
            Text.display(hovered_anywhere_x + TILESIZE * WORLD_SCALE, hovered_anywhere_y, entity_tooltip, Col.WHITE);
        }
    }
    

    //
    // Interact menu
    //

    // Set interact target on right click
    if (!turn_ended && Mouse.rightclick()) {
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
    // Can't use/pick up/equip if item has Buy, which means it's "in a shop"
    if (!turn_ended) {
        var done_interaction = false;
        GUI.x = interact_target_x + TILESIZE * WORLD_SCALE;
        GUI.y = interact_target_y;
        if (Entity.talk.exists(interact_target)) {
            if (GUI.auto_text_button('Talk')) {
                add_message(Entity.talk[interact_target]);
                done_interaction = true;
            }
        }
        if (Entity.use.exists(interact_target) && !Entity.cost.exists(interact_target)) {
            if (GUI.auto_text_button('Use')) {
                if (Entity.use[interact_target].need_target) {
                    use_entity_that_needs_target = interact_target;
                    start_targeting = true;
                    done_interaction = true;
                } else {
                    use_entity(interact_target);
                    done_interaction = true;
                }
            }
        }
        if (Entity.equipment.exists(interact_target) && !Entity.cost.exists(interact_target)) {
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
        if (Entity.item.exists(interact_target) && !Entity.cost.exists(interact_target)) {
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
        if (Entity.cost.exists(interact_target)) {
            var cost = Entity.cost[interact_target];
            if (GUI.auto_text_button('Buy for ${cost}')) {
                try_buy_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.container.exists(interact_target)) {
            if (GUI.auto_text_button('Open')) {
                try_open_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.combat.exists(interact_target)) {
            if (GUI.auto_text_button('Attack')) {
                attack_target = hovered_map;
                done_interaction = true;
            }
        }

        if (done_interaction) {
            interact_target = Entity.NONE;
            turn_ended = true;
        } else if (Mouse.leftclick()) {
            // Clicked out of context menu
            interact_target = Entity.NONE;
        }
    }

    //
    // Left click action
    //
    // Target entity for use, can't target the use entity itself
    // Check that target is appropriate for spell
    if (targeting_for_use && !turn_ended && Mouse.leftclick() && hovered_anywhere != use_entity_that_needs_target) {
        if (can_use_entity_on_target(hovered_anywhere)) {
            use_target = hovered_anywhere;
            turn_ended = true;
        }
    }

    //
    // Default left-click actions
    //
    // Attack, pick up or equip, if only one is possible, if multiple are possible, then must pick one through interact menu
    if (!turn_ended && Mouse.leftclick()) {
        if (Entity.position.exists(hovered_anywhere)) {
            var pos = Entity.position[hovered_anywhere];
            // Left-click interaction if entity is on map and is visible
            if (player_next_to(Entity.position[hovered_anywhere]) && !los[pos.x - view_x][pos.y - view_y]) {
                var can_attack = Entity.combat.exists(hovered_anywhere);
                var can_pickup = Entity.item.exists(hovered_anywhere) && !Entity.cost.exists(hovered_anywhere);
                var can_equip = Entity.equipment.exists(hovered_anywhere) && !Entity.cost.exists(hovered_anywhere);
                var can_use = Entity.use.exists(hovered_anywhere);
                var can_open = Entity.container.exists(hovered_anywhere);

                if (can_attack && !can_pickup && !can_equip) {
                    attack_target = hovered_anywhere;
                    turn_ended = true;
                } else if (!can_attack && can_pickup && !can_equip) {
                    move_entity_into_inventory(hovered_anywhere);
                    turn_ended = true;
                } else if (!can_attack && !can_pickup && can_equip) {
                    equip_entity(hovered_anywhere);
                    turn_ended = true;
                } else if (can_use && !can_pickup && !can_equip && !can_attack) {
                    use_entity(hovered_anywhere);
                    turn_ended = true;
                } else if (can_open) {
                    try_open_entity(hovered_anywhere);
                    turn_ended = true;
                } 
            }
        } else {
            // Left-click interaction if entity is equipped or in inventory
            var can_use = Entity.use.exists(hovered_anywhere);

            if (can_use && !targeting_for_use) {
                if (Entity.use[hovered_anywhere].need_target) {
                    use_entity_that_needs_target = hovered_anywhere;
                    start_targeting = true;
                    turn_ended = true;
                } else {
                    use_entity(hovered_anywhere);
                    turn_ended = true;
                }
            }
        }
    }

    //
    // Developer options
    //
    GUI.x = UI_X - 250;
    GUI.y = 0;
    if (SHOW_SHOW_BUTTONS_BUTTON) {
        if (GUI.auto_text_button('Toggle dev (POI)')) {
            DEV_show_buttons = !DEV_show_buttons;
        }
    }
    if (DEV_show_buttons) {
        if (GUI.auto_text_button('Hide buttons')) {
            DEV_show_buttons = false;
        }
        if (GUI.auto_text_button('Restart')) {
            restart_game();
            generate_level();
        }
        if (GUI.auto_text_button('To first room')) {
            Player.x = rooms[0].x;
            Player.y = rooms[0].y;
            turn_ended = true;
        }
        if (GUI.auto_text_button('Toggle full map')) {
            DEV_full_minimap = !DEV_full_minimap;
        }
        if (GUI.auto_text_button('Toggle noclip')) {
            DEV_noclip = !DEV_noclip;
        }
        if (GUI.auto_text_button('Toggle los')) {
            DEV_nolos = !DEV_nolos;
        }
        if (GUI.auto_text_button('Toggle frametime graph (F)')) {
            DEV_frametime_graph = !DEV_frametime_graph;
        }
        if (GUI.auto_text_button('Toggle nodeath')) {
            DEV_nodeath = !DEV_nodeath;
        }
        if (GUI.auto_text_button('Next floor')) {
            if (increment_level) {
                current_level++;
            }
            increment_level = !increment_level;
            current_floor++;

            generate_level();
        }
        if (GUI.auto_text_button('Print game stats (G)')) {
            print_game_stats();
        }
    }

    //
    // End of turn
    //
    if (turn_ended) {
        // Clear interact target if done something
        interact_target = Entity.NONE;

        // First turn after the start of use targeting, the flag is set, afterwards, targeting is unset and the mode is exited
        if (start_targeting) {
            start_targeting = false;
            targeting_for_use = true;
        } else {
            targeting_for_use = false;
        }
        // Perform targeted use if the target is an item in inventory
        // NOTE: use target is cleared after spells are done
        if (can_use_entity_on_target(use_target)) {
            use_entity(use_entity_that_needs_target);
        }

        // Recalculate player room if room changed
        if (Player.room != -1) {
            var old_room = rooms[Player.room];
            if (!Math.point_box_intersect(Player.x, Player.y, old_room.x, old_room.y, old_room.width, old_room.height)) {
                Player.room = get_room_index(Player.x, Player.y);
            }

            // Mark current room and adjacent rooms as visited
            if (Player.room != -1) {
                visited_room[Player.room] = true;
                for (i in rooms[Player.room].adjacent_rooms) {
                    visited_room[i] = true;
                }
            }
        } else {
            Player.room = get_room_index(Player.x, Player.y);
        }

        // Clear temporary spell effects
        Player.health_max_mod = 0;
        Player.attack_mod = 0;
        Player.defense_mod = 0;
        Player.damage_shield_mod = 0;
        Player.nolos = false;
        Player.noclip = false;
        Player.show_things = false;
        Player.health_leech = false;
        Player.movespeed_mod = 0;
        Player.dropchance_mod = 0;
        Player.copper_drop_mod = 0;
        Player.spell_damage_mod = 0;
        Player.increase_drop_level = false;
        Player.invisible = false;
        Player.full_minimap = false;

        //
        // Process spells
        //
        spells_this_turn = [for (i in 0...(Spells.last_prio + 1)) new Array<Spell>()];

        function process_spell(spell: Spell): Bool {
            var spell_over = false;
            var active = false;

            function decrement_duration() {
                // Spell is active every interval, until duration reaches zero
                spell.interval_current++;
                if (spell.interval_current >= spell.interval) {
                    spell.interval_current = 0;
                    active = true;

                    if (spell.duration != Entity.DURATION_INFINITE && spell.duration != Entity.DURATION_LEVEL) {
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
                if (Spells.prios.exists(spell.type)) {
                    var prio = Spells.prios[spell.type];
                    spells_this_turn[prio].push(spell);

                    // DR on random teleports with interval(teleport room)
                    if (spell.type == SpellType_RandomTeleport && spell.interval > 0) {
                        spell.interval *= 4;
                    }
                } else {
                    trace('no prio defined for ${spell.type}');
                }
            }

            return spell_over;
        }

        function process_spell_list(list: Array<Spell>, remove_from_list: Bool = false) {
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
                if (remove_from_list) {
                    list.remove(spell);
                }
            }
        }

        // Inventory spells
        for (x in 0...INVENTORY_WIDTH) {
            for (y in 0...INVENTORY_HEIGHT) {
                var e = Player.inventory[x][y];

                if (Entity.item.exists(e) && !Entity.position.exists(e) && Entity.item[e].spells.length > 0) {
                    process_spell_list(Entity.item[e].spells);
                }
            }
        }

        // Equipment spells
        for (equipment_type in Type.allEnums(EquipmentType)) {
            var e = Player.equipment[equipment_type];

            if (Entity.equipment.exists(e) && !Entity.position.exists(e) && Entity.equipment[e].spells.length > 0) {
                process_spell_list(Entity.equipment[e].spells);
            }
        }

        // Player spells
        process_spell_list(Player.spells, true);

        // Location spells
        process_spell_list(location_spells[Player.x][Player.y]);

        // Do spells in order of their priority, first 0th prio spells, then 1st, etc...
        for (i in 0...(Spells.last_prio + 1)) {
            for (spell in spells_this_turn[i]) {
                do_spell(spell);
            }
        }

        // Clear use target after spells are done
        use_target = Entity.NONE;

        // Limit health to health_max
        if (Player.health > Player.health_max + Player.health_max_mod) {
            Player.health = Player.health_max + Player.health_max_mod;
        }

        // Player attacks entity
        if (attack_target != Entity.NONE) {
            player_attack_entity(attack_target, Player.attack + Player.attack_mod, false);
            attack_target = Entity.NONE;
        }

        var entities_that_attacked_player = new Array<Int>();

        // Entities attack player
        for (e in entities_with(Entity.combat)) {
            var attacked_player = entity_attack(e);

            if (attacked_player) {
                entities_that_attacked_player.push(e);
            }
        }

        // Deal player shield damage to entities that attacked player
        var player_damage_shield_total = Player.damage_shield + Player.damage_shield_mod;
        if (player_damage_shield_total > 0) {
            for (e in entities_that_attacked_player) {
                player_attack_entity(e, player_damage_shield_total);
            }
        }

        // Move player to nearest room if noclip ends while player is still inside a wall
        if (walls[Player.x][Player.y] && !(Player.noclip || DEV_noclip)) {
            var closest_room: Room = null;
            var closest_dst2 = 100000000.0;
            for (r in rooms) {
                var dst2 = Math.dst2(Player.x, Player.y, r.x, r.y);

                if (dst2 < closest_dst2) {
                    closest_dst2 = dst2;
                    closest_room = r;
                }
            }

            var pos = GenerateWorld.room_free_positions_shuffled(closest_room)[0];

            // NOTE: position could have no path to stairs, if player blocks the path with items, won't handle this because player has to try really hard to screw this up
            Player.x = pos.x;
            Player.y = pos.y;
            Player.room = get_room_index(Player.x, Player.y);
        }

        // NOTE: can die from entity attacks or spells
        if (Player.health <= 0) {
            add_message('You died.');
        }

        for (e in entities_with(Entity.move)) {
            if (Entity.position.exists(e)) {
                move_entity(e);
            }
        }

        // Mark the end of turn
        if (added_message_this_turn) {
            add_message(TURN_DELIMITER);
            added_message_this_turn = false;
        }

        // DEAD indicator
        if (Player.health <= 0 && !DEV_nodeath) {
            add_message('You died.');
            game_state = GameState_Dead;
        }
    }

    // Print entity for debugging
    if (Input.justpressed(Key.U)) {
        Entity.print(hovered_anywhere);
    }

    //
    // Frametime graph
    //

    if (Input.justpressed(Key.F)) {
        DEV_frametime_graph = !DEV_frametime_graph;
    }

    if (DEV_frametime_graph) {
        var frame_time = Timer.stamp() - update_start;

        Gfx.drawtoimage('frametime_canvas2');
        Gfx.drawimage(-1, 0, 'frametime_canvas');
        Gfx.drawtoimage('frametime_canvas');
        Gfx.drawimage(0, 0, 'frametime_canvas2');
        Gfx.fillbox(99, 0, 1, 50, Col.DARKBLUE);

        var blip_color = if (turn_ended) {
            Col.RED;
        } else {
            Col.ORANGE;
        }
        Gfx.fillbox(99, 50 * (1 - frame_time / (1 / 30.0)), 1, 1, blip_color);
        Gfx.drawtoscreen();

        Gfx.drawimage(400, 100, 'frametime_canvas');

        Text.change_size(CHARGES_TEXT_SIZE);
        Text.display(400 + 100, 100 - Text.height(), '33.3ms');
        Text.display(400 + 100, 100 + 25 - Text.height(), '16.6ms');
        Text.display(400 + 100, 100 + 50 - Text.height(), '0ms');
        Text.display(400 + 100, 100 + 75 - Text.height(), 'Press F to hide');

    }

    if (Input.justpressed(Key.G)) {
        print_game_stats();
    }

    Player.x_old = Player.x;
    Player.y_old = Player.y;
}

var can_restart_timer = 0;
static inline var can_restart_timer_max = 60;

function update_dead() {
    render_world();

    var fade_alpha = 0.75 * Math.min(1.0, (can_restart_timer / can_restart_timer_max));
    Gfx.fillbox(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, Col.BLACK, fade_alpha);

    Text.change_size(100);

    can_restart_timer++;
    if (can_restart_timer > can_restart_timer_max) {
        Text.change_size(50);
        Text.display(100, 300, 'DEAD', Col.RED);
        Text.display(100, 400, 'Press SPACE to continue', Col.RED);

        if (Input.pressed(Key.SPACE)) {
            can_restart_timer = 0;

            game_state = GameState_Normal;
            restart_game();
            generate_level();
        }
    }
}

function update() {
    switch (game_state) {
        case GameState_Normal: update_normal();
        case GameState_Dead: update_dead();
    }

    if (Input.pressed(Key.P) && Input.pressed(Key.O) && Input.pressed(Key.I)) {
        DEV_show_buttons = true;
    }
}

}
