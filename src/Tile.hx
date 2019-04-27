
import Spells;

@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Black = at(9, 7);

    static var Ground = at(7, 0);
    static var Shadow = at(8, 0);
    static var Wall = at(9, 0);

    static var LevelPalette = at(9, 1);
    static inline var LevelPalette_count = 5;

    static inline var Stairs = at(8, 1);
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
    
    static inline var KeyRed = at(0, 9);
    static inline var KeyOrange = at(1, 9);
    static inline var KeyGreen = at(2, 9);
    static inline var KeyBlue = at(3, 9);

    static inline var UnlockedChest = at(6, 4);
    static inline var RedChest = at(6, 5);
    static inline var OrangeChest = at(6, 6);
    static inline var GreenChest = at(6, 7);
    static inline var BlueChest = at(6, 8);

    static inline var Golem = at(7, 1);
    static inline var Skeleton = at(7, 2);
    static inline var Imp = at(7, 3);
    static inline var Merchant = at(7, 4);

    static var Enemy = [for (i in 0...5) at(7, 5 + i)];
}