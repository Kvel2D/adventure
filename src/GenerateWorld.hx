
import haxegon.*;
import Entity;
import Entities;

using MathExtensions;

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
    adjacent_rooms: Array<Int>
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

static var origin_x = 1;
static var origin_y = 1;
static inline var min = Main.room_size_min;
static inline var max = Main.room_size_max;
static var spacing = 3;
static var iterations = 300;
static var max_rooms = 15;

static var enemy_room_entity_amount = 5;
static var item_room_entity_amount = 2;

static var enemy_types_per_level = 4;
static var empty_room_chance = 10;
static var enemy_room_chance = 90; // subset of non-empty rooms
static var spell_room_chance = 10; // subset of enemy rooms
static var locked_room_chance = 100; // subset of rooms with one connection

public static function shuffle<T>(array: Array<T>): Array<T> {
    if (array != null) {
        for (i in 0...array.length) {
            var j = Random.int(0, array.length - 1);
            var a = array[i];
            var b = array[j];
            array[i] = b;
            array[j] = a;
        }
    }
    return array;
}

static function room_free_positions_shuffled(r: Room): Array<Vec2i> {
    var free_map = Main.get_free_map(r.x, r.y, r.x + r.width, r.y + r.height);
    var positions = new Array<Vec2i>();
    for (x in r.x...(r.x + r.width)) {
        for (y in r.y...(r.y + r.height)) {
            if (free_map[x - r.x][y - r.y]) {
                positions.push({
                    x: x,
                    y: y,
                });
            }
        }
    }
    shuffle(positions);
    return positions;
}

static function fill_rooms_with_entities() {
    // Generate enemy types for level
    // First level only has physical enemies, later levels start having varied elements
    var enemy_types = [for (i in 0...enemy_types_per_level) Entities.random_enemy_type()];

    // Make sure that at least one enemy type is aggressive
    var at_least_one_enemy_type_is_aggressive = false;
    for (type in enemy_types) {
        if (type.combat.aggression == AggressionType_Aggressive) {
            at_least_one_enemy_type_is_aggressive = true;
            break;
        }
    }
    if (!at_least_one_enemy_type_is_aggressive) {
        enemy_types[0].combat.aggression = AggressionType_Aggressive;
    }

    function random_enemy(x: Int, y: Int): Int {
        return Entity.make_type(x, y, Random.pick(enemy_types));
    }

    var room_is_locked = [for (i in 0...Main.rooms.length) false];

    // NOTE: leave start room(0th) empty
    for (i in 1...Main.rooms.length) {
        var r = Main.rooms[i];

        // Don't generate entities in connections
        if (r.is_connection) {
            continue;
        }

        if (Random.chance(empty_room_chance)) {
            continue;
        }

        // Some one-connection rooms can be locked behind a door
        if (r.adjacent_rooms.length == 1 && Random.chance(locked_room_chance)) {
            room_is_locked[i] = true;
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
            var end_b: Vec2i = {x: connection.x + dx, y: connection.y + dy};
            var dst_a = Math.dst2(end_a.x, end_a.y, r.x, r.y);
            var dst_b = Math.dst2(end_b.x, end_b.y, r.x, r.y);

            // Pick the far end of the connection
            if (dst_a > dst_b) {
                Entities.locked_door(end_a.x, end_a.y);
            } else {
                Entities.locked_door(end_b.x, end_b.y);
            }
        }

        var positions = room_free_positions_shuffled(r);

        if (room_is_locked[i]) {
            // Locked room
            // More good stuff inside
            // NOTE: spawning chests behind locked doors is okay
            var amount = Random.int(1, Math.round((r.width * r.height) / (max * max) * item_room_entity_amount));

            for (i in 0...amount) {
                var pos = positions.pop();
                Pick.value([
                    {v: Entities.random_armor, c: 1.0},
                    {v: Entities.random_weapon, c: 1.0},
                    {v: Entities.random_ring, c: 1.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);
            }
        } else if (Random.chance(enemy_room_chance)) {
            // Enemy/item room with possible location spells
            var amount = Random.int(1, Math.round((r.width * r.height) / (max * max) * enemy_room_entity_amount));
            for (i in 0...amount) {
                var pos = positions.pop();
                Pick.value([
                    {v: random_enemy, c: 60.0},
                    {v: Entities.unlocked_chest, c: 6.0},
                    {v: Entities.random_potion, c: 4.0},
                    {v: Entities.random_armor, c: 3.0},
                    {v: Entities.random_scroll, c: 3.0},
                    {v: Entities.random_weapon, c: 1.0},
                    {v: Entities.random_ring, c: 1.0},
                    {v: Entities.locked_chest, c: 2.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);
            }

            // Sometimes add location spells
            if (Random.chance(spell_room_chance)) {
                Pick.value([
                    {v: Spells.poison_room, c: 1.0},
                    {v: Spells.lava_room, c: 1.0},
                    {v: Spells.ice_room, c: 1.0},
                    {v: Spells.teleport_room, c: 1.0},
                    {v: Spells.ailment_room, c: 1.0},
                    ])
                (r);
            }
        } else {
            // Room with items only
            var amount = Random.int(1, Math.round((r.width * r.height) / (max * max) * item_room_entity_amount));
            for (i in 0...amount) {
                var pos = positions.pop();
                Pick.value([
                    {v: Entities.random_potion, c: 4.0},
                    {v: Entities.random_armor, c: 3.0},
                    {v: Entities.random_scroll, c: 3.0},
                    {v: Entities.locked_chest, c: 2.0},
                    {v: Entities.random_weapon, c: 1.0},
                    {v: Entities.random_ring, c: 1.0},
                    {v: Entities.random_statue, c: 1.0},
                    ])
                (pos.x, pos.y);
            }
        }
    }

    // Spawn matching keys for each locked entity, duplicates possible, keys in same room as locked entity also possible, avoid spawning in connection rooms
    // NOTE: don't spawn keys in locked rooms, could spawn a key for the door itself behind it
    for (e in Entity.locked.keys()) {
        var locked = Entity.locked[e];
        if (locked.need_key) {
            var r_i = Random.int(1, Main.rooms.length - 1);
            while (Main.rooms[r_i].is_connection || room_is_locked[r_i]) {
                r_i = Random.int(1, Main.rooms.length - 1);
            }
            var r = Main.rooms[r_i];
            
            var positions = room_free_positions_shuffled(r);

            var pos = positions.pop();
            Entities.key(pos.x, pos.y, locked.color);
        }
    }
}

// Randomly place rooms that don't intersect with other rooms
static function generate_via_digging(): Array<Room> {

    var width_max = Math.floor((Main.map_width - origin_x - 1) * 0.75);
    var height_max = Math.floor((Main.map_height - origin_y - 1) * 0.75);
    var world_width = Random.int(width_max - 25, width_max);
    var world_height = Random.int(height_max - 25, height_max);

    var rooms = new Array<Room>();

    for (i in 0...iterations) {
        if (rooms.length >= max_rooms) {
            break;
        }

        var new_room = {
            x: Random.int(origin_x, world_width - max - 1),
            y: Random.int(origin_y, world_height - max - 1),
            // NOTE: have to decrement max dimensions here because they are incremented by one later
            width: Random.int(min, max - 1),
            height: Random.int(min, max - 1),
            is_connection: false,
            adjacent_rooms: [],
        };
        var no_intersections = true;
        for (r in rooms) {
            if (Math.box_box_intersect(r.x - spacing, r.y - spacing, r.width + spacing, r.height + spacing, new_room.x - spacing, new_room.y - spacing, new_room.width + spacing, new_room.height + spacing)) {
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
    var intersecting_horizontals = new Array<Connection>();
    for (c in horizontals) {
        for (room in rooms) {
            if (room.y <= c.y1 && c.y2 <= room.y + room.height && Math.collision_1d(room.x, room.x + room.width, c.x1, c.x2) != 0) {
                intersecting_horizontals.push(c);
            }
        }
    }
    for (c in intersecting_horizontals) {
        connected[c.i][c.j] = false;
        connected[c.j][c.i] = false;
        horizontals.remove(c);
    }
    var intersecting_verticals = new Array<Connection>();
    for (c in verticals) {
        for (room in rooms) {
            if (room.x <= c.x1 && c.x2 <= room.x + room.width && Math.collision_1d(room.y, room.y + room.height, c.y1, c.y2) != 0) {
                intersecting_verticals.push(c);
            }
        }
    }
    for (c in intersecting_verticals) {
        connected[c.i][c.j] = false;
        connected[c.j][c.i] = false;
        verticals.remove(c);
    }

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
        if (Math.dst(c.x1, c.y1, c.x2, c.y2) > max || Random.chance(10)) {
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
        });
    }
}

function new() {}
}