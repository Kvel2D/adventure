
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

var player_armor: Map<ArmorType, Entity> = [
ArmorType_Head => null,
ArmorType_Chest => null,
ArmorType_Legs => null,
];
var player_weapon: Entity = null;
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
var inventory = new Array<Entity>();

var interact_target: Entity = null;
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
    Entity.make(108, 100, 'bear');

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
        if (Entity.position.exists(e.id)) {
            var pos = Entity.position[e.id];
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

function use_entity(e: Entity) {
    var use = Entity.use[e.id];

    var display_name = e.type;
    if (Entity.item.exists(e.id)) {
        display_name = Entity.item[e.id].name;
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
        if (Entity.position.exists(e.id)) {
            var equipped_pos = Entity.position[e.id];
            Entity.position[equipped_entity.id] = {
                x: equipped_pos.x,
                y: equipped_pos.y
            };
        }
    }

    add_message('You put on ${Entity.equipment[e.id].name}.');

    if (Entity.armor.exists(e.id)) {
        var armor = Entity.armor[e.id];
        player_armor[armor.type] = e;
    } else if (Entity.weapon.exists(e.id)) {
        player_weapon = e;
    }
    Entity.equipment[e.id].equipped = true;
    Entity.position.remove(e.id);
}

function pick_up_entity(e: Entity) {
    if (inventory.length < inventory_size) {
        inventory.push(e);

        add_message('You pick up ${Entity.item[e.id].name}.');

        Entity.item[e.id].picked_up = true;
        Entity.position.remove(e.id);
    } else {
        add_message('Inventory is full.');
    }
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
        Entity.position[e.id] = {
            x: free_x,
            y: free_y
        };
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
    if (Entity.position.exists(e.id)) {
        var pos = Entity.position[e.id];
        return Math.dst2(pos.x, pos.y, player_x, player_y) <= 2;
    } else {
        return false;
    }
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
    // Find entity under mouse
    //
    var mouse_map_x = Math.floor(Mouse.x / WORLD_SCALE / TILESIZE + player_x - Math.floor(VIEW_WIDTH / 2));
    var mouse_map_y = Math.floor(Mouse.y / WORLD_SCALE / TILESIZE + player_y - Math.floor(VIEW_HEIGHT / 2));

    // Check for entities on map
    var hovered_map: Entity = null;
    if (!out_of_view_bounds(mouse_map_x, mouse_map_y)) {
        hovered_map = Entity.at(mouse_map_x, mouse_map_y);
    }

    // Check for entities anywhere, including inventory/equipment
    var hovered_anywhere: Entity = null;
    var hovered_anywhere_x: Int = 0;
    var hovered_anywhere_y: Int = 0;
    if (hovered_map != null) {
        hovered_anywhere = hovered_map;
        if (Entity.position.exists(hovered_anywhere.id)) {
            var pos = Entity.position[hovered_anywhere.id];
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

        if (hovered_anywhere == null) {
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

                if (hovered_anywhere != null) {
                    hovered_anywhere_x = UI_X + mouse_equip_x * TILESIZE * WORLD_SCALE;
                    hovered_anywhere_y = equipment_y;
                }
            }
        }
    }

    //
    // Attack on left click
    //

    if (Mouse.left_click() && !player_acted && hovered_map != null && player_next_to_entity(hovered_map) && Entity.combat.exists(hovered_map.type) && !hovered_map.equipped_or_picked_up()) {
        var defense_absorb_left = player_defense_absorb();

        var entity_combat = Entity.combat[hovered_map.type];
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

        add_message('You attack ${hovered_map.type}.');
        add_message(entity_combat.message);
        add_message('Your armor absorbs ${damage_absorbed} damage from ${hovered_map.type}.');
        add_message('You take ${damage_taken} damage from ${hovered_map.type}.');

        if (entity_health <= 0) {
            add_message('You slay ${hovered_map.type}.');

            // Some entities drop copper
            if (Entity.give_copper_on_death.exists(hovered_map.type)) {
                var give_copper = Entity.give_copper_on_death[hovered_map.type];

                if (Random.chance(give_copper.chance)) {
                    var drop_amount = Random.int(give_copper.min, give_copper.max);
                    copper_count += drop_amount;
                    add_message('${hovered_map.type} drops $drop_amount copper.');
                }
            }
        }

        if (player_health <= 0) {
            add_message('You died.');
        }

        if (entity_health <= 0) {
            if (Entity.drop_item.exists(hovered_map.id) && Entity.position.exists(hovered_map.id)) {
                var drop_item = Entity.drop_item[hovered_map.id];
                var pos = Entity.position[hovered_map.id];
                if (Random.chance(drop_item.chance)) {
                    add_message('${hovered_map.type} drops ${drop_item.type}.');
                    Entity.make_item(pos.x, pos.y, drop_item.type);
                }
            }

            Entity.remove(hovered_map);
            hovered_map = null;
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
        if (Entity.position.exists(e.id)) {
            var pos = Entity.position[e.id];
            if (Entity.draw_char.exists(e.type)) {
                // Draw char
                var draw_char = Entity.draw_char[e.type];

                var draw_char_color = Col.WHITE;
                if (Entity.draw_char_color.exists(e.type)) {
                    draw_char_color = Entity.draw_char_color[e.type];
                }

                Text.display(screen_x(pos.x), screen_y(pos.y), draw_char, draw_char_color);
            } else if (Entity.draw_tile.exists(e.id)) {
                // Draw tile
                var tile = Entity.draw_tile[e.id];
                Gfx.draw_tile(screen_x(pos.x), screen_y(pos.y), tile);
            }
        }
    }

    // Player, draw as parts of each equipment
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor_tile: Int;
        if (player_armor[armor_type] == null) {
            armor_tile = Entity.armor_tile[armor_type][0];
        } else {
            armor_tile = Entity.draw_tile[player_armor[armor_type].id];
        }

        Gfx.draw_tile(screen_x(player_x), screen_y(player_y), armor_tile); 
    }
    if (player_weapon != null) {
        var weapon_tile = Entity.draw_tile[player_weapon.id];
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
    if (player_weapon != null && Entity.draw_tile.exists(player_weapon.id)) {
        var tile = Entity.draw_tile[player_weapon.id];
        Gfx.draw_tile(UI_X, equipment_y, tile);
    }
    var armor_i = 1;
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor = player_armor[armor_type];
        if (armor != null && Entity.draw_tile.exists(armor.id)) {
            var tile = Entity.draw_tile[armor.id];
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
        if (Entity.draw_tile.exists(e.id)) {
            // Draw tile
            var tile = Entity.draw_tile[e.id];
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
    if (hovered_anywhere != null) {
        var e = hovered_anywhere;
        // current_ui_y = target_stats_y;
        current_ui_x = hovered_anywhere_x + TILESIZE * WORLD_SCALE;
        current_ui_y = hovered_anywhere_y;
        down_line('TARGET');
        down_line('Id: ${e.id}');
        down_line('Type: ${e.type}');
        if (Entity.combat.exists(e.type)) {
            var entity_combat = Entity.combat[e.type];
            down_line('Health: ${entity_combat.health}');
            down_line('Attack: ${entity_combat.attack}');
        }
        if (Entity.description.exists(e.type)) {
            down_line(Entity.description[e.type]);
        }
        if (Entity.equipment.exists(e.id)) {
            down_line('Equipment name: ${Entity.equipment[e.id].name}');
        }
        if (Entity.weapon.exists(e.id)) {
            down_line('Equipment attack: ${Entity.weapon[e.id].attack}');
        }
        if (Entity.armor.exists(e.id)) {
            down_line('Equipment defense: ${Entity.armor[e.id].defense}');
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
    if (interact_target != null && !interact_target.equipped_or_picked_up() && !player_next_to_entity(interact_target)) {
        interact_target = null;
    }

    if (interact_target != null) {
        GUI.x = interact_target_x + TILESIZE * WORLD_SCALE;
        GUI.y = interact_target_y;
        if (Entity.talk.exists(interact_target.type)) {
            if (GUI.auto_text_button('Talk')) {
                add_message(Entity.talk[interact_target.type]);
                done_interaction = true;
            }
        }
        if (Entity.use.exists(interact_target.id)) {
            if (GUI.auto_text_button('Use')) {
                use_entity(interact_target);

                done_interaction = true;
            }
        }
        if (Entity.equipment.exists(interact_target.id) && !Entity.equipment[interact_target.id].equipped) {
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
