
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Black = at(1, 0);
    static inline var Ground = at(2, 0);
    static inline var DarkerGround = at(3, 0);
    static inline var Stairs = at(4, 0);
    static inline var Poison = at(5, 0);
    static inline var Lava = at(6, 0);
    static inline var Magical = at(7, 0);
    static inline var Ailment = at(8, 0);
    static inline var Ice = at(9, 0);

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

    static inline var StatuePhysical = at(0, 9);
    static inline var StatueShadow = at(1, 9);
    static inline var StatueLight = at(2, 9);
    static inline var StatueFire = at(3, 9);
    static inline var StatueIce = at(4, 9);

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
    static inline var Sword6 = at(6, 5);

    static inline var KeyRed = at(0, 8);
    static inline var KeyOrange = at(1, 8);
    static inline var KeyGreen = at(2, 8);
    static inline var KeyBlue = at(3, 8);

}