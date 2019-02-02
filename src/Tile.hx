
@:publicFields
class Tile {
    static inline var tileset_width = 10;
    static inline function at(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var None = at(0, 0); // for bugged/invisible things
    static inline var Black = at(1, 0);
    static inline var Teleport = at(2, 0);
    static inline var Poison = at(3, 0);

    static inline var Stairs0 = at(7, 0);
    static inline var Ground0 = at(8, 0);
    static inline var GroundDark0 = at(9, 0);
    static inline var Stairs1 = at(7, 1);
    static inline var Ground1 = at(8, 1);
    static inline var GroundDark1 = at(9, 1);
    static inline var Stairs2 = at(7, 2);
    static inline var Ground2 = at(8, 2);
    static inline var GroundDark2 = at(9, 2);
    static inline var Stairs3 = at(7, 3);
    static inline var Ground3 = at(8, 3);
    static inline var GroundDark3 = at(9, 3);
    static inline var Stairs4 = at(7, 4);
    static inline var Ground4 = at(8, 4);
    static inline var GroundDark4 = at(9, 4);

    static var Stairs = [Stairs0, Stairs1, Stairs2, Stairs3, Stairs4];
    static var Ground = [Ground0, Ground1, Ground2, Ground3, Ground4];
    static var GroundDark = [GroundDark0, GroundDark1, GroundDark2, GroundDark3, GroundDark4];

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