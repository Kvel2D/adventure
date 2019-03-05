
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
    SpellType_ModCopperDrop;
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
    SpellType_CopyItem;
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

SpellType_CopyItem => 1,
SpellType_ModUseCharges => 1,
SpellType_Invisibility => 1,
SpellType_ModDropChance => 1,
SpellType_ModCopperDrop => 1,
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
        case SpellType_ModCopperDrop: '$sign${spell.value}% copper drop chance';

        case SpellType_ModLevelHealth: '$sign${spell.value} health to all enemies on the level';
        case SpellType_ModLevelAttack: '$sign${spell.value} attack to all enemies on the level';

        case SpellType_EnergyShield: 'replenish energy shield to ${spell.value}';
        case SpellType_Invisibility: 'turn invisible';
        case SpellType_ModDropLevel: 'make item drops more powerful';
        case SpellType_UncoverMap: 'uncover map';
        case SpellType_RandomTeleport: 'random teleport';
        case SpellType_SafeTeleport: 'safe teleport';
        case SpellType_Nolos: 'see everything';
        case SpellType_Noclip: 'go through walls';
        case SpellType_ShowThings: 'see treasure on the map';
        case SpellType_NextFloor: 'go to next floor';
        case SpellType_AoeDamage: 'deal ${spell.value} damage to all visible enemies';
        case SpellType_ModUseCharges: 'add ${spell.value} use charges to item in your inventory';
        case SpellType_CopyItem: 'copy item in your inventory (copy is placed on the ground, must have free space around you or the spell fails and scroll disappears)';
        case SpellType_Passify: 'passify an enemy';
        case SpellType_Sleep: 'put an enemy to sleep';
        case SpellType_ImproveEquipment: 'improve weapon or armor, increasing it\'s attack or defense bonus permanently';
        case SpellType_EnchantEquipment: 'enchant weapon or armor, giving it a random equip spell';
        case SpellType_DamageShield: 'deal ${spell.value} damage to attackers';
        case SpellType_SummonGolem: 'summon a golem that follows and protects you';
        case SpellType_SummonSkeletons: 'summon three skeletons that attack nearest enemies';
        case SpellType_SummonImp: 'summon an imp that protects you, it can\'t move but it can shoot fireballs!';
        case SpellType_ChainDamage: 'deals ${spell.value} damage to an enemy near to you, then jumps to nearby enemies, doubling the damage with each jump';
        case SpellType_ModCopper: '$sign ${spell.value} copper';
        case SpellType_HealthLeech: 'all damage dealt to enemies also heals you';
        case SpellType_SwapHealth: 'swaps yours and target enemy\'s current health, doesn\'t affect max health';
        case SpellType_ModSpellDamage: 'increases all spell damage by ${spell.value}';
        case SpellType_ModAttackByCopper: '+ to attack based on copper count';
        case SpellType_ModDefenseByCopper: '+ to defense based on copper count';
        case SpellType_Combust: 'blow up an enemy dealing ${spell.value} damage to everything nearby';
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
    if (spell.duration == Entity.DURATION_INFINITE) {
        '';
    } else if (spell.duration == Entity.DURATION_LEVEL) {
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

static function need_target(type: SpellType): Bool {
    return switch (type) {
        case SpellType_ModUseCharges: true;
        case SpellType_CopyItem: true;
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
        case SpellType_CopyItem: Entity.item.exists(target) && !Entity.position.exists(target);
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
        type: SpellType_ModCopperDrop,
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
        type: SpellType_CopyItem,
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

static function random_potion_spell_and_tile(level: Int, force_spell: SpellType) {
    var type = if (force_spell != null) {
        force_spell;
    } else {
        Random.pick_chance([
            {v: SpellType_ModHealth, c: 4.0},
            {v: SpellType_ModHealthMax, c: 1.0},
            {v: SpellType_ModAttack, c: 0.5},
            {v: SpellType_ModDefense, c: 0.5},
            {v: SpellType_Invisibility, c: 0.1},
            {v: SpellType_ModMoveSpeed, c: 0.1},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_ModHealth: SpellDuration_Permanent;
        case SpellType_ModAttack: Random.pick_chance([
            {v: SpellDuration_EveryTurn, c: 5.0},
            {v: SpellDuration_EveryAttack, c: 1.0},
            ]);
        case SpellType_ModDefense: Random.pick_chance([
            {v: SpellDuration_EveryTurn, c: 5.0},
            {v: SpellDuration_EveryAttack, c: 1.0},
            ]);
        case SpellType_Invisibility: SpellDuration_EveryTurn;
        case SpellType_ModMoveSpeed: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = switch (type) {
        case SpellType_ModAttack: switch(duration_type) {
            case SpellDuration_EveryTurn: Entity.DURATION_LEVEL;
            case SpellDuration_EveryAttack: Random.int(10, 15);
            default: 1000;
        };
        case SpellType_ModDefense: switch(duration_type) {
            case SpellDuration_EveryTurn: Entity.DURATION_LEVEL;
            case SpellDuration_EveryAttack: Random.int(10, 15);
            default: 1000;
        };
        case SpellType_Invisibility: Random.int(60, 80);
        case SpellType_ModMoveSpeed: Random.int(3, 5);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_ModHealth: Stats.get({min: 5, max: 5, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_ModDefense: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModHealthMax: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModMoveSpeed: Random.int(3, 4);
        default: 0;
    }

    var tile = switch (type) {
        case SpellType_ModHealth: Tile.PotionHealing;
        case SpellType_ModAttack: Tile.PotionPhysical;
        case SpellType_ModDefense: Tile.PotionPhysical;
        case SpellType_Invisibility: Tile.PotionShadow;
        case SpellType_ModMoveSpeed: Tile.PotionIce;
        case SpellType_ModHealthMax: Tile.PotionFire;
        default: Tile.None;
    };

    return {
        spell: {
            type: type,
            duration_type: duration_type,
            duration: duration,
            interval: 1,
            interval_current: 0,
            value: value,
            origin_name: "noname",
        },
        tile: tile,
    };
}

static function random_scroll_spell_and_tile(level: Int) {
    var type = Random.pick_chance([
        // {v: SpellType_UncoverMap, c: 1.0},
        {v: SpellType_Nolos, c: 0.25},
        {v: SpellType_ShowThings, c: 0.5},
        
        {v: SpellType_Noclip, c: 1.0},
        {v: SpellType_RandomTeleport, c: 0.5},
        {v: SpellType_SafeTeleport, c: 0.5},

        {v: SpellType_ModHealthMax, c: 1.0},
        {v: SpellType_AoeDamage, c: 1.0},
        {v: SpellType_ChainDamage, c: 1.0},
        {v: SpellType_DamageShield, c: 1.0},
        {v: SpellType_EnergyShield, c: 1.0},
        {v: SpellType_Combust, c: 1.0},

        {v: SpellType_ModUseCharges, c: 0.5},
        {v: SpellType_CopyItem, c: 1.0},
        {v: SpellType_ImproveEquipment, c: 1.0},
        {v: SpellType_EnchantEquipment, c: 1.0},

        {v: SpellType_Passify, c: 0.5},
        {v: SpellType_Sleep, c: 0.5},
        {v: SpellType_SummonGolem, c: 1.0},
        {v: SpellType_SummonSkeletons, c: 1.0},
        {v: SpellType_SummonImp, c: 1.0},

        {v: SpellType_HealthLeech, c: 1.0},
        {v: SpellType_SwapHealth, c: 1.0},
        {v: SpellType_ModSpellDamage, c: 1.0},
        ]);

    var duration_type = switch (type) {
        case SpellType_Nolos: SpellDuration_EveryTurn;
        case SpellType_Noclip: SpellDuration_EveryTurn;
        // case SpellType_UncoverMap: SpellDuration_EveryTurn;
        case SpellType_ShowThings: SpellDuration_EveryTurn;
        case SpellType_DamageShield: SpellDuration_EveryTurn;
        case SpellType_HealthLeech: SpellDuration_EveryTurn;
        case SpellType_ModSpellDamage: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = if (duration_type == SpellDuration_Permanent) {
        0;
    } else {
        switch (type) {
            // case SpellType_UncoverMap: Entity.DURATION_LEVEL;
            case SpellType_ShowThings: Entity.DURATION_LEVEL;
            case SpellType_Nolos: Random.int(100, 150);
            case SpellType_Noclip: Random.int(50, 100);
            case SpellType_AoeDamage: Random.int(30, 50);
            case SpellType_DamageShield: Random.int(30, 50);
            case SpellType_HealthLeech: Random.int(30, 50);
            case SpellType_ModSpellDamage: Random.int(30, 50);
            default: 0;
        }
    }

    var value = switch (type) {
        case SpellType_ModHealthMax: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModUseCharges: 1;
        case SpellType_EnergyShield: Stats.get({min: 3, max: 5, scaling: 1.0}, level);
        case SpellType_ImproveEquipment: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_DamageShield: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_Combust: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModSpellDamage: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        default: 0;
    }

    var tile = switch (type) {
        // case SpellType_UncoverMap: Tile.ScrollLight;
        case SpellType_Nolos: Tile.ScrollLight;
        case SpellType_ShowThings: Tile.ScrollLight;

        case SpellType_Noclip: Tile.ScrollShadow;
        case SpellType_RandomTeleport: Tile.ScrollShadow;
        case SpellType_SafeTeleport: Tile.ScrollShadow;
        case SpellType_HealthLeech: Tile.ScrollShadow;
        case SpellType_SwapHealth: Tile.ScrollShadow;

        case SpellType_ModUseCharges: Tile.ScrollIce;
        case SpellType_CopyItem: Tile.ScrollIce;
        case SpellType_ImproveEquipment: Tile.ScrollIce;
        case SpellType_EnchantEquipment: Tile.ScrollIce;
        case SpellType_ModSpellDamage: Tile.ScrollIce;

        case SpellType_ModHealthMax: Tile.ScrollPhysical;
        case SpellType_DamageShield: Tile.ScrollPhysical;
        case SpellType_EnergyShield: Tile.ScrollPhysical;

        case SpellType_Passify: Tile.ScrollMixed;
        case SpellType_Sleep: Tile.ScrollMixed;
        case SpellType_ChainDamage: Tile.ScrollMixed;
        case SpellType_AoeDamage: Tile.ScrollMixed;
        case SpellType_Combust: Tile.ScrollMixed;

        case SpellType_SummonGolem: Tile.ScrollFire;
        case SpellType_SummonSkeletons: Tile.ScrollFire;
        case SpellType_SummonImp: Tile.ScrollFire;

        default: Tile.None;
    };

    return {
        spell: {
            type: type,
            duration_type: duration_type,
            duration: duration,
            interval: 1,
            interval_current: 0,
            value: value,
            origin_name: "noname",
        }, 
        tile: tile,
    };
}

static function random_ring_spell(level: Int): Spell {
    var type = Random.pick_chance([
        {v: SpellType_ModAttack, c: 1.0},
        {v: SpellType_ModDefense, c: 10.0},
        {v: SpellType_AoeDamage, c: 1.0},
        ]);

    var duration = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttack;
        default: SpellDuration_EveryTurn;
    }

    var value = switch (type) {
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDefense: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        default: 0;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(4, 8);
        default: 1;
    }

    return {
        type: type,
        duration_type: duration,
        duration: Entity.DURATION_INFINITE,
        interval: interval,
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
    return [player_stat_buff_spell(), mod_copper(Stats.get({min: 2, max: 3, scaling: 1.0}, level))];
}

static function statue_ollopa(level: Int): Array<Spell> {
    var player_special_level_buff = {
        var type = Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperDrop, c: 1.0},
            {v: SpellType_ModDropLevel, c: 1.0},
            {v: SpellType_Noclip, c: 1.0},
            ]);

        var value = switch (type) {
            case SpellType_ModCopperDrop: Random.int(25, 75);
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

static function poison_room(r: Room) {
    var level = Main.current_level;

    // NOTE: all locations get a shared reference to spell so that duration is shared between them, otherwise the spell wouldn't tick unless you stood in the same place 
    var poison_spell = {
        type: SpellType_ModHealth,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: Random.int(15, 20),
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

static function teleport_room(r: Room) {
    var level = Main.current_level;
    
    var teleport_spell = {
        type: SpellType_RandomTeleport,
        duration_type: SpellDuration_EveryTurn,
        duration: Entity.DURATION_INFINITE,
        interval: Math.round(Math.max(r.width, r.height) * 2),
        interval_current: 0,
        value: 0,
        origin_name: "noname",
    };

    for (x in r.x...r.x + r.width) {
        for (y in r.y...r.y + r.height) {
            Main.location_spells[x][y].push(teleport_spell);
            Main.tiles[x][y] = Tile.Teleport;
        }
    }
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

static function random_equipment_spell_equip(equipment_type: EquipmentType): Spell {
    var level = Main.get_drop_entity_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_AoeDamage, c: 1.0},
            {v: SpellType_ChainDamage, c: 1.0},
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_ModAttackByCopper, c: 1.0},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_ModHealthMax, c: 1.0},
            // {v: SpellType_UncoverMap, c: 1.0},
            {v: SpellType_ShowThings, c: 1.0},
            {v: SpellType_ModDefenseByCopper, c: 1.0},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperDrop, c: 1.0},
            {v: SpellType_ModHealthMax, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_ModAttackByCopper, c: 1.0},
            {v: SpellType_ModDefenseByCopper, c: 1.0},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModHealthMax, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_ModAttackByCopper, c: 1.0},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttack;
        case SpellType_ChainDamage: SpellDuration_EveryAttack;
        case SpellType_ModHealth: SpellDuration_EveryAttack;
        case SpellType_EnergyShield: SpellDuration_EveryAttack;
        case SpellType_ModHealthMax: SpellDuration_EveryTurn;
        case SpellType_ShowThings: SpellDuration_EveryTurn;
        case SpellType_ModDropChance: SpellDuration_EveryTurn;
        case SpellType_ModCopperDrop: SpellDuration_EveryTurn;
        case SpellType_ModAttackByCopper: SpellDuration_EveryTurn;
        case SpellType_ModDefenseByCopper: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: Random.int(5, 8);
        case SpellType_ChainDamage: Random.int(5, 8);
        case SpellType_EnergyShield: Random.int(5, 8);
        case SpellType_ModHealth: Random.int(5, 8);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: switch(equipment_type) {
            case EquipmentType_Weapon: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            default: Stats.get({min: 1, max: 1, scaling: 0.8}, level);
        }
        case SpellType_ModHealth: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModHealthMax: Stats.get({min: 2, max: 3, scaling: 1.0}, level);
        case SpellType_ModDropChance: Random.int(10, 20);
        case SpellType_ModCopperDrop: Random.int(25, 75);
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
        case SpellType_AoeDamage: Random.int(6, 8);
        case SpellType_Invisibility: Random.int(1, 3);
        case SpellType_EnergyShield: Random.int(2, 4);
        case SpellType_Nolos: Random.int(3, 5);
        case SpellType_ModHealth: Random.int(2, 4);
        case SpellType_ModMoveSpeed: Random.int(2, 4);
        case SpellType_SummonGolem: Random.int(2, 4);
        case SpellType_SummonImp: Random.int(2, 4);
        case SpellType_ModAttack: Random.int(2, 4);
        case SpellType_ChainDamage: Random.int(2, 4);
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
        case SpellType_ModAttack: Random.int(10, 15);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModHealth: Stats.get({min: 3, max: 4, scaling: 1.0}, level);
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
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
        {v: 1, c: 0.33},
        {v: 2, c: 0.10},
        {v: 3, c: 0.05},
        ]);
    var spell_equip_count = 0;
    var spell_use_count = 0;
    var spell_equip_negative_count = 0;

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