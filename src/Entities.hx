
import haxegon.*;
import Entity;
import Spells;
import Pick;
import Stats;

typedef MarkovStruct = {
    chars: Array<String>,
    char_map: Map<String, Int>,
    char_counts: Map<Int, Int>,
    char_counts_inc: Array<Int>,
    char_chances: Map<String, Int>,
};

@:publicFields
class Entities {
// force unindent

static var locked_colors = [Col.RED, Col.ORANGE, Col.GREEN, Col.BLUE];
static var unlocked_color = Col.YELLOW;

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

static function get_element_color(element: ElementType): Int {
    return switch (element) {
        case ElementType_Physical: Col.GRAY;
        case ElementType_Fire: Col.RED;
        case ElementType_Ice: Col.BLUE;
        case ElementType_Shadow: Col.BLACK;
        case ElementType_Light: Col.YELLOW;
    }
}

static function spell_element_count(spells: Array<Spell>): Int {
    var spell_elements = new Array<ElementType>();
    for (spell in spells) {
        if (spell_elements.indexOf(spell.element) == -1) {
            spell_elements.push(spell.element);
        }
    }
    return spell_elements.length;
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
    Entity.draw_on_minimap[e] = {
        color: color,
        seen: false,
    };

    Entity.validate(e);

    return e;
}

static function unlocked_chest(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Chest';

    var color = unlocked_color;
    Entity.description[e] = 'An unlocked chest.';
    Entity.draw_char[e] = {
        char: 'C',
        color: color,
    };
    Entity.locked[e] = {
        color: color,
        need_key: false,
    };
    Entity.drop_entity[e] = {
        table: DropTable_Default,
        chance: 100,
    };
    Entity.draw_on_minimap[e] = {
        color: color,
        seen: false,
    };

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
        need_key: true,
    };
    Entity.drop_entity[e] = {
        table: DropTable_LockedChest,
        chance: 100,
    };
    Entity.draw_on_minimap[e] = {
        color: color,
        seen: false,
    };

    return e;
}

static function locked_door(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Door';

    var color = Random.pick(locked_colors);
    Entity.description[e] = 'A locked door.';
    Entity.draw_char[e] = {
        char: 'D',
        color: color,
    };
    Entity.locked[e] = {
        color: color,
        need_key: true,
    };
    Entity.draw_on_minimap[e] = {
        color: color,
        seen: false,
    };

    return e;
}

static function stairs(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Stairs';

    var color = Random.pick(locked_colors);
    Entity.description[e] = 'Stairs to the next level.';
    Entity.draw_tile[e] = Tile.Stairs;
    Entity.draw_on_minimap[e] = {
        color: Col.LIGHTBLUE,
        seen: false,
    };
    Entity.use[e] = {
        spells: [Spells.next_floor()],
        charges: 1,
        consumable: false,
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
        spells: [Spells.safe_teleport()],
        charges: 3,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.PotionPhysical;
    Entity.buy[e] = {
        cost: 3,
    };

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

static function random_element_split(element_count: Int, total: Int): Map<ElementType, Int> {
    function split2(x: Int): Array<Array<Int>> {
        return [for (i in 0...(x + 1)) [i, x - i]];
    }
    function split3(x: Int): Array<Array<Int>> {
        return [for (i in 0...(x + 1)) for (split in split2(x - i)) [i].concat(split)];
    }
    function split4(x: Int): Array<Array<Int>> {
        return [for (i in 0...(x + 1)) for (split in split3(x - i)) [i].concat(split)];
    }
    function split5(x: Int): Array<Array<Int>> {
        return [for (i in 0...(x + 1)) for (split in split4(x - i)) [i].concat(split)];
    }

    var all_splits = switch (element_count) {
        case 1: [[total]];
        case 2: split2(total);
        case 3: split3(total);
        case 4: split4(total);
        case 5: split5(total);
        default: [[0]];
    }

    var split = Random.pick(all_splits);

    var elements = Type.allEnums(ElementType);
    Random.shuffle(elements);
    while (elements.length > element_count) {
        elements.pop();
    }

    return [
    for (i in 0...element_count) if (split[i] > 0) 
        elements[i] => split[i]
    ];
}

static function random_weapon(x: Int, y: Int): Int {
    var e = Entity.make();
    Entity.set_position(e, x, y);
    Entity.draw_tile[e] = Tile.Sword1;
    var weapon_names = ['copper sword', 'iron shank', 'big hammer'];
    Entity.name[e] = 'Weapon';

    var level = Main.get_drop_entity_level();

    var attack_total = Stats.get({min: 1, max: 1, scaling: 1.0}, level); 

    var element_count: Int = 
    if (level == 0) 1;
    else if (level < 2) Random.int(1, 2);
    else if (level < 3) Random.int(1, 3);
    else Random.int(1, 4);

    var attack_split = random_element_split(element_count, attack_total);
    
    var attack_spells = [
    for (element in attack_split.keys())
        Spells.attack_buff(element, attack_split[element])
    ];

    var buff_count: Int = 
    if (level == 0) 0;
    else if (level < 2) Random.int(0, 1);
    else Random.int(1, 3);


    Entity.equipment[e] = {
        name: Random.pick(weapon_names),
        type: EquipmentType_Weapon,
        spells: attack_spells,
    };

    Entity.validate(e);

    return e;
}

static function random_armor(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.get_drop_entity_level();

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
    Entity.draw_tile[e] = armor_tiles[armor_type];

    var defense_total = Stats.get({min: 3, max: 4, scaling: 1.0}, level);

    var element_count: Int = 
    if (level == 0) Random.int(1, 2);
    else if (level < 2) Random.int(1, 3);
    else if (level < 3) Random.int(1, 4);
    else Random.int(1, 5);

    var defense_split = random_element_split(element_count, defense_total);

    var defense_spells = [
    for (element in defense_split.keys())
        Spells.defense_buff(element, defense_split[element])
    ];

    Entity.equipment[e] = {
        name: armor_names[armor_type],
        type: armor_type,
        spells: defense_spells,
    };

    Entity.validate(e);

    return e;
}

static function random_ring(x: Int, y: Int) {
    var e = Entity.make();

    var level = Main.get_drop_entity_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Ring';
    Entity.item[e] = {
        name: "Big Ring",
        type: ItemType_Ring,
        spells: [Spells.random_ring_spell(level)],
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

    var level = Main.get_drop_entity_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        name: "Healing potion",
        type: ItemType_Normal,
        spells: [],
    };
    var spells = Spells.random_potion_spells(level);
    Entity.use[e] = {
        spells: spells,
        charges: 1,
        consumable: true,
    };

    // Count spell elements
    var spell_elements = new Map<ElementType, Bool>();
    for (spell in spells) {
        spell_elements[spell.element] = true;
    }

    Entity.draw_tile[e] = 
    if (spell_element_count(spells) == 1) {
        switch(Entity.use[e].spells[0].element) {
            case ElementType_Physical: Tile.PotionPhysical;
            case ElementType_Shadow: Tile.PotionShadow;
            case ElementType_Light: Tile.PotionLight;
            case ElementType_Fire: Tile.PotionFire;
            case ElementType_Ice: Tile.PotionIce;
        }
    } else {
        Tile.PotionMixed;
    }


    Entity.validate(e);

    return e;
}

static function random_scroll(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.get_drop_entity_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Scroll';
    Entity.item[e] = {
        name: "Scroll item",
        type: ItemType_Normal,
        spells: [],
    };
    var spells = [Spells.random_scroll_spell(level)];
    Entity.use[e] = {
        spells: spells,
        charges: 1,
        consumable: true,
    };

    Entity.draw_tile[e] = 
    if (spell_element_count(spells) == 1) {
        switch(Entity.use[e].spells[0].element) {
            case ElementType_Physical: Tile.ScrollPhysical;
            case ElementType_Shadow: Tile.ScrollShadow;
            case ElementType_Light: Tile.ScrollLight;
            case ElementType_Fire: Tile.ScrollFire;
            case ElementType_Ice: Tile.ScrollIce;
        }
    } else {
        Tile.ScrollMixed;
    }

    Entity.validate(e);

    return e;
}

static function random_enemy_type(): EntityType {
    var name = generate_name();

    var level = Main.current_level;

    // Higher floors have more elemental enemies, with possibility of full elementals
    var element_ratio: Float = 
    if (level == 0) 0;
    else if (level < 2) Random.float(0, 0.33);
    else if (level < 3) Random.float(0, 0.66);
    else Random.float(0, 1);

    var attack = Stats.get({min: 1, max: 1.5, scaling: 1.0}, level); 
    var health = Stats.get({min: 1, max: 3, scaling: 1.0}, level); 
    var absorb = Stats.get({min: 0, max: 0, scaling: 1.0}, level); 

    var attack_physical = Std.int(Math.floor(attack * (1 - element_ratio)));
    var attack_elemental = Std.int(Math.floor(attack * element_ratio));

    var absorb_physical = Std.int(Math.floor(absorb * (1 - element_ratio)));
    var absorb_elemental = Std.int(Math.floor(absorb * element_ratio));

    var agression_type = Pick.value([
        {v: AggressionType_Aggressive, c: 4.0},
        {v: AggressionType_Neutral, c: (4.0 / (1 + level))},
        {v: AggressionType_Passive, c: (1.0 / (1 + level))},
        ]);

    var move_type = Pick.value([
        {v: MoveType_Astar, c: 1.0},
        {v: MoveType_Straight, c: 1.0},
        {v: MoveType_Random, c: (1.0 / (1 + level))},
        ]);

    var element = Random.pick([ElementType_Fire, ElementType_Ice, ElementType_Light, ElementType_Shadow]);

    // Only color according to element if some stat is non-zero
    var color = 
    if (attack_elemental > 0 || absorb_elemental > 0) {
        get_element_color(element);
    } else {
        get_element_color(ElementType_Physical);
    }

    // trace('ENEMY lvl$level: hp=$health,atk=$attack_physical+$attack_elemental,abs=$absorb_physical+$absorb_elemental');

    return {
        name: name,
        description: 'It\'s a $name.',
        draw_tile: Entity.NULL_INT,
        draw_char: {
            char: name.charAt(0),
            color: color,
        },
        equipment: null,
        item: null,
        use: null,
        combat: {
            health: health, 
            attack: [
            ElementType_Physical => attack_physical,
            element => attack_elemental,
            ], 
            absorb: [
            ElementType_Physical => absorb_physical,
            element => absorb_elemental,
            ], 
            message: '$name defends itself.',
            aggression: agression_type,
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
            type: move_type,
            cant_move: false,
        },
        locked: null,
        unlocker: null,
        draw_on_minimap: null,
        buy: null,
    };
} 

static function random_statue(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level;

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Statue';
    Entity.use[e] = {
        spells: Spells.random_statue_spells(level),
        charges: 1,
        consumable: false,
    };

    Entity.draw_tile[e] = switch (Entity.use[e].spells[0].element) {
        case ElementType_Physical: Tile.StatuePhysical;
        case ElementType_Shadow: Tile.StatueShadow;
        case ElementType_Light: Tile.StatueLight;
        case ElementType_Fire: Tile.StatueFire;
        case ElementType_Ice: Tile.StatueIce;
    }

    Entity.validate(e);

    return e;
}

}