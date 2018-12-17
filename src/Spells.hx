
import haxegon.*;
import Entity;
import Pick;
import Stats;

enum SpellType {
    SpellType_ModHealth;
    SpellType_ModHealthMax;
    SpellType_ModAttack;
    SpellType_ModDefense;
    SpellType_UncoverMap;
    SpellType_RandomTeleport;
    SpellType_SafeTeleport;
    SpellType_Nolos;
    SpellType_Noclip;
    SpellType_ShowThings;
    SpellType_NextFloor;
    SpellType_ModMoveSpeed;
    SpellType_ModDropChance;
    SpellType_ModCopperDrop;
}

enum SpellDuration {
    SpellDuration_Permanent;
    SpellDuration_EveryTurn;
    SpellDuration_EveryAttack;
}

typedef Spell = {
    var type: SpellType;
    var element: ElementType;
    var duration_type: SpellDuration;
    var duration: Int;
    var interval: Int;
    var interval_current: Int;
    var value: Int;
    var origin_name: String;
}

@:publicFields
class Spells {
// force unindent

// TODO: need to think about wording
// the interval thing is only for heal over time/dmg over time
// attack bonuses/ health max bonuses are applied every turn
static function get_description(spell: Spell): String {
    var element = switch (spell.element) {
        case ElementType_Physical: 'physical';
        case ElementType_Fire: 'fire';
        case ElementType_Ice: 'ice';
        case ElementType_Shadow: 'shadow';
        case ElementType_Light: 'light';
    }

    // effect + interval (if not 1) + duration
    // +2 fire attack
    // +2 fire attack for 30 turns
    // +2 fire attack (permanent)
    // +1 health every 3 turns for 30 turns
    // +1 ice defense for the rest of the level
    // see treasure on minimap for 30 turns

    var sign = if (spell.value > 0) '+' else '-';

    var effect = switch (spell.type) {
        case SpellType_ModHealth: '$sign${spell.value} health';
        case SpellType_ModHealthMax: '$sign${spell.value} max health';
        case SpellType_ModAttack: '$sign${spell.value} ${element} attack';
        case SpellType_ModDefense: '$sign${spell.value} ${element} defense';
        case SpellType_ModMoveSpeed: '$sign${spell.value} move speed';
        case SpellType_ModDropChance: '$sign${spell.value}% item drop chance';
        case SpellType_ModCopperDrop: '$sign${spell.value}% copper drop chance';

        case SpellType_UncoverMap: 'uncover map';
        case SpellType_RandomTeleport: 'random teleport';
        case SpellType_SafeTeleport: 'safe teleport';
        case SpellType_Nolos: 'see everything';
        case SpellType_Noclip: 'go through walls';
        case SpellType_ShowThings: 'see tresure on the map';
        case SpellType_NextFloor: 'go to next floor';
    }

    var interval = 
    if (spell.interval > 1) {
        if (spell.duration_type == SpellDuration_EveryTurn) {
            ' every ${spell.interval} turns';
        } else if (spell.duration_type == SpellDuration_EveryAttack) {
            ' every ${spell.interval} attacks';
        } else {
            ' BAD INTERVAL';
        }
    } else {
        if (spell.duration_type == SpellDuration_Permanent) {
            '';
        } else if (spell.duration_type == SpellDuration_EveryTurn) {
            '';
        } else if (spell.duration_type == SpellDuration_EveryAttack) {
            ' every attack';
        } else {
            ' BAD INTERVAL';
        }
    }

    var duration = 
    if (spell.duration == Entity.INFINITE_DURATION) {
        '';
    } else if (spell.duration == Entity.LEVEL_DURATION) {
        ' for the rest of the level';
    } else {
        switch (spell.duration_type) {
            case SpellDuration_Permanent: '';
            case SpellDuration_EveryTurn: ' for ${spell.duration} turns';
            case SpellDuration_EveryAttack: ' for ${spell.duration} attacks';
        }
    }

    return '$effect$interval$duration';
}

static function random_element(): ElementType {
    return Random.pick(Type.allEnums(ElementType));
}

static function copy(spell: Spell): Spell {
    return {
        type: spell.type,
        element: spell.element,
        duration_type: spell.duration_type,
        duration: spell.duration,
        interval: spell.interval,
        interval_current: spell.interval_current,
        value: spell.value,
        origin_name: spell.origin_name,
    };
}

static function randoml(): Spell {
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

static function attack_buff(element: ElementType, value: Int): Spell {
    return {
        type: SpellType_ModAttack,
        element: element,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function defense_buff(element: ElementType, value: Int): Spell {
    return {
        type: SpellType_ModDefense,
        element: element,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
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
        duration: Entity.INFINITE_DURATION,
        interval: 1,
        interval_current: 0,
        value: 6,
        origin_name: "noname",
    }
}

static function poison(): Spell {
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

static function random_teleport(): Spell {
    return {
        type: SpellType_RandomTeleport,
        element: ElementType_Shadow,
        duration_type: SpellDuration_Permanent,
        duration: Entity.INFINITE_DURATION,
        interval: 0,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function nolos(): Spell {
    return {
        type: SpellType_Nolos,
        element: ElementType_Light,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function noclip(): Spell {
    return {
        type: SpellType_Noclip,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function show_things(): Spell {
    return {
        type: SpellType_ShowThings,
        element: ElementType_Fire,
        duration_type: SpellDuration_EveryTurn,
        duration: 30,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function next_floor(): Spell {
    return {
        type: SpellType_NextFloor,
        element: ElementType_Physical,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function increase_movespeed(): Spell {
    return {
        type: SpellType_ModMoveSpeed,
        element: ElementType_Physical,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function increase_droprate(): Spell {
    return {
        type: SpellType_ModDropChance,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 50,
        origin_name: "noname",
    }
}

static function chance_copper_drop(): Spell {
    return {
        type: SpellType_ModCopperDrop,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function test(): Spell {
    return {
        type: SpellType_ModCopperDrop,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.LEVEL_DURATION,
        interval: 1,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function random_potion_spell(): Spell {
    var level = Main.current_level;

    var type = Pick.value([
        {v: SpellType_ModHealth, c: 4.0},
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModDefense, c: 1.0},
        {v: SpellType_ModHealthMax, c: 1.0},
        ]);

    var duration_type = switch (type) {
        case SpellType_ModHealth: SpellDuration_Permanent;
        case SpellType_ModHealthMax: SpellDuration_EveryTurn;
        case SpellType_ModAttack: SpellDuration_EveryTurn;
        case SpellType_ModDefense: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = if (duration_type == SpellDuration_Permanent) {
        0;
    } else {
        switch (type) {
            case SpellType_ModHealthMax: Random.int(20, 30);
            case SpellType_ModAttack: Random.int(20, 30);
            case SpellType_ModDefense: Random.int(20, 30);
            default: 0;
        }
    }

    // TODO: scale everything else
    var value = switch (type) {
        case SpellType_ModHealth: Stats.get({min: 5, max: 8, scaling: 1.0}, level);
        case SpellType_ModHealthMax: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        default: 0;
    }

    var element = switch (type) {
        case SpellType_ModHealth: ElementType_Light;
        case SpellType_ModHealthMax: ElementType_Shadow;
        case SpellType_ModAttack: ElementType_Physical;
        case SpellType_ModDefense: ElementType_Physical;
        case SpellType_UncoverMap: ElementType_Light;
        case SpellType_Nolos: ElementType_Light;
        default: ElementType_Physical;
    }

    return {
        type: type,
        element: element,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function random_scroll_spell(): Spell {
    var level = Main.current_level;

    var type = Pick.value([
        {v: SpellType_UncoverMap, c: 1.0},
        {v: SpellType_Nolos, c: 1.0},
        {v: SpellType_Noclip, c: 1.0},
        {v: SpellType_RandomTeleport, c: 0.5},
        {v: SpellType_SafeTeleport, c: 0.5},
        {v: SpellType_ModHealthMax, c: 1.0},
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModDefense, c: 1.0},
        {v: SpellType_ShowThings, c: 0.5},
        ]);

    var duration_type = switch (type) {
        case SpellType_Nolos: SpellDuration_EveryTurn;
        case SpellType_Noclip: SpellDuration_EveryTurn;
        case SpellType_RandomTeleport: SpellDuration_Permanent;
        case SpellType_SafeTeleport: SpellDuration_Permanent;
        case SpellType_ModHealthMax: SpellDuration_Permanent;
        case SpellType_ModAttack: SpellDuration_Permanent;
        case SpellType_ModDefense: SpellDuration_Permanent;
        case SpellType_UncoverMap: SpellDuration_EveryTurn;
        case SpellType_ShowThings: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = if (duration_type == SpellDuration_Permanent) {
        0;
    } else {
        switch (type) {
            case SpellType_UncoverMap: Entity.LEVEL_DURATION;
            case SpellType_ShowThings: Entity.LEVEL_DURATION;
            case SpellType_Nolos: Random.int(100, 150);
            case SpellType_Noclip: Random.int(50, 100);
            default: 0;
        }
    }

    var value = switch (type) {
        case SpellType_ModHealthMax: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        default: 0;
    }

    var element = switch (type) {
        case SpellType_ModHealthMax: ElementType_Shadow;
        case SpellType_ModAttack: random_element();
        case SpellType_ModDefense: random_element();
        case SpellType_UncoverMap: ElementType_Light;
        case SpellType_Nolos: ElementType_Light;
        case SpellType_Noclip: ElementType_Shadow;
        case SpellType_RandomTeleport: ElementType_Shadow;
        case SpellType_SafeTeleport: ElementType_Light;
        case SpellType_ShowThings: ElementType_Fire;
        default: ElementType_Physical;
    }

    return {
        type: type,
        element: element,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function random_ring_spell(): Spell {
    var level = Main.current_level;

    var type = Pick.value([
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModHealthMax, c: 5.0},
        {v: SpellType_ModDefense, c: 10.0},
        ]);

    var duration = SpellDuration_EveryTurn;

    var value = switch (type) {
        case SpellType_ModHealthMax: Stats.get({min: 4, max: 7, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        default: 0;
    }

    // Figure out when to make elements random
    var element = switch (type) {
        case SpellType_ModHealthMax: ElementType_Physical;
        case SpellType_ModAttack: ElementType_Physical;
        case SpellType_ModDefense: ElementType_Physical;
        default: ElementType_Physical;
    }

    return {
        type: type,
        element: ElementType_Physical,
        duration_type: duration,
        duration: Entity.INFINITE_DURATION,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

}