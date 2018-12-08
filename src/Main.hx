
import haxegon.*;
import haxe.ds.Vector;
import Entity;

using haxegon.MathExtensions;
using StringTools;
using Lambda;

@:publicFields
class Main {
// NOTE: force unindent

static inline var SCREEN_WIDTH = 1600;
static inline var SCREEN_HEIGHT = 1000;
static inline var TILESIZE = 8;
static inline var MAP_WIDTH = 200;
static inline var MAP_HEIGHT = 200;
static inline var VIEW_WIDTH = 31;
static inline var VIEW_HEIGHT = 31;
static inline var WORLD_SCALE = 4;

var tiles = Data.int_2d_vector(MAP_WIDTH, MAP_HEIGHT);
var walls = Data.bool_2d_vector(MAP_WIDTH, MAP_HEIGHT);

static inline var PLAYER_BASE_ATTACK = 1;
var player_x = 100;
var player_y = 100;
var player_health_max = 10;
var player_health = 10;
var copper_count = 0;

var player_armor: Map<ArmorType, Int> = [
ArmorType_Head => Entity.NONE,
ArmorType_Chest => Entity.NONE,
ArmorType_Legs => Entity.NONE,
];
var player_weapon: Int = Entity.NONE;
static inline var equipment_y = 110;
static inline var equipment_width = 4;

static inline var message_history_length_max = 20;
var message_history = new Array<String>();

// UI
static inline var MESSAGE_HISTORY_Y = 800;
static inline var UI_X = TILESIZE * VIEW_WIDTH * WORLD_SCALE + 13;
static inline var player_stats_y = 0;
static inline var target_stats_y = 300;

// Inventory
static inline var inventory_y = 170;
static inline var inventory_width = 4;
static inline var inventory_height = 4;
static inline var inventory_size = inventory_width * inventory_height;
var inventory = new Array<Int>();

var interact_target: Int = Entity.NONE;
var interact_target_x: Int;
var interact_target_y: Int;
var done_interaction = false;
var player_acted = false;
var need_to_update_tiles_canvas = true;

function new() {
    Gfx.resize_screen(SCREEN_WIDTH, SCREEN_HEIGHT, 1);
    Text.setfont('pixelFJ8', 8);
    Gfx.load_tiles('tiles', TILESIZE, TILESIZE);

    Gfx.create_image("tiles_canvas", VIEW_WIDTH * TILESIZE, VIEW_HEIGHT * TILESIZE);

    for (x in 0...MAP_WIDTH) {
        for (y in 0...MAP_HEIGHT) {
            walls[x][y] = false;
        }
    }

    walls[102][100] = true;
    walls[103][100] = true;
    walls[104][100] = true;
    walls[105][105] = true;

    for (x in 0...MAP_WIDTH) {
        for (y in 0...MAP_HEIGHT) {
            if (walls[x][y]) {
                tiles[x][y] = Tile.Wall;
            } else {
                tiles[x][y] = Tile.Ground;
            }
        }
    }

    Entity.make_snail(98, 98);
    Entity.make_snail(98, 97);
    Entity.make_snail(98, 96);
    Entity.make_bear(108, 100);

    Entity.make_fountain(105, 98);

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
    var free_map = Data.bool_2d_vector(MAP_WIDTH, MAP_HEIGHT, true);
    for (e in Entity.all) {
        if (Entity.position.exists(e)) {
            var pos = Entity.position[e];
            free_map[pos.x][pos.y] = false;
        }
    }
    // Walls
    for (x in 0...MAP_WIDTH) {
        for (y in 0...MAP_HEIGHT) {
            if (walls[x][y]) {
                free_map[x][y] = false;
            }
        }
    }
    // NOTE: Add player collision here if entities can move
    // free_map[player_x][player_y] = false;

    return free_map;
}

function screen_x(x) {
    return unscaled_screen_x(x) * WORLD_SCALE;
}
function screen_y(y) {
    return unscaled_screen_y(y) * WORLD_SCALE;
}
function unscaled_screen_x(x) {
    return (x - player_x + Math.floor(VIEW_WIDTH / 2)) * TILESIZE;
}
function unscaled_screen_y(y) {
    return (y - player_y + Math.floor(VIEW_HEIGHT / 2)) * TILESIZE;
}

function out_of_map_bounds(x, y) {
    return x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT;
}

function out_of_view_bounds(x, y) {
    return x < (player_x - Math.floor(VIEW_WIDTH / 2)) || y < (player_y - Math.floor(VIEW_HEIGHT / 2)) || x > (player_x + Math.floor(VIEW_WIDTH / 2)) || y > (player_y + Math.floor(VIEW_HEIGHT / 2));
}

function add_message(message: String) {
    message_history.insert(0, message);
}

function use_entity(e: Int) {
    var use = Entity.use[e];

    var display_name = 'noname';
    if (Entity.item.exists(e)) {
        display_name = Entity.item[e].name;
    } else if (Entity.name.exists(e)) {
        display_name = Entity.name[e];
    }

    if (use.charges > 0) {
        switch (use.type) {
            case UseType_Heal: {
                player_health += use.value;

                if (player_health > player_health_max) {
                    player_health = player_health_max;
                }

                use.charges--;

                add_message('${display_name} heals you for ${use.value} health.');

                if (use.charges == 0 && use.consumable) {
                    // Consumables disappear when all charges are used
                    Entity.remove(e);
                    inventory.remove(e);
                }
            }
        }
    } else {
        add_message('${display_name} can\'t be used anymore.');
    }
}

function equip_entity(e: Int) {
    var unequip_e = Entity.NONE;
    if (Entity.armor.exists(e)) {
        var armor = Entity.armor[e];
        unequip_e = player_armor[armor.type];
    } else if (Entity.weapon.exists(e)) {
        unequip_e = player_weapon;
    }

    if (unequip_e != Entity.NONE) {
        add_message('You take off ${Entity.equipment[unequip_e].name}.');

        // Drop armor to location of new armor
        Entity.equipment[unequip_e].equipped = false;
        if (Entity.position.exists(e)) {
            var e_pos = Entity.position[e];
            Entity.set_position(unequip_e, e_pos.x, e_pos.y);
        }
    }

    add_message('You put on ${Entity.equipment[e].name}.');

    if (Entity.armor.exists(e)) {
        var armor = Entity.armor[e];
        player_armor[armor.type] = e;
    } else if (Entity.weapon.exists(e)) {
        player_weapon = e;
    }
    Entity.equipment[e].equipped = true;
    Entity.remove_position(e);
}

function pick_up_entity(e: Int) {
    if (inventory.length < inventory_size) {
        inventory.push(e);

        add_message('You pick up ${Entity.item[e].name}.');

        Entity.item[e].picked_up = true;
        Entity.remove_position(e);
    } else {
        add_message('Inventory is full.');
    }
}

function drop_entity(e: Int) {
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
        Entity.set_position(e, free_x, free_y);
        Entity.item[e].picked_up = false;
        inventory.remove(e);
        add_message('You drop ${Entity.item[e].name}.');
    } else {
        add_message('No space to drop item.');
    }
}

function player_attack(): Int {
    if (player_weapon == Entity.NONE) {
        return PLAYER_BASE_ATTACK;
    } else {
        return Entity.weapon[player_weapon].attack;
    }
}

function player_defense(): Int {
    var total = 0;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (player_armor[armor_type] != Entity.NONE) {
            var armor = Entity.armor[player_armor[armor_type]];
            total += armor.defense;
        }
    }
    return total;
}

function player_defense_absorb(): Int {
    // Each 10 points of defense absorbs 1 dmg per fight
    return Math.floor(player_defense() / 10);
}

function player_next_to(pos: Position): Bool {
    return Math.dst2(pos.x, pos.y, player_x, player_y) <= 2;
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

    trace(Entity.at(98, 98));
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
    // Find entity under mouse
    //
    var mouse_map_x = Math.floor(Mouse.x / WORLD_SCALE / TILESIZE + player_x - Math.floor(VIEW_WIDTH / 2));
    var mouse_map_y = Math.floor(Mouse.y / WORLD_SCALE / TILESIZE + player_y - Math.floor(VIEW_HEIGHT / 2));

    // Check for entities on map
    var hovered_map: Int = Entity.NONE;
    if (!out_of_view_bounds(mouse_map_x, mouse_map_y)) {
        hovered_map = Entity.at(mouse_map_x, mouse_map_y);
    }

    // Check for entities anywhere, including inventory/equipment
    var hovered_anywhere: Int = Entity.NONE;
    var hovered_anywhere_x: Int = 0;
    var hovered_anywhere_y: Int = 0;
    if (hovered_map != Entity.NONE) {
        hovered_anywhere = hovered_map;
        if (Entity.position.exists(hovered_anywhere)) {
            var pos = Entity.position[hovered_anywhere];
            hovered_anywhere_x = screen_x(pos.x);
            hovered_anywhere_y = screen_y(pos.y);
        }
    } else {
        // Check for entities in inventory
        var mouse_inventory_x = Math.floor((Mouse.x - UI_X) / WORLD_SCALE / TILESIZE);
        var mouse_inventory_y = Math.floor((Mouse.y - inventory_y) / WORLD_SCALE / TILESIZE);

        function out_of_inventory_bounds(x, y) {
            return x < 0 || y < 0 || x >= inventory_width || y >= inventory_height;
        }

        if (!out_of_inventory_bounds(mouse_inventory_x, mouse_inventory_y)) {
            var inventory_i = mouse_inventory_x + mouse_inventory_y * inventory_width;
            if (inventory_i < inventory.length) {
                hovered_anywhere = inventory[inventory_i];
                hovered_anywhere_x = UI_X + mouse_inventory_x * TILESIZE * WORLD_SCALE;
                hovered_anywhere_y = inventory_y + mouse_inventory_y * TILESIZE * WORLD_SCALE;
            }
        }

        if (hovered_anywhere == Entity.NONE) {
            // Check for equipped entities
            var mouse_equip_x = Math.floor((Mouse.x - UI_X) / WORLD_SCALE / TILESIZE);
            var mouse_equip_y = Math.floor((Mouse.y - equipment_y) / WORLD_SCALE / TILESIZE);

            if (mouse_equip_x >= 0 && mouse_equip_x < equipment_width && mouse_equip_y == 0) {
                if (mouse_equip_x == 0) {
                    hovered_anywhere = player_weapon;
                } else if (mouse_equip_x == 1) {
                    hovered_anywhere = player_armor[ArmorType_Head];
                } else if (mouse_equip_x == 2) {
                    hovered_anywhere = player_armor[ArmorType_Chest];
                } else if (mouse_equip_x == 3) {
                    hovered_anywhere = player_armor[ArmorType_Legs];
                }

                if (hovered_anywhere != Entity.NONE) {
                    hovered_anywhere_x = UI_X + mouse_equip_x * TILESIZE * WORLD_SCALE;
                    hovered_anywhere_y = equipment_y;
                }
            }
        }
    }

    //
    // Attack on left click
    //

    if (Mouse.left_click() && !player_acted && hovered_map != Entity.NONE && Entity.position.exists(hovered_map) && player_next_to(Entity.position[hovered_map]) && Entity.combat.exists(hovered_map)) {
        var defense_absorb_left = player_defense_absorb();

        var entity_combat = Entity.combat[hovered_map];
        var entity_health = entity_combat.health;
        var entity_attack = entity_combat.attack;

        var damage_taken = 0;
        var damage_absorbed = 0;

        while (player_health > 0 && entity_health > 0) {
            // Simulate player and mob taking turns attacking
            if (defense_absorb_left > 0) {
                defense_absorb_left -= entity_attack;
                damage_absorbed += entity_attack;

                if (defense_absorb_left < 0) {
                    // Fix for negative absorb
                    player_health += defense_absorb_left;
                    damage_taken -= defense_absorb_left;
                    damage_absorbed += defense_absorb_left;
                }
            } else {
                player_health -= entity_attack;
                damage_taken += entity_attack;
            }
            entity_health -= player_attack();
        }

        var target_name = 'noname';
        if (Entity.name.exists(hovered_map)) {
            target_name = Entity.name[hovered_map];
        }
        add_message('------------------------------');
        add_message('You attack $target_name.');
        add_message(entity_combat.message);
        add_message('You take ${damage_taken} damage from $target_name.');
        add_message('Your armor absorbs ${damage_absorbed} damage.');
        

        if (entity_health <= 0) {
            add_message('You slay $target_name.');

            // Some entities drop copper
            if (Entity.give_copper_on_death.exists(hovered_map)) {
                var give_copper = Entity.give_copper_on_death[hovered_map];

                if (Random.chance(give_copper.chance)) {
                    var drop_amount = Random.int(give_copper.min, give_copper.max);
                    copper_count += drop_amount;
                    add_message('$target_name drops $drop_amount copper.');
                }
            }
        }

        if (player_health <= 0) {
            add_message('You died.');
        }

        if (entity_health <= 0) {
            if (Entity.drop_item.exists(hovered_map) && Entity.position.exists(hovered_map)) {
                var drop_item = Entity.drop_item[hovered_map];
                var pos = Entity.position[hovered_map];
                if (Random.chance(drop_item.chance)) {
                    add_message('$target_name drops ${drop_item.type}.');
                    Entity.remove_position(hovered_map);
                    Entity.make_item(pos.x, pos.y, drop_item.type);
                }
            }

            Entity.remove(hovered_map);
            hovered_map = Entity.NONE;
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
        var start_x = player_x - Math.floor(VIEW_WIDTH / 2);
        var end_x = player_x + Math.ceil(VIEW_WIDTH / 2);
        var start_y = player_y - Math.floor(VIEW_HEIGHT / 2);
        var end_y = player_y + Math.ceil(VIEW_HEIGHT / 2);
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

    Gfx.scale(WORLD_SCALE, WORLD_SCALE, 0, 0);
    Gfx.draw_image(0, 0, "tiles_canvas");

    // Entities
    Text.change_size(32);
    for (e in Entity.all) {
        if (Entity.position.exists(e)) {
            var pos = Entity.position[e];
            if (Entity.draw_char.exists(e)) {
                // Draw char
                var draw_char = Entity.draw_char[e];
                Text.display(screen_x(pos.x), screen_y(pos.y), draw_char.char, draw_char.color);
            } else if (Entity.draw_tile.exists(e)) {
                // Draw tile
                var tile = Entity.draw_tile[e];
                Gfx.draw_tile(screen_x(pos.x), screen_y(pos.y), tile);
            }
        }
    }

    // Player, draw as parts of each equipment
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor_tile: Int;
        if (player_armor[armor_type] == Entity.NONE) {
            var base_armor_tiles = [
            ArmorType_Head => Tile.Head0,
            ArmorType_Chest => Tile.Chest0,
            ArmorType_Legs => Tile.Legs0,
            ];
            armor_tile = base_armor_tiles[armor_type];
        } else {
            armor_tile = Entity.draw_tile[player_armor[armor_type]];
        }

        Gfx.draw_tile(screen_x(player_x), screen_y(player_y), armor_tile); 
    }
    if (player_weapon != Entity.NONE) {
        var weapon_tile = Entity.draw_tile[player_weapon];
        Gfx.draw_tile(screen_x(player_x) + 0.3 * TILESIZE * WORLD_SCALE, screen_y(player_y), weapon_tile); 
    }

    //
    // UI
    //
    Gfx.scale(1, 1, 0, 0);
    Text.change_size(12);

    var current_ui_x: Float = 0;
    var current_ui_y: Float = 0;
    function down_line(text) {
        Text.display(current_ui_x, current_ui_y, text);
        current_ui_y += (Text.height() + 2);
    }
    function up_line(text) {
        Text.display(current_ui_x, current_ui_y, text);
        current_ui_y -= (Text.height() + 2);
    }

    // Player stats
    current_ui_x = UI_X;
    current_ui_y = player_stats_y;
    down_line('PLAYER');
    down_line('Health: ${player_health}/${player_health_max}');
    down_line('Attack: ${player_attack()}');
    down_line('Defense: ${player_defense()} (absorb ${player_defense_absorb()} damage per fight)');
    down_line('Copper: ${copper_count}');
    down_line('');

    // Equipment
    down_line('EQUIPMENT');
    var tile_screen_size = TILESIZE * WORLD_SCALE;
    for (i in 0...equipment_width) {
        Gfx.draw_box(UI_X + i * tile_screen_size, equipment_y, tile_screen_size, tile_screen_size, Col.WHITE);
    }
    Gfx.scale(WORLD_SCALE, WORLD_SCALE, 0, 0);
    if (player_weapon != Entity.NONE && Entity.draw_tile.exists(player_weapon)) {
        var tile = Entity.draw_tile[player_weapon];
        Gfx.draw_tile(UI_X, equipment_y, tile);
    }
    var armor_i = 1;
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor = player_armor[armor_type];
        if (armor != Entity.NONE && Entity.draw_tile.exists(armor)) {
            var tile = Entity.draw_tile[armor];
            Gfx.draw_tile(UI_X + armor_i * tile_screen_size, equipment_y, tile);
        }
        armor_i++;
    }
    Gfx.scale(1, 1, 0, 0);

    //
    // Inventory
    //
    current_ui_y = inventory_y - Text.height();
    down_line('INVENTORY');
    // Inventory cells
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            Gfx.draw_box(UI_X + x * tile_screen_size, inventory_y + y * tile_screen_size, tile_screen_size, tile_screen_size, Col.WHITE);
        }
    }
    // Inventory entities
    Gfx.scale(WORLD_SCALE, WORLD_SCALE, 0, 0);
    var item_x = 0;
    var item_y = 0;
    for (e in inventory) {
        if (Entity.draw_tile.exists(e)) {
            // Draw tile
            var tile = Entity.draw_tile[e];
            Gfx.draw_tile(UI_X + item_x * TILESIZE * WORLD_SCALE, current_ui_y + item_y * TILESIZE * WORLD_SCALE, tile);
        }

        item_x++;
        if (item_x > inventory_width) {
            item_x = 0;
            item_y++;
        }
    }
    Gfx.scale(1, 1, 0, 0);

    //
    // Hovered entity tooltip
    //
    if (hovered_anywhere != Entity.NONE) {
        var e = hovered_anywhere;
        // current_ui_y = target_stats_y;
        current_ui_x = hovered_anywhere_x + TILESIZE * WORLD_SCALE;
        current_ui_y = hovered_anywhere_y;
        down_line('Id: ${e}');
        if (Entity.name.exists(e)) {
            down_line('Name: ${Entity.name[e]}');
        }
        if (Entity.combat.exists(e)) {
            var entity_combat = Entity.combat[e];
            down_line('Health: ${entity_combat.health}');
            down_line('Attack: ${entity_combat.attack}');
        }
        if (Entity.description.exists(e)) {
            down_line(Entity.description[e]);
        }
        if (Entity.equipment.exists(e)) {
            down_line('Equipment name: ${Entity.equipment[e].name}');
        }
        if (Entity.weapon.exists(e)) {
            down_line('Equipment attack: ${Entity.weapon[e].attack}');
        }
        if (Entity.armor.exists(e)) {
            down_line('Equipment defense: ${Entity.armor[e].defense}');
        }
    }

    //
    // Interact menu
    //
    if (Mouse.right_click() && !player_acted) {
        interact_target = hovered_anywhere;
        interact_target_x = hovered_anywhere_x;
        interact_target_y = hovered_anywhere_y;
    }

    // Stop interaction if entity too far away
    if (interact_target != Entity.NONE && Entity.position.exists(interact_target) && !player_next_to(Entity.position[interact_target])) {
        interact_target = Entity.NONE;
    }

    if (interact_target != Entity.NONE) {
        GUI.x = interact_target_x + TILESIZE * WORLD_SCALE;
        GUI.y = interact_target_y;
        if (Entity.talk.exists(interact_target)) {
            if (GUI.auto_text_button('Talk')) {
                add_message(Entity.talk[interact_target]);
                done_interaction = true;
            }
        }
        if (Entity.use.exists(interact_target)) {
            if (GUI.auto_text_button('Use')) {
                use_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.equipment.exists(interact_target) && !Entity.equipment[interact_target].equipped) {
            if (GUI.auto_text_button('Equip')) {
                equip_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.item.exists(interact_target)) {
            var item = Entity.item[interact_target];
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
            interact_target = Entity.NONE;
            done_interaction = false;
            end_turn();
        } else if (Mouse.left_click()) {
            // Clicked out of context menu
            interact_target = Entity.NONE;
            done_interaction = false;
        }
    }

    //
    // Messages
    //
    current_ui_y = hovered_anywhere_y;
    if (message_history.length > message_history_length_max) {
        message_history.pop();
    }
    current_ui_x = UI_X;
    current_ui_y = MESSAGE_HISTORY_Y;
    for (message in message_history) {
        up_line(message);
    }

    Text.display(0, 0, 'FPS: ${Gfx.render_fps()}');
}
}
