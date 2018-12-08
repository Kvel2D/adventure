
import haxegon.*;
import haxe.ds.Vector;
import Entity;

using haxegon.MathExtensions;
using StringTools;
using Lambda;

@:publicFields
class Main {
// NOTE: force unindent

static inline var screen_width = 1600;
static inline var screen_height = 1000;
static inline var tilesize = 8;
static inline var map_width = 200;
static inline var map_height = 200;
static inline var view_width = 31;
static inline var view_height = 31;

var tiles = Data.int_2d_vector(map_width, map_height);
var walls = Data.bool_2d_vector(map_width, map_height);

static inline var PLAYER_BASE_ATTACK = 1;
var player_x = 100;
var player_y = 100;
var player_health_max = 10;
var player_health = 10;
var copper_count = 0;
var player_armor: Map<ArmorType, Entity> = [
ArmorType_Head => null,
ArmorType_Chest => null,
ArmorType_Legs => null,
];
var player_weapon: Entity = null;

static inline var message_history_length_max = 20;
var message_history = new Array<String>();

// UI
static inline var message_history_y = 800;
static inline var ui_x_offset = 13;
static inline var player_stats_y = 0;
static inline var target_stats_y = 300;

// Inventory
static inline var inventory_y = 170;
static inline var inventory_width = 4;
static inline var inventory_height = 4;
static inline var inventory_size = inventory_width * inventory_height;
var inventory = new Array<Entity>();

var interact_target: Entity = null;
var interact_target_inv_x: Int;
var interact_target_inv_y: Int;
var done_interaction = false;
var player_acted = false;
var world_scale = 4;
var need_to_update_tiles_canvas = true;

function new() {
    Gfx.resize_screen(screen_width, screen_height, 1);
    Text.setfont('pixelFJ8', 8);
    Gfx.load_tiles('tiles', tilesize, tilesize);

    Gfx.create_image("tiles_canvas", view_width * tilesize, view_height * tilesize);

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            walls[x][y] = false;
        }
    }

    walls[102][100] = true;
    walls[103][100] = true;
    walls[104][100] = true;
    walls[105][105] = true;

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            if (walls[x][y]) {
                tiles[x][y] = Tile.Wall;
            } else {
                tiles[x][y] = Tile.Ground;
            }
        }
    }

    Entity.make(98, 98, 'snail');
    Entity.make(98, 97, 'snail');
    Entity.make(98, 96, 'snail');
    Entity.make(108, 100, 'bear');
    Entity.make(105, 98, 'fountain');

    Entity.make_armor(107, 98, ArmorType_Head);
    Entity.make_armor(107, 97, ArmorType_Head);
    Entity.make_armor(108, 98, ArmorType_Chest);
    Entity.make_armor(108, 97, ArmorType_Chest);
    Entity.make_armor(109, 98, ArmorType_Legs);
    Entity.make_armor(109, 97, ArmorType_Legs);

    Entity.make_sword(110, 97);
    Entity.make_potion(110, 98);
}

function get_free_map(): Vector<Vector<Bool>> {
    // Entities
    var free_map = Data.bool_2d_vector(map_width, map_height, true);
    for (e in Entity.all) {

        if (!e.equipped_or_picked_up()) {
            free_map[e.x][e.y] = false;
        }
    }
    // Walls
    for (x in 0...map_width) {
        for (y in 0...map_height) {
            if (walls[x][y]) {
                free_map[x][y] = false;
            }
        }
    }
    // TODO: Add player collision here
    // free_map[player_x][player_y] = false;

    return free_map;
}

// given x and y in map coordinates
// returns x and y in screen coordinates
function screen_x(x) {
    return unscaled_screen_x(x) * world_scale;
}
function screen_y(y) {
    return unscaled_screen_y(y) * world_scale;
}
function unscaled_screen_x(x) {
    return (x - player_x + Math.floor(view_width / 2)) * tilesize;
}
function unscaled_screen_y(y) {
    return (y - player_y + Math.floor(view_height / 2)) * tilesize;
}

function out_of_map_bounds(x, y) {
    return x < 0 || y < 0 || x >= map_width || y >= map_height;
}

function add_message(message) {
    message_history.insert(0, message);
}

function use_entity(e: Entity) {
    var use = Entity.use[e.type];
    var use_charges = Entity.use_charges[e.id];

    if (use_charges > 0) {
        if (use.name == 'heal 2') {
            player_health += 2;

            if (player_health > player_health_max) {
                player_health = player_health_max;
            }

            use_charges--;

            Entity.use_charges[e.id] = use_charges;

            add_message('${e.type} heals you for 2 health.');
        }
    }
}

function equip_entity(e: Entity) {
    var equipped_entity: Entity = null;
    if (Entity.armor.exists(e.id)) {
        var armor = Entity.armor[e.id];
        equipped_entity = player_armor[armor.type];
    } else if (Entity.weapon.exists(e.id)) {
        equipped_entity = player_weapon;
    }

    if (equipped_entity != null) {
        add_message('You take off ${Entity.equipment[equipped_entity.id].name}.');

        // Drop armor to location of new armor
        Entity.equipment[equipped_entity.id].equipped = false;
        equipped_entity.x = e.x;
        equipped_entity.y = e.y;
    }

    add_message('You put on ${Entity.equipment[e.id].name}.');

    if (Entity.armor.exists(e.id)) {
        var armor = Entity.armor[e.id];
        player_armor[armor.type] = e;
    } else if (Entity.weapon.exists(e.id)) {
        player_weapon = e;
    }
    Entity.equipment[e.id].equipped = true;
}

function pick_up_entity(e: Entity) {
    if (inventory.length < inventory_size) {
        inventory.push(e);

        add_message('You pick up ${Entity.item[e.id].name}.');
    } else {
        add_message('Inventory is full.');
    }

    Entity.item[e.id].picked_up = true;
}

function drop_entity(e: Entity) {
    // Search for free position around player
    var free_map = get_free_map();

    var free_x: Int = -1;
    var free_y: Int = -1;
    for (dx in -1...2) {
        for (dy in -1...2) {
            if (dx != 0 || dy != 0) {
                var x = player_x + dx;
                var y = player_y + dy;
                if (!out_of_map_bounds(x, y) && free_map[x][y]) {
                    free_x = x;
                    free_y = y;
                    break;
                }
            }
        }
    }

    if (free_x != -1 && free_y != -1) {
        e.x = free_x;
        e.y = free_y;
        Entity.item[e.id].picked_up = false;
        inventory.remove(e);
        add_message('You drop ${Entity.item[e.id].name}.');
    } else {
        add_message('No space to drop item.');
    }
}

function player_attack(): Int {
    if (player_weapon == null) {
        return PLAYER_BASE_ATTACK;
    } else {
        return Entity.weapon[player_weapon.id].attack;
    }
}

function player_defense(): Int {
    var total = 0;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (player_armor[armor_type] != null) {
            var armor = Entity.armor[player_armor[armor_type].id];
            total += armor.defense;
        }
    }
    return total;
}

function player_defense_absorb(): Int {
    // Each 10 points of defense absorbs 1 dmg per fight
    return Math.floor(player_defense() / 10);
}

function player_next_to_entity(e: Entity): Bool {
    return Math.dst2(e.x, e.y, player_x, player_y) <= 2;
}

function end_turn() {
    if (!player_acted) {
        // do mob stuff, if they move

        player_acted = true;
    }
}

function update() {
    //
    // Update
    //
    player_acted = false;

    // 
    // Player movement
    //
    var player_dx = 0;
    var player_dy = 0;
    var up = Input.delay_pressed(Key.W, 5) || Input.just_pressed(Key.W);
    var down = Input.delay_pressed(Key.S, 5) || Input.just_pressed(Key.S);
    var left = Input.delay_pressed(Key.A, 5) || Input.just_pressed(Key.A);
    var right = Input.delay_pressed(Key.D, 5) || Input.just_pressed(Key.D);
    if (up && !down) {
        player_dy = -1;
    }
    if (down && !up) {
        player_dy = 1;
    }
    if (left && !right) {
        player_dx = -1;
    }
    if (right && !left) {
        player_dx = 1;
    }
    if (player_dx != 0 && player_dy != 0) {
        player_dy = 0;
    }
    if (player_dx != 0 || player_dy != 0) {
        player_x += player_dx;
        player_y += player_dy;

        // Need to redraw tiles if player moved
        need_to_update_tiles_canvas = true;

        var free_map = get_free_map();
        if (free_map[player_x][player_y]) {
            end_turn();
        } else {
            player_x -= player_dx;
            player_y -= player_dy;
        }
    }

    //
    // Attack on left click
    //
    var mouse_map_x = Math.floor(Mouse.x / world_scale / tilesize + player_x - Math.floor(view_width / 2));
    var mouse_map_y = Math.floor(Mouse.y / world_scale / tilesize + player_y - Math.floor(view_height / 2));
    var hovered_entity = Entity.at(mouse_map_x, mouse_map_y);

    if (Mouse.left_click() && !player_acted && hovered_entity != null && player_next_to_entity(hovered_entity) && Entity.combat.exists(hovered_entity.type)) {
        // Add buffer of defense before combat
        var defense_absorb_left = player_defense_absorb();

        var entity_combat = Entity.combat[hovered_entity.type];
        var entity_health = entity_combat.health;
        var entity_attack = entity_combat.attack;

        var damage_taken = 0;

        while (player_health > 0 && entity_health > 0) {
            // Simulate player and mob taking turns attacking
            if (defense_absorb_left > 0) {
                defense_absorb_left -= entity_attack;

                if (defense_absorb_left < 0) {
                    // Fix for negative absorb
                    player_health += defense_absorb_left;
                    damage_taken -= defense_absorb_left;
                }
            } else {
                player_health -= entity_attack;
                damage_taken += entity_attack;
            }
            entity_health -= player_attack();
        }

        add_message('You attack ${hovered_entity.type}.');
        add_message(entity_combat.message);
        add_message('You take ${damage_taken} damage from ${hovered_entity.type}.');

        if (entity_health <= 0) {
            add_message('You slay ${hovered_entity.type}.');

            // Some entities drop copper
            if (Entity.give_copper_on_death.exists(hovered_entity.type)) {
                var give_copper = Entity.give_copper_on_death[hovered_entity.type];

                if (Random.chance(give_copper.chance)) {
                    var drop_amount = Random.int(give_copper.min, give_copper.max);
                    copper_count += drop_amount;
                    add_message('${hovered_entity.type} drops $drop_amount copper.');
                }
            }
        }

        if (player_health <= 0) {
            add_message('You died.');
        }

        if (entity_health <= 0) {
            Entity.all.remove(hovered_entity);
        }

        end_turn();
    }

    //
    // Render
    //

    // Tiles
    if (need_to_update_tiles_canvas) {
        Gfx.draw_to_image("tiles_canvas");
        Gfx.scale(1, 1, 0, 0);
        Gfx.clear_screen(Col.BLUE);
        var start_x = player_x - Math.floor(view_width / 2);
        var end_x = player_x + Math.ceil(view_width / 2);
        var start_y = player_y - Math.floor(view_height / 2);
        var end_y = player_y + Math.ceil(view_height / 2);
        for (x in start_x...end_x) {
            for (y in start_y...end_y) {
                if (!out_of_map_bounds(x, y)) {
                    Gfx.draw_tile(unscaled_screen_x(x), unscaled_screen_y(y), tiles[x][y]);
                }
            }
        }
        Gfx.draw_to_screen();

        need_to_update_tiles_canvas = false;
    }

    Gfx.scale(world_scale, world_scale, 0, 0);
    Gfx.draw_image(0, 0, "tiles_canvas");

    // Entities
    Text.change_size(32);
    for (e in Entity.all) {
        if (!out_of_map_bounds(e.x, e.y) && !e.equipped_or_picked_up()) {
            if (Entity.draw_char.exists(e.type)) {
                // Draw entity as char
                var draw_char = Entity.draw_char[e.type];

                var draw_char_color = Col.WHITE;
                if (Entity.draw_char_color.exists(e.type)) {
                    draw_char_color = Entity.draw_char_color[e.type];
                }

                Text.display(screen_x(e.x), screen_y(e.y), draw_char, draw_char_color);
            } else if (Entity.draw_tile.exists(e.id)) {
                // Draw armor tile
                var tile = Entity.draw_tile[e.id];
                Gfx.draw_tile(screen_x(e.x), screen_y(e.y), tile);
            }
        }
    }

    // Player, draw as parts of each armor
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor_tile: Int;
        if (player_armor[armor_type] == null) {
            armor_tile = Entity.armor_tile[armor_type][0];
        } else {
            armor_tile = Entity.draw_tile[player_armor[armor_type].id];
        }

        Gfx.draw_tile(screen_x(player_x), screen_y(player_y), armor_tile); 
    }

    //
    // Right-hand menu bar
    //
    Gfx.scale(1, 1, 0, 0);
    Text.change_size(12);

    var ui_y: Float = 0;
    var ui_x = view_width * tilesize * world_scale + ui_x_offset;
    function down_line(text) {
        Text.display(ui_x, ui_y, text);
        ui_y += (Text.height() + 2);
    }
    function up_line(text) {
        Text.display(ui_x, ui_y, text);
        ui_y -= (Text.height() + 2);
    }

    // Player stats
    ui_y = player_stats_y;
    down_line('PLAYER');
    down_line('Health: ${player_health}/${player_health_max}');
    down_line('Attack: ${player_attack()}');
    down_line('Defense: ${player_defense()} (absorb ${player_defense_absorb()} damage per fight)');
    down_line('Copper: ${copper_count}');
    down_line('Armor:');
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor = player_armor[armor_type];
        if (armor == null) {
            down_line('$armor_type: none');
        } else {
            down_line('$armor_type: ${Entity.equipment[armor.id].name}');
        }
    }

    //
    // Inventory
    //
    ui_y = inventory_y - Text.height();
    down_line('INVENTORY');
    ui_y = inventory_y;
    var inventory_cell_width = tilesize * world_scale;
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            Gfx.draw_box(ui_x + x * inventory_cell_width, inventory_y + y * inventory_cell_width, inventory_cell_width, inventory_cell_width, Col.WHITE);
        }
    }

    Gfx.scale(world_scale, world_scale, 0, 0);
    var item_x = 0;
    var item_y = 0;
    for (e in inventory) {
        if (Entity.draw_tile.exists(e.id)) {
            // Draw armor tile
            var tile = Entity.draw_tile[e.id];
            Gfx.draw_tile(ui_x + item_x * tilesize * world_scale, ui_y + item_y * tilesize * world_scale, tile);
        }

        item_x++;
        if (item_x > inventory_width) {
            item_x = 0;
            item_y++;
        }
    }
    Gfx.scale(1, 1, 0, 0);

    // Hovered entity stats
    if (hovered_entity != null) {
        ui_y = target_stats_y;
        down_line('TARGET');
        down_line('Id: ${hovered_entity.id}');
        down_line('Type: ${hovered_entity.type}');
        if (Entity.combat.exists(hovered_entity.type)) {
            var entity_combat = Entity.combat[hovered_entity.type];
            down_line('Health: ${entity_combat.health}');
            down_line('Attack: ${entity_combat.attack}');
        }
        if (Entity.description.exists(hovered_entity.type)) {
            down_line(Entity.description[hovered_entity.type]);
        }
        if (Entity.equipment.exists(hovered_entity.id)) {
            down_line('Equipment name: ${Entity.equipment[hovered_entity.id].name}');
        }
        if (Entity.weapon.exists(hovered_entity.id)) {
            down_line('Equipment attack: ${Entity.weapon[hovered_entity.id].attack}');
        }
        if (Entity.armor.exists(hovered_entity.id)) {
            down_line('Equipment defense: ${Entity.armor[hovered_entity.id].defense}');
        }
    }

    //
    // Interact menu
    //
    if (Mouse.right_click() && !player_acted) {
        interact_target = Entity.at(mouse_map_x, mouse_map_y);
        if (interact_target == null) {
            // Check if mouse over item in inventory
            var mouse_inventory_x = Math.floor((Mouse.x - ui_x) / world_scale / tilesize);
            var mouse_inventory_y = Math.floor((Mouse.y - inventory_y) / world_scale / tilesize);

            function out_of_inventory_bounds(x, y) {
                return x < 0 || y < 0 || x >= inventory_width || y >= inventory_height;
            }

            if (!out_of_inventory_bounds(mouse_inventory_x, mouse_inventory_y)) {
                var inventory_i = mouse_inventory_x + mouse_inventory_y * inventory_width;
                if (inventory_i < inventory.length) {
                    interact_target = inventory[inventory_i];
                    interact_target_inv_x = mouse_inventory_x;
                    interact_target_inv_y = mouse_inventory_y;
                }
            }
        }
    }

    // Only interact with nearby entities
    if (interact_target != null && !player_next_to_entity(interact_target)) {
        interact_target = null;
    }

    if (interact_target != null) {
        if (interact_target.equipped_or_picked_up()) {
            GUI.x = ui_x + interact_target_inv_x * tilesize * world_scale;
            GUI.y = inventory_y + interact_target_inv_x * tilesize * world_scale;
        } else {
            GUI.x = screen_x(interact_target.x) + tilesize * world_scale;
            GUI.y = screen_y(interact_target.y) + tilesize * world_scale;
        }
        if (Entity.talk.exists(interact_target.type)) {
            if (GUI.auto_text_button('Talk')) {
                add_message(Entity.talk[interact_target.type]);
                done_interaction = true;
            }
        }
        if (Entity.use.exists(interact_target.type)) {
            if (GUI.auto_text_button('Use')) {
                use_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.equipment.exists(interact_target.id)) {
            if (GUI.auto_text_button('Equip')) {
                equip_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.item.exists(interact_target.id)) {
            var item = Entity.item[interact_target.id];
            if (item.picked_up) {
                if (GUI.auto_text_button('Drop')) {
                    drop_entity(interact_target);

                    done_interaction = true;
                }
            } else {
                if (GUI.auto_text_button('Pick up')) {
                    pick_up_entity(interact_target);

                    done_interaction = true;
                }
            }
        }

        if (done_interaction) {
            interact_target = null;
            done_interaction = false;
            end_turn();
        } else if (Mouse.left_click()) {
            // Clicked out of context menu
            interact_target = null;
            done_interaction = false;
        }
    }

    //
    // Messages
    //
    if (message_history.length > message_history_length_max) {
        message_history.pop();
    }
    ui_y = message_history_y;
    for (message in message_history) {
        up_line(message);
    }

    Text.display(0, 0, 'FPS: ${Gfx.render_fps()}');
}
}
