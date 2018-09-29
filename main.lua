io.stdout:setvbuf('no')
WIDTH, HEIGHT = love.graphics.getDimensions()

SELECT_OUTLINE_COLOR     = { 244/255, 209/255, 66/255 }
NO_HP_COLOR              = { 70/255, 70/255, 70/255 }
HP_COLOR                 = { 4/255, 155/255, 32/255 }
HEALTH_BAR_OUTLINE_COLOR = { 20/255, 20/255, 20/255 }
PLAY_COLOR               = { 148/255, 183/255, 239/255 }
TIPS_COLOR               = { 26/255, 58/255, 26/255 }
ROAD_COLOR               = { 40/255, 40/255, 40/255 }
ROAD_OUTLINE_COLOR       = { 30/255, 30/255, 30/255 }
WORKER_COLOR             = { 163/255, 101/255, 155/255 }
WORKER_DEEP_COLOR        = { 119/255, 70/255, 113/255 }
SOLDIER_COLOR            = { 196/255, 58/255, 23/255 }
SOLDIER_DEEP_COLOR       = { 132/255, 31/255, 5/255 }
MONSTER_COLOR            = { 0/255, 0/255, 0/255 }
MONSTER_DEEP_COLOR       = { 0/255, 0/255, 0/255 }
PRODUCTION_GAUGE_COLOR   = { 79/255, 94/255, 209/255 }
FIGHT_GAUGE_COLOR        = { 206/255, 0/255, 0/255 }
TEXT_COLOR               = { 1, 1, 1 }
IRON_COLOR               = { 125/255, 134/255, 150/255 }
IRON_DEEP_COLOR          = { 80/255, 87/255, 96/255 }
LUMBER_COLOR             = { 153/255, 71/255, 0/255 }
LUMBER_DEEP_COLOR        = { 109/255, 47/255, 0/255 }
WEAPONS_COLOR            = { 84/255, 149/255, 255/255 }
WEAPONS_DEEP_COLOR       = { 49/255, 107/255, 198/255 }
TOWN_HALL_COLOR          = { 0/255, 153/255, 122/255 }
TOWN_HALL_DEEP_COLOR     = { 0/255, 112/255, 89/255 }
HOUSE_COLOR              = { 143/255, 55/255, 101/255 }
HOUSE_DEEP_COLOR         = { 112/255, 37/255, 65/255 }
BARRACK_COLOR            = { 117/255, 0/255, 0/255 }
BARRACK_DEEP_COLOR       = { 89/255, 0/255, 0/255 }

START_ANGLE          = -math.pi / 2
UNIT_RADIUS          = 7
ROAD_WIDTH           = 30
HEALTH_BAR_WIDTH     = 5
SELECT_OUTLINE_WIDTH = 2
UNIT_HEALTH_WIDTH    = 4
GAUGE_WIDTH          = 6

FIGHT_COUNTDOWN         = 4
PRODUCTION_COUNTDOWN    = 5
WAVES_COUNTDOWN         = 45
FLOATING_TEXT_COUNTDOWN = 1.5

ATTACKS_DAMAGE = 10
WAVES = { 5, 6, 8 }

BUILDINGS = {
  town_hall  = { max_hp = 400, radius = 60, deep_color = TOWN_HALL_DEEP_COLOR, color = TOWN_HALL_COLOR },
  mine       = { max_hp = 100, radius = 40, deep_color = IRON_DEEP_COLOR, color = IRON_COLOR },
  sawmill    = { max_hp = 100, radius = 40, deep_color = LUMBER_DEEP_COLOR, color = LUMBER_COLOR },
  house      = { max_hp = 80,  radius = 40, deep_color = HOUSE_DEEP_COLOR, color = HOUSE_COLOR },
  barrack    = { max_hp = 300, radius = 50, deep_color = BARRACK_DEEP_COLOR, color = BARRACK_COLOR },
  blacksmith = { max_hp = 150, radius = 40, deep_color = WEAPONS_DEEP_COLOR, color = WEAPONS_COLOR }
}

TIPS_COUNTDOWN = 10
TIPS = {
  "Envoyez un travailleur à la caserne (rouge) et appuyez sur ESPACE pour en faire un soldat. Cela coûte 1 arme.",
  "Envoyez un soldat à la maison (rose) et appuyez sur ESPACE pour en faire un travailleur. C'est gratuit.",
  "Cliquer gauche sur un péon ou un soldat pour le sélectionner, puis envoyez-le ailleurs avec un clic droit.",
  "Préparez-vous aux invasions en entraînant suffisemment de soldats !"
}


function love.conf(t)
	t.console = true
end


function love.load()
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  love.window.setTitle("Spherium")

  SMALL_FONT = love.graphics.setNewFont(12)
  BIG_FONT   = love.graphics.newFont(72)

  HAND_CURSOR  = love.mouse.getSystemCursor("hand")
  ARROW_CURSOR = love.mouse.getSystemCursor("arrow")

  screen = "main_menu"
end



function love.update(deltatime)
  if screen == "game" then
    seconds_since_last_click = seconds_since_last_click + deltatime
    rotate_tips(deltatime)
    change_waves(deltatime)
    update_floating_texts(deltatime)
    update_cursor()

    for _, building in pairs(buildings) do
      move_workers(building, deltatime)
      move_fighters(building, deltatime)
      run_production(building, deltatime)
      keep_fighting(building, deltatime)
    end

    for _, movement in pairs(movements) do
      keep_walking(movement, deltatime)
    end
  end
end


function love.draw()
  love.graphics.setLineStyle("smooth")

  if screen == "main_menu" then
    draw_main_menu()

  elseif screen == "game" or screen == "victory" or screen == "defeat" or screen == "game_menu" then
    for _, road in pairs(roads) do
      draw_road(road)
    end

    for _, building in pairs(buildings) do
      draw_outline_road(building)
      draw_health_bar(building)
      draw_building(building)
      draw_production_gauge(building)
      draw_fight_gauge(building)
      draw_workers(building)
      draw_soldiers(building)
      draw_monsters(building)

      -- Smooth outlines.
      love.graphics.setLineWidth(1)
      love.graphics.setColor(BUILDINGS[building.type].deep_color)
      love.graphics.circle("line", building.x, building.y, BUILDINGS[building.type].radius)
      love.graphics.setColor(HEALTH_BAR_OUTLINE_COLOR)
      love.graphics.circle("line", building.x, building.y, BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH)
      love.graphics.setColor(ROAD_OUTLINE_COLOR)
      love.graphics.circle("line", building.x, building.y, BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH)
    end

    for _, worker_movement in pairs(movements) do
      draw_moving_unit(worker_movement)
    end

    if mode == "build" then
      draw_building_ghost(building_to_build)
    end

    draw_resources()
    draw_tips()
    draw_waves_countdown()
    draw_floating_texts()
  end

  if screen == "defeat" then
    draw_defeat_overlay()

  elseif screen == "victory" then
    draw_victory_overlay()
  end
end


function draw_victory_overlay()
  love.graphics.setColor(0, 0, 0, .8)
  love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)

  local text = "VICTOIRE !"
  local width = BIG_FONT:getWidth(text)
  love.graphics.setFont(BIG_FONT)
  love.graphics.setColor(0, 1, 0)
  love.graphics.print(text, WIDTH/2 - width/2, HEIGHT * .4)

  local text = "Appuyez sur ESPACE pour retourner au menu"
  local width = SMALL_FONT:getWidth(text)
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(text, WIDTH/2 - width/2, HEIGHT * .6)
end


function draw_defeat_overlay()
  love.graphics.setColor(0, 0, 0, .8)
  love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)

  local width = BIG_FONT:getWidth("YOU DIED")
  love.graphics.setFont(BIG_FONT)
  love.graphics.setColor(1, 0, 0)
  love.graphics.print("YOU DIED", WIDTH/2 - width/2, HEIGHT * .4)

  local text = "Appuyez sur ESPACE pour retourner au menu"
  local width = SMALL_FONT:getWidth(text)
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(text, WIDTH/2 - width/2, HEIGHT * .6)
end


function love.keypressed(key)
  if key == "escape" and screen == "main_menu" then
    love.event.quit()

  elseif key == "escape" then
    screen = "main_menu"

  elseif key == "space" and screen == "main_menu" then
    start_fresh_game()

  elseif key == "space" and screen == "game" then
    transform_unit(selected_unit)

  elseif key == "space" and (screen == "defeat" or screen == "victory") then
    screen = "main_menu"

--  elseif key == "b" then
--    if mode == "build" then mode = "play" else mode = "build" end

--  elseif key == "m" and mode == "build" then
--      building_to_build = "mine"

--  elseif key == "s" and mode == "build" then
--      building_to_build = "sawmill"

--  elseif key == "r" then
--    if mode == "road" then mode = "play" else mode = "road" end
  end
end


function love.mousepressed(x, y, button)
  if screen ~= "game" then return end

  local is_double_click = seconds_since_last_click < .4
  seconds_since_last_click = 0

  if mode == "build" and building_to_build then
    build(building_to_build, x, y)

  else
    if button == 1 then
      selected_unit = get_clicked_unit(x, y)
      local selected_building = get_clicked_building(x, y)

      if selected_building and not selected_unit then
        select_unit(selected_building, x, y)
      end

    elseif button == 2 then
      local target_building = get_clicked_building(x, y)
      send_unit(selected_unit, target_building)
    end
  end
end


function draw_main_menu()
  local title = "Spherium"
  local title_width = BIG_FONT:getWidth(title)
  love.graphics.setFont(BIG_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(title, WIDTH * .1, HEIGHT * .2)

  local text = "Appuyez sur ESPACE pour commencer"
  local width = SMALL_FONT:getWidth(text)
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(text, WIDTH * .1 + title_width - width, HEIGHT * .35)

  local text = "Survivez aux vagues d'envahisseurs.\n\nAffectez vos travailleurs aux sites de production ou entraînez-les au combat et déployez-les dans votre ville pour la défendre..."
  local width = SMALL_FONT:getWidth(text)
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.printf(text, WIDTH * .1 + title_width + 20, HEIGHT * .35, 300)

  local text = "Pour sélectionner une unité, cliquez gauche dessus.\n\nPour l'envoyer vers un autre bâtiment, cliquez droit sur ce bâtiment.\n\nPour transformer un travailleur en soldat, envoyez-le sur la caserne (rouge) et appuyez sur ESPACE.\n\nPour transformer un soldat en travailleur, envoyez-le sur la maison (rose) et appuyez sur ESPACE.\n\nPour sélectionner rapidement un travailleur, cliquez dans l'anneau intérieur du bâtiment.\n\nPour sélectionner rapidement un soldat, cliquez dans l'anneau extérieur du bâtiment."
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(.6, .6, .6)
  love.graphics.printf(text, WIDTH * .1, HEIGHT * .65, 800)
end


function draw_floating_texts()
  for _, text in pairs(floating_texts) do
    local alpha = text.countdown > .8 and 1 or text.countdown

    love.graphics.setFont(SMALL_FONT)
    love.graphics.setColor(text.color[1], text.color[2], text.color[3], alpha)
    love.graphics.print(text.content, text.x, text.y)
  end
end


function update_cursor()
  local x, y = love.mouse.getPosition()

  for _, building in pairs(buildings) do
    local distance = distance_between(x, y, building.x, building.y)
    if distance <= inner_radius(building.type) and count(building.workers) > 0 then
      return love.mouse.setCursor(HAND_CURSOR)

    elseif distance >= inner_radius(building.type) and distance <= full_radius(building.type) and count(building.soldiers) > 0 then
      return love.mouse.setCursor(HAND_CURSOR)

    else
      love.mouse.setCursor(ARROW_CURSOR)
    end
  end
end


function update_floating_texts(deltatime)
  for _, text in pairs(floating_texts) do
    text.countdown = text.countdown - deltatime
    text.y = text.y - 20*deltatime

    if text.countdown <= 0 then
      floating_texts[text.id] = nil
    end
  end
end


function start_fresh_game()
  movements      = {}
  roads          = {}
  resources      = { iron = 5, lumber = 5, weapons = 2 }
  buildings      = {}
  floating_texts = {}
  barrack        = nil

  id = 0

  mode   = "play"
  screen = "game"

  building_to_build = nil
  selected_building = nil
  selected_unit     = nil

  seconds_since_last_click = 10

  current_tip    = 1
  tips_countdown = TIPS_COUNTDOWN

  waves_countdown       = WAVES_COUNTDOWN
  coming_wave           = 1
  living_monsters_count = 0

  town_hall  = build("town_hall",  WIDTH * .5,  HEIGHT * .6)
  mine       = build("mine",       WIDTH * .8,  HEIGHT * .8)
  sawmill    = build("sawmill",    WIDTH * .13, HEIGHT * .75)
  house      = build("house",      WIDTH * .2,  HEIGHT * .4)
  barrack    = build("barrack",    WIDTH * .45, HEIGHT * .25)
  blacksmith = build("blacksmith", WIDTH * .85, HEIGHT * .3)

  build_road(town_hall.id, mine.id)
  build_road(town_hall.id, sawmill.id)
  build_road(town_hall.id, house.id)
  build_road(town_hall.id, barrack.id)
  build_road(house.id, barrack.id)
  build_road(barrack.id, blacksmith.id)
  build_road(mine.id, blacksmith.id)

  spawn_worker(mine.id)
  spawn_worker(sawmill.id)
  spawn_worker(sawmill.id)
  spawn_worker(house.id)
  spawn_worker(house.id)
  spawn_worker(blacksmith.id)

  spawn_soldier(town_hall.id)
end


function add_floating_text(content, x, y, color)
  text_id = uuid("text")
  floating_texts[text_id] = {
    id = text_id,
    content = content,
    x = x,
    y = y, countdown = FLOATING_TEXT_COUNTDOWN,
    color = color or TEXT_COLOR
  }
end


function add_floating_text_above_building(content, building, offset, color)
  local radius = full_radius(building.type)
  local x = building.x - radius/2
  local y = building.y - radius
  add_floating_text(content, x, y + offset, color)
end


function change_waves(deltatime)
  if waves_countdown then
    waves_countdown = waves_countdown - deltatime

    if waves_countdown <= 0 then
      spawn_wave(WAVES[coming_wave])

      if coming_wave < #WAVES then
        coming_wave = coming_wave + 1
        waves_countdown = WAVES_COUNTDOWN

      else
        coming_wave = nil
        waves_countdown = nil
      end
    end
  end
end


function draw_waves_countdown()
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)

  if waves_countdown == nil then
    if living_monsters_count == 1 then
      love.graphics.print("Exterminez le dernier envahisseur.", 10, 10)
    else
      love.graphics.print("Exterminez les " .. tostring(living_monsters_count) .. " envahisseurs restants !", 10, 10)
    end
  else
    love.graphics.setFont(SMALL_FONT)
    love.graphics.print("La vague " .. tostring(coming_wave) .. " sur " .. tostring(#WAVES) .." attaquera dans " .. tostring(math.ceil(waves_countdown)) .. " secondes...", 10, 10)
  end
end


function select_unit(building, x, y)
  local distance = distance_between(x, y, building.x, building.y)
  if distance <= inner_radius(building.type) then
      for _, worker in pairs(building.workers) do
        selected_unit = worker
        return worker
      end
  else
    for _, soldier in pairs(building.soldiers) do
      selected_unit = soldier
      return soldier
    end
  end
end


function draw_building(building)
  love.graphics.setColor(BUILDINGS[building.type].color)
  love.graphics.circle("fill", building.x, building.y, BUILDINGS[building.type].radius)
end


function draw_tips()
  love.graphics.setColor(TIPS_COLOR)
  love.graphics.rectangle("fill", 5, HEIGHT - 35, WIDTH - 10, 30)
  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print("Astuce " .. tostring(current_tip) .. "/" .. tostring(#TIPS) .. " : " .. tostring(TIPS[current_tip]), 20, HEIGHT - 27)
end


function draw_production_gauge(building)
  if building.production_countdown == nil then return end

  local ratio = building.production_countdown/PRODUCTION_COUNTDOWN
  local start_angle = START_ANGLE + math.pi * ratio
  local end_angle = START_ANGLE + math.pi
  love.graphics.setColor(PRODUCTION_GAUGE_COLOR)
  love.graphics.setLineWidth(GAUGE_WIDTH)
  love.graphics.arc("line", "open", building.x, building.y, BUILDINGS[building.type].radius - GAUGE_WIDTH/2, start_angle, end_angle)
end


function draw_fight_gauge(building)
  if building.fight_countdown == nil then return end
  local ratio = building.fight_countdown/FIGHT_COUNTDOWN
  local start_angle = math.pi/2
  local end_angle = start_angle + math.pi * (1 - ratio)
  love.graphics.setColor(FIGHT_GAUGE_COLOR)
  love.graphics.setLineWidth(GAUGE_WIDTH)
  love.graphics.arc("line", "open", building.x, building.y, BUILDINGS[building.type].radius - GAUGE_WIDTH/2, start_angle, end_angle)
end


function draw_building_ghost(type)
  if building_to_build == nil then return end
  if building_to_build == "road" then return end

  love.graphics.setColor(BUILDINGS[type].color)
  local x, y = love.mouse.getPosition()
  love.graphics.circle("fill", x, y, BUILDINGS[type].radius)
end


function draw_outline_road(building)
  love.graphics.setColor(ROAD_COLOR)
  love.graphics.circle("fill", building.x, building.y, BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH)
end


function count(hash_table)
  local i = 0
  for _, _ in pairs(hash_table) do
    i = i + 1
  end
  return i
end


function unit_outline_color(unit)
  if unit.type == "worker" and unit.building_id then
    return BUILDINGS[buildings[unit.building_id].type].deep_color
  else
    return ROAD_OUTLINE_COLOR
  end
end


function unit_color(unit)
  if unit.type == "worker" then
    return WORKER_COLOR
  elseif unit.type == "soldier" then
    return SOLDIER_COLOR
  elseif unit.type == "monster" then
    return MONSTER_COLOR
  end
end


function unit_deep_color(unit)
  if unit.type == "worker" then
    return WORKER_DEEP_COLOR
  elseif unit.type == "soldier" then
    return SOLDIER_DEEP_COLOR
  elseif unit.type == "monster" then
    return MONSTER_DEEP_COLOR
  end
end


function draw_workers(building)
  for _, worker in pairs(building.workers) do
    draw_worker(worker, worker.x, worker.y)
  end
end


function draw_unit(unit, x, y)
  love.graphics.setColor(NO_HP_COLOR)
  love.graphics.circle("fill", x, y, UNIT_RADIUS + UNIT_HEALTH_WIDTH)

  local health_ratio = unit.hp / unit.max_hp
  local end_angle = START_ANGLE - math.pi * 2 * health_ratio
  love.graphics.setColor(HP_COLOR)
  love.graphics.arc("fill", "pie", x, y, UNIT_RADIUS + UNIT_HEALTH_WIDTH, START_ANGLE, end_angle)

  love.graphics.setColor(unit_color(unit))
  love.graphics.circle("fill", x, y, UNIT_RADIUS)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(unit_deep_color(unit))
  love.graphics.circle("line", x, y, UNIT_RADIUS)
  love.graphics.setColor(unit_outline_color(unit))
  love.graphics.circle("line", x, y, UNIT_RADIUS + UNIT_HEALTH_WIDTH)

  if selected_unit and selected_unit.id == unit.id then
    love.graphics.setColor(SELECT_OUTLINE_COLOR)
    love.graphics.circle("line", x, y, UNIT_RADIUS + UNIT_HEALTH_WIDTH + SELECT_OUTLINE_WIDTH)
  end
end


function draw_worker(worker, x, y)
  draw_unit(worker, x, y)
end


function draw_soldiers(building)
  for _, soldier in pairs(building.soldiers) do
    draw_soldier(soldier, soldier.x, soldier.y)
  end
end


function draw_soldier(soldier, x, y)
  draw_unit(soldier, x, y)
end



function draw_monsters(building)
  for _, monster in pairs(building.monsters) do
    draw_monster(monster, monster.x, monster.y)
  end
end


function draw_monster(monster, x, y)
  draw_unit(monster, x, y)
end



function draw_health_bar(building)
  local health_ratio = building.hp / BUILDINGS[building.type].max_hp
  local end_angle = START_ANGLE - math.pi * 2 * health_ratio

  love.graphics.setColor(NO_HP_COLOR)
  love.graphics.circle("fill", building.x, building.y, BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH)

  love.graphics.setColor(HP_COLOR)
  love.graphics.arc("fill", "pie", building.x, building.y, BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH, START_ANGLE, end_angle)
end


function draw_road(road)
  local from = buildings[road.from_id]
  local to = buildings[road.to_id]
  love.graphics.setColor(ROAD_COLOR)
  love.graphics.setLineWidth(ROAD_WIDTH)
  love.graphics.line(from.x, from.y, to.x, to.y)
end


function draw_moving_unit(movement)
  local from = buildings[movement.from_id]
  local to = buildings[movement.to_id]
  local angle = math.atan2(to.y - from.y, to.x - from.x)
  local x = from.x + movement.progression * math.cos(angle)
  local y = from.y + movement.progression * math.sin(angle)

  draw_unit(movement.unit, x, y)
end


RESOURCE_WIDTH = 40
RESOURCE_PADDING = 25
RESOURCES_WIDTH = 3 * RESOURCE_WIDTH + 2 * RESOURCE_PADDING
RESOURCE_SIDE = RESOURCE_WIDTH/2
RESOURCE_TEXT_MARGIN = RESOURCE_SIDE + 5

function draw_resources()
  local x =  WIDTH/2 - RESOURCES_WIDTH/2
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", x, 10, RESOURCES_WIDTH, 20)

  love.graphics.setColor(BUILDINGS["mine"].color)
  love.graphics.rectangle("fill", x, 10, 20, 20)

  love.graphics.setColor(BUILDINGS["sawmill"].color)
  love.graphics.rectangle("fill", x + RESOURCE_WIDTH + RESOURCE_PADDING, 10, 20, 20)

  love.graphics.setColor(BUILDINGS["blacksmith"].color)
  love.graphics.rectangle("fill", x + RESOURCE_WIDTH * 2 + RESOURCE_PADDING * 2, 10, 20, 20)

  love.graphics.setFont(SMALL_FONT)
  love.graphics.setColor(TEXT_COLOR)
  love.graphics.print(tostring(resources.iron), x + RESOURCE_TEXT_MARGIN, 12)
  love.graphics.print(tostring(resources.lumber), x + RESOURCE_WIDTH + RESOURCE_PADDING + RESOURCE_TEXT_MARGIN, 12)
  love.graphics.print(tostring(resources.weapons), x + RESOURCE_WIDTH * 2 + RESOURCE_PADDING * 2 + RESOURCE_TEXT_MARGIN, 12)
end


function spend(quantity, resource)
  resources[resource] = resources[resource] - quantity
end


function store(quantity, resource)
  resources[resource] = resources[resource] + quantity
end


function transform_unit(unit)
  if unit and unit.type == "soldier"
    and buildings[unit.building_id] and buildings[unit.building_id].type == "house" then
    convert_soldier_into_worker(unit)
    add_floating_text_above_building("-1 soldat", buildings[unit.building_id], 0, SOLDIER_COLOR)
    add_floating_text_above_building("+1 péon", buildings[unit.building_id], -15, WORKER_COLOR)

  elseif unit and unit.type == "worker"
    and buildings[unit.building_id] and buildings[unit.building_id].type == "barrack"
    and resources["weapons"] > 0 then
    convert_worker_into_soldier(unit)
    spend(1, "weapons")
    add_floating_text_above_building("-1 péon", buildings[unit.building_id], 0, WORKER_COLOR)
    add_floating_text_above_building("-1 arme", buildings[unit.building_id], -15, WEAPONS_COLOR)
    add_floating_text_above_building("+1 soldat", buildings[unit.building_id], -30, SOLDIER_COLOR)
  end
end


function move_workers(building, deltatime)
  building.workers_angle = building.workers_angle - math.pi / 500
  local angle_between_workers = 2 * math.pi / count(building.workers)
  local i = 1
  for _, worker in pairs(building.workers) do
    local angle = START_ANGLE + angle_between_workers * i + building.workers_angle
    worker.x = building.x + (BUILDINGS[building.type].radius * .5) * math.sin(angle)
    worker.y = building.y + (BUILDINGS[building.type].radius * .5) * math.cos(angle)
    i = i + 1
  end
end


function move_fighters(building, deltatime)
  building.fighters_angle = building.fighters_angle - math.pi / 400

  local angle_between_soldiers = 2 * math.pi / (count(building.soldiers) + count(building.monsters))
  local i = 1

  for _, soldier in pairs(building.soldiers) do
    local angle = START_ANGLE + angle_between_soldiers * i + building.fighters_angle
    soldier.x = building.x + (BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH/2) * math.sin(angle)
    soldier.y = building.y + (BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH/2) * math.cos(angle)
    i = i + 1
  end

  for _, monster in pairs(building.monsters) do
    local angle = START_ANGLE + angle_between_soldiers * i + building.fighters_angle
    monster.x = building.x + (BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH/2) * math.sin(angle)
    monster.y = building.y + (BUILDINGS[building.type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH/2) * math.cos(angle)
    i = i + 1
  end
end


function build(type, x, y)
  local building_id = uuid(type)
  buildings[building_id] = {
    type           = type,
    id             = building_id,
    x              = x,
    y              = y,
    hp             = BUILDINGS[type].max_hp,
    workers        = {},
    soldiers       = {},
    monsters       = {},
    workers_angle  = 2 * math.pi * math.random(),
    fighters_angle = 2 * math.pi * math.random()
  }
  return buildings[building_id]
end


function build_road(from_id, to_id)
  if road_between(from_id, to_id) then return end
  local road_id = uuid("road")
  roads[road_id] = { id = road_id, from_id = from_id, to_id = to_id }
end


function run_production(building, deltatime)
  if building.hp <= 0 then return end
  local workers_count = count(building.workers)

  -- Building producing from void.
  if building.type == "mine" or building.type == "sawmill" then
    local number_bonus = math.min(workers_count - 1, 3)

    if workers_count > 0 then
      if building.production_countdown == nil then -- Start production!
        building.production_countdown = PRODUCTION_COUNTDOWN - number_bonus
      else
        building.production_countdown = (building.production_countdown or PRODUCTION_COUNTDOWN) - deltatime

        if building.production_countdown <= 0 then -- Start new production!
          building.production_countdown = PRODUCTION_COUNTDOWN - number_bonus
          produce(building)
        end
      end
    else
      building.production_countdown = nil
    end

  -- Building producing from primary resources.
  elseif building.type == "blacksmith" then
    local number_bonus = math.min(workers_count - 1, 3)

    if workers_count > 0 and resources["iron"] >= 2 and resources["lumber"] >= 1 then
      if building.production_countdown == nil then -- Start production!
        building.production_countdown = PRODUCTION_COUNTDOWN - number_bonus
        spend(2, "iron")
        spend(1, "lumber")
        add_floating_text_above_building("-2 fer", building, 0, IRON_COLOR)
        add_floating_text_above_building("-1 bois", building, -15, LUMBER_COLOR)
      else
        building.production_countdown = (building.production_countdown or PRODUCTION_COUNTDOWN) - deltatime

        if building.production_countdown <= 0 then -- Start new production!
          produce(building)
          building.production_countdown = PRODUCTION_COUNTDOWN - number_bonus
          spend(2, "iron")
          spend(1, "lumber")
          add_floating_text_above_building("-2 fer", building, -15, IRON_COLOR)
          add_floating_text_above_building("-1 bois", building, -30, LUMBER_COLOR)
        end
      end
    else
      building.production_countdown = nil
    end

  -- Make babies!
  elseif building.type == "house" then
    if workers_count == 2 then
      building.production_countdown = (building.production_countdown or PRODUCTION_COUNTDOWN) - deltatime

      if building.production_countdown <= 0 then
        building.production_countdown = PRODUCTION_COUNTDOWN
        worker = spawn_worker(building.id)
        send_unit(worker, barrack)
        add_floating_text_above_building("+1 péon", building, 0, WORKER_COLOR)
      end
    else
      building.production_countdown = PRODUCTION_COUNTDOWN
    end
  end
end


function keep_fighting(building, deltatime)
  monsters_count = count(building.monsters)

  if monsters_count > 0 and building.hp == 0 then
    attack_another_building(building)
  elseif monsters_count > 0 and building.hp > 0 then
    if building.fight_countdown == nil then -- Start the fight!
        building.fight_countdown = FIGHT_COUNTDOWN
      else
        building.fight_countdown = (building.fight_countdown or FIGHT_COUNTDOWN) - deltatime

        if building.fight_countdown <= 0 then -- Start new production!
          fight(building)
          building.fight_countdown = FIGHT_COUNTDOWN
        end
      end
  else
    building.fight_countdown = nil
  end
end


function attack_another_building(building)
  local targets = get_neighbours(building)

  for _, monster in pairs(building.monsters) do
    local target = targets[math.random(1, #targets)]
    send_unit(monster, target)
  end
end


function get_neighbours(building)
  local neighbours = {}
  for _, road in pairs(roads) do
    if building.id == road.from_id then
      table.insert(neighbours, buildings[road.to_id])
    elseif building.id == road.to_id then
      table.insert(neighbours, buildings[road.from_id])
    end
  end
  return neighbours
end


function keep_walking(movement, deltatime)
  movement.progression = math.min(movement.distance, movement.progression + 3)
  if movement.progression == movement.distance then
    unit_arrived(movement)
  end
end


function produce(building)
  if building.type == "mine" then
    store(3, "iron")
    add_floating_text_above_building("+3 fer", building, 0, IRON_COLOR)

  elseif building.type == "sawmill" then
    store(1, "lumber")
    add_floating_text_above_building("+1 bois", building, 0, LUMBER_COLOR)

  elseif building.type == "blacksmith" then
    store(1, "weapons")
    add_floating_text_above_building("+1 arme", building, 0, WEAPONS_COLOR)
  end
end


-- Every monster hits a living soldier, or a living worker, or the building.
-- Then every soldier (even fatally wounded one) hits a living monster.
-- Then all deads are removed.
function fight(building)
  for _, monster in pairs(building.monsters) do
    local target = first_living_unit(building.soldiers) or first_living_unit(building.workers) or building
    if target then target.hp = target.hp - ATTACKS_DAMAGE end
  end

  for _, soldier in pairs(building.soldiers) do
    local target = first_living_unit(building.monsters)
    if target then target.hp = target.hp - ATTACKS_DAMAGE end
  end

  for _, monster in pairs(building.monsters) do bury(building, monster) end
  for _, soldier in pairs(building.soldiers) do bury(building, soldier) end
  for _, worker in pairs(building.workers) do bury(building, worker) end

  destroy(building)
end


function first_living_unit(units)
  for _, unit in pairs(units) do
    if unit.hp > 0 then return unit end
  end
end


function destroy(building)
  if building.hp > 0 then return end
  building.hp = 0

  check_defeat_conditions()
end


function check_defeat_conditions()
  if #living_buildings() == 0 then
    screen = "defeat"
  end
end


function check_victory_conditions()
  if coming_wave == nil and living_monsters_count == 0 then
    screen = "victory"
  end
end


function living_buildings()
  local living_buildings = {}
  for _, building in pairs(buildings) do
    if building.hp > 0 then
      table.insert(living_buildings, building)
    end
  end
  return living_buildings
end


function bury(building, unit)
  if unit.hp > 0 then return end

  if unit.type == "worker" then
    building.workers[unit.id] = nil
  elseif unit.type == "soldier" then
    building.soldiers[unit.id] = nil
  elseif unit.type == "monster" then
    building.monsters[unit.id] = nil
    living_monsters_count = living_monsters_count - 1
    check_victory_conditions()
  end
end


function spawn_worker(building_id)
  local unit_id = uuid("unit")
  buildings[building_id].workers[unit_id] = { type = "worker", hp = 30, max_hp = 30, x = 0, y = 0, id = unit_id, building_id = building_id }
  return buildings[building_id].workers[unit_id]
end


function spawn_monster(building_id)
  local unit_id = uuid("monster")
  buildings[building_id].monsters[unit_id] = { type = "monster", hp = 30, max_hp = 30, x = 0, y = 0, id = unit_id, building_id = building_id }
  return buildings[building_id].monsters[unit_id]
end


function spawn_soldier(building_id)
  local unit_id = uuid("unit")
  buildings[building_id].soldiers[unit_id] = { type = "soldier", hp = 30, max_hp = 30, x = 0, y = 0, id = unit_id, building_id = building_id }
  return buildings[building_id].soldiers[unit_id]
end


function get_clicked_building(x, y)
  for _, building in pairs(buildings) do
    local distance = distance_between(x, y, building.x, building.y)
    if distance <= full_radius(building.type) then
      return building
    end
  end
end


function get_clicked_unit(x, y)
  local building = get_clicked_building(x, y)
  if building then
    for _, worker in pairs(building.workers) do
      local distance = distance_between(x, y, worker.x, worker.y)
      if distance <= UNIT_RADIUS then
        return worker
      end
    end

    for _, soldier in pairs(building.soldiers) do
      local distance = distance_between(x, y, soldier.x, soldier.y)
      if distance <= UNIT_RADIUS then return soldier end
    end
  end
end


function full_radius(building_type)
  return BUILDINGS[building_type].radius + HEALTH_BAR_WIDTH + ROAD_WIDTH
end


function inner_radius(building_type)
  return BUILDINGS[building_type].radius + HEALTH_BAR_WIDTH
end


function distance_between(x1, y1, x2, y2)
  return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end


function unit_arrived(movement)
  local destination = buildings[movement.to_id]
  movement.unit.building_id = movement.to_id

  if movement.unit.type == "soldier" then
    buildings[movement.to_id].soldiers[movement.unit.id] = movement.unit
  elseif movement.unit.type == "worker" then
    buildings[movement.to_id].workers[movement.unit.id] = movement.unit
  elseif movement.unit.type == "monster" then
    buildings[movement.to_id].monsters[movement.unit.id] = movement.unit
  end

  movements[movement.id] = nil
end


function send_unit(unit, to)
  if not unit then return end
  if not to then return end
  if not unit.building_id then return end -- Do not send moving units.
  if unit.building_id == to.id then return end
  if not road_between(unit.building_id, to.id) then return end

  local from        = buildings[unit.building_id]
  local distance    = distance_between(from.x, from.y, to.x, to.y)
  local movement_id = uuid("movement")
  unit.building_id  = nil

  if unit.type == "worker" then
    from.workers[unit.id] = nil
  elseif unit.type == "soldier" then
    from.soldiers[unit.id] = nil
  elseif unit.type == "monster" then
    from.monsters[unit.id] = nil
  end

  movements[movement_id] = { id = movement_id, unit = unit, from_id = from.id, to_id = to.id, progression = 0, distance = distance }
  return movements[movement_id]
end


function convert_soldier_into_worker(soldier)
  soldier.type = "worker"
  soldier.hp = soldier.max_hp
  buildings[soldier.building_id].soldiers[soldier.id] = nil
  buildings[soldier.building_id].workers[soldier.id] = soldier
end


function convert_worker_into_soldier(worker)
  worker.type = "soldier"
  worker.hp = worker.max_hp
  buildings[worker.building_id].workers[worker.id] = nil
  buildings[worker.building_id].soldiers[worker.id] = worker

end


function road_between(from_id, to_id)
  for _, road in pairs(roads) do
    if road.from_id == from_id and road.to_id == to_id
    or road.from_id == to_id and road.to_id == from_id
    then return road end
  end
end


function spawn_wave(monsters_count)
  living_monsters_count = living_monsters_count + monsters_count

  local targets = {}
  for _, building in pairs(buildings) do
    table.insert(targets, building)
  end

  for i = 1, monsters_count do
    local building = targets[math.random(1, #targets)]
    spawn_monster(building.id)
  end
end



function rotate_tips(deltatime)
  tips_countdown = tips_countdown - deltatime

  if tips_countdown <= 0 then
    current_tip    = (current_tip % #TIPS) + 1
    tips_countdown = TIPS_COUNTDOWN
  end
end


function uuid(prefix)
  id = id + 1
  return prefix .. " " .. tostring(id)
end
