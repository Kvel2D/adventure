
import haxegon.*;
import haxe.ds.Vector;
import Entity;
import GenerateWorld;

using haxegon.MathExtensions;

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
static inline var world_scale = 4;

static inline var funtown_x = 15;
static inline var funtown_y = 15;
var in_funtown = true;
var previous_world_x = 20;
var previous_world_y = 20;
var draw_map = false;
static inline var map_scale = 4;

var tiles = Data.int_2d_vector(map_width, map_height);
var walls = Data.bool_2d_vector(map_width, map_height);

static inline var player_base_attack = 1;
var player_x = 0;
var player_y = 0;
var player_health_max = 10;
var player_health = 10;
var copper_count = 0;

static inline var equipment_y = 110;
static inline var equipment_width = 4;
var player_armor = [
ArmorType_Head => Entity.NONE,
ArmorType_Chest => Entity.NONE,
ArmorType_Legs => Entity.NONE,
];
var player_weapon = Entity.NONE;

static inline var message_history_y = 800;
static inline var message_history_length_max = 20;
var message_history = new Array<String>();

static inline var ui_x = tilesize * view_width * world_scale + 13;
static inline var player_stats_y = 0;

// Inventory
static inline var inventory_y = 170;
static inline var inventory_width = 4;
static inline var inventory_height = 4;
static inline var inventory_size = inventory_width * inventory_height;
var inventory = new Vector<Vector<Int>>(inventory_width);

var interact_target = Entity.NONE;
var interact_target_x: Int;
var interact_target_y: Int;
var player_acted = false;

var move_tile_canvas = false;
var canvas_dx = 0;
var canvas_dy = 0;
var redraw_tile_canvas = true;

var rooms: Array<Room>;
var connections: Array<Connection>;

function new() {
    Gfx.resize_screen(screen_width, screen_height, 1);
    Text.setfont('pixelFJ8', 8);
    Gfx.load_tiles('tiles', tilesize, tilesize);

    Gfx.create_image('tiles_canvas', view_width * tilesize, view_height * tilesize);

    for (x in 0...inventory_width) {
        inventory[x] = new Vector<Int>(inventory_height);
        for (y in 0...inventory_height) {
            inventory[x][y] = Entity.NONE;
        }
    }

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            walls[x][y] = true;
        }
    }

    // Funtown
    for (x in 0...funtown_x + 1) {
        for (y in 0...funtown_y + 1) {
            walls[x][y] = false;
        }
    }
    walls[2][4] = true;
    walls[2][5] = true;
    walls[2][6] = true;
    walls[3][6] = true;

    rooms = GenerateWorld.generate_via_digging();
    connections = GenerateWorld.connect_rooms(rooms);

    // Clear walls for rooms and connections
    for (r in rooms) {
        for (x in r.x...(r.x + r.width + 1)) {
            for (y in r.y...(r.y + r.height + 1)) {
                walls[x][y] = false;
            }
        }
    }
    for (c in connections) {
        for (x in c.x1...(c.x2 + 1)) {
            for (y in c.y1...(c.y2 + 1)) {
                walls[x][y] = false;
            }
        }
    }

    GenerateWorld.fill_rooms_with_entities(rooms);

    previous_world_x = rooms[0].x;
    previous_world_y = rooms[0].y;

    if (in_funtown) {
        player_x = funtown_x;
        player_y = funtown_y;
    } else {
        player_x = previous_world_x;
        player_y = previous_world_y;
    }

    for (x in 0...map_width) {
        for (y in 0...map_height) {
            if (walls[x][y]) {
                tiles[x][y] = Tile.Wall;
            } else {
                tiles[x][y] = Tile.Ground;
            }
        }
    }

    MakeEntity.snail(10, 3);
    MakeEntity.snail(10, 4);
    MakeEntity.snail(10, 5);
    MakeEntity.bear(8, 8);

    MakeEntity.fountain(8, 10);

    for (i in 0...2) {
        var x = 7;
        var y = 5;
        MakeEntity.armor(x + 0, y + i, ArmorType_Head);
        MakeEntity.armor(x + 1, y + i, ArmorType_Chest);
        MakeEntity.armor(x + 2, y + i, ArmorType_Legs);
    }

    MakeEntity.sword(6, 7);
    MakeEntity.potion(6, 8);

    MakeEntity.chest(2, 15);

    for (i in 0...15) {
        var x = 0;
        var y = 0;
        MakeEntity.potion(x + i, y);
    }
}

function get_free_map(): Vector<Vector<Bool>> {
    // Entities
    var free_map = Data.bool_2d_vector(map_width, map_height, true);
    for (pos in Entity.position) {
        free_map[pos.x][pos.y] = false;
    }
    // Walls
    for (x in 0...map_width) {
        for (y in 0...map_height) {
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

function out_of_view_bounds(x, y) {
    return x < (player_x - Math.floor(view_width / 2)) || y < (player_y - Math.floor(view_height / 2)) || x > (player_x + Math.floor(view_width / 2)) || y > (player_y + Math.floor(view_height / 2));
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
        use.charges--;

        switch (use.type) {
            case UseType_Heal: {
                player_health += use.value;

                if (player_health > player_health_max) {
                    player_health = player_health_max;
                }

                add_message('${display_name} heals you for ${use.value} health.');
            }
        }
    }

    // Chance color to gray if out of charges
    if (use.charges == 0 && Entity.draw_char.exists(e)) {
        Entity.draw_char[e].color = Col.GRAY;
    }

    // Consumables disappear when all charges are used
    if (use.consumable && use.charges == 0) {
        Entity.remove(e);
    }
}

function equip_entity(e: Int) {
    var old_e = Entity.NONE;
    if (Entity.armor.exists(e)) {
        var old_armor = Entity.armor[e];
        old_e = player_armor[old_armor.type];
    } else if (Entity.weapon.exists(e)) {
        old_e = player_weapon;
    }

    // Remove new equipment from map
    var e_pos = Entity.position[e];
    var drop_x = e_pos.x;
    var drop_y = e_pos.y;
    Entity.remove_position(e);

    // Unequip old equipment
    if (Entity.equipment.exists(old_e)) {
        add_message('You take off ${Entity.equipment[old_e].name}.');
        Entity.set_position(old_e, drop_x, drop_y);
    }

    add_message('You put on ${Entity.equipment[e].name}.');

    if (Entity.armor.exists(e)) {
        var armor = Entity.armor[e];
        player_armor[armor.type] = e;
    } else if (Entity.weapon.exists(e)) {
        player_weapon = e;
    }
}

function pick_up_entity(e: Int) {
    // Flip loop order so that rows are filled first
    for (y in 0...inventory_height) {
        for (x in 0...inventory_width) {
            // Inventory slot is free if it points to entity that is not an item(removed) or an entity that is an item but has position(dropped on map)
            var doesnt_exist = !Entity.item.exists(inventory[x][y]);
            var not_in_inventory = Entity.item.exists(inventory[x][y]) && Entity.position.exists(inventory[x][y]);
            if (doesnt_exist || not_in_inventory) {
                inventory[x][y] = e;

                add_message('You pick up ${Entity.item[e].name}.');
                Entity.remove_position(e);

                return;
            }
        }
    }
    add_message('Inventory is full.');
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
        add_message('You drop ${Entity.item[e].name}.');

        Entity.set_position(e, free_x, free_y);
    } else {
        add_message('No space to drop item.');
    }
}

function player_attack(): Int {
    // Weapon is valid if it's a weapon and it doesn't have a position(not on map)
    if (Entity.weapon.exists(player_weapon) && !Entity.position.exists(player_weapon)) {
        return Entity.weapon[player_weapon].attack;
    } else {
        return player_base_attack;
    }
}

function player_defense(): Int {
    // Armor is valid if it's an armor and it doesn't have a position(not on map)
    var total = 0;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (Entity.armor.exists(player_armor[armor_type]) && !Entity.position.exists(player_armor[armor_type])) {
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
        // NOTE: do mob stuff here

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
        move_tile_canvas = true;

        var free_map = get_free_map();
        if (free_map[player_x][player_y] || Input.pressed(Key.I)) {
            canvas_dx = player_dx;
            canvas_dy = player_dy;
            end_turn();
        } else {
            player_x -= player_dx;
            player_y -= player_dy;
        }
    }

    //
    // Find entity under mouse
    //
    var mouse_map_x = Math.floor(Mouse.x / world_scale / tilesize + player_x - Math.floor(view_width / 2));
    var mouse_map_y = Math.floor(Mouse.y / world_scale / tilesize + player_y - Math.floor(view_height / 2));

    // Check for entities on map
    var hovered_map = Entity.NONE;
    if (!out_of_view_bounds(mouse_map_x, mouse_map_y) && !out_of_map_bounds(mouse_map_x, mouse_map_y)) {
        hovered_map = Entity.at(mouse_map_x, mouse_map_y);
    }

    // Check for entities anywhere, map/inventory/equipment
    var hovered_anywhere = Entity.NONE;
    var hovered_anywhere_x: Int = 0;
    var hovered_anywhere_y: Int = 0;
    if (Entity.position.exists(hovered_map)) {
        // Hovering over map
        var pos = Entity.position[hovered_map];
        hovered_anywhere = hovered_map;
        hovered_anywhere_x = screen_x(pos.x);
        hovered_anywhere_y = screen_y(pos.y);
    } else {
        // Check if hovering over inventory or equipment
        var mouse_inventory_x = Math.floor((Mouse.x - ui_x) / world_scale / tilesize);
        var mouse_inventory_y = Math.floor((Mouse.y - inventory_y) / world_scale / tilesize);
        var mouse_equip_x = Math.floor((Mouse.x - ui_x) / world_scale / tilesize);
        var mouse_equip_y = Math.floor((Mouse.y - equipment_y) / world_scale / tilesize);

        function hovering_inventory(x, y) {
            return x >= 0 && y >= 0 && x < inventory_width && y < inventory_height;
        }
        function hovering_equipment(x, y) {
            return y == 0 && x >= 0 && x < equipment_width;
        }

        if (hovering_inventory(mouse_inventory_x, mouse_inventory_y)) {
            hovered_anywhere = inventory[mouse_inventory_x][mouse_inventory_y];
            hovered_anywhere_x = ui_x + mouse_inventory_x * tilesize * world_scale;
            hovered_anywhere_y = inventory_y + mouse_inventory_y * tilesize * world_scale;
        } else if (hovering_equipment(mouse_equip_x, mouse_equip_y)) {
            hovered_anywhere = switch (mouse_equip_x) {
                case 0: player_weapon;
                case 1: player_armor[ArmorType_Head];
                case 2: player_armor[ArmorType_Chest];
                case 3: player_armor[ArmorType_Legs];
                default: Entity.NONE;
            }
            hovered_anywhere_x = ui_x + mouse_equip_x * tilesize * world_scale;
            hovered_anywhere_y = equipment_y;
        }
    }

    //
    // Attack on left click
    //
    if (Mouse.left_click() && !player_acted && Entity.position.exists(hovered_map) && player_next_to(Entity.position[hovered_map]) && Entity.combat.exists(hovered_map)) {
        var defense_absorb_left = player_defense_absorb();

        var entity_combat = Entity.combat[hovered_map];

        var damage_taken = 0;
        var damage_absorbed = 0;

        // Player and mob attack at the same time
        // TODO: figure if mob should attack if player attack kills it this turn
        if (defense_absorb_left > 0) {
            defense_absorb_left -= entity_combat.attack;
            damage_absorbed += entity_combat.attack;

            if (defense_absorb_left < 0) {
                // Fix for negative absorb
                player_health += defense_absorb_left;
                damage_taken -= defense_absorb_left;
                damage_absorbed += defense_absorb_left;
            }
        } else {
            player_health -= entity_combat.attack;
            damage_taken += entity_combat.attack;
        }
        entity_combat.health -= player_attack();

        var target_name = 'noname';
        if (Entity.name.exists(hovered_map)) {
            target_name = Entity.name[hovered_map];
        }
        add_message('------------------------------');
        add_message('You attack $target_name.');
        add_message(entity_combat.message);
        if (damage_taken != 0) {
            add_message('You take ${damage_taken} damage from $target_name.');
        }
        if (damage_absorbed != 0) {
            add_message('Your armor absorbs ${damage_absorbed} damage.');
        }
        

        if (entity_combat.health <= 0) {
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

        if (entity_combat.health <= 0) {
            if (Entity.drop_item.exists(hovered_map) && Entity.position.exists(hovered_map)) {
                var drop_item = Entity.drop_item[hovered_map];
                var pos = Entity.position[hovered_map];
                if (Random.chance(drop_item.chance)) {
                    add_message('$target_name drops ${drop_item.type}.');
                    Entity.remove_position(hovered_map);
                    MakeEntity.item(pos.x, pos.y, drop_item.type);
                }
            }

            Entity.remove(hovered_map);
        }

        end_turn();
    }

    //
    // Render
    //

    // Tiles
    redraw_tile_canvas = true;
    if (redraw_tile_canvas) {
        Gfx.draw_to_image('tiles_canvas');
        Gfx.scale(1, 1, 0, 0);
        Gfx.clear_screen(Col.BLUE);
        var start_x = player_x - Math.floor(view_width / 2);
        var end_x = player_x + Math.ceil(view_width / 2);
        var start_y = player_y - Math.floor(view_height / 2);
        var end_y = player_y + Math.ceil(view_height / 2);
        for (x in start_x...end_x) {
            for (y in start_y...end_y) {
                if (!out_of_view_bounds(x, y) && !out_of_map_bounds(x, y)) {
                    Gfx.draw_tile(unscaled_screen_x(x), unscaled_screen_y(y), tiles[x][y]);
                }
            }
        }
        Gfx.draw_to_screen();

        redraw_tile_canvas = false;
    } else if (move_tile_canvas) {
        Gfx.draw_to_image('tiles_canvas');
        Gfx.scale(1, 1, 0, 0);
        Gfx.draw_image((-canvas_dx) * tilesize, (-canvas_dy) * tilesize, 'tiles_canvas');

        if (canvas_dx != 0) {
            // Draw first or last column
            var x = player_x - canvas_dx * Math.ceil(view_width / 2);
            var start_y = player_y - Math.floor(view_height / 2);
            var end_y = player_y + Math.ceil(view_height / 2);

            // Clear before old row
            var clear_x = if (canvas_dx < 0) {
                unscaled_screen_x(-1);
            } else {
                unscaled_screen_x(map_width);
            };
            Gfx.fill_box(clear_x, 0, tilesize, view_height * tilesize, Col.BLACK);

            for (y in start_y...end_y) {
                if (!out_of_map_bounds(x, y)) {
                    Gfx.draw_tile(unscaled_screen_x(x), unscaled_screen_y(y), tiles[x][y]);
                }
            }
        }
        if (canvas_dy != 0) {
            // Draw top bottom row
            var start_x = player_x - Math.floor(view_width / 2);
            var end_x = player_x + Math.ceil(view_width / 2);
            var y = player_y - canvas_dy * Math.floor(view_height / 2);

            // Clear before old row
            var clear_y  = if (canvas_dy < 0) {
                unscaled_screen_y(-1);
            } else {
                unscaled_screen_y(map_height);
            };
            Gfx.fill_box(0, clear_y, view_height * tilesize, tilesize, Col.BLACK);

            for (x in start_x...end_x) {
                if (!out_of_map_bounds(x, y)) {
                    Gfx.draw_tile(unscaled_screen_x(x), unscaled_screen_y(y), tiles[x][y]);
                }
            }
        }

        Gfx.draw_to_screen();

        canvas_dx = 0;
        canvas_dy = 0;
        move_tile_canvas = false;
    }

    Gfx.scale(world_scale, world_scale, 0, 0);
    Gfx.draw_image(0, 0, "tiles_canvas");

    // Entities
    Text.change_size(32);
    for (e in Entity.position.keys()) {
        var pos = Entity.position[e];
        if (!out_of_view_bounds(pos.x, pos.y)) {
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
        if (Entity.draw_tile.exists(player_armor[armor_type])) {
            armor_tile = Entity.draw_tile[player_armor[armor_type]];
        } else {
            armor_tile = switch (armor_type) {
                case ArmorType_Head: Tile.Head0;
                case ArmorType_Chest: Tile.Chest0;
                case ArmorType_Legs: Tile.Legs0;
            }
        }

        Gfx.draw_tile(screen_x(player_x), screen_y(player_y), armor_tile); 
    }
    if (Entity.draw_tile.exists(player_weapon)) {
        var weapon_tile = Entity.draw_tile[player_weapon];
        Gfx.draw_tile(screen_x(player_x) + 0.3 * tilesize * world_scale, screen_y(player_y), weapon_tile); 
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
    current_ui_x = ui_x;
    current_ui_y = player_stats_y;
    down_line('PLAYER');
    down_line('Health: ${player_health}/${player_health_max}');
    down_line('Attack: ${player_attack()}');
    down_line('Defense: ${player_defense()} (absorb ${player_defense_absorb()} damage per fight)');
    down_line('Copper: ${copper_count}');
    down_line('');

    // Equipment
    down_line('EQUIPMENT');
    var tile_screen_size = tilesize * world_scale;
    for (i in 0...equipment_width) {
        Gfx.draw_box(ui_x + i * tile_screen_size, equipment_y, tile_screen_size, tile_screen_size, Col.WHITE);
    }
    Gfx.scale(world_scale, world_scale, 0, 0);
    if (Entity.draw_tile.exists(player_weapon)) {
        var tile = Entity.draw_tile[player_weapon];
        Gfx.draw_tile(ui_x, equipment_y, tile);
    }
    var armor_i = 1;
    for (armor_type in Type.allEnums(ArmorType)) {
        if (Entity.draw_tile.exists(player_armor[armor_type])) {
            var tile = Entity.draw_tile[player_armor[armor_type]];
            Gfx.draw_tile(ui_x + armor_i * tile_screen_size, equipment_y, tile);
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
            Gfx.draw_box(ui_x + x * tile_screen_size, inventory_y + y * tile_screen_size, tile_screen_size, tile_screen_size, Col.WHITE);
        }
    }
    // Inventory entities
    Gfx.scale(world_scale, world_scale, 0, 0);
    for (x in 0...inventory_width) {
        for (y in 0...inventory_height) {
            if (Entity.draw_tile.exists(inventory[x][y]) && !Entity.position.exists(inventory[x][y])) {
                Gfx.draw_tile(ui_x + x * tilesize * world_scale, current_ui_y + y * tilesize * world_scale, Entity.draw_tile[inventory[x][y]]);
            }
        }
    }
    Gfx.scale(1, 1, 0, 0);

    //
    // Hovered entity tooltip
    //
    current_ui_x = hovered_anywhere_x + tilesize * world_scale;
    current_ui_y = hovered_anywhere_y;
    if (Entity.name.exists(hovered_anywhere)) {
        down_line('Id: ${hovered_anywhere}');
        down_line('Name: ${Entity.name[hovered_anywhere]}');
    }
    if (Entity.combat.exists(hovered_anywhere)) {
        var entity_combat = Entity.combat[hovered_anywhere];
        down_line('Health: ${entity_combat.health}');
        down_line('Attack: ${entity_combat.attack}');
    }
    if (Entity.description.exists(hovered_anywhere)) {
        down_line(Entity.description[hovered_anywhere]);
    }
    if (Entity.equipment.exists(hovered_anywhere)) {
        down_line('Equipment name: ${Entity.equipment[hovered_anywhere].name}');
    }
    if (Entity.weapon.exists(hovered_anywhere)) {
        down_line('Equipment attack: ${Entity.weapon[hovered_anywhere].attack}');
    }
    if (Entity.armor.exists(hovered_anywhere)) {
        down_line('Equipment defense: ${Entity.armor[hovered_anywhere].defense}');
    }

    //
    // Interact menu
    //
    // Set interact target on right click
    if (Mouse.right_click() && !player_acted) {
        interact_target = hovered_anywhere;
        interact_target_x = hovered_anywhere_x;
        interact_target_y = hovered_anywhere_y;
    }

    // Stop interaction if entity too far away
    if (Entity.position.exists(interact_target) && !player_next_to(Entity.position[interact_target])) {
        interact_target = Entity.NONE;
    }

    // Interaction buttons
    var done_interaction = false;
    GUI.x = interact_target_x + tilesize * world_scale;
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
    if (Entity.equipment.exists(interact_target) && Entity.position.exists(interact_target)) {
        // Can equip if is equipment and is on map
        if (GUI.auto_text_button('Equip')) {
            equip_entity(interact_target);

            done_interaction = true;
        }
    }
    if (Entity.item.exists(interact_target)) {
        if (Entity.position.exists(interact_target)) {
            // Can be picked up if on map
            if (GUI.auto_text_button('Pick up')) {
                pick_up_entity(interact_target);

                done_interaction = true;
            }
        } else {
            // Can be dropped up if not on map(in inventory)
            if (GUI.auto_text_button('Drop')) {
                drop_entity(interact_target);

                done_interaction = true;
            }
        }
    }

    if (done_interaction) {
        interact_target = Entity.NONE;
        end_turn();
    } else if (Mouse.left_click()) {
        // Clicked out of context menu
        interact_target = Entity.NONE;
    }

    //
    // Messages
    //
    current_ui_y = hovered_anywhere_y;
    if (message_history.length > message_history_length_max) {
        message_history.pop();
    }
    current_ui_x = ui_x;
    current_ui_y = message_history_y;
    for (message in message_history) {
        up_line(message);
    }

    if (in_funtown) {
        if (GUI.text_button(ui_x, 950, 'To world')) {
            in_funtown = false;
            player_x = previous_world_x;
            player_y = previous_world_y;
            redraw_tile_canvas = true;
        }
    } else {
        if (GUI.text_button(ui_x, 950, 'To funtown')) {
            in_funtown = true;
            previous_world_x = player_x;
            previous_world_y = player_y;
            player_x = funtown_x;
            player_y = funtown_y;
            redraw_tile_canvas = true;
        }
    }

    if (GUI.text_button(ui_x, 970, 'Toggle map')) {
        draw_map = !draw_map;
    }
    
    if (draw_map) {
        for (c in connections) {
            var width = c.x2 - c.x1;
            var height = c.y2 - c.y1;
            if (width == 0) {
                width = 1;
            }
            if (height == 0) {
                height = 1;
            }
            Gfx.draw_box(c.x1 * map_scale, c.y1 * map_scale, (width) * map_scale, (height) * map_scale, Col.BLUE);
        }
        for (r in rooms) {
            Gfx.draw_box(r.x * map_scale, r.y * map_scale, (r.width + 1) * map_scale, (r.height + 1) * map_scale, Col.WHITE);
        }

        Gfx.draw_box(player_x * map_scale, player_y * map_scale, map_scale, map_scale, Col.RED);
    }

    if (Input.pressed(Key.SPACE)) {
        rooms = GenerateWorld.generate_via_digging();
        connections = GenerateWorld.connect_rooms(rooms);
    }

    Text.display(0, 0, 'FPS: ${Gfx.render_fps()}');
}
}
