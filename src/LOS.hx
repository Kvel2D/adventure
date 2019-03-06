
import haxegon.*;

using haxegon.MathExtensions;

@:publicFields
class LOS {

    static var rays = new Array<Array<Vec2i>>();

    static function ray(x1: Int, y1: Int, x2: Int, y2: Int): Array<Vec2i> {
        var points = new Array<Vec2i>();

        var dst = 0.5;
        var x_min = Std.int(Math.min(x1, x2));
        var x_max = Std.int(Math.max(x1, x2));
        var y_min = Std.int(Math.min(y1, y2));
        var y_max = Std.int(Math.max(y1, y2));

        for (x in x_min...x_max + 1) {
            for (y in y_min...y_max + 1) {
                if (Math.point_line_dst(x, y, x1, y1, x2, y2) <= dst) {
                    points.push({x: x, y: y});
                }
            }
        }

        return points;
    }

    static function calculate_rays() {
        var center_x = Math.floor(Main.VIEW_HEIGHT / 2);
        var center_y = Math.floor(Main.VIEW_HEIGHT / 2);

        // top row
        for (x in 0...Main.VIEW_HEIGHT) {
            rays.push(ray(center_x, center_y, x, 0));
        }
        // bottom row
        for (x in 0...Main.VIEW_HEIGHT) {
            rays.push(ray(center_x, center_y, x, Main.VIEW_HEIGHT - 1));
        }
        // left column
        for (y in 0...Main.VIEW_HEIGHT) {
            rays.push(ray(center_x, center_y, 0, y));
        }
        // right column
        for (y in 0...Main.VIEW_HEIGHT) {
            rays.push(ray(center_x, center_y, Main.VIEW_HEIGHT - 1, y));
        }

        // Sort points in rays by distance
        for (l in rays) {
            l.sort(function(a, b): Int {
                var dst_a = Math.dst2(a.x, a.y, center_x, center_y);
                var dst_b = Math.dst2(b.x, b.y, center_x, center_y);

                if (dst_a < dst_b) {
                    return -1;
                } else if (dst_a > dst_b) {
                    return 1;
                } else {
                    return 0;
                }
            });
        }
    }

    static var free_map = Data.create2darray(Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, false);
    static function update_los(los: Array<Array<Bool>>) {
        var start_x = Player.x - Math.floor(Main.VIEW_HEIGHT / 2);
        var start_y = Player.y - Math.floor(Main.VIEW_HEIGHT / 2);

        Main.get_free_map(start_x, start_y, Main.VIEW_HEIGHT, Main.VIEW_HEIGHT, free_map, false, false, true);

        for (ray in rays) {
            var obstruction = false;
            for (i in 1...ray.length) {
                var p = ray[i];
                if (obstruction) {
                    los[p.x][p.y] = true;
                } else {
                    if (!Main.out_of_map_bounds(start_x + p.x, start_y + p.y) && !free_map[p.x][p.y]) {
                        // los[p.x][p.y] = true;
                        obstruction = true;
                    } else {
                        los[p.x][p.y] = false;
                    }
                }
            }
        }
    }

    function new() {}
}