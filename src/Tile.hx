
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 1); // bugged tile

    static inline var Player = at(0, 0);
    static inline var Wall = at(1, 0);
    static inline var Ground = at(2, 0);
    static inline var Gnome = at(3, 0);
    static inline var Bananas = at(4, 0);
    static inline var Tree = at(5, 0);
    static inline var Gnome2 = at(6, 0);

}