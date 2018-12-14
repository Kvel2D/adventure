
import haxegon.*;
import Entity;

@:publicFields
class MakeEntity {
// NOTE: force unindent

static var generated_names = new Array<String>();
static var vowels = ['a', 'e', 'i', 'o', 'u'];
static var consonants = ['y', 'q', 'w', 'r', 't', 'p', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm'];

static function generate_name(): String {
    var name = '';
    while (generated_names.indexOf(name) != -1 || name == '') {
        var consonant_first = Random.bool();
        if (consonant_first) {
            name += consonants[Random.int(0, consonants.length - 1)];
            name += vowels[Random.int(0, vowels.length - 1)];
        } else {
            name += vowels[Random.int(0, vowels.length - 1)];
            name += consonants[Random.int(0, consonants.length - 1)];
        }
        consonant_first = Random.bool();
        if (consonant_first) {
            name += consonants[Random.int(0, consonants.length - 1)];
            name += vowels[Random.int(0, vowels.length - 1)];
        } else {
            name += vowels[Random.int(0, vowels.length - 1)];
            name += consonants[Random.int(0, consonants.length - 1)];
        }
        name = name.toUpperCase();
    }
    return name;
}

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
        attack: [
        ElementType_Physical => 1,
        ], 
        absorb: [
        ElementType_Physical => 0,
        ElementType_Ice => 2,
        ], 
        message: 'Snail silently defends itself.',
        aggression: AggressionType_Aggressive,
        attacked_by_player: false,
    };
    Entity.move[e] = {
        type: MoveType_Straight,
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
        attack: [
        ElementType_Physical => 2,
        ],
        absorb: [
        ElementType_Physical => 0,
        ElementType_Ice => 2,
        ], 
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

static function armor(x: Int, y: Int, armor_type: EquipmentType): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    var level = Random.int(1, 3);

    var armor_name = [
    EquipmentType_Head => ['leather helmet', 'copper helmet', 'iron helmet', 'obsidian helmet'],
    EquipmentType_Chest => ['leather chestplate', 'copper chestplate', 'iron chestplate', 'obsidian chestplate'],
    EquipmentType_Legs => ['leather pants', 'copper pants', 'iron pants', 'obsidian pants'],
    ];
    var armor_tile = [
    EquipmentType_Head => [Tile.Head1, Tile.Head2, Tile.Head3, Tile.Head4],
    EquipmentType_Chest => [Tile.Chest1, Tile.Chest2, Tile.Chest3, Tile.Chest4],
    EquipmentType_Legs => [Tile.Legs1, Tile.Legs2, Tile.Legs3, Tile.Legs4],
    ];

    Entity.name[e] = 'Armor';
    Entity.equipment[e] = {
        name: armor_name[armor_type][level - 1],
        type: armor_type,
        spells: [buff_phys_def_spell(4 * level)],
    };
    Entity.draw_tile[e] = armor_tile[armor_type][level - 1];

    Entity.validate(e);

    return e;
}

static function sword(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    var level = Random.int(1, 3);

    var weapon_type = EquipmentType_Weapon;

    var weapon_name = [
    EquipmentType_Weapon => ['copper sword', 'iron sword', 'obsidian sword'],
    ];
    var weapon_tile = [
    EquipmentType_Weapon => [Tile.Sword2, Tile.Sword3, Tile.Sword4],
    ];

    Entity.name[e] = 'Weapon';
    Entity.equipment[e] = {
        name: weapon_name[weapon_type][level - 1],
        type: EquipmentType_Weapon,
        spells: [increase_attack_everyturn()],
    };
    Entity.draw_tile[e] = weapon_tile[weapon_type][level - 1];

    Entity.validate(e);

    return e;
}

static function fountain(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Fountain';
    // Entity.use[e] = {
    //     type: UseType_Heal,
    //     value: 2, 
    //     charges: 1,
    //     consumable: false,
    // };
    Entity.draw_char[e] = {
        char: 'F',
        color: Col.WHITE
    };
    Entity.description[e] = 'A beautiful fountain. Water flowing through it looks magical.';

    Entity.validate(e);

    return e;
}

static function random_spell(): Spell {
    return {
        type: Random.pick(Type.allEnums(SpellType)),
        element: Random.pick(Type.allEnums(ElementType)),
        duration_type: Random.pick(Type.allEnums(SpellDuration)),
        duration: Random.int(1, 10),
        interval: 1,
        interval_current: 0,
        value: Random.int(1, 5),
        origin_name: "noname",
    }
}

static function increase_attack_everyturn(): Spell {
    return {
        type: SpellType_ModAttack,
        element: ElementType_Ice,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE,
        interval: 1,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function health_instant(): Spell {
    return {
        type: SpellType_ModHealth,
        element: ElementType_Light,
        duration_type: SpellDuration_Permanent,
        duration: 10,
        interval: 0,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function heal_overtime(): Spell {
    return {
        type: SpellType_ModHealth,
        element: ElementType_Light,
        duration_type: SpellDuration_EveryTurn,
        duration: 4,
        interval: 1,
        interval_current: 0,
        value: 1,
        origin_name: "noname",
    }
}

static function heal_overattack(): Spell {
    return {
        type: SpellType_ModHealth,
        element: ElementType_Light,
        duration_type: SpellDuration_EveryAttack,
        duration: 4,
        interval: 1,
        interval_current: 0,
        value: 1,
        origin_name: "noname",
    }
}

static function increase_healthmax_forever(): Spell {
    return {
        type: SpellType_ModHealthMax,
        element: ElementType_Light,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 5,
        origin_name: "noname",
    }
}

static function increase_healthmax_everyturn(): Spell {
    return {
        type: SpellType_ModHealthMax,
        element: ElementType_Light,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE,
        interval: 1,
        interval_current: 0,
        value: 6,
        origin_name: "noname",
    }
}

static function health_potion(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        name: "Healing potion",
        type: ItemType_Normal,
        spells: [],
    };
    Entity.use[e] = {
        spells: [health_instant()],
        charges: 1,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.Potion;

    Entity.validate(e);

    return e;
}

static function ring(x: Int, y: Int) {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Ring';
    Entity.item[e] = {
        name: "Big Ring",
        type: ItemType_Ring,
        spells: [test_spell()],
    };
    Entity.use[e] = {
        spells: [health_instant()],
        charges: 1,
        consumable: true,
    };
    Entity.draw_char[e] = {
        char: 'R',
        color: Col.YELLOW
    };

    Entity.validate(e);
}

static function item(x: Int, y: Int, item_type: String) {
    if (item_type == 'armor') {
        armor(x, y, EquipmentType_Head);
    } else if (item_type == 'weapon') {
        sword(x, y);
    } else if (item_type == 'potion') {
        health_potion(x, y);
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
        attack: [
        ElementType_Physical => 0
        ], 
        absorb: [
        ElementType_Physical => 0
        ], 
        message: 'Chest opens with a creak.',
        aggression: AggressionType_Passive,
        attacked_by_player: false,
    };

    return e;
}

static function poison_spell(): Spell {
    return {
        type: SpellType_ModHealth,
        element: ElementType_Physical,
        duration_type: SpellDuration_EveryTurn,
        duration: 40,
        interval: 4,
        interval_current: 0,
        value: 1,
        origin_name: "noname",
    }
}

static function buff_phys_def_spell(value: Int): Spell {
    return {
        type: SpellType_ModDefense,
        element: ElementType_Physical,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

static function test_spell(): Spell {
    return {
        type: SpellType_ModHealth,
        element: ElementType_Physical,
        duration_type: SpellDuration_EveryTurn,
        duration: 5,
        interval: 5,
        interval_current: 0,
        value: 1,
        origin_name: "noname",
    }
}

static function test_potion(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        name: "Test potion",
        type: ItemType_Normal,
        spells: [],
    };
    Entity.use[e] = {
        spells: [test_spell()],
        charges: 1,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.Potion;

    Entity.validate(e);

    return e;
}

}