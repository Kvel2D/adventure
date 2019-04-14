
import haxegon.*;
import Entity;
import Spells;
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

static inline var ENEMY_BASE_ITEM_DROP_CHANCE = 25;
static inline var ENEMY_BASE_COPPER_DROP_CHANCE = 35;
static inline var ENEMY_NOTHING_DROP_CHANCE = 40;

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
    Entity.container[e] = {
        color: color,
        locked: false,
    };
    Entity.drop_entity[e] = {
        drop_func: function(x, y) {
            return (Random.pick_chance([
                {v: Entities.random_weapon, c: 1.0 * GenerateWorld.weapon_bad_streak_mod()},
                {v: Entities.random_armor, c: 6.0},
                {v: Entities.random_potion, c: 2.0},
                {v: Entities.random_ring, c: 2.0},
                ])
            (x, y));
        }
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
    Entity.container[e] = {
        color: color,
        locked: true,
    };
    Entity.drop_entity[e] = {
        drop_func: function(x, y) {
            return (Random.pick_chance([
                {v: Entities.random_weapon, c: 1.0 * GenerateWorld.weapon_bad_streak_mod()},
                {v: Entities.random_armor, c: 6.0},
                {v: Entities.random_ring, c: 1.0},
                ])
            (x, y));
        }
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
    Entity.container[e] = {
        color: color,
        locked: true,
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
        draw_charges: false,
    };

    return e;
}

static function test_potion(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        spells: [],
    };
    Entity.use[e] = {
        spells: [Spells.copy_item()],
        charges: 3,
        consumable: true,
        flavor_text: '',
        need_target: true,
        draw_charges: true,
    };
    Entity.draw_tile[e] = Tile.Potion[0];

    Entity.validate(e);

    return e;
}

static function random_weapon(x: Int, y: Int): Int {
    GenerateWorld.weapons_on_floor[Main.current_floor] = true;

    var level = Main.current_level();
    
    var e = Entity.make();
    Entity.set_position(e, x, y);

    var tile_index = Math.floor(Math.min(Tile.Head.length - 1, level / 2));
    Entity.draw_tile[e] = Tile.Sword[tile_index];

    Entity.name[e] = 'Sword';

    var attack_buff_value = Stats.get_unrounded({min: 1, max: 1, scaling: 1.0}, level);  

    var equip_plus_use_spells = Spells.random_equipment_spells(EquipmentType_Weapon);

    var equip_spells = equip_plus_use_spells[0];
    var use_spells = equip_plus_use_spells[1];

    var spells_weight: Float = 0;
    for (s in equip_spells) {
        spells_weight += Spells.get_weapon_equip_spell_weight(s);
    }
    for (s in use_spells) {
        spells_weight += Spells.get_weapon_use_spell_weight(s);
    }

    attack_buff_value -= spells_weight;
    attack_buff_value = Math.round(attack_buff_value);
    if (attack_buff_value < 0) {
        attack_buff_value = 0;
    }

    equip_spells.insert(0, Spells.attack_buff(Std.int(attack_buff_value)));

    if (use_spells.length > 0) {
        Entity.use[e] = {
            spells: use_spells,
            charges: Spells.get_spells_min_use_charges(use_spells),
            consumable: false,
            flavor_text: 'You use weapon\'s spell.',
            need_target: false,
            draw_charges: true,
        };
    }

    Entity.equipment[e] = {
        type: EquipmentType_Weapon,
        spells: equip_spells,
    };

    Entity.validate(e);

    return e;
}

static var armor_type_tallies = new Array<EquipmentType>();

static function random_armor(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level();

    Entity.set_position(e, x, y);

    var armor_tally_head = 0;
    var armor_tally_chest = 0;
    var armor_tally_legs = 0;
    for (t in armor_type_tallies) {
        switch (t) {
            case EquipmentType_Head: armor_tally_head++; 
            case EquipmentType_Chest: armor_tally_chest++; 
            case EquipmentType_Legs: armor_tally_legs++;
            default:
        }
    }
    var head_ratio: Float = armor_tally_head / armor_type_tallies.length;
    var chest_ratio: Float = armor_tally_chest / armor_type_tallies.length;
    var legs_ratio: Float = armor_tally_legs / armor_type_tallies.length;

    // NOTE: ideal type distribution is 0.33 for each
    var armor_type = Random.pick_chance([
        {v: EquipmentType_Head, c: if (head_ratio > 0.2) 1.0 else 2.0 },
        {v: EquipmentType_Chest, c: if (chest_ratio > 0.2) 1.0 else 2.0 },
        {v: EquipmentType_Legs, c: if (legs_ratio > 0.2) 1.0 else 2.0 },
        ]);
    armor_type_tallies.push(armor_type);
    if (armor_type_tallies.length > 10) {
        armor_type_tallies.shift();
    }

    Entity.name[e] = switch (armor_type) {
        case EquipmentType_Head: 'Helmet'; 
        case EquipmentType_Chest: 'Chestplate'; 
        case EquipmentType_Legs: 'Pants';
        case EquipmentType_Weapon: 'invalid';
    }
    // NOTE: +1 because the 0th armors are the default body parts
    var tile_index = Math.floor(Math.min(Tile.Head.length - 1, 1 + level));
    Entity.draw_tile[e] = switch (armor_type) {
        case EquipmentType_Head: Tile.Head[tile_index];
        case EquipmentType_Chest: Tile.Chest[tile_index];
        case EquipmentType_Legs: Tile.Legs[tile_index];
        case EquipmentType_Weapon: Tile.None;
    }

    var defense_total = Stats.get({min: 1, max: 2, scaling: 1.0}, level);

    var equip_plus_use_spells = Spells.random_equipment_spells(armor_type);

    var equip_spells = equip_plus_use_spells[0];
    var use_spells = equip_plus_use_spells[1];
    
    equip_spells.insert(0, Spells.defense_buff(defense_total));

    if (use_spells.length > 0) {
        Entity.use[e] = {
            spells: use_spells,
            charges: Spells.get_spells_min_use_charges(use_spells),
            consumable: false,
            flavor_text: 'You use armor\'s spell.',
            need_target: false,
            draw_charges: true,
        };
    }

    Entity.equipment[e] = {
        type: armor_type,
        spells: equip_spells,
    };

    Entity.validate(e);

    return e;
}

static function random_ring(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Ring';
    var spell = Spells.random_ring_spell(level);
    Entity.item[e] = {
        spells: [spell],
    };
    Entity.ring[e] = true;
    var spell_color = Spells.get_color(spell);
    Entity.draw_tile[e] = Tile.Ring[Tile.col_to_index(spell_color)];

    Entity.validate(e);

    return e;
}

static function random_potion(x: Int, y: Int, force_spell: SpellType = null): Int {
    var e = Entity.make();

    var level = Main.current_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Potion';
    Entity.item[e] = {
        spells: [],
    };
    var spell = Spells.random_potion_spell(level, force_spell);
    Entity.use[e] = {
        spells: [spell],
        charges: 1,
        consumable: true,
        flavor_text: 'You chug the potion.',
        need_target: false,
        draw_charges: true,
    };

    var spell_color = Spells.get_color(spell);
    Entity.draw_tile[e] = Tile.Potion[Tile.col_to_index(spell_color)];

    Entity.validate(e);

    return e;
}

static function random_scroll(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Scroll';
    Entity.item[e] = {
        spells: [],
    };
    var spell = Spells.random_scroll_spell(level);
    Entity.use[e] = {
        spells: [spell],
        charges: 1,
        consumable: true,
        flavor_text: 'You read the scroll aloud.',
        need_target: Spells.need_target(spell.type),
        draw_charges: true,
    };

    var spell_color = Spells.get_color(spell);
    Entity.draw_tile[e] = Tile.Scroll[Tile.col_to_index(spell_color)];

    Entity.validate(e);

    return e;
}

static function random_orb(x: Int, y: Int): Int {
    var e = Entity.make();

    var level = Main.current_level();

    Entity.set_position(e, x, y);
    Entity.name[e] = 'Orb';
    Entity.item[e] = {
        spells: [],
    };
    var spell = Spells.random_orb_spell(level);
    Entity.use[e] = {
        spells: [spell],
        charges: 1,
        consumable: true,
        flavor_text: 'You crush the orb in your hands.',
        need_target: Spells.need_target(spell.type),
        draw_charges: true,
    };

    var spell_color = Spells.get_color(spell);
    Entity.draw_tile[e] = Tile.Orb[Tile.col_to_index(spell_color)];

    Entity.validate(e);

    return e;
}

static function random_enemy_type(): Int->Int->Int {
    var name = generate_name();

    var level = Main.current_level();

    // NOTE: removed ranged enemies for now because they suck
    // var range: Int = if (level <= 1) {
    //     2;
    // } else {
    //     // NOTE: Ranges are sums of squares, this means that each range covers a square area, 1^2 + 1^2 = 2, 2^2 + 2^2 = 8, 3^2 + 3^2 = 18
    //     Random.pick_chance([
    //         {v: 2, c: 8.0},
    //         {v: 8, c: 2.0},
    //         {v: 18, c: 1.0},
    //         ]);
    // }
    var range = 2;

    // Long-ranged mobs have lower attack and health to compensate
    var range_factor = 
    if (range == 2) 
        1.0;
    else if (range <= 8) 
        0.5;
    else 
        0.25;
    var attack = Stats.get({min: 1 * range_factor, max: 1.5 * range_factor, scaling: 1.0}, level);
    if (attack == 0) {
        attack = 1;
    }
    var health = Stats.get({min: 4 * range_factor, max: 5 * range_factor, scaling: 2.0}, level); 

    // Make first floor easy
    if (Main.current_floor == 0) {
        attack = 1;
        health  = Math.round(health / 2);
    }

    var aggression_type = Random.pick_chance([
        {v: AggressionType_Aggressive, c: 1.0},
        // {v: AggressionType_NeutralToAggressive, c: 0.1},
        // {v: AggressionType_Neutral, c: (0.1 / (1 + level))},
        ]);

    // NeutralToAggressive start out stationary
    var move: Move = if (aggression_type == AggressionType_NeutralToAggressive) {
        null;
    } else if (aggression_type == AggressionType_Aggressive) {
        {
            type: Random.pick_chance([
                // {v: MoveType_Astar, c: 1.0},
                {v: MoveType_Straight, c: 2.0},
                // {v: MoveType_StayAway, c: 0.25},
                // {v: MoveType_Random, c: (1.0 / (1 + level))},
                ]),
            cant_move: false,
            successive_moves: 0,
            chase_dst: Random.int(10, 16),
            target: MoveTarget_FriendlyThenPlayer,
        }
    } else {
        {
            type: Random.pick_chance([
                {v: MoveType_StayAway, c: 0.25},
                {v: MoveType_Random, c: (1.0 / (1 + level))},
                ]),
            cant_move: false,
            successive_moves: 0,
            chase_dst: 0,
            target: MoveTarget_FriendlyThenPlayer,
        }
    }

    var message = switch (aggression_type) {
        case AggressionType_Aggressive: '$name defends itself.';
        case AggressionType_NeutralToAggressive: '$name angrily defends itself.';
        case AggressionType_Neutral: '$name reluctantly hits you back.';
        case AggressionType_Passive: '$name cowers in fear.';
    };

    var color = Col.GRAY;

    var item_drop_chance = ENEMY_BASE_ITEM_DROP_CHANCE + Player.dropchance_mod;
    var copper_drop_chance = ENEMY_BASE_COPPER_DROP_CHANCE + Player.copper_drop_mod;


    return function (x, y) {
        var e = Entity.make();

        Entity.set_position(e, x, y);

        Entity.name[e] = name;
        Entity.description[e] = 'It\'s a $name.';
        Entity.draw_char[e] = {
            char: name.charAt(0),
            color: color,
        };
        Entity.combat[e] = {
            health: health, 
            health_max: health, 
            attack: attack, 
            message: message,
            aggression: aggression_type,
            attacked_by_player: false,
            range_squared: range,
            target: CombatTarget_FriendlyThenPlayer
        };
        Entity.drop_entity[e] = {
            drop_func: function(x, y) {
                return Random.pick_chance([
                    {v: Random.pick_chance([
                        {v: Entities.random_weapon, c: 1.0},
                        {v: Entities.random_armor, c: 6.0},
                        {v: Entities.random_potion, c: 3.0},
                        {v: Entities.random_ring, c: 2.0},
                        ]), 
                    c: ENEMY_BASE_ITEM_DROP_CHANCE + Player.dropchance_mod},
                    {
                        v: Entities.copper, 
                        c: ENEMY_BASE_COPPER_DROP_CHANCE + Player.copper_drop_mod
                    },
                    {
                        v: function(x, y) { return Entity.NONE; }, 
                        c: ENEMY_NOTHING_DROP_CHANCE
                    },
                    ])(x, y);
                },
            };

            if (move != null) {
                Entity.move[e] = {
                    type: move.type,
                    cant_move: move.cant_move,
                    successive_moves: move.successive_moves,
                    chase_dst: move.chase_dst,
                    target: move.target,
                };
            }

            return e;
        };
    } 

    static function random_statue(x: Int, y: Int): Int {
        var e = Entity.make();

        var level = Main.current_level();

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
            draw_charges: true,
        };

        var color = switch (statue_god) {
            case StatueGod_Sera: SpellColor_Gray;
            case StatueGod_Subere: SpellColor_Purple;
            case StatueGod_Ollopa: SpellColor_Yellow;
            case StatueGod_Suthaephes: SpellColor_Red;
            case StatueGod_Enohik: SpellColor_Blue;
            default: SpellColor_Green;
        }

        Entity.draw_tile[e] = Tile.Statue[Tile.col_to_index(color)];

        if (statue_god == StatueGod_Sera) {
            Entity.cost[e] = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }

        Entity.validate(e);

        return e;
    }

    static function merchant(x: Int, y: Int): Int {
        var e = Entity.make();

        var level = Main.current_level();

        Entity.set_position(e, x, y);
        Entity.name[e] = 'Merchant';
        Entity.description[e] = 'It\'s a merchant.';
        Entity.talk[e] = 'Merchant says: "I\'ve got kids to feed".';
        Entity.draw_char[e] = {
            char: 'M',
            color: Col.PINK,
        };
        var health = Stats.get({min: 15, max: 20, scaling: 4.0}, level);
        Entity.combat[e] = {
            health: health,
            health_max: health, 
            attack: Stats.get({min: 4, max: 6, scaling: 1.5}, level), 
            message: 'Merchant says: "You will regret this".',
            aggression: AggressionType_NeutralToAggressive,
            attacked_by_player: false,
            range_squared: 2,
            target: CombatTarget_FriendlyThenPlayer,
        };
        Entity.draw_on_minimap[e] = {
            color: Col.PINK,
            seen: false,
        };
        Entity.merchant[e] = true;

        Entity.validate(e);

        return e;
    }

    static function golem(level: Int, x: Int, y: Int): Int {
        var e = Entity.make();

        Entity.set_position(e, x, y);
        Entity.name[e] = 'Golem';
        Entity.description[e] = 'It\'s a golem.';
        Entity.talk[e] = 'Golem says: "Protect you"';
        Entity.draw_char[e] = {
            char: 'g',
            color: Col.GREEN,
        };
        var health = Stats.get({min: 4, max: 7, scaling: 1.0}, level);
        Entity.combat[e] = {
            health: health, 
            health_max: health, 
            attack: Stats.get({min: 1, max: 2, scaling: 1.0}, level), 
            message: 'Golem says: "Why?"',
            aggression: AggressionType_Aggressive,
            attacked_by_player: false,
            range_squared: 1,
            target: CombatTarget_Enemy,
        };
        Entity.move[e] = {
            type: MoveType_Astar,
            cant_move: false,
            successive_moves: 0,
            chase_dst: 14,
            target: MoveTarget_EnemyThenPlayer,
        };

        Entity.validate(e);

        return e;
    }

    static function skeleton(level: Int, x: Int, y: Int): Int {
        var e = Entity.make();

        Entity.set_position(e, x, y);
        Entity.name[e] = 'Skeleton';
        Entity.description[e] = 'It\'s a skeleton.';
        Entity.talk[e] = 'Skeleton says: "Click clack"';
        Entity.draw_char[e] = {
            char: 's',
            color: Col.GREEN,
        };
        var health = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        Entity.combat[e] = {
            health: health,
            health_max: health, 
            attack: Stats.get({min: 1, max: 1, scaling: 1.0}, level), 
            message: 'Skeleton attacks.',
            aggression: AggressionType_Aggressive,
            attacked_by_player: false,
            range_squared: 1,
            target: CombatTarget_Enemy,
        };
        Entity.move[e] = {
            type: MoveType_Straight,
            cant_move: false,
            successive_moves: 0,
            chase_dst: Random.int(7, 14),
            target: MoveTarget_EnemyOnly,
        };

        Entity.validate(e);

        return e;
    }

    static function imp(level: Int, x: Int, y: Int): Int {
        var e = Entity.make();

        Entity.set_position(e, x, y);
        Entity.name[e] = 'Imp';
        Entity.description[e] = 'It\'s an imp.';
        Entity.talk[e] = 'Imp grins at you.';
        Entity.draw_char[e] = {
            char: 'i',
            color: Col.GREEN,
        };
        var health = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        Entity.combat[e] = {
            health: health, 
            health_max: health, 
            attack: Stats.get({min: 1, max: 1, scaling: 1.0}, level), 
            message: 'Imp attacks.',
            aggression: AggressionType_Aggressive,
            attacked_by_player: false,
            range_squared: 9,
            target: CombatTarget_Enemy,
        };

        Entity.validate(e);

        return e;
    }

    static function copper(x: Int, y: Int): Int {
        var e = Entity.make();

        var level = Main.current_level();

        Entity.set_position(e, x, y);
        Entity.name[e] = 'Copper';
        Entity.description[e] = 'A bunch of copper pieces';
        Entity.draw_tile[e] = Tile.Copper;
        Entity.use[e] = {
            spells: [Spells.mod_copper(Stats.get({min: 1, max: 2, scaling: 1.0}, level))],
            charges: 1,
            consumable: true,
            flavor_text: 'You pick up the copper.',
            need_target: false,
            draw_charges: false,
        };

        Entity.validate(e);

        return e;
    }

}