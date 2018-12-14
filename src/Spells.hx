
import haxegon.*;
import Entity;
import Chance;

@:publicFields
class Spells {
// NOTE: force unindent

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

static function buff_phys_def(value: Int): Spell {
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

}