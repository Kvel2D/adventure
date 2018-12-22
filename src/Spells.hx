
import haxegon.*;
import Entity;
import Pick;
import Stats;
import GenerateWorld;

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
    SpellType_AoeDamage;
    SpellType_ModDropLevel;
    SpellType_Invisibility;
    SpellType_EnergyShield;

    SpellType_ModLevelHealth;
    SpellType_ModLevelAttack;
    SpellType_ModLevelAbsorb;

    SpellType_ModUseCharges;
    SpellType_CopyItem;
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

// Drop effects before everything else so that all drops that can be caused by spells are affected
// Teleports last so that aoe hits stuff in old room
// Must do NextFloor before ModDropLevel, otherwise all spawned entities will be +1 level
static var prios = [
SpellType_NextFloor => 0,

SpellType_CopyItem => 1,
SpellType_ModUseCharges => 1,
SpellType_Invisibility => 1,
SpellType_ModDropChance => 1,
SpellType_ModCopperDrop => 1,
SpellType_ModDropLevel => 1,
SpellType_EnergyShield => 1,

SpellType_ModHealthMax => 2,
SpellType_ModHealth => 2,
SpellType_ModAttack => 2,
SpellType_ModDefense => 2,
SpellType_AoeDamage => 2,

SpellType_ModLevelHealth => 3,
SpellType_ModLevelAttack => 3,
SpellType_ModLevelAbsorb => 3,
SpellType_ShowThings => 3,
SpellType_UncoverMap => 3,
SpellType_SafeTeleport => 3,
SpellType_RandomTeleport => 3,
SpellType_Nolos => 3,
SpellType_Noclip => 3,
SpellType_ModMoveSpeed => 3,
];
static inline var last_prio = 3;

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

    // negative numbers already have '-' in front
    var sign = if (spell.value > 0) '+' else '';

    var effect = switch (spell.type) {
        case SpellType_ModHealth: '$sign${spell.value} health';
        case SpellType_ModHealthMax: '$sign${spell.value} max health';
        case SpellType_ModAttack: '$sign${spell.value} ${element} attack';
        case SpellType_ModDefense: '$sign${spell.value} ${element} defense';
        case SpellType_ModMoveSpeed: '$sign${spell.value} move speed';
        case SpellType_ModDropChance: '$sign${spell.value}% item drop chance';
        case SpellType_ModCopperDrop: '$sign${spell.value}% copper drop chance';

        case SpellType_ModLevelHealth: '$sign${spell.value} health to all enemies on the level';
        case SpellType_ModLevelAttack: '$sign${spell.value} ${element} attack to all enemies on the level';
        case SpellType_ModLevelAbsorb: '$sign${spell.value} ${element} absorb to all enemies on the level';

        case SpellType_EnergyShield: 'energy shield that absorbs ${spell.value} damage';
        case SpellType_Invisibility: 'turn invisible';
        case SpellType_ModDropLevel: 'make item drops more powerful';
        case SpellType_UncoverMap: 'uncover map';
        case SpellType_RandomTeleport: 'random teleport';
        case SpellType_SafeTeleport: 'safe teleport';
        case SpellType_Nolos: 'see everything';
        case SpellType_Noclip: 'go through walls';
        case SpellType_ShowThings: 'see tresure on the map';
        case SpellType_NextFloor: 'go to next floor';
        case SpellType_AoeDamage: 'deal ${spell.value} ${element} damage to enemies in the room';
        case SpellType_ModUseCharges: 'add ${spell.value} use charges to item';
        case SpellType_CopyItem: 'copy item in your inventory and drop it on the ground (must have free space around you or the spell fails)';
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

static function all_elements(): Array<ElementType> {
    return return Type.allEnums(ElementType);
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
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: 4,
        interval_current: 0,
        value: -1,
        origin_name: "noname",
    }
}

static function safe_teleport(): Spell {
    return {
        type: SpellType_SafeTeleport,
        element: ElementType_Shadow,
        duration_type: SpellDuration_Permanent,
        duration: Entity.INFINITE_DURATION,
        interval: 0,
        interval_current: 0,
        value: 0,
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

static function fire_aoe(): Spell {
    return {
        type: SpellType_AoeDamage,
        element: ElementType_Fire,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function drop_level(): Spell {
    return {
        type: SpellType_ModDropLevel,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.LEVEL_DURATION,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function uncover_map(): Spell {
    return {
        type: SpellType_UncoverMap,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.LEVEL_DURATION,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function mod_level_health(): Spell {
    return {
        type: SpellType_ModLevelHealth,
        element: ElementType_Shadow,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function mod_level_attack(): Spell {
    return {
        type: SpellType_ModLevelAttack,
        element: ElementType_Shadow,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function invisibility(): Spell {
    return {
        type: SpellType_Invisibility,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: 100,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function energy_shield(): Spell {
    return {
        type: SpellType_EnergyShield,
        element: ElementType_Light,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 10,
        origin_name: "noname",
    }
}

static function add_charges(): Spell {
    return {
        type: SpellType_ModUseCharges,
        element: ElementType_Shadow,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function copy_item(): Spell {
    return {
        type: SpellType_CopyItem,
        element: ElementType_Light,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 0,
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

static function random_potion_spells(level: Int): Array<Spell> {
    var type = Pick.value([
        {v: SpellType_ModHealth, c: 4.0},
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModDefense, c: 1.0},
        {v: SpellType_Invisibility, c: 0.25},
        ]);

    var duration_type = switch (type) {
        case SpellType_ModHealth: SpellDuration_Permanent;
        case SpellType_ModAttack: SpellDuration_EveryTurn;
        case SpellType_ModDefense: SpellDuration_EveryTurn;
        case SpellType_Invisibility: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = switch (type) {
        case SpellType_ModAttack: Random.int(80, 120);
        case SpellType_ModDefense: Random.int(80, 120);
        case SpellType_Invisibility: Random.int(40, 60);
        default: 0;
    }

    var elements = switch (type) {
        case SpellType_ModHealth: [ElementType_Light];
        case SpellType_ModHealthMax: [ElementType_Shadow];
        case SpellType_UncoverMap: [ElementType_Light];
        case SpellType_ModAttack: [random_element()];
        case SpellType_ModDefense: all_elements();
        case SpellType_Invisibility: [ElementType_Shadow];
        default: [ElementType_Physical];
    }

    var value = switch (type) {
        case SpellType_ModHealth: Stats.get({min: 5, max: 5, scaling: 1.0}, level);
        case SpellType_ModHealthMax: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 2, max: 3, scaling: 0.5}, level);
        case SpellType_ModDefense: Stats.get({min: 10, max: 15, scaling: 1.0}, level);
        default: 0;
    }

    return [for (element in elements) {
        type: type,
        element: element,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }];
}

static function random_scroll_spell(level: Int): Spell {
    var type = Pick.value([
        {v: SpellType_UncoverMap, c: 1.0},
        {v: SpellType_Nolos, c: 0.25},
        {v: SpellType_Noclip, c: 1.0},
        {v: SpellType_RandomTeleport, c: 0.5},
        {v: SpellType_SafeTeleport, c: 0.5},
        {v: SpellType_ModHealthMax, c: 1.0},
        {v: SpellType_ShowThings, c: 0.5},
        {v: SpellType_AoeDamage, c: 1.0},
        {v: SpellType_ModUseCharges, c: 0.5},
        {v: SpellType_CopyItem, c: 10000},
        ]);

    var duration_type = switch (type) {
        case SpellType_Nolos: SpellDuration_EveryTurn;
        case SpellType_Noclip: SpellDuration_EveryTurn;
        case SpellType_RandomTeleport: SpellDuration_Permanent;
        case SpellType_SafeTeleport: SpellDuration_Permanent;
        case SpellType_ModHealthMax: SpellDuration_Permanent;
        case SpellType_UncoverMap: SpellDuration_EveryTurn;
        case SpellType_ShowThings: SpellDuration_EveryTurn;
        case SpellType_AoeDamage: Pick.value([
            {v: SpellDuration_Permanent, c: 3.0},
            {v: SpellDuration_EveryTurn, c: 1.0},]);
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
            case SpellType_AoeDamage: Random.int(30, 50);
            default: 0;
        }
    }

    var value = switch (type) {
        case SpellType_ModHealthMax: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModUseCharges: 1;
        default: 0;
    }

    var element = switch (type) {
        case SpellType_ModHealthMax: ElementType_Shadow;
        case SpellType_UncoverMap: ElementType_Light;
        case SpellType_Nolos: ElementType_Light;
        case SpellType_Noclip: ElementType_Shadow;
        case SpellType_RandomTeleport: ElementType_Shadow;
        case SpellType_SafeTeleport: ElementType_Light;
        case SpellType_ShowThings: ElementType_Fire;
        case SpellType_AoeDamage: random_element();
        case SpellType_ModUseCharges: ElementType_Shadow;
        case SpellType_CopyItem: ElementType_Light;
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

static function random_ring_spell(level: Int): Spell {
    var type = Pick.value([
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModHealthMax, c: 5.0},
        {v: SpellType_ModDefense, c: 10.0},
        {v: SpellType_AoeDamage, c: 1.0},
        ]);

    var duration = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttack;
        default: SpellDuration_EveryTurn;
    }

    var value = switch (type) {
        case SpellType_ModHealthMax: Stats.get({min: 4, max: 7, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        default: 0;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(10, 15);
        default: 1;
    }

    // Figure out when to make elements random
    var element = switch (type) {
        case SpellType_ModHealthMax: ElementType_Physical;
        case SpellType_ModAttack: ElementType_Physical;
        case SpellType_ModDefense: ElementType_Physical;
        case SpellType_AoeDamage: random_element();
        default: ElementType_Physical;
    }

    return {
        type: type,
        element: ElementType_Physical,
        duration_type: duration,
        duration: Entity.INFINITE_DURATION,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function enemy_curse_spells(): Array<Spell> {
    var level = Main.current_level;

    var type = Pick.value([
        {v: SpellType_ModLevelHealth, c: 1.0},
        {v: SpellType_ModLevelAttack, c: 1.0},
        {v: SpellType_ModLevelAbsorb, c: 1.0},
        ]);

    var elements = switch (type) {
        case SpellType_ModLevelAbsorb: all_elements();
        case SpellType_ModLevelHealth: [ElementType_Shadow];
        case SpellType_ModLevelAttack: all_elements();
        default: [ElementType_Shadow];
    }

    return [for (element in elements) {
        type: type,
        element: element,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level),
        origin_name: "noname",
    }];
}

static function enemy_buff_spells(avoid_type: SpellType = null): Array<Spell> {
    var level = Main.current_level;
    
    // Select buff type that's not the same as curse
    var type = avoid_type;
    while (type == avoid_type) {
        type = Pick.value([
            {v: SpellType_ModLevelHealth, c: 1.0},
            {v: SpellType_ModLevelAttack, c: 1.0},
            {v: SpellType_ModLevelAbsorb, c: 1.0},
            ]);
    }

    var elements = switch (type) {
        case SpellType_ModLevelAbsorb: all_elements();
        case SpellType_ModLevelHealth: [ElementType_Shadow];
        case SpellType_ModLevelAttack: [random_element()];
        default: [ElementType_Shadow];
    }

    return [for (element in elements) {
        type: type,
        element: element,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: 1 * Stats.get({min: 1, max: 1, scaling: 0.25}, level),
        origin_name: "noname",
    }];
} 

static function player_buff_spell(): Spell {
    var level = Main.current_level;

    var type = Pick.value([
        {v: SpellType_ModAttack, c: 3.0},
        {v: SpellType_ModDefense, c: 3.0},
        {v: SpellType_AoeDamage, c: 1.0},
        ]);

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(10, 15);
        default: 1;
    }

    var value = switch (type) {
        case SpellType_ModAttack: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 4, max: 6, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        default: 0;
    }

    var element = switch (type) {
        case SpellType_ModAttack: random_element();
        case SpellType_ModDefense: random_element();
        case SpellType_AoeDamage: random_element();
        default: ElementType_Physical;
    }

    return {
        type: type,
        element: element,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.LEVEL_DURATION,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

// Enohik, ice
// +player stat bonus for level
// -enemy buff
static function statue_enohik(level: Int): Array<Spell> {
    return enemy_buff_spells().concat([player_buff_spell()]);
}

// Subere, shadow
// +enemy curse
// -random teleport every X turns
static function statue_subere(level: Int): Array<Spell> {
    function random_teleport_spell(): Spell {
        return {
            type: SpellType_RandomTeleport,
            element: ElementType_Shadow,
            duration_type: SpellDuration_EveryTurn,
            duration: Entity.LEVEL_DURATION,
            interval: Random.int(100, 150),
            interval_current: 0,
            value: 0,
            origin_name: "noname",
        };
    } 

    return enemy_curse_spells().concat([random_teleport_spell()]);
}

// Sera, physical
// +enemy curse
// -enemy buff
static function statue_sera(level: Int): Array<Spell> {
    var curses = enemy_curse_spells();
    var buffs = enemy_buff_spells(curses[0].type);

    return curses.concat(buffs);
}

// Ollopa, light
// +drop related bonus for level or noclip
// -enemy buff
static function statue_ollopa(level: Int): Array<Spell> {
    function level_buff_spell(): Spell {
        var type = Pick.value([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperDrop, c: 1.0},
            {v: SpellType_ModDropLevel, c: 1.0},
            {v: SpellType_Noclip, c: 1.0},
            ]);

        var value = switch (type) {
            case SpellType_ModCopperDrop: 10 * Stats.get({min: 1, max: 2, scaling: 1.0}, level);
            case SpellType_ModDropChance: 10 * Random.int(4, 6);
            case SpellType_ModDropLevel: Random.int(1, 2);
            default: 0;
        }

        return {
            type: type,
            element: ElementType_Light,
            duration_type: SpellDuration_EveryTurn,
            duration: Entity.LEVEL_DURATION,
            interval: 1,
            interval_current: 0,
            value: value,
            origin_name: "noname",
        };
    }

    return enemy_buff_spells().concat([level_buff_spell()]);
}

// Suthaephes, fire
// +player stat bonus for level
// -health (dealt as fire)
static function statue_suthaephes(level: Int): Array<Spell> {
    function health_cost_spell(): Spell {
        var duration_type = Pick.value([
            {v: SpellDuration_Permanent, c: 2.0},
            {v: SpellDuration_EveryTurn, c: 1.0},
            ]);

        var interval = switch (duration_type) {
            case SpellDuration_EveryTurn: Random.int(30, 40);
            default: 1;
        }

        var duration = if (duration_type == SpellDuration_Permanent) {
            0;
        } else {
            Entity.LEVEL_DURATION;
        }

        var value = switch (duration_type) {
            case SpellDuration_Permanent: Stats.get({min: 5, max: 7, scaling: 1.0}, level);
            case SpellDuration_EveryTurn: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            default: 0;
        }

        return {
            type: SpellType_ModHealth,
            element: ElementType_Fire,
            duration_type: duration_type,
            duration: duration,
            interval: interval,
            interval_current: 0,
            value: -1 * value,
            origin_name: "noname",
        };
    } 

    return [player_buff_spell(), health_cost_spell()];
}

static function poison_room(r: Room) {
    var level = Main.current_level;

    // NOTE: all locations get a shared reference to spell so that duration is shared between them, otherwise the spell wouldn't tick unless you stood in the same place 
    var poison_spell = {
        type: SpellType_ModHealth,
        element: ElementType_Shadow,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: Random.int(10, 15),
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level),
        origin_name: "noname",
    };

    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            Main.location_spells[x][y].push(poison_spell);
            Main.tiles[x][y] = Tile.Poison;
        }
    }
}

static function lava_room(r: Room) {
    var level = Main.current_level;
    
    var lava_spell = {
        type: SpellType_ModHealth,
        element: ElementType_Fire,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: Random.int(2, 3),
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level),
        origin_name: "noname",
    };

    // Lava only covers portions of the room
    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            if (Random.chance(10)) {
                Main.location_spells[x][y].push(lava_spell);
                Main.tiles[x][y] = Tile.Lava;
            }
        }
    }
}

static function ice_room(r: Room) {
    var level = Main.current_level;

    var ice_spell = {
        type: SpellType_ModHealth,
        element: ElementType_Ice,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: Random.int(10, 15),
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.1}, level),
        origin_name: "noname",
    };

    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            Main.location_spells[x][y].push(ice_spell);
            Main.tiles[x][y] = Tile.Ice;
        }
    }
}

static function teleport_room(r: Room) {
    var level = Main.current_level;
    
    var teleport_spell = {
        type: SpellType_RandomTeleport,
        element: ElementType_Light,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: Random.int(40, 60),
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    };

    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            Main.location_spells[x][y].push(teleport_spell);
            Main.tiles[x][y] = Tile.Magical;
        }
    }
}

static function ailment_room(r: Room) {
    var level = Main.current_level;
    
    // TODO: decrease all defences
    var decrease_def_spells = 
    [for (element in Type.allEnums(ElementType)) {
        type: SpellType_ModDefense,
        element: element,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.INFINITE_DURATION,
        interval: 1,
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level),
        origin_name: "noname",
    }];

    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            for (spell in decrease_def_spells) {
                Main.location_spells[x][y].push(spell);
            }
            Main.tiles[x][y] = Tile.Ice;
        }
    }
}

}