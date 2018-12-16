
import haxegon.*;
import Entity;
import Spells;
import Pick;

typedef MarkovStruct = {
    chars: Array<String>,
    char_map: Map<String, Int>,
    char_counts: Map<Int, Int>,
    char_counts_inc: Array<Int>,
    char_chances: Map<String, Int>,
};

@:publicFields
class Entities {
// NOTE: force unindent

static var locked_colors = [Col.RED, Col.ORANGE, Col.GREEN, Col.BLUE];

static var firsts: MarkovStruct = {
    chars: new Array<String>(),
    char_map: new Map<String, Int>(),
    char_counts: new Map<Int, Int>(),
    char_counts_inc: new Array<Int>(),
    char_chances: new Map<String, Int>(),
};

static var pairs = new Map<String, MarkovStruct>();
static var pairs_chars = new Array<String>();
static var pairs_char_map = new Map<String, Int>();

static inline var EOF = '0';

static function read_name_corpus() {
    function count_char(char: String, s: MarkovStruct) {
        if (!s.char_map.exists(char)) {
            s.chars.push(char);
            s.char_map[char] = s.chars.length - 1;
            s.char_counts[s.chars.length - 1] = 1;
        } else {
            var index = s.char_map[char];
            s.char_counts[index]++;
        }
    }

    function add_up_increments(s: MarkovStruct) {
        var total: Int = 0;
        for (i in 0...s.chars.length) {
            total += s.char_counts[i];
            s.char_counts_inc.push(total);
        }
    }

    var corpus = Data.loadtext('name_corpus.txt');

    for (name in corpus) {
        count_char('${name.charAt(0)}${name.charAt(1)}', firsts);
    }

    add_up_increments(firsts);

    for (name in corpus) {
        for (i in 0...name.length) {
            var j = 0;

            while (j < name.length - 2) {
                var first = name.charAt(j);
                var second = name.charAt(j + 1);

                var third = if (j + 2 == name.length) {
                    EOF;
                } else {
                    name.charAt(j + 2);
                }

                var pair = first + second;

                if (!pairs_char_map.exists(pair)) {
                    pairs[pair] = {
                        chars: new Array<String>(),
                        char_map: new Map<String, Int>(),
                        char_counts: new Map<Int, Int>(),
                        char_counts_inc: new Array<Int>(),
                        char_chances: new Map<String, Int>(),
                    };

                    pairs_chars.push(pair);
                    pairs_char_map[pair] = pairs_chars.length - 1;
                }

                if (third != second && third != first) {
                    count_char(third, pairs[pair]);
                }
                j++;
            }
        }
    }

    for (i in 0...pairs_chars.length) {
        add_up_increments(pairs[pairs_chars[i]]);
    }
}

static var generated_names = new Array<String>();

static function generate_name(): String {
    var name = '';
    while (generated_names.indexOf(name) != -1 || name == '') {
        name = generate_name_markov();
    }
    return name;
}

static function generate_name_markov(): String {
    function random_char(struct: MarkovStruct): String {
        var total = struct.char_counts_inc[struct.char_counts_inc.length - 1];
        var k = Random.int(0, total);
        for (i in 0...struct.chars.length) {
            if (k <= struct.char_counts_inc[i]) {
                return struct.chars[i];
            }
        }

        return EOF;
    }

    var str = "";

    var first_pair = random_char(firsts);
    while (!pairs.exists(first_pair) || pairs[first_pair].chars.length == 0) {
        first_pair = random_char(firsts);
    }

    var count = 2;
    str += first_pair;

    var prev_prev = first_pair.charAt(0);
    var prev = first_pair.charAt(1);
    var k = Random.int(4, 10);
    while (k > 0) {
        var pair = prev_prev + prev;
        var next = "";
        if (pairs.exists(pair)) {
            next = random_char(pairs[pair]);
            count++;
        }

        prev_prev = prev;
        prev = next;
        if (!pairs.exists(pair) || next == EOF) {
            break;
        } else {
            str += next;
        }
        k--;
    }

    return str;
}

static var vowels = ['a', 'e', 'i', 'o', 'u'];
static var consonants = ['y', 'q', 'w', 'r', 't', 'p', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm'];

static function generate_name_old(): String {
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

static function get_element_color(element: ElementType): Int {
    return switch (element) {
        case ElementType_Physical: Col.GREEN;
        case ElementType_Fire: Col.RED;
        case ElementType_Ice: Col.BLUE;
        case ElementType_Shadow: Col.BLACK;
        case ElementType_Light: Col.YELLOW;
    }
}

static function snail(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Snail';
    Entity.drop_entity[e] = {
        table: DropTable_Default,
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
    Entity.drop_entity[e] = {
        table: DropTable_Default,
        chance: 20,
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
        spells: [Spells.buff_phys_def(ElementType_Physical, 4 * level)],
    };
    Entity.draw_tile[e] = armor_tile[armor_type][level - 1];

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
        spells: [Spells.health_instant()],
        charges: 1,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.PotionPhysical;

    Entity.validate(e);

    return e;
}

static function key(x: Int, y: Int, color: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Key';
    Entity.item[e] = {
        name: "Key",
        type: ItemType_Normal,
        spells: [],
    };
    Entity.draw_tile[e] = if (color == Col.RED) {
        Tile.KeyRed;
    } else if (color == Col.ORANGE) {
        Tile.KeyOrange;
    } else if (color == Col.GREEN) {
        Tile.KeyGreen;
    } else if (color == Col.BLUE) {
        Tile.KeyBlue;
    } else {
        Tile.None;
    }
    Entity.unlocker[e] = {
        color: color,
    };

    Entity.validate(e);

    return e;
}

static function locked_chest(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Chest';

    var color = Random.pick(locked_colors);
    Entity.description[e] = 'A locked chest.';
    Entity.draw_char[e] = {
        char: 'C',
        color: color,
    };
    Entity.locked[e] = {
        color: color,
        seen: false,
    };
    Entity.drop_entity[e] = {
        table: DropTable_LockedChest,
        chance: 100,
    };

    return e;
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
        spells: [{
        type: SpellType_ModDefense,
        element: ElementType_Physical,
        duration_type: SpellDuration_EveryTurn,
        duration: 30,
        interval: 1,
        interval_current: 0,
        value: 1,
        origin_name: "noname",
    }],
        charges: 2,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.PotionPhysical;

    Entity.validate(e);

    return e;
}

static function entity_from_table(x: Int, y: Int, droptable: DropTable): Int {
    switch (droptable) {
        // For common mobs chests
        case DropTable_Default: {
            return (Pick.value([
                {v: Entities.random_weapon, c: 1.0},
                {v: Entities.random_armor, c: 3.0},
                {v: Entities.random_potion, c: 6.0},
                {v: Entities.random_ring, c: 2.0},
                ])(x, y));
        }
        // For locked chests
        case DropTable_LockedChest: {
            return (Pick.value([
                {v: Entities.random_weapon, c: 1.0},
                {v: Entities.random_armor, c: 3.0},
                {v: Entities.random_ring, c: 1.0},
                ])(x, y));
        }
    };
}

static function random_weapon(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);

    var tile = Tile.Sword1;

    var weapon_names = ['copper sword', 'iron shank', 'big hammer'];

    Entity.name[e] = 'Weapon';
    Entity.equipment[e] = {
        name: Random.pick(weapon_names),
        type: EquipmentType_Weapon,
        spells: [Spells.attack_buff(ElementType_Physical, 1)],
    };
    Entity.draw_tile[e] = tile;

    Entity.validate(e);

    return e;
}

static function random_armor(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);

    var armor_type = Random.pick([EquipmentType_Head, EquipmentType_Chest, EquipmentType_Legs]);

    var armor_names = [
    EquipmentType_Head => 'helmet', 
    EquipmentType_Chest => 'chainmail vest', 
    EquipmentType_Legs => 'pants',
    ];
    var armor_tiles = [
    EquipmentType_Head => Tile.Head1, 
    EquipmentType_Chest => Tile.Chest1,  
    EquipmentType_Legs => Tile.Legs1, 
    ];

    Entity.name[e] = 'Armor';
    Entity.equipment[e] = {
        name: armor_names[armor_type],
        type: armor_type,
        spells: [Spells.buff_phys_def(ElementType_Physical, Random.int(2, 4))],
    };
    Entity.draw_tile[e] = armor_tiles[armor_type];

    Entity.validate(e);

    return e;
}

static function random_ring(x: Int, y: Int) {
    var e = Entity.make();
    Entity.set_position(e, x, y);
    Entity.name[e] = 'Ring';
    Entity.item[e] = {
        name: "Big Ring",
        type: ItemType_Ring,
        spells: [Spells.random_ring_spell()],
    };
    // TODO: make some rings have a use
    // Entity.use[e] = {
    //     spells: [],
    //     charges: 1,
    //     consumable: false,
    // };
    Entity.draw_char[e] = {
        char: 'R',
        color: Col.YELLOW
    };

    Entity.validate(e);
}

static function random_potion(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        name: "Healing potion",
        type: ItemType_Normal,
        spells: [],
    };
    Entity.use[e] = {
        spells: [Spells.random_potion_spell()],
        charges: 1,
        consumable: true,
    };

    // TODO: figure out what tile to pick for potions with multiple spells that potentially have different elements
    Entity.draw_tile[e] = switch(Entity.use[e].spells[0].element) {
        case ElementType_Physical: Tile.PotionPhysical;
        case ElementType_Shadow: Tile.PotionShadow;
        case ElementType_Light: Tile.PotionLight;
        case ElementType_Fire: Tile.PotionFire;
        case ElementType_Ice: Tile.PotionIce;
    }

    Entity.validate(e);

    return e;
}

static function random_scroll(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Scroll';
    Entity.item[e] = {
        name: "Scroll item",
        type: ItemType_Normal,
        spells: [],
    };
    Entity.use[e] = {
        spells: [Spells.random_scroll_spell()],
        charges: 1,
        consumable: true,
    };

    Entity.draw_tile[e] = switch(Entity.use[e].spells[0].element) {
        case ElementType_Physical: Tile.ScrollPhysical;
        case ElementType_Shadow: Tile.ScrollShadow;
        case ElementType_Light: Tile.ScrollLight;
        case ElementType_Fire: Tile.ScrollFire;
        case ElementType_Ice: Tile.ScrollIce;
    }

    Entity.validate(e);

    return e;
}

static function random_enemy_type(element: ElementType): EntityType {
    var name = generate_name();

    return {
        name: name,
        description: 'It\'s a $name.',
        draw_tile: Entity.NULL_INT,
        draw_char: {
            char: name.charAt(0),
            color: get_element_color(element),
        },
        equipment: null,
        item: null,
        use: null,
        combat: {
            health: Random.int(1, 3) + Main.current_level, 
            attack: [
            element => Random.int(1, 2) + Main.current_level,
            ], 
            absorb: [
            element => 0 + Random.int(0, Main.current_level),
            ], 
            message: '$name defends itself.',
            aggression: Pick.value([
                {v: AggressionType_Aggressive, c: 6.0},
                {v: AggressionType_Neutral, c: 3.0},
                {v: AggressionType_Passive, c: 1.0},
                ]),
            attacked_by_player: false,
        },
        // TODO: think about what percentage is good and whether to vary percentages by mob
        drop_entity: {
            table: DropTable_Default, 
            chance: 10,
        },
        talk: Entity.NULL_STRING,
        give_copper_on_death: {
            chance: 50, 
            min: 1, 
            max: 1,
        },
        move: {
            type: Random.pick(Type.allEnums(MoveType)),
            cant_move: false,
        },
        locked: null,
        unlocker: null,
    };
} 

}