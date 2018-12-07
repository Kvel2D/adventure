
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

var player_x = 100;
var player_y = 100;
var player_health_max = 10;
var player_health = 10;
var player_attack = 1;
var copper_count = 0;
var player_armor: Map<ArmorType, Entity> = [
ArmorType_Head => null,
ArmorType_Chest => null,
ArmorType_Legs => null,
];

static inline var message_history_length_max = 20;
var message_history = new Array<String>();

static inline var message_history_y = 800;
static inline var player_stats_y = 100;
static inline var target_stats_y = 300;

var interact_target: Entity = null;
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
    Entity.make(108, 100, 'bear');
    Entity.make(105, 98, 'fountain');

    Entity.make(106, 100, 'copper');
    Entity.make_armor(107, 98, ArmorType_Head);
    Entity.make_armor(107, 97, ArmorType_Head);
    Entity.make_armor(108, 98, ArmorType_Chest);
    Entity.make_armor(108, 97, ArmorType_Chest);
    Entity.make_armor(109, 98, ArmorType_Legs);
    Entity.make_armor(109, 97, ArmorType_Legs);
}

function entity_picked_up(e: Entity): Bool {
    return Entity.picked_up.exists(e.id) && Entity.picked_up[e.id];
}

function get_free_map(): Vector<Vector<Bool>> {
    var free_map = Data.bool_2d_vector(map_width, map_height, true);
    // Entities
    for (e in Entity.all) {
        
        if (!entity_picked_up(e)) {
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

function out_of_bounds(x, y) {
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

function pick_up_entity(e: Entity) {
    if (e.type == 'copper') {
        copper_count += Entity.stacks[e.id];

        // Copper goes away after pick up
        Entity.all.remove(e);
    } else if (Entity.armor.exists(e.id)) {
        var armor = Entity.armor[e.id];

        var current_armor = player_armor[armor.type];
        if (current_armor != null) {
            trace('Current armor: ${Entity.armor[player_armor[armor.type].id].name}');
    
            var current_armor_armor = Entity.armor[current_armor.id];
            add_message('You take off ${current_armor_armor.name}');
            Entity.picked_up[current_armor.id] = false;
            current_armor.x = e.x;
            current_armor.y = e.y;

            trace('Current armor: ${Entity.armor[player_armor[armor.type].id].name}');

        }

        add_message('You put on ${armor.name}');

        player_armor[armor.type] = e;

            trace('Current armor: ${Entity.armor[player_armor[armor.type].id].name}');
        
        Entity.picked_up[e.id] = true;
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

    var mouse_x = Std.int((Mouse.x / world_scale) / tilesize + player_x - Math.floor(view_width / 2));
    var mouse_y = Std.int((Mouse.y / world_scale) / tilesize + player_y - Math.floor(view_height / 2));
    var hovered_entity = Entity.at(mouse_x, mouse_y);

    if (player_dx != 0 || player_dy != 0) {
        player_x += player_dx;
        player_y += player_dy;

        // Need to redraw tiles if player moved
        need_to_update_tiles_canvas = true;

        var free_map = get_free_map();
        if (free_map[player_x][player_y]) {
            interact_target = null;

            end_turn();
        } else {
            player_x -= player_dx;
            player_y -= player_dy;
        }
    } else if (hovered_entity != null && Math.dst2(mouse_x, mouse_y, player_x, player_y) <= 2) {
        if (Mouse.right_click()) {
            // Interact on right click
            interact_target = hovered_entity;
        } else if (Mouse.left_click() && Entity.combat.exists(hovered_entity.type)) {
            // Attack on left click

            var entity_combat = Entity.combat[hovered_entity.type];
            var entity_health = entity_combat.health;
            var entity_attack = entity_combat.attack;

            var damage_taken = 0;

            while (player_health > 0 && entity_health > 0) {
                // Simulate player and mob taking turns attacking
                entity_health -= player_attack;
                player_health -= entity_attack;
                damage_taken += entity_attack;
            }

            add_message('You attack ${hovered_entity.type}.');
            add_message(entity_combat.message);
            add_message('You take ${damage_taken} damage from ${hovered_entity.type}.');

            if (entity_health <= 0) {
                add_message('You slay ${hovered_entity.type}.');
            }

            if (player_health <= 0) {
                add_message('You died.');
            }

            if (entity_health <= 0) {
                Entity.all.remove(hovered_entity);
            }

            end_turn();
        }
    }

    if (message_history.length > message_history_length_max) {
        message_history.pop();
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
                if (!out_of_bounds(x, y)) {
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
        if (!out_of_bounds(e.x, e.y) && Entity.draw_char.exists(e.type) && !entity_picked_up(e)) {

            var draw_char = Entity.draw_char[e.type];

            var draw_char_color = Col.WHITE;
            if (Entity.draw_char_color.exists(e.type)) {
                draw_char_color = Entity.draw_char_color[e.type];
            }

            Text.display(screen_x(e.x), screen_y(e.y), draw_char, draw_char_color);
        }
    }

    // Player
    Gfx.draw_tile(screen_x(player_x), screen_y(player_y), Tile.Player); 

    //
    // Right-hand menu bar
    //
    Gfx.scale(1, 1, 0, 0);
    Text.change_size(12);

    var y: Float = 0;
    function down_line(text) {
        Text.display(1005, y, text);
        y += (Text.height() + 2);
    }
    function up_line(text) {
        Text.display(1005, y, text);
        y -= (Text.height() + 2);
    }

    // Player stats
    y = player_stats_y;
    down_line('PLAYER');
    down_line('Health: ${player_health}/${player_health_max}');
    down_line('Attack: ${player_attack}');
    down_line('Copper: ${copper_count}');
    down_line('Armor:');
    for (armor_type in Type.allEnums(ArmorType)) {
        var armor = player_armor[armor_type];
        if (armor == null) {
            down_line('$armor_type: none');
        } else {
            down_line('$armor_type: ${Entity.armor[armor.id].name}');
        }
    }
    // var head = player_armor[ArmorType_Head];
    // if (head == null) {
    //     down_line('Head: none');
    // } else {
    //     down_line('Head: ${Entity.armor[head.id].name}');
    // }
    // var chest = player_armor[ArmorType_Chest];
    // if (chest == null) {
    //     down_line('Chest: none');
    // } else {
    //     down_line('Chest: ${Entity.armor[chest.id].name}');
    // }
    // var legs = player_armor[ArmorType_Legs];
    // if (legs == null) {
    //     down_line('Chest: none');
    // } else {
    //     down_line('Chest: ${Entity.armor[legs.id].name}');
    // }


    // Hovered entity stats
    if (hovered_entity != null) {
        y = target_stats_y;
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
        if (Entity.armor.exists(hovered_entity.id)) {
            down_line('Armor name: ${Entity.armor[hovered_entity.id].name}');
        }
    }

    // Messages
    y = message_history_y;
    for (message in message_history) {
        up_line(message);
    }

    // Interact menu
    if (interact_target != null && !entity_picked_up(interact_target)) {
        GUI.x = screen_x(interact_target.x) + tilesize * world_scale;
        GUI.y = screen_y(interact_target.y) + tilesize * world_scale;

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

        if (Entity.pick_up.exists(interact_target.type)) {
            if (GUI.auto_text_button('Pick up')) {
                pick_up_entity(interact_target);

                done_interaction = true;
            }
        }

        if (done_interaction) {
            interact_target = null;
            done_interaction = false;
        }
    }

    Text.display(0, 0, 'FPS: ${Gfx.render_fps()}');
}
}
