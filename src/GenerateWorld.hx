
import haxegon.*;
import Entity;
import MakeEntity;

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
    height: Int
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
// NOTE: force unindent

static var origin_x = Main.funtown_x + 1;
static var origin_y = Main.funtown_y + 1;
static var min = 10;
static var max = 20;
static var spacing = 3;
static var iterations = 400;
static var max_entities_per_biggest_room = 8;

static function fill_rooms_with_entities(rooms: Array<Room>) {

    var spawns: Array<Spawn> = [
    {fun: MakeEntity.snail, chance: 10.0},
    {fun: MakeEntity.bear, chance: 10.0},
    {fun: MakeEntity.potion, chance: 1.0},
    {fun: MakeEntity.fountain, chance: 3.0},
    ];
    var chance_total = 0.0;
    for (s in spawns) {
        chance_total += s.chance;
    }
    for (i in 1...spawns.length) {
        spawns[i].chance += spawns[i - 1].chance;
    }

    // spawn only one entity in first room
    for (i in 1...rooms.length) {
        var r = rooms[i];
        var entities = new Array<Int>();

        var positions = new Array<Position>();
        for (x in r.x...(r.x + r.width)) {
            for (y in r.y...(r.y + r.height)) {
                positions.push({
                    x: x,
                    y: y
                });
            }
        }
        Random.shuffle(positions);

        function random_entity(): Int {
            var k = Random.float(0, chance_total);

            var pos = positions.pop();
            for (s in spawns) {
                if (k <= s.chance) {
                    return s.fun(pos.x, pos.y);
                }
            }

            return Entity.NONE;
        }

        var amount = Random.int(1, Math.round((r.width * r.height) / (max * max) * max_entities_per_biggest_room));
        for (i in 0...amount) {
            entities.push(random_entity());
        }
    }
}

// Randomly place rooms that don't intersect with other rooms
static function generate_via_digging(): Array<Room> {

    var world_width = Math.floor((Main.map_width - origin_x - 1) * 0.75);
    var world_height = Math.floor((Main.map_height - origin_y - 1) * 0.75);

    var rooms = new Array<Room>();

    for (i in 0...iterations) {
        var new_room = {
            x: Random.int(origin_x, world_width - max - 1),
            y: Random.int(origin_y, world_height - max - 1),
            width: Random.int(min, max),
            height: Random.int(min, max),
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
static function connect_rooms(rooms: Array<Room>): Array<Connection> {
    var horizontals = new Array<Connection>();
    var verticals = new Array<Connection>();

    var connected = Data.bool_2d_vector(rooms.length, rooms.length, false);

    // Connect rooms with horizontal or vertical lines with random attach points
    // TODO: possible to have a room that doesn't intersect with any other room, bad if player is spawned in it
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
                horizontals.push({
                    x1: x1, 
                    y1: y, 
                    x2: x2, 
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
                verticals.push({
                    x1: x, 
                    y1: y1, 
                    x2: x, 
                    y2: y2,
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

    // Remove long connections
    var removed = new Array<Connection>();
    for (c in connections) {
        if (Math.dst(c.x1, c.y1, c.x2, c.y2) > max || Random.chance(10)) {
            connected[c.i][c.j] = false;
            connected[c.j][c.i] = false;

            if (all_connected()) {
                removed.push(c);
            } else {
                connected[c.i][c.j] = true;
                connected[c.j][c.i] = true;
            }
        }
    }
    for (c in removed) {
        connections.remove(c);
    }

    return connections;
}

static function generate_rooms_via_bst(): Array<Room> {
    var rooms = new Array<Room>();

    var room_width = 30;
    var room_height = 20;

    var max = 0.3;
    var max = 0.3;


    var world_width = Main.map_width - origin_x - 1;
    var world_height = Main.map_height - origin_y - 1;

    var pre_rooms = new Array<PreRoom>();
    pre_rooms.push({
        x: 0.0,
        y: 0.0,
        width: 1.0,
        height: 1.0
    });

    while (true) {
        var done = true;

        var new_rooms = new Array<PreRoom>();

        for (r in pre_rooms) {
            var split = false;
            if (r.width > max || r.height > max) {
                done = false;
                split = true;
            }

            if (split) {
                var split_horizontally = false;
                if (r.width > max && r.height > max) {
                    split_horizontally = Random.bool();
                } else if (r.width > max) {
                    split_horizontally = true;
                } else {
                    split_horizontally = false;
                }

                if (split_horizontally) {
                    var split_width = Random.float(0.2, 0.9) * r.width;
                    new_rooms.push({
                        x: r.x + split_width,
                        y: r.y,
                        width: r.width - split_width,
                        height: r.height
                    });
                    r.width = split_width;
                } else {
                    var split_height = Random.float(0.2, 0.9) * r.height;
                    new_rooms.push({
                        x: r.x,
                        y: r.y + split_height,
                        width: r.width,
                        height: r.height - split_height
                    });
                    r.height = split_height;
                }
            }
        }

        pre_rooms = pre_rooms.concat(new_rooms);

        if (done) {
            break;
        }
    }

    for (r in pre_rooms) {
        var old_width = r.width;
        var old_height = r.height;
        r.width = Random.float(r.width * 0.6, r.width * 0.9);
        r.height = Random.float(r.height * 0.6, r.height * 0.9);
        r.x = Random.float(r.x, r.x + old_width - r.width);
        r.y = Random.float(r.y, r.y + old_height - r.height);
        rooms.push({
            x: Math.floor(r.x * world_width),
            y: Math.floor(r.y * world_height),
            width: Math.floor(r.width * world_width),
            height: Math.floor(r.height * world_height)
        });
    }

    return rooms;
}

function new() {}
}