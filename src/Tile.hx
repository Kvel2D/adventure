
import Spells;

@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Black = at(9, 7);

    static var Stairs = [for (i in 0...5) at(7, i)];
    static var Ground = [for (i in 0...5) at(8, i)];
    static var GroundDark = [for (i in 0...5) at(9, i)];

    static inline var Teleport = at(8, 5);
    static inline var TeleportDark = at(9, 5);
    static inline var Poison = at(8, 6);
    static inline var PoisonDark= at(9, 6);

    static var Sword = [for (i in 1...7) at(i, 0)];
    static var Head = [for (i in 0...7) at(i, 1)];
    static var Chest = [for (i in 0...7) at(i, 2)];
    static var Legs = [for (i in 0...7) at(i, 3)];

    static inline var Copper = at(4, 9);

    static var Potion = [for (i in 0...6) at(i, 4)];
    static var Scroll = [for (i in 0...6) at(i, 5)];
    static var Ring = [for (i in 0...6) at(i, 6)];
    static var Orb = [for (i in 0...6) at(i, 7)];
    static var Statue = [for (i in 0...6) at(i, 8)];

    static inline function col_to_index(col: SpellColor) {
        return if (col == SpellColor_Gray) {
            0;
        } else if (col == SpellColor_Purple) {
            1;
        } else if (col == SpellColor_Yellow) {
            2;
        } else if (col == SpellColor_Red) {
            3;
        } else if (col == SpellColor_Blue) {
            4;
        } else if (col == SpellColor_Green) {
            5;
        } else {
            0;
        } 
    }
    
    static inline var KeyRed = at(0, 8);
    static inline var KeyOrange = at(1, 8);
    static inline var KeyGreen = at(2, 8);
    static inline var KeyBlue = at(3, 8);
}