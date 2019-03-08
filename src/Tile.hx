
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Black = at(1, 0);

    static var Stairs = [for (i in 0...5) at(7, i)];
    static var Ground = [for (i in 0...5) at(8, i)];
    static var GroundDark = [for (i in 0...5) at(9, i)];

    static inline var Teleport = at(8, 5);
    static inline var TeleportDark = at(9, 5);
    static inline var Poison = at(8, 6);
    static inline var PoisonDark= at(9, 6);

    static var Head = [for (i in 0...7) at(i, 2)];
    static var Chest = [for (i in 0...7) at(i, 3)];
    static var Legs = [for (i in 0...7) at(i, 4)];
    static var Sword = [for (i in 0...7) at(i, 5)];

    static inline var Copper = at(4, 8);

    static inline var PotionPhysical = at(0, 1);
    static inline var PotionShadow = at(1, 1);
    static inline var PotionLight = at(2, 1);
    static inline var PotionFire = at(3, 1);
    static inline var PotionIce = at(4, 1);
    static inline var PotionHealing = at(5, 1);
    static inline var PotionMixed = at(6, 1);

    static inline var ScrollPhysical = at(0, 7);
    static inline var ScrollShadow = at(1, 7);
    static inline var ScrollLight = at(2, 7);
    static inline var ScrollFire = at(3, 7);
    static inline var ScrollIce = at(4, 7);
    static inline var ScrollMixed = at(5, 7);

    static inline var StatueSera = at(0, 9);
    static inline var StatueSubere = at(1, 9);
    static inline var StatueOllopa = at(2, 9);
    static inline var StatueSuthaephes = at(3, 9);
    static inline var StatueEnohik = at(4, 9);

    static inline var KeyRed = at(0, 8);
    static inline var KeyOrange = at(1, 8);
    static inline var KeyGreen = at(2, 8);
    static inline var KeyBlue = at(3, 8);

}