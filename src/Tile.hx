
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 1); // bugged tile

    static inline var Black = at(7, 1);
    static inline var Player = at(0, 0);
    static inline var Wall = at(1, 0);
    static inline var Ground = at(2, 0);
    static inline var DarkerWall = at(5, 1);
    static inline var DarkerGround = at(6, 1);
    static inline var Gnome = at(3, 0);
    static inline var Bananas = at(4, 0);
    static inline var Tree = at(5, 0);
    static inline var Gnome2 = at(6, 0);

    static inline var Head0 = at(0, 2);
    static inline var Head1 = at(1, 2);
    static inline var Head2 = at(2, 2);
    static inline var Head3 = at(3, 2);
    static inline var Head4 = at(4, 2);
    static inline var Head5 = at(5, 2);
    static inline var Head6 = at(6, 2);

    static inline var Chest0 = at(0, 3);
    static inline var Chest1 = at(1, 3);
    static inline var Chest2 = at(2, 3);
    static inline var Chest3 = at(3, 3);
    static inline var Chest4 = at(4, 3);
    static inline var Chest5 = at(5, 3);
    static inline var Chest6 = at(6, 3);

    static inline var Legs0 = at(0, 4);
    static inline var Legs1 = at(1, 4);
    static inline var Legs2 = at(2, 4);
    static inline var Legs3 = at(3, 4);
    static inline var Legs4 = at(4, 4);
    static inline var Legs5 = at(5, 4);
    static inline var Legs6 = at(6, 4);

    static inline var Sword1 = at(1, 5);
    static inline var Sword2 = at(2, 5);
    static inline var Sword3 = at(3, 5);
    static inline var Sword4 = at(4, 5);
    static inline var Sword5 = at(5, 5);

    static inline var Potion = at(1, 1);
}