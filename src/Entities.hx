
import haxegon.*;
import Entity;
import Spells;
import Chance;

@:publicFields
class Entities {
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
        spells: [Spells.buff_phys_def(4 * level)],
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
        spells: [Spells.increase_attack_everyturn()],
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
        spells: [Spells.test()],
    };
    Entity.use[e] = {
        spells: [Spells.health_instant()],
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
        color: Col.YELLOW,
    };
    Entity.drop_entity[e] = {
        table: DropTable_Default,
        chance: 100,
    };
    Entity.description[e] = 'An unlocked chest.';
    Entity.combat[e] = {
        health: 1, 
        attack: [
        ElementType_Physical => 0,
        ], 
        absorb: [
        ElementType_Physical => 0,
        ], 
        message: 'Chest opens with a creak.',
        aggression: AggressionType_Passive,
        attacked_by_player: false,
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
        spells: [Spells.test()],
        charges: 1,
        consumable: true,
    };
    Entity.draw_tile[e] = Tile.Potion;

    Entity.validate(e);

    return e;
}

static function entity_from_table(x: Int, y: Int, droptable: DropTable): Int {
    switch (droptable) {
        case DropTable_Default: {
            return (Chance.pick([
            {v: sword, c: 1.0},
            {v: health_potion, c: 1.0},
            {v: ring, c: 1.0},
            ])(x, y));
        }
    };
}

static function entity_from_type(x: Int, y: Int, type: EntityType): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    if (type.description != Entity.NULL_STRING) {
        Entity.description[e] = type.description;
    }
    if (type.draw_tile != Entity.NULL_INT) {
        Entity.draw_tile[e] = type.draw_tile;
    }
    if (type.draw_char != null) {
        Entity.draw_char[e] = {
            char: type.draw_char.char,
            color: type.draw_char.color,
        };
    }
    if (type.equipment != null) {
        Entity.equipment[e] = {
            name: type.equipment.name,
            type: type.equipment.type,
            spells: [for (spell in type.equipment.spells) Spells.copy(spell)],
        };
    }
    if (type.item != null) {
        Entity.item[e] = {
            name: type.item.name,
            type: type.item.type,
            spells: [for (spell in type.item.spells) Spells.copy(spell)],
        };
    }
    if (type.use != null) {
        Entity.use[e] = {
            spells: [for (spell in type.use.spells) Spells.copy(spell)],
            charges: type.use.charges,
            consumable: type.use.consumable,
        };
    }
    if (type.combat != null) {
        Entity.combat[e] = {
            health: type.combat.health,
            attack: [ for (key in type.combat.attack.keys()) key => type.combat.attack[key]],
            absorb: [ for (key in type.combat.absorb.keys()) key => type.combat.absorb[key]],
            message: type.combat.message,
            aggression: type.combat.aggression,
            attacked_by_player: type.combat.attacked_by_player,
        };
    }
    if (type.drop_entity != null) {
        Entity.drop_entity[e] = {
            table: type.drop_entity.table,
            chance: type.drop_entity.chance,
        };
    }
    if (type.talk != Entity.NULL_STRING) {
        Entity.talk[e] = type.talk;
    }
    if (type.give_copper_on_death != null) {
        Entity.give_copper_on_death[e] = {
            chance: type.give_copper_on_death.chance,
            min: type.give_copper_on_death.min,
            max: type.give_copper_on_death.max,
        };
    }
    if (type.move != null) {
        Entity.move[e] = {
            type: type.move.type,
            cant_move: type.move.cant_move,
        };
    }

    Entity.validate(e);

    return e;
}

static function random_enemy_type(): EntityType {
    var name = generate_name();

    return {
        name: name,
        description: 'It\'s a $name.',
        draw_tile: Entity.NULL_INT,
        draw_char: {
            char: name.charAt(0),
            color: Col.RED,
        },
        equipment: null,
        item: null,
        use: null,
        combat: {
            health: Random.int(3, 6), 
            attack: [
            ElementType_Physical => Random.int(1, 2),
            ], 
            absorb: [
            ElementType_Physical => 0,
            ], 
            message: '$name defense itself.',
            aggression: Chance.pick([
                {v: AggressionType_Aggressive, c: 6.0},
                {v: AggressionType_Neutral, c: 3.0},
                {v: AggressionType_Passive, c: 1.0},
                ]),
            attacked_by_player: false,
        },
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
    };
} 

static function random_enemy(x: Int, y: Int): Int {
    var e = Entity.make();

    Entity.set_position(e, x, y);
    Entity.name[e] = generate_name();
    Entity.draw_char[e] = {
        char: Entity.name[e].charAt(0),
        color: Col.RED
    };
    Entity.description[e] = 'Random enemy';
    // TODO: scale copper drop amount to level
    Entity.give_copper_on_death[e] = {
        chance: 50, 
        min: 1, 
        max: 1
    };
    Entity.move[e] = {
        type: Random.pick(Type.allEnums(MoveType)),
        cant_move: false,
    };
    Entity.combat[e] = {
        health: Random.int(3, 6), 
        attack: [
        ElementType_Physical => Random.int(0, 1),
        ], 
        absorb: [
        ElementType_Physical => 0,
        ], 
        message: 'Enemy defense itself.',
        aggression: Chance.pick([
            {v: AggressionType_Aggressive, c: 6.0},
            {v: AggressionType_Neutral, c: 3.0},
            {v: AggressionType_Passive, c: 1.0},
            ]),
        attacked_by_player: false,
    };
    Entity.drop_entity[e] = {
        table: DropTable_Default, 
        chance: 100,
    };

    Entity.validate(e);

    return e;
}

}