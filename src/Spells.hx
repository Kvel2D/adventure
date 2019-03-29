
import haxegon.*;
import Entity;
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
    SpellType_ModCopperChance;
    SpellType_AoeDamage;
    SpellType_Combust;
    SpellType_ModDropLevel;
    SpellType_Invisibility;
    SpellType_EnergyShield;
    SpellType_DamageShield;
    SpellType_ChainDamage;
    SpellType_HealthLeech;

    SpellType_ModLevelHealth;
    SpellType_ModLevelAttack;

    SpellType_ModUseCharges;
    SpellType_CopyEntity;
    SpellType_ImproveEquipment;
    SpellType_EnchantEquipment;
    SpellType_Passify;
    SpellType_Sleep;
    SpellType_SwapHealth;

    SpellType_SummonGolem;
    SpellType_SummonSkeletons;
    SpellType_SummonImp;

    SpellType_ModCopper;
    SpellType_ModSpellDamage;

    SpellType_ModAttackByCopper;
    SpellType_ModDefenseByCopper;
}

enum SpellDuration {
    SpellDuration_Permanent;
    SpellDuration_EveryTurn;
    SpellDuration_EveryAttack;
}

enum StatueGod {
    StatueGod_Sera;
    StatueGod_Subere;
    StatueGod_Ollopa;
    StatueGod_Suthaephes;
    StatueGod_Enohik;
}

enum SpellColor {
    SpellColor_None;
    SpellColor_Gray;
    SpellColor_Blue;
    SpellColor_Yellow;
    SpellColor_Purple;
    SpellColor_Red;
    SpellColor_Green;
}

typedef Spell = {
    var type: SpellType;
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

SpellType_CopyEntity => 1,
SpellType_ModUseCharges => 1,
SpellType_Invisibility => 1,
SpellType_ModDropChance => 1,
SpellType_ModCopperChance => 1,
SpellType_ModDropLevel => 1,
SpellType_EnergyShield => 1,
SpellType_DamageShield => 1,
SpellType_Passify => 1,
SpellType_Sleep => 1,
SpellType_ImproveEquipment => 1,
SpellType_EnchantEquipment => 1,
SpellType_ModCopper => 1,
SpellType_HealthLeech => 1,
SpellType_SwapHealth => 1,
SpellType_ModSpellDamage => 1,

SpellType_ModHealthMax => 2,
SpellType_ModHealth => 2,
SpellType_ModAttack => 2,
SpellType_ModAttackByCopper => 2,
SpellType_ModDefenseByCopper => 2,
SpellType_ModDefense => 2,
SpellType_AoeDamage => 2,
SpellType_ChainDamage => 2,
SpellType_Combust => 2,

SpellType_ModLevelHealth => 3,
SpellType_ModLevelAttack => 3,
SpellType_ShowThings => 3,
SpellType_UncoverMap => 3,
SpellType_SafeTeleport => 3,
SpellType_RandomTeleport => 3,
SpellType_Nolos => 3,
SpellType_Noclip => 3,
SpellType_ModMoveSpeed => 3,
SpellType_SummonGolem => 3,
SpellType_SummonSkeletons => 3,
SpellType_SummonImp => 3,
];
static inline var last_prio = 3;

// the interval thing is only for heal over time/dmg over time
// attack bonuses/ health max bonuses are applied every turn
static function get_description(spell: Spell): String {
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
        case SpellType_ModAttack: '$sign${spell.value} attack';
        case SpellType_ModDefense: '$sign${spell.value} defense';
        case SpellType_ModMoveSpeed: '$sign${spell.value} move speed';
        case SpellType_ModDropChance: '$sign${spell.value}% item drop chance';
        case SpellType_ModCopperChance: '$sign${spell.value}% copper drop chance';
        case SpellType_ModLevelHealth: '$sign${spell.value} health to all enemies on the current floor';
        case SpellType_ModLevelAttack: '$sign${spell.value} attack to all enemies on the current floor';
        case SpellType_EnergyShield: 'Energy Shield: get energy shield that absorbs ${spell.value} damage';
        case SpellType_Invisibility: 'turn invisible';
        case SpellType_ModDropLevel: 'make item drops more powerful';
        case SpellType_UncoverMap: 'uncover map';
        case SpellType_RandomTeleport: 'random teleport';
        case SpellType_SafeTeleport: 'safe teleport';
        case SpellType_Nolos: 'see everything';
        case SpellType_Noclip: 'go through walls';
        case SpellType_ShowThings: 'see treasure on the map';
        case SpellType_NextFloor: 'go to next floor';
        case SpellType_AoeDamage: 'Inferno: deal ${spell.value} damage to all visible enemies';
        case SpellType_ModUseCharges: 'add ${spell.value} use charges to item in your inventory';
        case SpellType_CopyEntity: 'Copy: copy anything (copy is placed on the ground, must have free space around you or the spell fails and orb disappears)';
        case SpellType_Passify: 'Passify: passify an enemy';
        case SpellType_Sleep: 'Sleep: put an enemy to sleep';
        case SpellType_ImproveEquipment: 'Improve equipment: improve weapon or armor, increasing it\'s attack or defense bonus permanently';
        case SpellType_EnchantEquipment: 'Enchant Equipment: enchant weapon or armor, giving it a random equip spell';
        case SpellType_DamageShield: 'Damaging Shield: deal ${spell.value} damage to attackers';
        case SpellType_SummonGolem: 'Summon Golem: summon a golem that follows and protects you';
        case SpellType_SummonSkeletons: 'Summon Skeletons: summon three skeletons that attack nearest enemies';
        case SpellType_SummonImp: 'Summon Imp: summon an imp that protects you, it can\'t move but it can shoot fireballs!';
        case SpellType_ChainDamage: 'Light Chain: deals ${spell.value} damage to an enemy near to you, then jumps to nearby enemies, doubling the damage with each jump';
        case SpellType_ModCopper: '$sign ${spell.value} copper';
        case SpellType_HealthLeech: 'Health Leech: damage dealt to enemies has a chance to also heal you';
        case SpellType_SwapHealth: 'Swap Health: swaps yours and target enemy\'s current health, doesn\'t affect max health';
        case SpellType_ModSpellDamage: 'increases all spell damage by ${spell.value}';
        case SpellType_ModAttackByCopper: '+ to attack based on copper count';
        case SpellType_ModDefenseByCopper: '+ to defense based on copper count';
        case SpellType_Combust: 'Combust: blow up an enemy dealing ${spell.value} damage to everything nearby';
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
            // NOTE: special case because "x every attack for y attacks" sounds bad
            // do "x for y attacks" instead
            // ' every attack';
            '';
        } else {
            ' BAD INTERVAL';
        }
    }

    var duration = 
    if (spell.duration == Entity.DURATION_INFINITE) {
        '';
    } else if (spell.duration == Entity.DURATION_LEVEL) {
        ' for the rest of the floor';
    } else {
        switch (spell.duration_type) {
            case SpellDuration_Permanent: '';
            case SpellDuration_EveryTurn: ' for ${spell.duration} turns';
            case SpellDuration_EveryAttack: ' for ${spell.duration} attacks';
        }
    }

    return '$effect$interval$duration';
}

static function get_color(spell: Spell) {
    return switch (spell.type) {
        case SpellType_ModAttack: SpellColor_Gray;
        case SpellType_ModDefense: SpellColor_Gray;
        case SpellType_Passify: SpellColor_Gray;
        case SpellType_Sleep: SpellColor_Gray;

        case SpellType_ModSpellDamage: SpellColor_Blue;
        case SpellType_EnergyShield: SpellColor_Blue;
        case SpellType_DamageShield: SpellColor_Blue;

        case SpellType_UncoverMap: SpellColor_Yellow;
        case SpellType_ShowThings: SpellColor_Yellow;
        case SpellType_RandomTeleport: SpellColor_Yellow;
        case SpellType_Nolos: SpellColor_Yellow;
        case SpellType_Noclip: SpellColor_Yellow;

        case SpellType_ModMoveSpeed: SpellColor_Purple;
        case SpellType_Invisibility: SpellColor_Purple;
        case SpellType_SafeTeleport: SpellColor_Purple;
        case SpellType_ModCopper: SpellColor_Purple;
        case SpellType_SummonSkeletons: SpellColor_Purple;
        case SpellType_SummonGolem: SpellColor_Purple;
        case SpellType_SummonImp: SpellColor_Purple;

        case SpellType_ModDropChance: SpellColor_Red;
        case SpellType_ModHealthMax: SpellColor_Red;
        case SpellType_AoeDamage: SpellColor_Red;
        case SpellType_Combust: SpellColor_Red;
        case SpellType_ChainDamage: SpellColor_Red;
        case SpellType_ModCopperChance: SpellColor_Red;

        case SpellType_ModHealth: SpellColor_Green;
        case SpellType_SwapHealth: SpellColor_Green;
        case SpellType_HealthLeech: SpellColor_Green;

        case SpellType_ModUseCharges: SpellColor_Blue;
        case SpellType_CopyEntity: SpellColor_Yellow;
        case SpellType_ImproveEquipment: SpellColor_Gray;
        case SpellType_EnchantEquipment: SpellColor_Red;

        default: SpellColor_Gray;
    }
}

static function need_target(type: SpellType): Bool {
    return switch (type) {
        case SpellType_ModUseCharges: true;
        case SpellType_CopyEntity: true;
        case SpellType_Passify: true;
        case SpellType_Sleep: true;
        case SpellType_ImproveEquipment: true;
        case SpellType_EnchantEquipment: true;
        case SpellType_SwapHealth: true;
        case SpellType_Combust: true;
        default: false;
    }
}

static function spell_can_be_used_on_target(type: SpellType, target: Int): Bool {
    return switch (type) {
        case SpellType_ModUseCharges: Entity.item.exists(target) && !Entity.position.exists(target);
        case SpellType_CopyEntity: Entity.position.exists(target) || (!Entity.position.exists(target) && (Entity.item.exists(target) || Entity.equipment.exists(target)));
        case SpellType_Passify: Entity.combat.exists(target);
        case SpellType_Sleep: Entity.combat.exists(target);
        case SpellType_ImproveEquipment: Entity.equipment.exists(target);
        case SpellType_EnchantEquipment: Entity.equipment.exists(target);
        case SpellType_SwapHealth: Entity.combat.exists(target);
        case SpellType_Combust: Entity.combat.exists(target);
        default: false;
    }
}

static function copy(spell: Spell): Spell {
    return {
        type: spell.type,
        duration_type: spell.duration_type,
        duration: spell.duration,
        interval: spell.interval,
        interval_current: spell.interval_current,
        value: spell.value,
        origin_name: spell.origin_name,
    };
}

static function attack_buff(value: Int): Spell {
    return {
        type: SpellType_ModAttack,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function defense_buff(value: Int): Spell {
    return {
        type: SpellType_ModDefense,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

static function health_instant(): Spell {
    return {
        type: SpellType_ModHealth,
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
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: 1,
        interval_current: 0,
        value: 6,
        origin_name: "noname",
    }
}

static function poison(): Spell {
    return {
        type: SpellType_ModHealth,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: 4,
        interval_current: 0,
        value: -1,
        origin_name: "noname",
    }
}

static function safe_teleport(): Spell {
    return {
        type: SpellType_SafeTeleport,
        duration_type: SpellDuration_Permanent,
        duration: Entity.DURATION_INFINITE,
        interval: 0,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function random_teleport(): Spell {
    return {
        type: SpellType_RandomTeleport,
        duration_type: SpellDuration_Permanent,
        duration: Entity.DURATION_INFINITE,
        interval: 0,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function nolos(): Spell {
    return {
        type: SpellType_Nolos,
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
        type: SpellType_ModCopperChance,
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
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_LEVEL,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function uncover_map(): Spell {
    return {
        type: SpellType_UncoverMap,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_LEVEL,
        interval: 1,
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    }
}

static function mod_level_health(): Spell {
    return {
        type: SpellType_ModLevelHealth,
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
        type: SpellType_CopyEntity,
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
        type: SpellType_ModCopperChance,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_LEVEL,
        interval: 1,
        interval_current: 0,
        value: 2,
        origin_name: "noname",
    }
}

static function mod_copper(amount: Int): Spell {
    return {
        type: SpellType_ModCopper,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: amount,
        origin_name: "noname",
    }
}

static function random_potion_spell(level: Int, force_spell: SpellType): Spell {
    var type = if (force_spell != null) {
        force_spell;
    } else {
        Random.pick_chance([
            // NOTE: health potions are rolled separately from random_potion through force_spell
            // {v: SpellType_ModHealth, c: 1.0},

            {v: SpellType_ModAttack, c: 1.0},
            {v: SpellType_ModDefense, c: 1.0},

            {v: SpellType_ModSpellDamage, c: 0.5},

            {v: SpellType_UncoverMap, c: 0.25},
            {v: SpellType_ShowThings, c: 0.25},

            {v: SpellType_ModMoveSpeed, c: 0.25},
            {v: SpellType_Invisibility, c: 0.25},

            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_ModHealthMax, c: 1.0},
            ]);
    }

    var duration_type = SpellDuration_Permanent;
    var duration = 0;
    var value = 0;

    switch (type) {
        case SpellType_ModHealth: {
            duration_type = SpellDuration_Permanent;
            duration = 0;
            value = Stats.get({min: 5, max: 5, scaling: 1.0}, level);
        }
        case SpellType_ModAttack: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(3, 7);
            value = Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        }
        case SpellType_ModDefense: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(3, 7);
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_ModSpellDamage: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(20, 30);
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        }
        case SpellType_UncoverMap: {
            duration_type = SpellDuration_EveryTurn;
            duration = Entity.DURATION_LEVEL;
            value = 0;
        }
        case SpellType_ShowThings: {
            duration_type = SpellDuration_EveryTurn;
            duration = Entity.DURATION_LEVEL;
            value = 0;
        }
        case SpellType_ModMoveSpeed: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(4, 6);
            value = Random.int(1, 2);
        }
        case SpellType_Invisibility: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(60, 80);
            value = 0;
        }
        case SpellType_ModCopperChance: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(7, 11);
            value = Random.int(10, 15);
        }
        case SpellType_ModHealthMax: {
            duration_type = SpellDuration_Permanent;
            duration = 0;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        default: {
            trace('Unhandled potion spell type: ${type}');
        }
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

static function random_scroll_spell(level: Int): Spell {
    var type = Random.pick_chance([
        {v: SpellType_Passify, c: 0.5},
        {v: SpellType_Sleep, c: 0.5},

        {v: SpellType_EnergyShield, c: 1.0},
        {v: SpellType_DamageShield, c: 1.0},

        {v: SpellType_RandomTeleport, c: 0.5},
        {v: SpellType_Nolos, c: 0.25},
        {v: SpellType_Noclip, c: 0.5},

        {v: SpellType_SummonGolem, c: 1.0},
        {v: SpellType_SummonSkeletons, c: 1.0},
        {v: SpellType_SummonImp, c: 1.0},
        
        {v: SpellType_AoeDamage, c: 1.0},
        {v: SpellType_Combust, c: 1.0},
        {v: SpellType_ChainDamage, c: 1.0},

        {v: SpellType_SwapHealth, c: 0.25},
        {v: SpellType_HealthLeech, c: 0.5},
        ]);

    var duration_type = SpellDuration_Permanent;
    var duration = 0;
    var value = 0;

    switch (type) {
        case SpellType_Passify: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_Sleep: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_EnergyShield: {
            duration_type = SpellDuration_Permanent;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_DamageShield: {
            duration_type = SpellDuration_EveryTurn;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
            duration = Random.int(60, 90);
        }
        case SpellType_RandomTeleport: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_Nolos: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(60, 90);
        }
        case SpellType_Noclip: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(60, 90);
        }
        case SpellType_SummonGolem: {
            duration_type = SpellDuration_Permanent;
            value = level;
        }
        case SpellType_SummonSkeletons: {
            duration_type = SpellDuration_Permanent;
            value = level;
        }
        case SpellType_SummonImp: {
            duration_type = SpellDuration_Permanent;
            value = level;
        }
        case SpellType_AoeDamage: {
            duration_type = SpellDuration_Permanent;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_Combust: {
            duration_type = SpellDuration_Permanent;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_ChainDamage: {
            duration_type = SpellDuration_Permanent;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_SwapHealth: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_HealthLeech: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(3, 6);
            value = Random.int(20, 30);
        }
        default: {
            trace('Unhandled scroll spell type: ${type}');
        }
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }; 
}

static function random_ring_spell(level: Int): Spell {
    var type = Random.pick_chance([
        {v: SpellType_ModAttack, c: if (level <= 2) {
            0.0;
        } else {
            1000.0;
        }},
        {v: SpellType_ModDefense, c: 1.0},

        {v: SpellType_ModSpellDamage, c: 1.0},
        {v: SpellType_EnergyShield, c: 0.5},

        {v: SpellType_ShowThings, c: 0.5},
        {v: SpellType_Noclip, c: 0.05},

        // TODO: this needs to be use if want to add
        // {v: SpellType_SafeTeleport, c: 1.0},
        {v: SpellType_ModCopper, c: 1.0},

        {v: SpellType_ModDropChance, c: 1.0},
        {v: SpellType_ModCopperChance, c: 1.0},

        {v: SpellType_ModHealth, c: 1.0},
        {v: SpellType_HealthLeech, c: 0.25},
        ]);

    var duration_type = SpellDuration_Permanent;
    var duration = 0;
    var value = 0;
    var interval = 1;

    switch (type) {
        case SpellType_ModAttack: {
            duration_type = SpellDuration_EveryTurn;
            value = Stats.get({min: 1, max: 1, scaling: 0.2}, level);
        }
        case SpellType_ModDefense: {
            duration_type = SpellDuration_EveryTurn;
            value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        }
        case SpellType_ModSpellDamage: {
            duration_type = SpellDuration_EveryTurn;
            value = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        }
        case SpellType_EnergyShield: {
            duration_type = SpellDuration_EveryAttack;
            value = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
            interval = 4;
        }
        case SpellType_ShowThings: {
            duration_type = SpellDuration_EveryTurn;
        }
        case SpellType_Noclip: {
            duration_type = SpellDuration_EveryTurn;
        }
        case SpellType_ModCopper: {
            duration_type = SpellDuration_EveryAttack;
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            interval = 5;
        }
        case SpellType_ModDropChance: {
            duration_type = SpellDuration_EveryTurn;
            value = Random.int(10, 15);
        }
        case SpellType_ModCopperChance: {
            duration_type = SpellDuration_EveryTurn;
            value = Random.int(10, 15);
        }
        case SpellType_ModHealth: {
            duration_type = SpellDuration_EveryAttack;
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            interval = 5;
        }
        case SpellType_HealthLeech: {
            duration_type = SpellDuration_EveryTurn;
            value = Random.int(20, 30);
        }
        default: {
            trace('Unhandled ring spell type: ${type}');
        }
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: Entity.DURATION_INFINITE,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function random_orb_spell(level: Int): Spell {
    var type = Random.pick_chance([
        {v: SpellType_ModUseCharges, c: 1.0},
        {v: SpellType_CopyEntity, c: 1.0},
        {v: SpellType_ImproveEquipment, c: 1.0},
        {v: SpellType_EnchantEquipment, c: 1.0},
        ]);

    var duration_type = SpellDuration_Permanent;
    var duration = 0;
    var value = 0;

    switch (type) {
        case SpellType_ModUseCharges: {
            value = 1;
        }
        case SpellType_CopyEntity: {
        }
        case SpellType_ImproveEquipment: {
            value = Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        }
        case SpellType_EnchantEquipment: {
        }
        default: {
            trace('Unhandled orb spell type: ${type}');
        }
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    }
}

static function enemy_buff_spell(avoid_type: SpellType = null): Spell {
    var level = Main.current_level;
    
    // Select buff type that's not the same as curse
    var type = avoid_type;
    while (type == avoid_type) {
        type = Random.pick_chance([
            {v: SpellType_ModLevelHealth, c: 1.0},
            {v: SpellType_ModLevelAttack, c: 1.0},
            ]);
    }

    var value = switch (type) {
        case SpellType_ModLevelHealth: Stats.get({min: 2, max: 3, scaling: 0.5}, level);
        case SpellType_ModLevelAttack: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        default: 100;
    }

    return {
        type: type,
        duration_type: SpellDuration_Permanent,
        duration: 0,
        interval: 0,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
} 

static function player_stat_buff_spell(): Spell {
    var level = Main.current_level;

    var type = Random.pick_chance([
        {v: SpellType_ModAttack, c: 3.0},
        {v: SpellType_ModDefense, c: 3.0},
        {v: SpellType_AoeDamage, c: 1.0},
        ]);

    var duration_type = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttack;
        default: SpellDuration_EveryTurn;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(10, 15);
        default: 1;
    }

    var value = switch (type) {
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 4, max: 6, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        default: 0;
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: Entity.DURATION_LEVEL,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

static function statue_enohik(level: Int): Array<Spell> {
    return [
    player_stat_buff_spell(), 
    enemy_buff_spell(),
    ];
}

static function statue_subere(level: Int): Array<Spell> {
    // NOTE: these are *level-wide* spells, but not *level-long*, only done once
    var enemy_curse = {
        var level = Main.current_level;

        var type = Random.pick_chance([
            {v: SpellType_ModLevelHealth, c: 1.0},
            {v: SpellType_ModLevelAttack, c: 1.0},
            ]);

        var value = switch (type) {
            case SpellType_ModLevelHealth: -1 * Stats.get({min: 2, max: 3, scaling: 0.5}, level);
            case SpellType_ModLevelAttack: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level);
            default: 100;
        }

        {
            type: type,
            duration_type: SpellDuration_Permanent,
            duration: 0,
            interval: 0,
            interval_current: 0,
            value: value,
            origin_name: "noname",
        };
    }
    var no_drop_spell = {
        type: SpellType_ModDropChance,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_LEVEL,
        interval: 1,
        interval_current: 0,
        value: -100,
        origin_name: "noname",
    };

    return [
    enemy_curse,
    no_drop_spell,
    ];
}

static function statue_sera(level: Int): Array<Spell> {
    return [player_stat_buff_spell(), mod_copper(-1 * Stats.get({min: 2, max: 3, scaling: 1.0}, level))];
}

static function statue_ollopa(level: Int): Array<Spell> {
    var player_special_level_buff = {
        var type = Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_ModDropLevel, c: 1.0},
            {v: SpellType_Noclip, c: 1.0},
            ]);

        var value = switch (type) {
            case SpellType_ModCopperChance: Random.int(25, 75);
            case SpellType_ModDropChance: 10 * Random.int(4, 6);
            case SpellType_ModDropLevel: Random.int(1, 2);
            default: 0;
        }

        {
            type: type,
            duration_type: SpellDuration_EveryTurn,
            duration: Entity.DURATION_LEVEL,
            interval: 1,
            interval_current: 0,
            value: value,
            origin_name: "noname",
        };
    }

    return [
    player_special_level_buff,
    enemy_buff_spell(),
    ];
}

static function statue_suthaephes(level: Int): Array<Spell> {
    function health_cost_spell(): Spell {
        var duration_type = Random.pick_chance([
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
            Entity.DURATION_LEVEL;
        }

        var value = switch (duration_type) {
            case SpellDuration_Permanent: Stats.get({min: 5, max: 7, scaling: 1.0}, level);
            case SpellDuration_EveryTurn: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            default: 0;
        }

        return {
            type: SpellType_ModHealth,
            duration_type: duration_type,
            duration: duration,
            interval: interval,
            interval_current: 0,
            value: -1 * value,
            origin_name: "noname",
        };
    } 

    return [
    player_stat_buff_spell(), 
    health_cost_spell()
    ];
}

static function poison_room_spell(): Spell {
    var level = Main.current_level;
    
    return {
        type: SpellType_ModHealth,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: Random.int(15, 20),
        interval_current: 0,
        value: -1 * Stats.get({min: 1, max: 1, scaling: 0.5}, level),
        origin_name: "noname",
    };
}

static function teleport_room_spell(): Spell {
    return {
        type: SpellType_RandomTeleport,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: Random.int(Std.int(GenerateWorld.ROOM_SIZE_MAX * 0.5), GenerateWorld.ROOM_SIZE_MAX * 3),
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    };
}

static function random_equipment_spell_equip_negative(equipment_type: EquipmentType): Spell {
    var level = Main.get_drop_entity_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_ModDefense, c: 1.0},
            {v: SpellType_ModHealthMax, c: 1.0},
            {v: SpellType_SummonSkeletons, c: 1.0},
            {v: SpellType_SummonSkeletons, c: 1.0},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_ModHealthMax, c: 1.0},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModHealthMax, c: 1.0},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModHealthMax, c: 1.0},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_ModHealth: Random.pick_chance([
            {v: SpellDuration_EveryAttack, c: 1.0},
            {v: SpellDuration_EveryTurn, c: 0.5},
            ]);
        case SpellType_SummonSkeletons: SpellDuration_EveryAttack;
        case SpellType_ModHealthMax: SpellDuration_EveryTurn;
        case SpellType_ModDefense: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var interval = switch (type) {
        case SpellType_ModHealth: switch (duration_type) {
            case SpellDuration_EveryAttack: Random.int(10, 15);
            case SpellDuration_EveryTurn: Random.int(30, 50);
            default: 1;
        }
        case SpellType_SummonSkeletons: Random.int(15, 20);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_ModHealth: -1 * Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDefense: -1 * Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModHealthMax: -1 * Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        default: 0;
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: Entity.DURATION_INFINITE,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

static function get_weapon_equip_spell_weight(spell: Spell): Float {
    return switch (spell.type) {
        case SpellType_AoeDamage: 0.1 * spell.value;
        case SpellType_ChainDamage: 0.1 * spell.value;
        case SpellType_ModHealth: 0.1 * spell.value;
        case SpellType_EnergyShield: 0.1 * spell.value;
        case SpellType_ModAttackByCopper: 0.1 * spell.value;
        default: 0;
    }
}

static function random_equipment_spell_equip(equipment_type: EquipmentType): Spell {
    var level = Main.get_drop_entity_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},

            {v: SpellType_Combust, c: 1.0},
            {v: SpellType_ChainDamage, c: 1.0},
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_ModAttackByCopper, c: 1.0},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},

            {v: SpellType_UncoverMap, c: 1.0},
            {v: SpellType_ShowThings, c: 1.0},
            {v: SpellType_ModHealth, c: 1.0},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},

            {v: SpellType_AoeDamage, c: 1.0},

            {v: SpellType_ModDefenseByCopper, c: 1.0},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},

            {v: SpellType_DamageShield, c: 1.0},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttack;
        case SpellType_ChainDamage: SpellDuration_EveryAttack;
        case SpellType_Combust: SpellDuration_EveryAttack;
        case SpellType_ModHealth: SpellDuration_EveryAttack;
        case SpellType_EnergyShield: SpellDuration_EveryAttack;
        case SpellType_DamageShield: SpellDuration_EveryAttack;
        case SpellType_ShowThings: SpellDuration_EveryTurn;
        case SpellType_ModDropChance: SpellDuration_EveryTurn;
        case SpellType_ModCopperChance: SpellDuration_EveryTurn;
        case SpellType_ModAttackByCopper: SpellDuration_EveryTurn;
        case SpellType_ModDefenseByCopper: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(5, 8);
        case SpellType_ChainDamage: Random.int(5, 8);
        case SpellType_Combust: Random.int(5, 8);
        case SpellType_EnergyShield: Random.int(5, 8);
        case SpellType_DamageShield: Random.int(5, 8);
        case SpellType_ModHealth: Random.int(5, 8);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_Combust: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_DamageShield: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModHealth: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDropChance: Random.int(10, 20);
        case SpellType_ModCopperChance: Random.int(10, 20);
        default: 0;
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: Entity.DURATION_INFINITE,
        interval: interval,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

// NOTE: update this when adding new types to random_equipment_spell_use()
static function get_equipment_spell_use_charges(s: Spell): Int {
    return switch (s.type) {
        case SpellType_AoeDamage: Random.int(2, 4);
        case SpellType_Invisibility: Random.int(1, 3);
        case SpellType_EnergyShield: Random.int(2, 3);
        case SpellType_Nolos: Random.int(3, 5);
        case SpellType_ModHealth: Random.int(2, 3);
        case SpellType_ModMoveSpeed: Random.int(2, 3);
        case SpellType_SummonGolem: Random.int(2, 3);
        case SpellType_SummonImp: Random.int(2, 3);
        case SpellType_ModAttack: Random.int(2, 3);
        case SpellType_ChainDamage: Random.int(2, 3);
        case SpellType_RandomTeleport: 1;
        case SpellType_SafeTeleport: 1;
        default: 100;
    }
}

static function get_spells_min_use_charges(spells: Array<Spell>) {
    var charges_min = 1000;
    for (spell in spells) {
        var charges = get_equipment_spell_use_charges(spell);
        if (charges < charges_min) {
            charges_min = charges;
        }
    }
    return charges_min;
}

static function get_weapon_use_spell_weight(spell: Spell): Float {
    return switch (spell.type) {
        case SpellType_AoeDamage: 0.1 * spell.value;
        case SpellType_SummonGolem: 0.3 * spell.value;
        case SpellType_ModAttack: 0.3 * spell.value;
        default: 0;
    }
}

static function random_equipment_spell_use(equipment_type: EquipmentType): Spell {
    var level = Main.get_drop_entity_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_AoeDamage, c: 1.0},
            {v: SpellType_Invisibility, c: 0.5},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_SummonGolem, c: 1.0},
            {v: SpellType_ModAttack, c: 1.0},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_Nolos, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_SummonImp, c: 1.0},
            {v: SpellType_ChainDamage, c: 1.0},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_AoeDamage, c: 1.0},
            {v: SpellType_Invisibility, c: 1.0},
            {v: SpellType_ModAttack, c: 1.0},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModMoveSpeed, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_RandomTeleport, c: 0.5},
            {v: SpellType_SafeTeleport, c: 0.5},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_Invisibility: SpellDuration_EveryTurn;
        case SpellType_Nolos: SpellDuration_EveryTurn;
        case SpellType_ModMoveSpeed: SpellDuration_EveryTurn;
        case SpellType_ModAttack: SpellDuration_EveryAttack;
        default: SpellDuration_Permanent;
    }

    var duration = switch (type) {
        case SpellType_Invisibility: Random.int(60, 80);
        case SpellType_Nolos: Random.int(60, 80);
        case SpellType_ModMoveSpeed: Random.int(60, 80);
        case SpellType_ModAttack: Random.int(3, 4);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModHealth: Stats.get({min: 3, max: 4, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_SummonGolem: level;
        case SpellType_SummonImp: level;
        case SpellType_ModMoveSpeed: 1;
        default: 0;
    }

    return {
        type: type,
        duration_type: duration_type,
        duration: duration,
        interval: 1,
        interval_current: 0,
        value: value,
        origin_name: "noname",
    };
}

// NOTE: returns [equip spells, use spells]
static function random_equipment_spells(equipment_type: EquipmentType): Array<Array<Spell>> {
    var level = Main.get_drop_entity_level();
    
    var total_spell_count: Int = Random.pick_chance([
        {v: 0, c: 1},
        {v: 1, c: 0.5},
        {v: 2, c: if (level > 0) 0.25 else 0},
        // {v: 3, c: if (level > 1) 0.125 else 0},
        ]);
    var spell_equip_count = 0;
    var spell_use_count = 0;
    var spell_equip_negative_count = 0;

    // TODO: no negative spells for armor for now, figure out which ones are good

    if (equipment_type == EquipmentType_Weapon) { 
        if (total_spell_count == 1) {
            Random.pick_chance([
                {v: function() {
                    spell_equip_count = 1;
                }, c: 1.0},
                {v: function() {
                    spell_use_count = 1;
                }, c: 1.0},
                ])
            ();
        } else if (total_spell_count == 2) {
            Random.pick_chance([
                {v: function() {
                    spell_equip_negative_count = 1;
                    spell_equip_count = 1;
                }, c: 1.0},
                {v: function() {
                    spell_equip_negative_count = 1;
                    spell_use_count = 1;
                }, c: 1.0},
                {v: function() {
                    spell_equip_count = 1;
                    spell_use_count = 1;
                }, c: 0.5},
                {v: function() {
                    spell_equip_count = 2;
                }, c: 0.5},
                ])
            ();
        } else if (total_spell_count == 3) {
            Random.pick_chance([
                {v: function() {
                    spell_equip_negative_count = 1;
                    spell_equip_count = 1;
                    spell_use_count = 1;
                }, c: 1.0},
                {v: function() {
                    spell_equip_negative_count = 1;
                    spell_equip_count = 2;
                }, c: 1.0},
                {v: function() {
                    spell_use_count = 1;
                    spell_equip_count = 2;
                }, c: 0.25},
                {v: function() {
                    spell_equip_count = 3;
                }, c: 0.25},
                ])
            ();
        }
    } else { 
        if (total_spell_count == 1) {
            Random.pick_chance([
                {v: function() {
                    spell_equip_count = 1;
                }, c: 1.0},
                {v: function() {
                    spell_use_count = 1;
                }, c: 0.5},
                ])
            ();
        } else if (total_spell_count == 2) {
            Random.pick_chance([
                {v: function() {
                    spell_equip_count = 1;
                    spell_use_count = 1;
                }, c: 0.5},
                {v: function() {
                    spell_equip_count = 2;
                }, c: 0.5},
                ])
            ();
        } else if (total_spell_count == 3) {
            Random.pick_chance([
                {v: function() {
                    spell_use_count = 1;
                    spell_equip_count = 2;
                }, c: 0.25},
                {v: function() {
                    spell_equip_count = 3;
                }, c: 0.25},
                ])
            ();
        }
    }


    var equip_spells = new Array<Spell>();
    for (i in 0...spell_equip_count) {
        equip_spells.push(Spells.random_equipment_spell_equip(equipment_type));
    }
    for (i in 0...spell_equip_negative_count) {
        equip_spells.push(Spells.random_equipment_spell_equip_negative(equipment_type));
    }

    var use_spells = new Array<Spell>();
    for (i in 0...spell_use_count) {
        use_spells.push(Spells.random_equipment_spell_use(equipment_type));
    }

    return [equip_spells, use_spells];
}

}