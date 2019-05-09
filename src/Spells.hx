
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
    SpellType_LuckyCharge;
    SpellType_Critical;

    SpellType_ModLevelHealth;
    SpellType_ModLevelAttack;

    SpellType_ModUseCharges;
    SpellType_CopyEntity;
    SpellType_ImproveEquipment;
    SpellType_EnchantEquipment;
    SpellType_Passify;
    SpellType_Sleep;
    SpellType_Charm;
    SpellType_SwapHealth;

    SpellType_SummonGolem;
    SpellType_SummonSkeletons;
    SpellType_SummonImp;

    SpellType_ModCopper;
    SpellType_ModSpellDamage;
    SpellType_MoreEnemies;
    SpellType_WeakHeal;
    SpellType_StrongerEnemies;

    SpellType_ModAttackByCopper;
    SpellType_ModDefenseByCopper;
    SpellType_ExtraRing;
}

enum SpellDuration {
    SpellDuration_Permanent;
    SpellDuration_EveryTurn;
    SpellDuration_EveryAttack;
    SpellDuration_EveryAttackChance;
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

// Some prio order idiosyncrasies:
// Drop effects before everything else so that all drops that can be caused by spells are affected
// Teleports last so that aoe hits stuff in old room
// Must do NextFloor before ModDropLevel, otherwise all spawned entities will be +1 level
static var prios = [
SpellType_NextFloor => 0,

SpellType_ExtraRing => 1,
SpellType_MoreEnemies => 1,
SpellType_WeakHeal => 1,
SpellType_StrongerEnemies => 1,
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
SpellType_Charm => 1,
SpellType_ImproveEquipment => 1,
SpellType_EnchantEquipment => 1,
SpellType_ModCopper => 1,
SpellType_HealthLeech => 1,
SpellType_SwapHealth => 1,
SpellType_ModSpellDamage => 1,
SpellType_LuckyCharge => 1,
SpellType_Critical => 1,

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

static inline var ModDropChance_value = 10;
static inline var ModCopperChance_value = 10;
static inline var LuckyCharge_value = 10;
static inline var Critical_value = 10;
static inline var HealthLeech_value = 10;

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
    
    var long = Main.USER_long_spell_descriptions;

    var effect = switch (spell.type) {
        case SpellType_ModHealth: '$sign${spell.value} health';
        case SpellType_ModHealthMax: '$sign${spell.value} max health';
        case SpellType_ModAttack: '$sign${spell.value} attack';
        case SpellType_ModDefense: '$sign${spell.value} defense';
        case SpellType_ModMoveSpeed: '$sign${spell.value} move speed';
        case SpellType_ModDropChance: if (spell.value > 0) '+item drop chance' else '$sign${spell.value}% item drop chance';
        case SpellType_ModCopperChance: '+copper drop chance';
        case SpellType_ModLevelHealth: '$sign${spell.value}% health to all enemies on the current floor';
        case SpellType_ModLevelAttack: '$sign${spell.value}% attack to all enemies on the current floor';
        case SpellType_EnergyShield: if (long) 
        'Shield: get shield that absorbs ${spell.value} damage (not additive)' else 
        'Shield ${spell.value}';
        case SpellType_Invisibility: 'Turn invisible';
        case SpellType_ModDropLevel: '+item drop power';
        case SpellType_UncoverMap: 'Uncover map';
        case SpellType_RandomTeleport: 'Random teleport';
        case SpellType_SafeTeleport: 'Safe teleport';
        case SpellType_Nolos: 'See everything';
        case SpellType_Noclip: 'Go through walls';
        case SpellType_ShowThings: 'See treasure on the map';
        case SpellType_NextFloor: 'Go to next floor';
        case SpellType_AoeDamage: if (long) 
        'Inferno: deal ${spell.value} damage to all visible enemies' 
        else 
            'Inferno ${spell.value}';
        case SpellType_ModUseCharges: if (long) 
        'Add ${spell.value} charges to item in your inventory' 
        else 
            'Add ${spell.value} charges';
        case SpellType_CopyEntity: if (long) 
        'Copy: copy anything (copy is placed on the ground, must have free space around you)' 
        else 
            'Copy';
        case SpellType_Passify: if (long) 
        'Passify: passify an enemy' 
        else
            'Passify';
        case SpellType_Sleep: if (long)
        'Sleep: put an enemy to sleep' 
        else
            'Sleep';
        case SpellType_Charm: if (long)
        'Charm: turn an enemy into an ally' 
        else
            'Charm';
        case SpellType_ImproveEquipment: if (long)
        'Improve equipment: make armor or a weapon more powerful' 
        else
            'Improve equipment';
        case SpellType_EnchantEquipment: if (long)
        'Enchant equipment: enchant weapon or armor with a random equip spell' 
        else
            'Enchant equipment';
        case SpellType_DamageShield: if (long)
        'Damaging shield: deal ${spell.value} damage to attackers' 
        else
            'Damaging shield ${spell.value}';
        case SpellType_SummonGolem: if (long)
        'Summon Golem that follows and protects you' 
        else
            'Summon Golem';
        case SpellType_SummonSkeletons: if (long)
        'Summon Skeletons that attack nearby enemies but don\'t follow you' 
        else
            'Summon Skeletons';
        case SpellType_SummonImp: if (long)
        'Summon Imp that can\'t move but will throw fireballs at enemies' 
        else
            'Summon Imp';
        case SpellType_ChainDamage: if (long)
        'Light chain: deals ${spell.value} damage to an enemy near to you, then jumps to nearby enemies, doubling the damage with each jump' 
        else
            'Light chain ${spell.value}';
        case SpellType_ModCopper: '$sign ${spell.value} copper';
        case SpellType_HealthLeech: if (long)
        'Health leech: damage dealt to enemies has a chance to heal you' 
        else
            'Health leech';
        case SpellType_SwapHealth: if (long)
        'Swap health: swaps yours and target enemy\'s current health' 
        else
            'Swap health';
        case SpellType_ModSpellDamage: if (long)
        'Increases all spell damage by ${spell.value}, also increase power of summons' 
        else
            '+Spell power ${spell.value}';
        case SpellType_ModAttackByCopper: if (long)
        'Copper attack: + to attack based on copper count' 
        else
            'Copper attack';
        case SpellType_ModDefenseByCopper: if (long)
        'Copper defense: + to defense based on copper count' 
        else
            'Copper defense';
        case SpellType_Combust: if (long)
        'Combust: blow up an enemy dealing ${spell.value} damage to everything nearby' 
        else
            'Combust ${spell.value}';
        case SpellType_LuckyCharge: if (long)
        'Lucky use: chance of preserving a charge when using anything' 
        else
            'Lucky use';
        case SpellType_Critical: if (long)
        'Critical: chance of dealing double damage' 
        else
            'Critical';
        case SpellType_MoreEnemies: 'More enemies';
        case SpellType_WeakHeal: 'Weaker healing potions';
        case SpellType_StrongerEnemies: 'Stronger enemies';
        case SpellType_ExtraRing: if (long)
        'Third Finger: extra ring slot' 
        else
            'Third Finger';
    }

    var interval = 
    if (spell.interval > 1) {
        if (spell.duration_type == SpellDuration_EveryTurn) {
            ' every ${spell.interval} turns';
        } else if (spell.duration_type == SpellDuration_EveryAttack) {
            ' every ${spell.interval} attacks';
        } else if (spell.duration_type == SpellDuration_EveryAttackChance) {
            ' sometimes';
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
            case SpellDuration_EveryAttackChance: ' for ${spell.duration} attacks';
        }
    }
    
    return '$effect$interval$duration';
}

static function spell_color_to_color(spell_color: SpellColor): Int {
    return switch (spell_color) {
        case SpellColor_Gray: Col.GRAY;
        case SpellColor_Yellow: Col.YELLOW;
        case SpellColor_Purple: Col.DARKBLUE;
        case SpellColor_Red: Col.RED;
        case SpellColor_Green: Col.GREEN;
        case SpellColor_Blue: Col.BLUE;
        case SpellColor_None: Col.WHITE;
    }
}

static function get_color(spell: Spell): SpellColor {
    return switch (spell.type) {
        case SpellType_ModAttack: SpellColor_Gray;
        case SpellType_ModDefense: SpellColor_Gray;
        case SpellType_Passify: SpellColor_Gray;
        case SpellType_Sleep: SpellColor_Gray;
        case SpellType_Charm: SpellColor_Gray;
        case SpellType_Critical: SpellColor_Gray;

        case SpellType_ModSpellDamage: SpellColor_Blue;
        case SpellType_EnergyShield: SpellColor_Blue;
        case SpellType_DamageShield: SpellColor_Blue;
        case SpellType_LuckyCharge: SpellColor_Blue;
        case SpellType_MoreEnemies: SpellColor_Blue;
        case SpellType_WeakHeal: SpellColor_Blue;
        case SpellType_StrongerEnemies: SpellColor_Blue;

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
        case SpellType_Charm: true;
        case SpellType_ImproveEquipment: true;
        case SpellType_EnchantEquipment: true;
        case SpellType_SwapHealth: true;
        case SpellType_Combust: true;
        default: false;
    }
}

static function spell_can_be_used_on_target(type: SpellType, target: Int): Bool {
    var copy_or_charges_spell = false;
    if (Entity.use.exists(target)) {
        for (s in Entity.use[target].spells) {
            if (s.type == SpellType_ModUseCharges || s.type == SpellType_CopyEntity) {
                copy_or_charges_spell = true;
                break;
            }
        }
    }

    return switch (type) {
        case SpellType_ModUseCharges: Entity.item.exists(target) && !Entity.position.exists(target) && !copy_or_charges_spell;
        case SpellType_CopyEntity:  !copy_or_charges_spell && (Entity.position.exists(target) || (!Entity.position.exists(target) && (Entity.item.exists(target) || Entity.equipment.exists(target))));
        case SpellType_Passify: Entity.combat.exists(target) && !Entity.merchant.exists(target);
        case SpellType_Sleep: Entity.combat.exists(target) && !Entity.merchant.exists(target);
        case SpellType_Charm: Entity.combat.exists(target) && !Entity.merchant.exists(target);
        case SpellType_ImproveEquipment: Entity.equipment.exists(target);
        case SpellType_EnchantEquipment: Entity.equipment.exists(target);
        case SpellType_SwapHealth: Entity.combat.exists(target) && !Entity.merchant.exists(target);
        case SpellType_Combust: Entity.combat.exists(target) && Entity.position.exists(target);
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

    function healthmax_chance(): Float {
        var curr = GenerateWorld.healthmax_on_floor[Main.current_floor];
        var prev = Main.current_floor > 0 && GenerateWorld.healthmax_on_floor[Main.current_floor - 1];
        return if (!curr && !prev) {
            3.0;
        } else {
            0.0;
        }
    }

    var type = if (force_spell != null) {
        force_spell;
    } else {
        Random.pick_chance([
            // NOTE: ModHealth potions are rolled separately via force_spell in GenerateWorld
            // {v: SpellType_ModHealth, c: 1.0},

            {v: SpellType_ModAttack, c: 1.0},
            {v: SpellType_ModDefense, c: 1.0},
            {v: SpellType_Critical, c: 0.5},

            {v: SpellType_ModSpellDamage, c: 0.5},

            {v: SpellType_UncoverMap, c: 0.25},
            {v: SpellType_ShowThings, c: 0.25},

            {v: SpellType_ModMoveSpeed, c: 0.25},
            {v: SpellType_Invisibility, c: 0.25},

            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_ModHealthMax, c: healthmax_chance()},
            ]);
    }

    // NOTE: only tally up non-forced healthmax, meaning non-merchant ones
    if (type == SpellType_ModHealthMax && force_spell != SpellType_ModHealthMax) {
        GenerateWorld.healthmax_on_floor[Main.current_floor] = true;
    }

    var duration_type = SpellDuration_Permanent;
    var duration = 0;
    var value = 0;

    switch (type) {
        case SpellType_ModHealth: {
            duration_type = SpellDuration_Permanent;
            if (Player.weak_heal) {
                value = Stats.get({min: 3, max: 4, scaling: 0.4}, level);
            } else {
                value = Stats.get({min: 5, max: 5, scaling: 0.5}, level);
            }
        }
        case SpellType_ModAttack: {
            duration_type = SpellDuration_EveryAttack;

            if (Random.chance(5)) {
                duration = 1;
                value = 100;
            } else {
                duration = Random.int(3, 5);
                value = Stats.get({min: 1, max: 1, scaling: 0.5}, level);
            }
        }
        case SpellType_ModDefense: {

            if (Random.chance(5)) {
                duration_type = SpellDuration_EveryTurn;
                duration = 5;
                value = 100;
            } else {
                duration_type = SpellDuration_EveryAttack;
                duration = Random.int(3, 5);
                value = Stats.get({min: 2, max: 3, scaling: 1.0}, level);
            }
        }
        case SpellType_ModCopperChance: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(4, 8);
            value = ModCopperChance_value;
        }
        case SpellType_Critical: {
            duration_type = SpellDuration_EveryAttack;
            duration = Random.int(3, 5);
            value = Random.int(20, 30);
        }
        case SpellType_ModSpellDamage: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(20, 30);
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        }
        case SpellType_UncoverMap: {
            duration_type = SpellDuration_EveryTurn;
            duration = Entity.DURATION_LEVEL;
        }
        case SpellType_ShowThings: {
            duration_type = SpellDuration_EveryTurn;
            duration = Entity.DURATION_LEVEL;
        }
        case SpellType_ModMoveSpeed: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(5, 10);
            value = Random.int(1, 2);
        }
        case SpellType_Invisibility: {
            duration_type = SpellDuration_EveryTurn;
            duration = Random.int(60, 80);
        }
        case SpellType_ModHealthMax: {
            duration_type = SpellDuration_Permanent;
            value = Stats.get({min: 2, max: 3, scaling: 0.25}, level);
        }
        case SpellType_MoreEnemies: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_WeakHeal: {
            duration_type = SpellDuration_Permanent;
        }
        case SpellType_StrongerEnemies: {
            duration_type = SpellDuration_Permanent;
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
        {v: SpellType_Charm, c: 0.5},

        {v: SpellType_EnergyShield, c: 1.0},
        {v: SpellType_DamageShield, c: 1.0},

        {v: SpellType_RandomTeleport, c: 0.5},
        {v: SpellType_Nolos, c: 0.25},
        {v: SpellType_Noclip, c: 0.75},

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
        case SpellType_Charm: {
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
            value = HealthLeech_value;
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
            1.0;
        }},
        {v: SpellType_ModDefense, c: 1.0},
        {v: SpellType_Critical, c: 0.5},

        {v: SpellType_ModSpellDamage, c: 1.0},
        {v: SpellType_EnergyShield, c: 0.5},
        {v: SpellType_LuckyCharge, c: 0.5},

        {v: SpellType_ShowThings, c: 0.5},
        {v: SpellType_Noclip, c: 0.05},

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
        case SpellType_Critical: {
            duration_type = SpellDuration_EveryTurn;
            value = Critical_value;
        }
        case SpellType_ModSpellDamage: {
            duration_type = SpellDuration_EveryTurn;
            value = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        }
        case SpellType_EnergyShield: {
            duration_type = SpellDuration_EveryAttackChance;
            value = Stats.get({min: 1, max: 2, scaling: 1.0}, level);
            interval = 25;
        }
        case SpellType_ShowThings: {
            duration_type = SpellDuration_EveryTurn;
        }
        case SpellType_Noclip: {
            duration_type = SpellDuration_EveryTurn;
        }
        case SpellType_ModCopper: {
            duration_type = SpellDuration_EveryAttackChance;
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            interval = 20;
        }
        case SpellType_ModDropChance: {
            duration_type = SpellDuration_EveryTurn;
            value = ModDropChance_value;
        }
        case SpellType_ModCopperChance: {
            duration_type = SpellDuration_EveryTurn;
            value = ModCopperChance_value;
        }
        case SpellType_ModHealth: {
            duration_type = SpellDuration_EveryAttackChance;
            value = Stats.get({min: 1, max: 1, scaling: 1.0}, level);
            interval = 20;
        }
        case SpellType_HealthLeech: {
            duration_type = SpellDuration_EveryTurn;
            value = HealthLeech_value;
        }
        case SpellType_LuckyCharge: {
            duration_type = SpellDuration_EveryTurn;
            value = LuckyCharge_value;
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
        {v: SpellType_CopyEntity, c: 0.5},
        {v: SpellType_ImproveEquipment, c: 1.0},
        {v: SpellType_EnchantEquipment, c: 1.0},
        ]);

    if (type == SpellType_CopyEntity) {
        trace("!");
    }

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
            value = 0;
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
    var level = Main.current_level();
    
    // Select buff type that's not the same as curse
    var type = avoid_type;
    while (type == avoid_type) {
        type = Random.pick_chance([
            {v: SpellType_ModLevelHealth, c: 1.0},
            {v: SpellType_ModLevelAttack, c: 1.0},
            ]);
    }

    var value = switch (type) {
        case SpellType_ModLevelHealth: Random.pick([25, 40, 50]);
        case SpellType_ModLevelAttack: Random.pick([25, 40, 50]);
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
    var level = Main.current_level();

    var type = Random.pick_chance([
        {v: SpellType_ModAttack, c: 3.0},
        {v: SpellType_ModDefense, c: 3.0},
        {v: SpellType_AoeDamage, c: 1.0},
        ]);

    var duration_type = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttackChance;
        default: SpellDuration_EveryTurn;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: 15;
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
        var level = Main.current_level();

        var type = Random.pick_chance([
            {v: SpellType_ModLevelHealth, c: 1.0},
            {v: SpellType_ModLevelAttack, c: 1.0},
            ]);

        var value = switch (type) {
            case SpellType_ModLevelHealth: -Random.pick([25, 40, 50]);
            case SpellType_ModLevelAttack: -Random.pick([25, 40, 50]);
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
    // NOTE: copper cost is added outside in random_statue()
    return [player_stat_buff_spell()];
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
            case SpellType_ModCopperChance: ModCopperChance_value;
            case SpellType_ModDropChance: ModDropChance_value;
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

    var spells = [
    player_special_level_buff,
    enemy_buff_spell(),
    ];

    // Need to double the chance based spells for them to be worth it
    if (player_special_level_buff.type == SpellType_ModCopperChance || player_special_level_buff.type == SpellType_ModDropChance) {
        spells.push(copy(player_special_level_buff));
    }

    return spells;
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
            case SpellDuration_Permanent: Stats.get({min: 3, max: 4, scaling: 1.0}, level);
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
    var level = Main.current_level();
    
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

static function random_equipment_spell_equip(equipment_type: EquipmentType): Spell {
    var level = Main.current_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_Critical, c: 1.0},

            {v: SpellType_ChainDamage, c: 1.0},
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_ModAttackByCopper, c: 0.15},

            {v: SpellType_ModCopper, c: 1.0},
            {v: SpellType_SummonSkeletons, c: 0.25},
            {v: SpellType_SummonGolem, c: 0.5},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},

            {v: SpellType_UncoverMap, c: 1.0},
            {v: SpellType_ShowThings, c: 1.0},
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_HealthLeech, c: 1.0},
            {v: SpellType_Nolos, c: 1.0},
            {v: SpellType_ModAttack, c: 1.0},

            {v: SpellType_ModAttackByCopper, c: 0.15},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_LuckyCharge, c: 1.0},
            {v: SpellType_Critical, c: 1.0},
            {v: SpellType_SummonSkeletons, c: 0.25},
            {v: SpellType_ExtraRing, c: 0.1},

            {v: SpellType_AoeDamage, c: 1.0},

            {v: SpellType_ModDefenseByCopper, c: 0.15},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModDropChance, c: 1.0},
            {v: SpellType_ModCopperChance, c: 1.0},
            {v: SpellType_EnergyShield, c: 1.0},
            {v: SpellType_LuckyCharge, c: 1.0},
            {v: SpellType_Critical, c: 1.0},
            {v: SpellType_HealthLeech, c: 1.0},

            {v: SpellType_DamageShield, c: 1.0},
            {v: SpellType_ModAttack, c: 1.0},

            {v: SpellType_SummonGolem, c: 0.5},
            {v: SpellType_ModDefenseByCopper, c: 0.15},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_AoeDamage: SpellDuration_EveryAttackChance;
        case SpellType_ChainDamage: SpellDuration_EveryAttackChance;
        case SpellType_ModHealth: SpellDuration_EveryAttackChance;
        case SpellType_EnergyShield: SpellDuration_EveryAttackChance;
        case SpellType_DamageShield: SpellDuration_EveryAttackChance;
        case SpellType_ModCopper: SpellDuration_EveryAttackChance;
        case SpellType_SummonSkeletons: SpellDuration_EveryAttackChance;
        case SpellType_SummonGolem: SpellDuration_EveryAttackChance;
        case SpellType_ModAttack: SpellDuration_EveryAttackChance;

        case SpellType_ShowThings: SpellDuration_EveryTurn;
        case SpellType_ModDropChance: SpellDuration_EveryTurn;
        case SpellType_ModCopperChance: SpellDuration_EveryTurn;
        case SpellType_ModAttackByCopper: SpellDuration_EveryTurn;
        case SpellType_ModDefenseByCopper: SpellDuration_EveryTurn;
        case SpellType_LuckyCharge: SpellDuration_EveryTurn;
        case SpellType_Critical: SpellDuration_EveryTurn;
        case SpellType_HealthLeech: SpellDuration_EveryTurn;
        case SpellType_Nolos: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var interval = switch (type) {
        case SpellType_AoeDamage: 20;
        case SpellType_ChainDamage: 20;
        case SpellType_EnergyShield: 20;
        case SpellType_DamageShield: 20;
        case SpellType_ModHealth: 20;
        case SpellType_ModCopper: 20;
        case SpellType_SummonSkeletons: 10;
        case SpellType_SummonGolem: 8;
        case SpellType_ModAttack: 20;
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_DamageShield: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModHealth: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ModDropChance: ModDropChance_value;
        case SpellType_ModCopperChance: ModCopperChance_value;
        case SpellType_LuckyCharge: LuckyCharge_value;
        case SpellType_Critical: Critical_value;
        case SpellType_HealthLeech: HealthLeech_value;
        case SpellType_ModCopper: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_SummonSkeletons: level;
        case SpellType_SummonGolem: level;
        case SpellType_ModAttack: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
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
        case SpellType_AoeDamage: Random.int(1, 2);
        case SpellType_Invisibility: Random.int(1, 2);
        case SpellType_EnergyShield: Random.int(1, 2);
        case SpellType_Nolos: Random.int(2, 3);
        case SpellType_ModHealth: Random.int(1, 2);
        case SpellType_ModMoveSpeed: Random.int(1, 2);
        case SpellType_SummonGolem: 1;
        case SpellType_SummonImp: 1;
        case SpellType_ChainDamage: Random.int(1, 2);
        case SpellType_RandomTeleport: 1;
        case SpellType_SafeTeleport: 1;
        case SpellType_Combust: Random.int(1, 2);
        case SpellType_Noclip: Random.int(1, 2);
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
    var level = Main.current_level();

    var type = switch (equipment_type) {
        case EquipmentType_Weapon: Random.pick_chance([
            {v: SpellType_AoeDamage, c: 1.0},
            {v: SpellType_Invisibility, c: 0.5},
            {v: SpellType_SummonGolem, c: 1.0},
            ]);
        case EquipmentType_Head: Random.pick_chance([
            {v: SpellType_SummonImp, c: 1.0},
            {v: SpellType_ChainDamage, c: 1.0},
            {v: SpellType_Combust, c: 100000000.0},
            ]);
        case EquipmentType_Chest: Random.pick_chance([
            {v: SpellType_ModHealth, c: 1.0},
            {v: SpellType_AoeDamage, c: 1.0},
            {v: SpellType_Invisibility, c: 1.0},
            ]);
        case EquipmentType_Legs: Random.pick_chance([
            {v: SpellType_ModMoveSpeed, c: 1.0},
            {v: SpellType_RandomTeleport, c: 0.5},
            {v: SpellType_SafeTeleport, c: 0.5},
            {v: SpellType_Noclip, c: 0.1},
            ]);
    }

    var duration_type = switch (type) {
        case SpellType_Invisibility: SpellDuration_EveryTurn;
        case SpellType_Nolos: SpellDuration_EveryTurn;
        case SpellType_ModMoveSpeed: SpellDuration_EveryTurn;
        case SpellType_Noclip: SpellDuration_EveryTurn;
        default: SpellDuration_Permanent;
    }

    var duration = switch (type) {
        case SpellType_Invisibility: Random.int(60, 80);
        case SpellType_Nolos: Random.int(60, 80);
        case SpellType_ModMoveSpeed: Random.int(60, 80);
        case SpellType_Noclip: Random.int(60, 80);
        default: 0;
    }

    var value = switch (type) {
        case SpellType_AoeDamage: Stats.get({min: 1, max: 1, scaling: 1.0}, level);
        case SpellType_ChainDamage: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_Combust: Stats.get({min: 1, max: 1, scaling: 0.5}, level);
        case SpellType_EnergyShield: Stats.get({min: 1, max: 2, scaling: 1.0}, level);
        case SpellType_ModHealth: Stats.get({min: 3, max: 4, scaling: 1.0}, level);
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

static function random_equipment_spells(equipment_type: EquipmentType): Array<Array<Spell>> {
    var level = Main.current_level();
    
    var total_spell_count: Int = Random.pick_chance([
        {v: 0, c: 1.0},
        {v: 1, c: if (level > 0) 2.0 else 1.0},
        {v: 2, c: if (level > 0) 1.0 else 0},
        ]);
    var spell_equip_count = 0;
    var spell_use_count = 0;

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
            }, c: 1.0},
            {v: function() {
                spell_equip_count = 2;
            }, c: 0.5},
            ])
        ();
    }

    var equip_spells = new Array<Spell>();
    for (i in 0...spell_equip_count) {
        equip_spells.push(Spells.random_equipment_spell_equip(equipment_type));
    }

    var use_spells = new Array<Spell>();
    for (i in 0...spell_use_count) {
        use_spells.push(Spells.random_equipment_spell_use(equipment_type));
    }

    return [equip_spells, use_spells];
}

}