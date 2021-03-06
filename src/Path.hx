
import haxegon.*;
import GenerateWorld;

using haxegon.MathExtensions;

@:publicFields
class Path {
// force unindent

static inline var INFINITY = 10000000;
static var closed: Array<Array<Bool>>;
static var open: Array<Array<Bool>>;
static var g_score: Array<Array<Int>>;
static var f_score: Array<Array<Int>>;
static var prev: Array<Array<Vec2i>>;
static var free_map: Array<Array<Bool>>;

// NOTE: astar_internal needs to have the data structures assigned, the map/room astars are the optimized versions which reuse same structures each time

// Astar with an area at offset returns path relative to the offset
// A straight path from 100,100 to 105,100, would be 0,0->1,0->2,0->etc
static function astar_internal(x1:Int, y1:Int, x2:Int, y2:Int, area_x: Int, area_y: Int, area_width: Int, area_height: Int) {

    inline function heuristic_score(x1:Int, y1:Int, x2:Int, y2:Int):Int {
        return Std.int(Math.abs(x2 - x1) + Math.abs(y2 - y1));
    }
    inline function out_of_bounds(x, y) {
        return x < 0 || y < 0 || x >= area_width || y >= area_height;
    }

    x1 -= area_x;
    x2 -= area_x;

    y1 -= area_y;
    y2 -= area_y;
    
    Main.get_free_map(area_x, area_y, area_width, area_height, free_map, true, true);
    // destination and origin need to be "free" for the algorithm to find paths correctly
    free_map[x2][y2] = true; 
    free_map[x1][y1] = true; 

    for (x in 0...area_width) {
        for (y in 0...area_height) {
            closed[x][y] = false;
        }
    }
    for (x in 0...area_width) {
        for (y in 0...area_height) {
            open[x][y] = false;
        }
    }
    open[x1][y1] = true;
    var open_queue: Array<Vec2i> = [{x: x1, y: y1}];

    for (x in 0...area_width) {
        for (y in 0...area_height) {
            prev[x][y].x = -1;
            prev[x][y].y = -1;
        }
    }

    for (x in 0...area_width) {
        for (y in 0...area_height) {
            g_score[x][y] = INFINITY;
        }
    }
    g_score[x1][y1] = 0;

    for (x in 0...area_width) {
        for (y in 0...area_height) {
            f_score[x][y] = INFINITY;
        }
    }
    f_score[x1][y1] = heuristic_score(x1, y1, x2, y2);

    while (open_queue.length != 0) {
        var current = function(): Vec2i {
            var lowest_score = INFINITY;
            var lowest_node: Vec2i = {x: -1, y: -1};
            for (node in open_queue) {
                var f_score = f_score[node.x][node.y];
                if (f_score <= lowest_score) {
                    lowest_node = node;
                    lowest_score = f_score;
                }
            }
            open_queue.remove(lowest_node);
            return lowest_node;
        }();
        open[current.x][current.y] = false;
        closed[current.x][current.y] = true;

        if (current.x == x2 && current.y == y2) {
            var x = current.x;
            var y = current.y;
            var current = {x: x, y: y};
            var temp = {x: x, y: y};
            var path: Array<Vec2i> = [{x: current.x, y: current.y}];
            while (prev[current.x][current.y].x != -1) {
                temp.x = current.x;
                temp.y = current.y;
                current.x = prev[temp.x][temp.y].x;
                current.y = prev[temp.x][temp.y].y;
                path.push({x: current.x, y: current.y});
            }
            return path;
        }

        for (dx_dy in Main.four_dxdy) {
            var neighbor_x = current.x + dx_dy.x;
            var neighbor_y = current.y + dx_dy.y;
            if (out_of_bounds(neighbor_x, neighbor_y) || !free_map[neighbor_x][neighbor_y]) {
                continue;
            }

            if (closed[neighbor_x][neighbor_y]) {
                continue;
            }
            var tentative_g_score = g_score[current.x][current.y] + 1;
            if (!open[neighbor_x][neighbor_y]) {
                open[neighbor_x][neighbor_y] = true;
                open_queue.push({x: neighbor_x, y: neighbor_y});
            } else if (tentative_g_score >= g_score[neighbor_x][neighbor_y]) {
                continue;
            }

            prev[neighbor_x][neighbor_y].x = current.x;
            prev[neighbor_x][neighbor_y].y = current.y;
            g_score[neighbor_x][neighbor_y] = tentative_g_score;
            f_score[neighbor_x][neighbor_y] = tentative_g_score + heuristic_score(neighbor_x, neighbor_y, x2, y2);
        }
    }

    return new Array<Vec2i>();
}

static var view_closed = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, false);
static var view_open = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, false);
static var view_g_score = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, 0);
static var view_f_score = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, 0);
static var view_prev = [for (x in 0...Main.VIEW_HEIGHT) [for (y in 0...Main.VIEW_HEIGHT) {x: -1, y: -1}]];
static var view_free_map = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, false);

static function astar_view(x1:Int, y1:Int, x2:Int, y2:Int): Array<Vec2i> {
    closed = view_closed;
    open = view_open;
    g_score = view_g_score;
    f_score = view_f_score;
    prev = view_prev;
    free_map = view_free_map;

    return astar_internal(x1, y1, x2, y2, Main.get_view_x(), Main.get_view_y(), Main.VIEW_HEIGHT, Main.VIEW_HEIGHT);
}

static var map_closed = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, false);
static var map_open = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, false);
static var map_g_score = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, 0);
static var map_f_score = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, 0);
static var map_prev = [for (x in 0...Main.MAP_WIDTH) [for (y in 0...Main.MAP_HEIGHT) {x: -1, y: -1}]];
static var map_free_map = Data.create2darray(Main.MAP_WIDTH, Main.MAP_HEIGHT, false);

static function astar_map(x1:Int, y1:Int, x2:Int, y2:Int):Array<Vec2i> {
    closed = map_closed;
    open = map_open;
    g_score = map_g_score;
    f_score = map_f_score;
    prev = map_prev;
    free_map = map_free_map;

    return astar_internal(x1, y1, x2, y2, 0, 0, Main.MAP_WIDTH, Main.MAP_HEIGHT);
}

}