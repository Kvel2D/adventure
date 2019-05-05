
import haxegon.*;
import Entity;
import Spells;

@:publicFields
class Player {
// force unindent

static var x = 0;
static var y = 0;
static var x_old = -1;
static var y_old = -1;
static var room = -1;

static var health = 10;
static var health_max = 10;
static var attack = 1;
static var defense = 0;
static var pure_absorb = 0;
static var damage_shield = 0;
static var copper_count = 0;

static var equipment = [
EquipmentType_Head => Entity.NONE,
EquipmentType_Chest => Entity.NONE,
EquipmentType_Legs => Entity.NONE,
EquipmentType_Weapon => Entity.NONE,
];
static var inventory = Data.create2darray(Main.INVENTORY_WIDTH, Main.INVENTORY_HEIGHT, Entity.NONE);
static var spells = new Array<Spell>();

static var attack_mod = 0;
static var defense_mod = 0;
static var health_max_mod = 0;
static var damage_shield_mod = 0;
static var movespeed_mod = 0;
static var dropchance_mod = 0;
static var copper_drop_mod = 0;
static var spell_damage_mod = 0;
static var health_leech = 0;
static var lucky_charge = 0;
static var critical = 0;

static var noclip = false;
static var nolos = false;
static var show_things = false;
static var full_minimap = false;
static var invisible = false;
static var increase_drop_level = false;
static var summon_buff = false;
static var more_enemies = false;
static var weak_heal = false;
static var stronger_enemies = false;
static var extra_ring = false;

}