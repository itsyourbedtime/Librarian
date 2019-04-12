-- Librarian
--
-- hold btn 1 to
--   * update lib
--   * update selected script

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
local pull_msg = nil

local function exist(scr)
  if util.file_exists(_path.code .. links.names[scr]) == true then
    return true
  else
    return false
  end
end

local function get(scr)
  if util.file_exists(_path.code .. links.names[scr]) == false then
    util.os_capture("cd " .. _path.code .. " && git clone " .. links.git[links.names[scr]] .. " " .. links.names[scr])
  end
end

local function git_pull(scr)
  if util.file_exists(_path.code .. links.names[scr]) == false then
    pull_msg = util.os_capture("cd " .. _path.code .. links.names[scr] .. "/ && git pull")
  end
  return pull_msg
end

local function rm(scr)
  if util.file_exists(_path.code .. links.names[scr]) == true then
    util.os_capture("cd " .. _path.code .. " && rm -rf ".. links.names[scr])
  end
end

local function draw_descr()
  local description = {}
  description = tab.split(links.descr[links.names[script]], " ")
  local lenl = 0
  screen.level(15)
  screen.move(1,10)
  local y = 18
  for i = 1, #description do
    screen.level(i == 1 and 15 or 3)
    screen.text(description[i] .. " ")
    if i==1 or i == 4 or i == 8 then
      y = y + 8
      lenl = 0
      screen.move(0,y) end
  end
  screen.level(1)
  screen.move(0,62)
  screen.text(exist(script) and "hold BTN1 to update" or "")
  screen.level(6)
  screen.move(128,62)
  screen.text_right(exist(script) and "remove" or "install")
end

local function get_links()
  local last_links = links.topics
  browser.entries = {}
  screen.clear()
  screen.move(12,30)
  screen.level(9)
  screen.text("Updating library data")
  screen.update()
  links_to_topics = util.os_capture( [[curl -s https://llllllll.co/c/library | grep "raw-topic-link" | cut -d"'" -f2]])
  links.topics = tab.split(links_to_topics, " ")
  table.remove(links.topics,1)
  tab.print(links.topics)
  for i=1,#links.topics do
    links.names[i] = string.gsub(links.topics[i]:match("^.+/(.+)/"), "-", "_")
    --links.names[i] = exist(i) and "* " ..  links.names[i] or links.names[i]
    --table.insert(browser.entries, name)
    if not tab.contains(last_links, links.topics[i]) then
      local link = [[curl --compressed -s ]]  .. links.topics[i] ..  [[ | grep -Eo "^(http|https)://github[a-zA-Z0-9./?=_-]*.zip" | cut -d'/' -f1,2,3,4,5]]
      local descr = [[curl --compressed -s ]]  .. links.topics[i] ..  [[ | grep 'meta name="description"' -A 2]]
      links_to_git = util.os_capture(link)
      description = util.os_capture(descr)
      links.descr[links.names[i]] =  tab.split(description,'"')[4]
      print(links.names[i])
      links.git[links.names[i]] = tab.split(links_to_git, " ")[1]
      p = util.clamp(p + 1, 1, #links.topics) -- progress flag
      screen.clear()
      screen.move(12,30)
      screen.level(9)
      screen.text("Updating library data")
      screen.move(38,40)
      screen.level(2)
      screen.text(p .. " of ".. #links.topics )
      screen.update()
    else
      screen.update()
    end
  end
  browser.entries = links.names
  last_links = links.topics
  tab.save(links, _path.code .. "Librarian/lib/scripts.db")
  main_menu = true
  redraw()
end

local function init_db()
  if util.file_exists(_path.code .. "Librarian/lib/scripts.db") == true then
    load_db = tab.load(_path.code .. "Librarian/lib/scripts.db")
    links = load_db
    browser.entries = {}
    for i=1,#links.topics do
      table.insert(browser.entries, links.names[i])
    end
  else
    util.make_dir(_path.code .. "Librarian/lib/")
    get_links()
  end
  redraw()
end




function init()
  browser = UI.ScrollingList.new(0, 1, 1, {})
  browser.num_visible = 6
  browser.num_above_selected = 2
  browser.active = 1
  init_db()
  get_links()
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
    if n == 1 then
      git_pull(script)
    elseif n == 2 then
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