-- Librarian
--
-- hold btn 1 to update lib
--

local UI = require "ui"
local p = 0
local main_menu = true
local script_menu = false
local script = 0

 links = {}
links.topics = {}
links.names = {}
links.git = {}
links.descr = {}
pos_x = 0

local function exist(scr)
  if util.file_exists(_path.code .. links.names[scr]) == true then
    return true
  else
    return false
  end
end

local function get(scr)
  if util.file_exists(_path.code .. links.names[scr]) == false then
    util.os_capture("cd " .. _path.code .. " && git clone " .. links.git[scr] .. " " .. links.names[scr])
  end
end

local function rm(scr)
  if util.file_exists(_path.code .. links.names[scr]) == true then
    util.os_capture("cd " .. _path.code .. " && rm -rf ".. links.names[scr])
  end
end


local function draw_descr()
  screen.level(6)
  screen.move(1,10)
  screen.text(links.names[script])
   screen.move(1 - pos_x,40)
  screen.text(links.descr[script])
  screen.move(128,60)
  screen.text_right(exist(script) and "Remove" or "Install")
end

local function get_links()
  browser.entries = {}
  links_to_topics = util.os_capture( [[curl -s https://llllllll.co/c/library | grep "raw-topic-link" | cut -d"'" -f2]])
  links.topics = tab.split(links_to_topics, " ")
  table.remove(links.topics,1)
  print("Getting topic links")
  tab.print(links.topics)
  print("Getting git links")
  screen.clear()
  screen.move(12,30)
  screen.level(9)
  screen.text("Updating library data")
  screen.update()
  for i=1,#links.topics do
    links.names[i] = links.topics[i]:match("^.+/(.+)/")
    table.insert(browser.entries, links.names[i])
    local link = [[curl --compressed -s ]]  .. links.topics[i] ..  [[ | grep -Eo "(http|https)://github[a-zA-Z0-9./?=_-]*.zip|.zip" | cut -d'/' -f1,2,3,4,5]]
    local descr = [[curl --compressed -s ]]  .. links.topics[i] ..  [[  | grep 'meta name="description"' -A 2]]
    links_to_git = util.os_capture(link)
    description = util.os_capture(descr)
    links.descr[i] =  tab.split(description,'"')[4]
    print(links.descr[i])
    links.git[i] = tab.split(links_to_git, " ")[1]
    p = util.clamp(p + 1, 1, #links.topics) -- progress flag
    screen.clear()
    screen.move(12,30)
    screen.level(9)
    screen.text("Updating library data")
    screen.move(34,40)
    screen.level(2)
    screen.text(p .. " of ".. #links.topics )
    screen.update()
   end
   redraw()
   tab.save(links, _path.code .. "utils/lib/scripts.db")
   main_menu = true
end

local function init_db()
  if util.file_exists(_path.code .. "utils/lib/scripts.db") == true then
    load_db = tab.load(_path.code .. "utils/lib/scripts.db")
    links = load_db
    browser.entries = {}
    for i=1,#links.topics do
      table.insert(browser.entries, links.names[i])
    end
  else
    get_links()
  end
  redraw()
end




function init()
  browser = UI.ScrollingList.new(10, 1, 1, {})
  browser.num_visible = 6
  browser.num_above_selected = 2
  browser.active = 1
  init_db()
end

function key(n,z)
  if main_menu then
    if n == 1 then
      get_links()
    elseif n == 3 then
      if z == 1 then
        script = browser.index
        script_menu = true
        main_menu = false
      end
    end
  elseif script_menu then
    if n == 2 then
      main_menu = true
      script_menu = false
    elseif n == 3 then
      if z == 1 then
        if exist(script) then
          rm(script)
        else
          get(script)
        end
      end
    end
  end
  redraw()
end

function enc(n,d)
  if n == 2 then
    if main_menu then
    browser:set_index_delta(d, false)
    redraw()
    elseif script_menu then
    pos_x = util.clamp(pos_x + d, 0, #links.descr[script] + 6)
    redraw()
    end
  end
end


function redraw()
  screen.clear()
  if main_menu then
    browser:redraw()
  elseif script_menu then
    draw_descr()
  end
  screen.update()
end
