
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
static var generated_first_chars = new Array<String>();

static function generate_name(): String {
    // Generate name that wasn't generated before and which starts with a unique char for this level
    var name = '';
    while (generated_names.indexOf(name) != -1 || generated_first_chars.indexOf(name.charAt(0)) != -1 || name == '') {
        name = generate_name_markov();
    }
    generated_names.push(name);
    generated_first_chars.push(name.charAt(0));
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
        flavor_text: 'You ascend the stairs.',
        need_target: false,
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
        spells: [Spells.copy_item()],
        charges: 3,
        consumable: true,
        flavor_text: '',
        need_target: true,
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
                {v: Entities.random_armor, c: 6.0},
                {v: Entities.random_potion, c: 6.0},
                {v: Entities.random_ring, c: 2.0},
                ])(x, y));
        }
        // For locked chests
        case DropTable_LockedChest: {
            return (Pick.value([
                {v: Entities.random_weapon, c: 1.0},
                {v: Entities.random_armor, c: 6.0},
                {v: Entities.random_ring, c: 1.0},
                ])(x, y));
        }
    };
}

static function random_weapon(x: Int, y: Int): Int {
    var level = Main.get_drop_entity_level();
    
    var e = Entity.make();
    Entity.set_position(e, x, y);

    var weapon_tiles = [Tile.Sword1, Tile.Sword2, Tile.Sword3, Tile.Sword4, Tile.Sword5, Tile.Sword6];
    Entity.draw_tile[e] = weapon_tiles[Math.floor(Math.min(5, level / 2))];

    var weapon_names = ['copper sword', 'iron shank', 'big hammer'];
    Entity.name[e] = 'Weapon';

    var attack_total = Stats.get({min: 1, max: 1, scaling: 1.0}, level); 

    var attack_spells = [
    Spells.attack_buff(attack_total)
    ];

    /*
    SpellType_RandomTeleport
    SpellType_SafeTeleport
    SpellType_AoeDamage
    SpellType_Invisibility
    everyattack +SpellType_ModHealth (leech)
    everyattack -SpellType_ModHealth (damages player)
    everyattack SpellType_EnergyShield (infrequent)

    need to make weapon usable if it got usable spells
    */

    // Need to split spells into use/buff??
    // i guess for single pick randomly between use or buff
    // for double do use + buff or 2 buffs
    
    // var buff_count: Int = Pick.value([
    //     {v: 0, c: 1,
    //     {v: 1, c: 0.5 * level,
    //     {v: 2, c: Math.max(0, 0.55 * (level - 1)),
    //     ]);
    var buff_count = 1;

    var buff_spells = new Array<Spell>();
    for (i in 0...buff_count) {
        buff_spells.push(Spells.random_weapon_buff());
    }

    Entity.use[e] = {
        spells: buff_spells,
        charges: 3,
        consumable: false,
        flavor_text: 'You use weapon.',
        need_target: false,
    };

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
    EquipmentType_Head => [Tile.Head1, Tile.Head2, Tile.Head3, Tile.Head4, Tile.Head5, Tile.Head6],
    EquipmentType_Chest => [Tile.Chest1, Tile.Chest2, Tile.Chest3, Tile.Chest4, Tile.Chest5, Tile.Chest6],
    EquipmentType_Legs => [Tile.Legs1, Tile.Legs2, Tile.Legs3, Tile.Legs4, Tile.Legs5, Tile.Legs6],
    ];
    Entity.name[e] = 'Armor';
    Entity.draw_tile[e] = armor_tiles[armor_type][Math.floor(Math.min(5, level / 2))];

    var defense_total = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
    
    /*
    SpellType_ModHealthMax
    ModAttack
    ModDefense

    helmet only
    SpellType_UncoverMap
    SpellType_Nolos
    SpellType_ShowThings

    legs only
    SpellType_RandomTeleport
    SpellType_SafeTeleport
    SpellType_Noclip
    SpellType_NextFloor
    SpellType_ModMoveSpeed

    chest only
    SpellType_Invisibility
    SpellType_EnergyShield

    */

    var defense_spells = [
    Spells.defense_buff(defense_total)
    ];

    Entity.equipment[e] = {
        name: armor_names[armor_type],
        type: armor_type,
        spells: defense_spells,
    };

    Entity.validate(e);

    return e;
}

static function random_ring(x: Int, y: Int): Int {
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

    return e;
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
    var has_healing_spell = false;
    for (s in spells) {
        if (s.type == SpellType_ModHealth && s.value > 0) {
            has_healing_spell = true;
            break;
        }
    }
    Entity.use[e] = {
        spells: spells,
        charges: 1,
        consumable: true,
        flavor_text: 'You chug the potion.',
        need_target: false,
    };

    // TODO: diversify potion icons based on potion spell
    Entity.draw_tile[e] = Tile.PotionHealing;

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
        flavor_text: 'You read the scroll aloud.',
        // NOTE: incorrect if there are multiple spells and one of them needs a target, though I can't think of an item like that yet
        need_target: switch (spells[0].type) {
            case SpellType_ModUseCharges: true;
            case SpellType_CopyItem: true;
            default: false;
        },
    };

    // TODO: diversify scroll icons based on scroll spell
    Entity.draw_tile[e] = Tile.ScrollPhysical;

    Entity.validate(e);

    return e;
}

static function random_enemy_type(): EntityType {
    var name = generate_name();

    var level = Main.current_level;

    // Ranges are squared, this means that each range covers a square area
    var range: Int = if (level == 0) {
        1;
    } else {
        Pick.value([
            {v: 1, c: 8.0},
            {v: 2, c: 2.0},
            {v: 3, c: 1.0},
            ]);
    }

    // Long-ranged mobs have weaker attack to compensate
    // 0.75 of regular for range = 2
    // 0.5 of regular for range = 3
    // var range_factor = if (range >= 3) 0.5 else if (range >= 2) 0.75 else 1.0;
    var range_factor = 1.0;
    var attack = Stats.get({min: 1 * range_factor, max: 1.5 * range_factor, scaling: 1.0}, level);
    var health = Stats.get({min: 4, max: 5, scaling: 1.0}, level); 

    var absorb = 0;

    // TODO: diversify enemy colors
    var color = Col.GRAY;

    var aggression_type = Pick.value([
        {v: AggressionType_Aggressive, c: 1.0},
        {v: AggressionType_NeutralToAggressive, c: 0.1},
        {v: AggressionType_Neutral, c: (0.1 / (1 + level))},
        {v: AggressionType_Passive, c: (0.1 / (1 + level))},
        ]);

    // NeutralToAggressive start out stationary
    var move: Move = if (aggression_type == AggressionType_NeutralToAggressive) {
        null;
    } else if (aggression_type == AggressionType_Aggressive) {
        {
            type: Pick.value([
                {v: MoveType_Astar, c: 1.0},
                {v: MoveType_Straight, c: 1.0},
                {v: MoveType_StayAway, c: 0.25},
                {v: MoveType_Random, c: (1.0 / (1 + level))},
                ]),
            cant_move: false,
            successive_moves: 0,
            chase_dst: Random.int(7, 14),
        }
    } else {
        {
            type: Pick.value([
                {v: MoveType_StayAway, c: 0.25},
                {v: MoveType_Random, c: (1.0 / (1 + level))},
                ]),
            cant_move: false,
            successive_moves: 0,
            chase_dst: 0,
        }
    }

    var message = switch (aggression_type) {
        case AggressionType_Aggressive: '$name defends itself.';
        case AggressionType_NeutralToAggressive: '$name angrily defends itself.';
        case AggressionType_Neutral: '$name reluctantly hits you back.';
        case AggressionType_Passive: '$name cowers in fear.';
    };

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
            attack: attack, 
            absorb: absorb, 
            message: message,
            aggression: aggression_type,
            attacked_by_player: false,
            range_squared: range * range,
        },
        // TODO: think about what percentage is good and whether to vary percentages by mob
        drop_entity: {
            table: DropTable_Default, 
            chance: 10,
        },
        talk: Entity.NULL_STRING,
        give_copper_on_death: {
            chance: 50, 
            min: Stats.get({min: 1, max: 1, scaling: 1.0}, level), 
            max: Stats.get({min: 2, max: 2, scaling: 1.0}, level),
        },
        move: move,
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

    var statue_god = Random.pick(Type.allEnums(StatueGod));

    Entity.name[e] = switch (statue_god) {
        case StatueGod_Sera: 'Altar of Sera';
        case StatueGod_Subere: 'Statue of Subere';
        case StatueGod_Ollopa: 'Ollopa\'s effigy';
        case StatueGod_Suthaephes: 'Shrine of Suthaephes';
        case StatueGod_Enohik: 'Enohik\'s pedestal';
    }

    Entity.use[e] = {
        spells: switch (statue_god) {
            case StatueGod_Sera: Spells.statue_sera(level);
            case StatueGod_Subere: Spells.statue_subere(level);
            case StatueGod_Ollopa: Spells.statue_ollopa(level);
            case StatueGod_Suthaephes: Spells.statue_suthaephes(level);
            case StatueGod_Enohik: Spells.statue_enohik(level);
        },
        charges: 1,
        consumable: false,
        flavor_text: switch (statue_god) {
            case StatueGod_Sera: 'Sera\'s war cry echoes around you.';
            case StatueGod_Subere: 'Subere\'s shadow descends on the tower.';
            case StatueGod_Ollopa: 'You obtain Ollopa\'s blessing.';
            case StatueGod_Suthaephes: 'Suthaephes\' burns and strengthens you.';
            case StatueGod_Enohik: 'You feel Enohik\'s chill run through your bones.';
        },
        need_target: false,
    };

    Entity.draw_tile[e] = switch (statue_god) {
        case StatueGod_Sera: Tile.StatueSera;
        case StatueGod_Subere: Tile.StatueSubere;
        case StatueGod_Ollopa: Tile.StatueOllopa;
        case StatueGod_Suthaephes: Tile.StatueSuthaephes;
        case StatueGod_Enohik: Tile.StatueEnohik;
    }

    Entity.validate(e);

    return e;
}

static function merchant(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level;

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Merchant';
    Entity.description[e] = 'It\'s a merchant.';
    Entity.talk[e] = 'Merchant says: "I\'ve got kids to feed".';
    Entity.draw_char[e] = {
        char: 'M',
        color: Col.PINK,
    };
    Entity.combat[e] = {
        health: Stats.get({min: 10, max: 20, scaling: 2.0}, level), 
        attack: Stats.get({min: 3, max: 3, scaling: 1.0}, level), 
        absorb: 0,
        message: 'Merchant says: "You will regret this".',
        aggression: AggressionType_NeutralToAggressive,
        attacked_by_player: false,
        range_squared: 1,
    };
    Entity.draw_on_minimap[e] = {
        color: Col.PINK,
        seen: false,
    };

    Entity.validate(e);

    return e;
}

}