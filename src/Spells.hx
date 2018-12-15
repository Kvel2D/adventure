
import haxegon.*;
import Entity;
import Pick;

@:publicFields
class Spells {
// NOTE: force unindent

// TODO: need to think about wording
// the interval thing is only for heal over time/dmg over time
// attack bonuses/ health max bonuses are applied every turn
static function description(spell: Spell): String {
    var string = '';
    var type = switch (spell.type) {
        case SpellType_ModHealth: 'change health';
        case SpellType_ModHealthMax: 'change max health';
        case SpellType_ModAttack: 'change attack';
        case SpellType_ModDefense: 'change defense';
        case SpellType_UncoverMap: 'uncover map';
    }
    var element = switch (spell.element) {
        case ElementType_Physical: 'physical';
        case ElementType_Fire: 'fire';
        case ElementType_Ice: 'ice';
        case ElementType_Shadow: 'shadow';
        case ElementType_Light: 'light';
    }

    var duration = if (spell.duration_type == SpellDuration_Permanent) {
        'permanent';
    } else {
        var interval_name = if (spell.duration_type == SpellDuration_EveryTurn) {
            'turn';
        } else {
            'attack';
        }

        if (spell.duration == Entity.INFINITE_DURATION) {
            if (spell.interval == 1) {
                'applied every ${interval_name}';
            } else {
                'applied every ${spell.interval} ${interval_name}s';
            }
        } else if (spell.interval == 1) {
            'for ${spell.duration * spell.interval} ${interval_name}s';
        } else {
            if (spell.interval == 1) {
                'for ${spell.duration} ${interval_name}s, applied every ${interval_name}';
            } else {
                'for ${spell.duration} ${interval_name}s, applied every ${spell.interval} ${interval_name}s';
            }
        }
    }

    // physical change attack 2 for 10 attacks
    // physical change attack 2 every 3 attacks for 9 attacks total
    return '$element $type ${spell.value} $duration (${spell.interval - spell.interval_current})';
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

static function buff_phys_def(element: ElementType, value: Int): Spell {
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

static function test(): Spell {
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

static function random_potion_spell(): Spell {
    // Health potion is most common, other modifiers are more rare
    var type = Pick.value([
        {v: SpellType_ModHealth, c: 2.0},
        {v: SpellType_ModHealthMax, c: 1.0},
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModDefense, c: 1.0},

        {v: SpellType_UncoverMap, c: 0.1},
        ]);

    var duration_type = switch (type) {
        case SpellType_ModHealth: SpellDuration_Permanent;
        case SpellType_ModHealthMax: Pick.value([
            {v: SpellDuration_Permanent, c: 1.0},
            {v: SpellDuration_EveryTurn, c: 2.0},
            ]);
        case SpellType_ModAttack: Pick.value([
            {v: SpellDuration_Permanent, c: 1.0},
            {v: SpellDuration_EveryTurn, c: 40.0},
            ]);
        case SpellType_ModDefense: Pick.value([
            {v: SpellDuration_Permanent, c: 1.0},
            {v: SpellDuration_EveryTurn, c: 20.0},
            ]);
        case SpellType_UncoverMap: SpellDuration_Permanent;
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

    var value = switch (type) {
        case SpellType_ModHealth: Random.int(5, 8);
        case SpellType_ModHealthMax: {
            switch (duration_type) {
                case SpellDuration_Permanent: Random.int(1, 2);
                case SpellDuration_EveryTurn: Random.int(4, 8);
                default: 0;
            };
        }
        case SpellType_ModAttack: {
            switch (duration_type) {
                case SpellDuration_Permanent: 1;
                case SpellDuration_EveryTurn: Random.int(1, 2);
                default: 0;
            };
        }
        case SpellType_ModDefense: {
            switch (duration_type) {
                case SpellDuration_Permanent: Random.int(1, 2);
                case SpellDuration_EveryTurn: Random.int(2, 4);
                default: 0;
            };
        }
        default: 0;
    }

    var element = switch (type) {
        case SpellType_ModHealth: ElementType_Light;
        case SpellType_ModHealthMax: ElementType_Shadow;
        case SpellType_ModAttack: ElementType_Physical;
        case SpellType_ModDefense: ElementType_Physical;
        case SpellType_UncoverMap: ElementType_Light;
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
    var type = Pick.value([
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModHealthMax, c: 5.0},
        {v: SpellType_ModDefense, c: 10.0},
        ]);

    var duration = SpellDuration_EveryTurn;

    var value = switch (type) {
        case SpellType_ModHealthMax: Random.int(4, 7);
        case SpellType_ModAttack: 1;
        case SpellType_ModDefense: Random.int(1, 2);
        default: 0;
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