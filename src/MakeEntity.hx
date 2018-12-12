
import haxegon.*;
import Entity;

@:publicFields
class MakeEntity {
// NOTE: force unindent

static function snail(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Snail';
    Entity.drop_item[e] = {
        type: 'potion', 
        chance: 20
    };
    Entity.draw_char[e] = {
        char: 'S',
        color: Col.RED
    };
    Entity.description[e] = 'A green snail with a brown shell.';
    Entity.talk[e] = 'You try talking to the Snail, it doesn\'t respond.';
    Entity.give_copper_on_death[e] = {
        chance: 50, 
        min: 1, 
        max: 1
    };
    Entity.combat[e] = {
        health: 2, 
        attack: 1, 
        message: 'Snail silently defends itself.',
        aggression: AggressionType_Aggressive,
        attacked_by_player: false,
    };
    Entity.move[e] = {
        type: MoveType_Astar,
        cant_move: false
    };

    Entity.validate(e);

    return e;
}

static function bear(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Bear';
    Entity.draw_char[e] = {
        char: 'B',
        color: Col.RED
    };
    Entity.description[e] = 'A brown bear, looks cute.';
    Entity.talk[e] = 'You try talking to the Bear, it roars angrily at you.';
    Entity.give_copper_on_death[e] = {
        chance: 50, 
        min: 1, 
        max: 2
    };
    Entity.combat[e] = {
        health: 2, 
        attack: 2, 
        message: 'Bear roars angrily at you.',
        aggression: AggressionType_Aggressive,
        attacked_by_player: false,
    };
    Entity.drop_item[e] = {
        type: 'potion', 
        chance: 20
    };

    Entity.validate(e);

    return e;
}

static function armor(x: Int, y: Int, armor_type: ArmorType): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    var level = Random.int(1, 3);

    var armor_name = [
    ArmorType_Head => ['leather helmet', 'copper helmet', 'iron helmet', 'obsidian helmet'],
    ArmorType_Chest => ['leather chestplate', 'copper chestplate', 'iron chestplate', 'obsidian chestplate'],
    ArmorType_Legs => ['leather pants', 'copper pants', 'iron pants', 'obsidian pants'],
    ];
    var armor_tile = [
    ArmorType_Head => [Tile.Head1, Tile.Head2, Tile.Head3, Tile.Head4],
    ArmorType_Chest => [Tile.Chest1, Tile.Chest2, Tile.Chest3, Tile.Chest4],
    ArmorType_Legs => [Tile.Legs1, Tile.Legs2, Tile.Legs3, Tile.Legs4],
    ];

    Entity.name[e] = 'Armor';
    Entity.equipment[e] = {
        name: armor_name[armor_type][level - 1],
    };
    Entity.armor[e] = {
        type: armor_type, 
        defense: level * 4
    };
    Entity.draw_tile[e] = armor_tile[armor_type][level - 1];

    Entity.validate(e);

    return e;
}

static function sword(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    var level = Random.int(1, 3);

    var weapon_type = WeaponType_Sword;

    var weapon_name = [
    WeaponType_Sword => ['copper sword', 'iron sword', 'obsidian sword'],
    ];
    var weapon_tile = [
    WeaponType_Sword => [Tile.Sword2, Tile.Sword3, Tile.Sword4],
    ];

    Entity.name[e] = 'Weapon';
    Entity.equipment[e] = {
        name: weapon_name[weapon_type][level - 1],
    };
    Entity.weapon[e] = {
        type: weapon_type, 
        attack: Main.player_base_attack + level
    };
    Entity.draw_tile[e] = weapon_tile[weapon_type][level - 1];

    Entity.validate(e);

    return e;
}

static function fountain(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Fountain';
    Entity.use[e] = {
        type: UseType_Heal,
        value: 2, 
        charges: 1,
        consumable: false,
    };
    Entity.draw_char[e] = {
        char: 'F',
        color: Col.WHITE
    };
    Entity.description[e] = 'A beautiful fountain. Water flowing through it looks magical.';

    Entity.validate(e);

    return e;
}

static function potion(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        name: "Healing potion"
    };
    Entity.use[e] = {
        type: UseType_Heal,
        value: 2,
        charges: 1,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.Potion;

    Entity.validate(e);

    return e;
}

static function item(x: Int, y: Int, item_type: String) {
    if (item_type == 'armor') {
        armor(x, y, ArmorType_Head);
    } else if (item_type == 'weapon') {
        sword(x, y);
    } else if (item_type == 'potion') {
        potion(x, y);
    }
}

static function chest(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Chest';
    Entity.draw_char[e] = {
        char: 'C',
        color: Col.YELLOW
    };
    Entity.drop_item[e] = {
        type: 'weapon', 
        chance: 100
    };
    Entity.description[e] = 'An unlocked chest.';
    Entity.combat[e] = {
        health: 1, 
        attack: 0, 
        message: 'Chest opens with a creak.',
        aggression: AggressionType_Passive,
        attacked_by_player: false,
    };

    return e;
}
}