
import haxegon.*;
import Entity;
import Entities;
import Spells;

using haxegon.MathExtensions;

typedef PreRoom = {
    x: Float,
    y: Float,
    width: Float, 
    height: Float
}

typedef Room = {
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    is_connection: Bool,
    adjacent_rooms: Array<Int>,
    is_locked: Bool,
    is_horizontal: Bool,
}

typedef Connection = {
    x1: Int,
    y1: Int,
    x2: Int,
    y2: Int,
    i: Int,
    j: Int
}

typedef Spawn = {
    fun: Dynamic,
    chance: Float
};

@:publicFields
class GenerateWorld {
// force unindent

static inline var ORIGIN_X = 1;
static inline var ORIGIN_Y = 1;
static inline var ROOM_SPACING = 3;
static inline var DIG_TRIES = 300;
static inline var ROOMS_MAX = 15;
static inline var ROOM_SIZE_MIN = 5;
static inline var ROOM_SIZE_MAX = 15;

static inline var ITEM_ROOM_ENTITY_AMOUNT = 2;
static inline var MERCHANT_ITEM_AMOUNT = 3;
static inline var ROOM_SPELL_CHANCE = 3;
static inline var ROOM_SPELL_SPREADS_TO_NEIGHBORS_CHANCE = 50;

static inline var ENEMY_TYPES_PER_LEVEL_MIN = 2;
static inline var ENEMY_TYPES_PER_LEVEL_MAX = 5;

static inline var KEY_ON_ENEMY_CHANCE = 50;
static inline var MERCHANT_ITEM_LEVEL_BONUS = 2;

static inline var ENEMY_ITEM_IDEAL_RATIO = 0.5;
// static function ENEMY_ITEM_RATIO_MARGIN(): Float { return Random.float(0.75, 1.25); };
static function ENEMY_ITEM_RATIO_MARGIN(): Float { return 1.0; };

static var enemy_rooms_this_floor = 0;
static var item_rooms_this_floor = 0;
static var enemies_this_floor = 0;
static var items_this_floor = 0;

static var floors_until_floor_with_merchant = Random.int(0, 2);

static function room_free_positions_shuffled(r: Room): Array<Vec2i> {
    // Exclude positions next to walls to avoid creating impassable cells
    var free_map = Main.get_free_map(r.x, r.y, r.x + r.width, r.y + r.height);
    var positions = new Array<Vec2i>();
    for (x in (r.x + 1)...(r.x + r.width - 1)) {
        for (y in (r.y + 1)...(r.y + r.height - 1)) {
            if (free_map[x - r.x][y - r.y]) {
                positions.push({
                    x: x,
                    y: y,
                });
            }
        }
    }
    Random.shuffle(positions);
    return positions;
}

// Odd only positions to avoid creating impassable formations
static function room_free_ODD_positions_shuffled(r: Room): Array<Vec2i> {
    var positions = room_free_positions_shuffled(r);
    var even_positions = new Array<Vec2i>();
    for (pos in positions) {
        if (pos.x % 2 == 0 || pos.y % 2 == 0) {
            even_positions.push(pos);
        }        
    }
    for (pos in even_positions) {
        positions.remove(pos);
    }
    return positions;
}

static function fill_rooms_with_entities() {
    // Reset first chars for new level
    Entities.generated_first_chars = new Array<String>();

    // Generate enemy types for level
    var enemy_types_per_level = Random.int(ENEMY_TYPES_PER_LEVEL_MIN, ENEMY_TYPES_PER_LEVEL_MAX);
    var enemy_types = [for (i in 0...enemy_types_per_level) Entities.random_enemy_type()];

    function random_enemy(x: Int, y: Int): Int {
        return Random.pick(enemy_types)(x, y);
    }

    var spawned_merchant = false;

    var room_is_empty = [for (i in 0...Main.rooms.length) false];

    var do_spawn_merchant = false;
    floors_until_floor_with_merchant--;
    if (floors_until_floor_with_merchant <= 0) {
        floors_until_floor_with_merchant = Random.int(2, 3);
        do_spawn_merchant = true;
    }

    function health_potion(x: Int, y: Int): Int {
        return Entities.random_potion(x, y, SpellType_ModHealth);
    }

    function health_max_potion(x: Int, y: Int): Int {
        return Entities.random_potion(x, y, SpellType_ModHealthMax);
    }

    enemy_rooms_this_floor = 0;
    item_rooms_this_floor = 0;

    var enemies = new Array<Int>();
    var items = new Array<Int>();

    // NOTE: leave start room(0th) empty
    for (i in 1...Main.rooms.length) {
        var r = Main.rooms[i];

        // Don't generate entities in connections
        if (r.is_connection) {
            continue;
        }

        var positions = room_free_ODD_positions_shuffled(r);

        function empty_room() {
            room_is_empty[i] = true;
        }

        function enemy_room() {
            // Enemy/item room with possible location spells
            var amount = Stats.get({min: 1, max: 2, scaling: 1.0}, Main.current_level());
            for (i in 0...amount) {
                if (positions.length == 0) {
                    break;
                }
                var pos = positions.pop();
                var e = Random.pick_chance([
                    {v: random_enemy, c: 90.0},
                    {v: Entities.unlocked_chest, c: 12.0},
                    {v: health_potion, c: 3.0},
                    {v: Entities.random_potion, c: 3.0},
                    {v: Entities.random_armor, c: 3.0},
                    {v: Entities.random_scroll, c: 4.0},
                    {v: Entities.random_orb, c: 1.5},
                    {v: Entities.random_weapon, c: 0.5},
                    {v: Entities.random_ring, c: 0.5},
                    {v: Entities.locked_chest, c: 2.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);

                if (Entity.combat.exists(e)) {
                    enemies.push(e);
                } else {
                    items.push(e);
                }
            }

            enemy_rooms_this_floor++;
        }

        function merchant_room() {
            // Spawn merchant and items in a line starting from 3,3 away from top-left corner
            spawned_merchant = true;

            var positions = room_free_ODD_positions_shuffled(r);
            if (positions.length == 0) {
                return;
            }
            var merchant_pos = positions[0];
            Entities.merchant(merchant_pos.x, merchant_pos.y);

            // Position items around merchant
            var item_positions = new Array<Vec2i>();
            var free_map = Main.get_free_map(merchant_pos.x - 1, merchant_pos.y - 1, merchant_pos.x + 1, merchant_pos.y + 1);
            for (dx in -1...2) {
                for (dy in -1...2) {
                    if (free_map[dx + 1][dy + 1]) {
                        item_positions.push({x: merchant_pos.x + dx, y: merchant_pos.y + dy});
                    }
                }
            }

            if (item_positions.length > 0) {
                // Spawn items with increased level
                Main.current_level_mod = MERCHANT_ITEM_LEVEL_BONUS;
                var sell_items = new Array<Int>();
                sell_items.push(health_potion(item_positions[0].x, item_positions[0].y));
                for (i in 1...Std.int(Math.min(MERCHANT_ITEM_AMOUNT, item_positions.length))) {
                    sell_items.push(Random.pick_chance([
                        {v: health_max_potion, c: 1.0},
                        {v: Entities.random_potion, c: 3.0},
                        {v: Entities.random_armor, c: 1.0},
                        {v: Entities.random_scroll, c: 1.0},
                        {v: Entities.random_orb, c: 0.5},
                        {v: Entities.random_weapon, c: 0.5},
                        {v: Entities.random_ring, c: 0.5},
                        ])
                    (item_positions[i].x, item_positions[i].y));
                }
                Main.current_level_mod = 0;

                // Add cost to items
                for (e in sell_items) {
                    Entity.cost[e] = Stats.get({min: 3, max: 5, scaling: 2.0}, Main.current_level());
                }
            }
        }

        function item_room() {
            var amount = Random.int(1, Math.round((r.width * r.height) / (ROOM_SIZE_MAX * ROOM_SIZE_MAX) * ITEM_ROOM_ENTITY_AMOUNT));
            for (i in 0...amount) {
                if (positions.length == 0) {
                    break;
                }
                var pos = positions.pop();
                var e = Random.pick_chance([
                    {v: Entities.random_armor, c: 3.0},
                    {v: Entities.random_weapon, c: 0.5},
                    {v: health_potion, c: 3.0},
                    {v: Entities.random_potion, c: 3.0},
                    {v: Entities.random_scroll, c: 3.0},
                    {v: Entities.random_orb, c: 1.5},
                    {v: Entities.locked_chest, c: 2.0},
                    {v: Entities.random_ring, c: 1.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);

                items.push(e);
            }

            item_rooms_this_floor++;
        }

        function locked_room() {
            // More good stuff inside
            var connection = Main.rooms[r.adjacent_rooms[0]];

            // other room
            //    |D|
            //    | |
            //    | |
            // this room
            var end_a: Vec2i = {x: connection.x, y: connection.y};
            // For connections with width or height of 1, need to not increment so that door is within connection
            var dx = if (connection.width > 1) connection.width - 1; else 0;
            var dy = if (connection.height > 1) connection.height - 1; else 0;
            var end_b: Vec2i = if (connection.is_horizontal) {
                {x: connection.x + dx, y: connection.y};
            } else {
                {x: connection.x, y: connection.y + dy};
            }
            var dst_a = Math.dst2(end_a.x, end_a.y, r.x, r.y);
            var dst_b = Math.dst2(end_b.x, end_b.y, r.x, r.y);

            // Pick the far end of the connection
            var door_pos = 
            if (dst_a > dst_b) {
                end_a;
            } else {
                end_b;
            }

            Entities.locked_door(door_pos.x, door_pos.y);
            if (connection.is_horizontal) {
                if (connection.height > 1) {
                    for (y in door_pos.y + 1...door_pos.y + connection.height) {
                        Main.walls[door_pos.x][y] = true;
                    }
                }
            } else {
                if (connection.width > 1) {
                    for (x in door_pos.x + 1...door_pos.x + connection.width) {
                        Main.walls[x][door_pos.y] = true;
                    }
                }
            }

            // NOTE: spawning chests behind locked doors is okay
            var amount = Random.int(1, Math.round((r.width * r.height) / (ROOM_SIZE_MAX * ROOM_SIZE_MAX) * ITEM_ROOM_ENTITY_AMOUNT));

            for (i in 0...amount) {
                if (positions.length == 0) {
                    break;
                }
                var pos = positions.pop();
                Random.pick_chance([
                    {v: Entities.random_armor, c: 3.0},
                    {v: Entities.random_ring, c: 3.0},
                    {v: Entities.random_weapon, c: 1.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);
            }
        }

        var dead_end = r.adjacent_rooms.length == 1;

        if (!spawned_merchant && do_spawn_merchant) {
            merchant_room();
        } else {
            Random.pick_chance([
                {v: empty_room, c: if (dead_end) 5.0 else 15.0},
                {v: enemy_room, c: 50.0},
                {v: item_room, c: 40.0},
                // {v: locked_room, c: 5.0},
                ])
            ();
        }
    }

    // Balance enemy/item ratio
    // Remove whichever one has spawned too much until within margins
    if (enemies.length > 0 && items.length > 0) { 
        Random.shuffle(enemies);
        Random.shuffle(items);
        var enemy_item_ratio = 1.0 * enemies.length / items.length;
        var item_enemy_ratio = 1.0 * items.length / enemies.length;
        var margin = ENEMY_ITEM_RATIO_MARGIN();
        if (enemy_item_ratio > ENEMY_ITEM_IDEAL_RATIO * margin) {
            while (enemy_item_ratio > ENEMY_ITEM_IDEAL_RATIO * margin) {
                Entity.remove(enemies.pop());
                enemy_item_ratio = 1.0 * enemies.length / items.length;
            }
        } else if (item_enemy_ratio > (1.0 / ENEMY_ITEM_IDEAL_RATIO) * margin) {
            while (item_enemy_ratio > (1.0 / ENEMY_ITEM_IDEAL_RATIO) * margin) {
                Entity.remove(items.pop());
                item_enemy_ratio = 1.0 * items.length / enemies.length;
            }
        }
    }

    enemies_this_floor = enemies.length;
    items_this_floor = items.length;

    var room_has_location_spell = [for (i in 0...Main.rooms.length) false];

    // Add location spells
    for (i in 0...Main.rooms.length) {
        if (Random.chance(ROOM_SPELL_CHANCE)) {
            var location_spell: Spell = Random.pick_chance([
                {v: Spells.poison_room_spell, c: 1.0},
                {v: Spells.teleport_room_spell, c: 1.0},
                ])
            ();
            var location_spell_tile = switch (location_spell.type) {
                case SpellType_RandomTeleport: Tile.Teleport;
                case SpellType_ModHealth: Tile.Poison;
                default: Tile.None;
            }

            function add_location_spell_to_room_and_adjacent(room_i: Int, depth: Int) {
                // NOTE: connections can be very long, don't put location spells if they are longer than max room dimension
                var room = Main.rooms[room_i];
                var max_dimension = Math.max(room.width, room.height);

                if (!room_has_location_spell[room_i] && max_dimension <= ROOM_SIZE_MAX * 1.1) {
                    room_has_location_spell[room_i] = true;

                    // Set location spells and tiles
                    // NOTE: all locations get a shared reference to spell so that duration is shared between them, otherwise the spell wouldn't tick unless you stood in the same place 
                    for (x in room.x...room.x + room.width) {
                        for (y in room.y...room.y + room.height) {
                            if (Main.location_spells[x][y].length == 0) {
                                Main.location_spells[x][y].push(location_spell);
                                Main.tiles[x][y] = location_spell_tile;
                            }
                        }
                    }

                    if (depth > 0 && Random.chance(ROOM_SPELL_SPREADS_TO_NEIGHBORS_CHANCE)) {
                        for (adj_i in Main.rooms[room_i].adjacent_rooms) {
                            add_location_spell_to_room_and_adjacent(adj_i, depth - 1);
                        }
                    }
                }
            }

            add_location_spell_to_room_and_adjacent(i, 2);
        }
    }

    var stairs_room = Main.get_room_index(Main.stairs_x, Main.stairs_y);
    room_is_empty[stairs_room] = false;

    // Create matching keys for each locked entity
    // Either insert into a random enemy's droptable or spawn on map 
    var enemies_that_can_hold_keys = Main.entities_with(Entity.combat);
    Random.shuffle(enemies_that_can_hold_keys);
    for (e in Main.entities_with(Entity.container)) {
        var locked = Entity.container[e];
        var locked_pos = Entity.position[e];

        if (locked.locked) {
            var key_done = false;

            // Give key to a random enemy(replaces current drop)
            if (Random.chance(KEY_ON_ENEMY_CHANCE)) {
                while (enemies_that_can_hold_keys.length > 0) {
                    var random_enemy = enemies_that_can_hold_keys.pop();

                    // Don't give the key to the merchant
                    if (Entity.name.exists(e) && Entity.merchant.exists(e)) {
                        continue;
                    }

                    Entity.drop_entity[random_enemy] = {
                        drop_func: function(x, y) {
                            return Entities.key(x, y, locked.color);
                        }
                    };

                    key_done = true;

                    break;
                }
            }

            // Put the key on the map otherwise
            // Pick a random position in a random non-connection room that's far from locked entity
            if (!key_done) {
                var furthest_r_i = -1;
                var furthest_pos = {x: -1, y: -1};
                var furthest_dst: Float = -1;

                for (i in 0...10) {
                    var r_i = Main.random_good_room();
                    var r = Main.rooms[r_i];
                    var positions = room_free_ODD_positions_shuffled(r);
                    if (positions.length == 0) {
                        continue;
                    }
                    var pos = positions.pop();

                    var dst = Math.dst(locked_pos.x, locked_pos.y, pos.x, pos.y);

                    if (dst > furthest_dst) {
                        furthest_r_i = r_i;
                        furthest_pos = pos;
                        furthest_dst = dst;
                    }
                }

                if (furthest_r_i != -1) {
                    room_is_empty[furthest_r_i] = false;
                    Entities.key(furthest_pos.x, furthest_pos.y, locked.color);
                }
            }
        }
    }

    //
    // Trim down empty rooms to intersections and bends
    //
    // var empty_rooms = new Array<Room>();
    // for (i in 0...Main.rooms.length) {
    //     if (room_is_empty[i]) {
    //         empty_rooms.push(Main.rooms[i]);
    //     }
    // }

    // for (r in empty_rooms) {
    //     r.is_connection = true;

    //     var no_horizontals = true;
    //     var no_verticals = true;
    //     var xs = new Array<Int>();
    //     var ys = new Array<Int>();
    //     for (adj_i in r.adjacent_rooms) {
    //         var adj = Main.rooms[adj_i];
    //         if (adj.width == 1) {
    //             xs.push(adj.x);
    //             no_verticals = false;
    //         } else {
    //             ys.push(adj.y);
    //             no_horizontals = false;
    //         }
    //     }

    //     for (x in r.x...r.x + r.width) {
    //         for (y in r.y...r.y + r.height) {
    //             Main.walls[x][y] = true;
    //         }
    //     }

    //     // Create a no-walls cross in the room to connect all connections
    //     // Only if there are more than one connection
    //     if (r.adjacent_rooms.length > 1) {
    //         if (no_horizontals) {
    //             var y_mid = Math.floor(r.y + r.height / 2);
    //             for (x in r.x...r.x + r.width) {
    //                 Main.walls[x][y_mid] = false;
    //             }
    //             ys.push(y_mid);
    //         }
    //         if (no_verticals) {
    //             var x_mid = Math.floor(r.x + r.width / 2);
    //             for (y in r.y...r.y + r.height) {
    //                 Main.walls[x_mid][y] = false;
    //             }
    //             xs.push(x_mid);
    //         }
    //     }

    //     // Elongate connections
    //     for (x in xs) {
    //         for (y in r.y...r.y + r.height) {
    //             Main.walls[x][y] = false;
    //         }
    //     }
    //     for (x in r.x...r.x + r.width) {
    //         for (y in ys) {
    //             Main.walls[x][y] = false;
    //         }
    //     }

    //     // Trim connections
    //     // Vertical
    //     for (x in xs) {
    //         var y1 = r.y - 1;
    //         var y2 = r.y + r.height + 1;
    //         if (Main.out_of_map_bounds(x, y1) || Main.walls[x][y1]) {
    //             // trim from y1

    //             while ((Main.out_of_map_bounds(x - 1, y1) || Main.walls[x - 1][y1]) && (Main.out_of_map_bounds(x + 1, y1) || Main.walls[x + 1][y1])) {
    //                 if (!Main.out_of_map_bounds(x, y1)) {
    //                     Main.walls[x][y1] = true;
    //                 }
    //                 y1++;

    //                 if (Main.out_of_map_bounds(x, y1)) {
    //                     break;
    //                 }
    //             }
    //         }
    //         if (Main.out_of_map_bounds(x, y2) || Main.walls[x][y2]) {
    //             // trim from y2

    //             while ((Main.out_of_map_bounds(x - 1, y2) || Main.walls[x - 1][y2]) && (Main.out_of_map_bounds(x + 1, y2) || Main.walls[x + 1][y2])) {
    //                 if (!Main.out_of_map_bounds(x, y2)) {
    //                     Main.walls[x][y2] = true;
    //                 }
    //                 y2--;

    //                 if (Main.out_of_map_bounds(x, y2)) {
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    //     // Horizontal
    //     for (y in ys) {
    //         var x1 = r.x - 1;
    //         var x2 = r.x + r.width + 1;
    //         if (Main.out_of_map_bounds(x1, y) || Main.walls[x1][y]) {
    //             // trim from x1

    //             while ((Main.out_of_map_bounds(x1, y - 1) || Main.walls[x1][y - 1]) && (Main.out_of_map_bounds(x1, y + 1) || Main.walls[x1][y + 1])) {
    //                 if (!Main.out_of_map_bounds(x1, y)) {
    //                     Main.walls[x1][y] = true;
    //                 }
    //                 x1++;

    //                 if (Main.out_of_map_bounds(x1, y)) {
    //                     break;
    //                 }
    //             }
    //         }
    //         if (Main.out_of_map_bounds(x2, y) || Main.walls[x2][y]) {
    //             // trim from x2

    //             while ((Main.out_of_map_bounds(x2, y - 1) || Main.walls[x2][y - 1]) && (Main.out_of_map_bounds(x2, y + 1) || Main.walls[x2][y + 1])) {
    //                 if (!Main.out_of_map_bounds(x2, y)) {
    //                     Main.walls[x2][y] = true;
    //                 }
    //                 x2--;

    //                 if (Main.out_of_map_bounds(x2, y)) {
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    // }
}

// Randomly place rooms that don't intersect with other rooms
static function generate_via_digging(): Array<Room> {

    var width_max = Math.floor((Main.MAP_WIDTH - ORIGIN_X - 1) * 0.75);
    var height_max = Math.floor((Main.MAP_HEIGHT - ORIGIN_Y - 1) * 0.75);
    var world_width = Random.int(width_max - 25, width_max);
    var world_height = Random.int(height_max - 25, height_max);

    var rooms = new Array<Room>();

    for (i in 0...DIG_TRIES) {
        if (rooms.length >= ROOMS_MAX) {
            break;
        }

        var new_room = {
            x: Random.int(ORIGIN_X, world_width - ROOM_SIZE_MAX - 1),
            y: Random.int(ORIGIN_Y, world_height - ROOM_SIZE_MAX - 1),
            // NOTE: have to decrement max dimensions here because they are incremented by one later
            width: Random.int(ROOM_SIZE_MIN, ROOM_SIZE_MAX - 1),
            height: Random.int(ROOM_SIZE_MIN, ROOM_SIZE_MAX - 1),
            is_connection: false,
            adjacent_rooms: [],
            is_locked: false,
            is_horizontal: false,
        };
        var no_intersections = true;
        for (r in rooms) {
            if (Math.box_box_intersect(r.x - ROOM_SPACING, r.y - ROOM_SPACING, r.width + ROOM_SPACING, r.height + ROOM_SPACING, new_room.x - ROOM_SPACING, new_room.y - ROOM_SPACING, new_room.width + ROOM_SPACING, new_room.height + ROOM_SPACING)) {
                no_intersections = false;
                break;
            }
        }
        if (no_intersections) {
            rooms.push(new_room);
        }
    }

    return rooms;
}

// Connect rooms that intersect with each other on an axis
// Then remove connections that go across rooms or are too long
// Avoid creating disconnected islands
static function connect_rooms(rooms: Array<Room>, disconnect_factor: Float = 0.0) {
    var horizontals = new Array<Connection>();
    var verticals = new Array<Connection>();

    var connected = Data.create2darray(rooms.length, rooms.length, false);

    // Remove disconnected rooms that don't collide with any other room
    var unconnected_rooms = new Array<Room>();
    for (i in 0...rooms.length) {
        var unconnected = true;

        for (j in 0...rooms.length) {
            if (i == j) {
                continue;
            }

            var r = rooms[i];
            var other = rooms[j];

            if (Math.collision_1d(r.y, r.y + r.height, other.y, other.y + other.height) != 0 || Math.collision_1d(r.x, r.x + r.width, other.x, other.x + other.width) != 0) {
                // Collission along y-axis
                unconnected = false;
                break;
            }
        }

        if (unconnected) {
            unconnected_rooms.push(rooms[i]);
        }
    }

    for (r in unconnected_rooms) {
        rooms.remove(r);
    }

    // Connect rooms with horizontal or vertical lines with random attach points
    for (i in 0...rooms.length) {
        for (j in 0...rooms.length) {
            if (i == j || connected[i][j]) {
                continue;
            }

            var r = rooms[i];
            var other = rooms[j];

            if (Math.collision_1d(r.y, r.y + r.height, other.y, other.y + other.height) != 0) {
                // Collission along y-axis
                var x1;
                var x2;
                if (r.x < other.x) {
                    // r left of other
                    x1 = r.x + r.width;
                    x2 = other.x;
                } else {
                    // other left of r
                    x1 = other.x + other.width;
                    x2 = r.x;
                };
                var y_min = Std.int(Math.max(r.y, other.y));
                var y_max = Std.int(Math.min(r.y + r.height, other.y + other.height));
                // Avoid connecting to corners for rooms
                if (y_max - y_min > 0) {
                    y_min++;
                    y_max--;
                }
                var y = Random.int(y_min, y_max);
                // Off by one so that connection doesn't go inside rooms
                horizontals.push({
                    x1: x1 + 1, 
                    y1: y, 
                    x2: x2 - 1, 
                    y2: y,
                    i: i,
                    j: j
                });

                connected[i][j] = true;
                connected[j][i] = true;
            } else if (Math.collision_1d(r.x, r.x + r.width, other.x, other.x + other.width) != 0) {
                // Collission along x-axis
                var y1;
                var y2;
                if (r.y < other.y) {
                    // r above other
                    y1 = r.y + r.height;
                    y2 = other.y;
                } else {
                    // other above r
                    y1 = other.y + other.height;
                    y2 = r.y;
                };
                var x_min = Std.int(Math.max(r.x, other.x));
                var x_max = Std.int(Math.min(r.x + r.width, other.x + other.width));
                // Avoid connecting to corners for rooms
                if (x_max - x_min > 0) {
                    x_min++;
                    x_max--;
                }
                var x = Random.int(x_min, x_max);
                // Off by one so that connection doesn't go inside rooms
                verticals.push({
                    x1: x, 
                    y1: y1 + 1, 
                    x2: x, 
                    y2: y2 - 1,
                    i: i,
                    j: j
                });

                connected[i][j] = true;
                connected[j][i] = true;
            }
        }
    }

    // Remove connections that intersect with rooms
    // var intersecting_horizontals = new Array<Connection>();
    // for (c in horizontals) {
    //     for (room in rooms) {
    //         if (room.y <= c.y1 && c.y2 <= room.y + room.height && Math.collision_1d(room.x, room.x + room.width, c.x1, c.x2) != 0) {
    //             intersecting_horizontals.push(c);
    //         }
    //     }
    // }
    // for (c in intersecting_horizontals) {
    //     connected[c.i][c.j] = false;
    //     connected[c.j][c.i] = false;
    //     horizontals.remove(c);
    // }
    // var intersecting_verticals = new Array<Connection>();
    // for (c in verticals) {
    //     for (room in rooms) {
    //         if (room.x <= c.x1 && c.x2 <= room.x + room.width && Math.collision_1d(room.y, room.y + room.height, c.y1, c.y2) != 0) {
    //             intersecting_verticals.push(c);
    //         }
    //     }
    // }
    // for (c in intersecting_verticals) {
    //     connected[c.i][c.j] = false;
    //     connected[c.j][c.i] = false;
    //     verticals.remove(c);
    // }

    // Remove intersections between horizontal and verticals by removing either a horizontal or all intersecting verticals
    var removed_horizontal = new Array<Connection>();
    var removed_vertical = new Array<Connection>();
    for (v in verticals) {
        var remove_vertical_if_intersecting = Random.chance(50);
        for (h in horizontals) {
            if (Math.line_line_intersect(h.x1, h.y1, h.x2, h.y2, v.x1, v.y1, v.x2, v.y2)) {
                if (remove_vertical_if_intersecting) {
                    removed_vertical.push(v);
                    break;
                } else {
                    removed_horizontal.push(h);
                }
            }
        }
    }
    for (h in removed_horizontal) {
        connected[h.i][h.j] = false;
        connected[h.j][h.i] = false;
        horizontals.remove(h);
    }
    for (v in removed_vertical) {
        connected[v.i][v.j] = false;
        connected[v.j][v.i] = false;
        verticals.remove(v);
    }
    var connections = horizontals.concat(verticals);

    // Remove connections that are too long, unless it disconnects the map
    function all_connected(): Bool {
        var visited = [for (i in 0...rooms.length) false];
        var edge: Array<Int> = [0];

        var i;
        while (edge.length > 0) {
            i = edge.pop();

            for (j in 0...rooms.length) {
                if (!visited[j] && connected[i][j]) {
                    edge.push(j);
                    visited[j] = true;
                }
            }
        }

        for (i in 0...visited.length) {
            if (!visited[i]) {
                return false;
            }
        }

        return true;
    }
    var removed_long = new Array<Connection>();
    for (c in connections) {
        if (Math.dst(c.x1, c.y1, c.x2, c.y2) > ROOM_SIZE_MAX || Random.chance(10)) {
            connected[c.i][c.j] = false;
            connected[c.j][c.i] = false;

            if (all_connected()) {
                removed_long.push(c);
            } else {
                connected[c.i][c.j] = true;
                connected[c.j][c.i] = true;
            }
        }
    }
    for (c in removed_long) {
        connections.remove(c);
    }

    // Remove random connections without disconnecting rooms
    var removed_random = new Array<Connection>();
    for (i in 0...Math.floor(disconnect_factor * connections.length)) {
        var c = Random.pick(connections);

        connected[c.i][c.j] = false;
        connected[c.j][c.i] = false;

        if (all_connected()) {
            removed_random.push(c);
        } else {
            connected[c.i][c.j] = true;
            connected[c.j][c.i] = true;
        }
    }
    for (c in removed_random) {
        connections.remove(c);
    }

    // Add connections as rooms
    for (c in connections) {
        var width = c.x2 - c.x1;
        var height = c.y2 - c.y1;

        // Push connection room into the adjacent_rooms list of connected rooms
        // Index of connection room is rooms.length because it will be inserted at the end of rooms list
        rooms[c.i].adjacent_rooms.push(rooms.length);
        rooms[c.j].adjacent_rooms.push(rooms.length);

        rooms.push({
            x: c.x1,
            y: c.y1,
            width: width,
            height: height,
            is_connection: true,
            adjacent_rooms: [c.i, c.j],
            is_locked: false,
            is_horizontal: (height == 0),
        });
    }
}

static function fatten_connections() {
    // Fatten connections
    for (r in Main.rooms) {
        if (r.is_connection) {
            if (r.width == 1) {
                // Vertical
                var can_fatten_left = true;
                var can_fatten_right = true;

                for (adj_i in r.adjacent_rooms) {
                    var adj = Main.rooms[adj_i];

                    if (adj.x == r.x) {
                        can_fatten_left = false;
                    } else if (adj.x + adj.width == r.x) {
                        can_fatten_right = false;
                    }
                }

                if (can_fatten_left && r.x > 1) {
                    r.x--;
                    r.width++;
                }

                if (can_fatten_right && r.x + r.width < Main.MAP_WIDTH - 1) {
                    r.width++;
                }
            } else {
                // Horizontal
                var can_fatten_up = true;
                var can_fatten_down = true;

                for (adj_i in r.adjacent_rooms) {
                    var adj = Main.rooms[adj_i];

                    if (adj.y == r.y) {
                        can_fatten_up = false;
                    } else if (adj.y + adj.height == r.y) {
                        can_fatten_down = false;
                    }
                }

                if (can_fatten_up && r.y > 1) {
                    r.y--;
                    r.height++;
                }

                if (can_fatten_down && r.y + r.height < Main.MAP_HEIGHT - 1) {
                    r.height++;
                }
            }
        }
    }
}

static function decorate_rooms_with_walls() {
    function no_walls(r: Room) {}

    function cross_section(r: Room) {
        var x_mid = Math.floor((r.x + r.width / 2));
        var y_mid = Math.floor((r.y + r.height / 2));
        
        for (x in r.x + 1...r.x + r.width - 1) {
            Main.walls[x][y_mid] = true;
        }
        for (y in r.y + 1...r.y + r.height - 1) {
            Main.walls[x_mid][y] = true;
        }
    }

    function columns(r: Room) {
        var spacing = Random.int(3, 4);

        for (x in r.x + 1...r.x + r.width - 1) {
            for (y in r.y + 1...r.y + r.height - 1) {
                if (x % spacing == 0 && y % spacing == 0) {
                    Main.walls[x][y] = true;
                }
            }
        }
    }

    function thin_ring(r: Room) {
        for (x in (r.x + 2)...(r.x + r.width - 2)) {
            for (y in (r.y + 2)...(r.y + r.height - 2)) {
                Main.walls[x][y] = true;
                Main.tiles[x][y] = Tile.Black;
            }
        }
    }

    function fat_ring(r: Room) {
        for (x in (r.x + 3)...(r.x + r.width - 3)) {
            for (y in (r.y + 3)...(r.y + r.height - 3)) {
                Main.walls[x][y] = true;
                Main.tiles[x][y] = Tile.Black;
            }
        }
    }

    for (r in Main.rooms) {
        if (!r.is_connection) {
            Random.pick_chance([
                {v: no_walls, c: 10.0},
                {v: thin_ring, c: 0.5},
                {v: fat_ring, c: 1.0},
                ])(r);
            }
        }
    }

    function new() {}
}