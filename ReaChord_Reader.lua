--[[
 * ReaScript Name: ReaChord Reader
 * Copy from X-Raym Region's Clock
--]]


--// USER CONFIG AREA -->
text_color = "White"         -- support names (see color function) and hex values with #
background_color =
"#333333"                    -- support names and hex values with #. REAPER defaults are dark grey #333333 and brigth grey #A4A4A4
no_regions_text = true       -- set to false to desactivate "NO REGIONS UNDER PLAY CURSOR" instructions
console = false              -- Display debug messages in the console

--// -------------------- END OF USER CONFIG AREA


--// INITIAL VALUES //--
font_size = 40
font_name = "Arial"
format = 0

vars = {}
vars.wlen = 640
vars.hlen = 270
vars.docked = 0
vars.xpos = 100
vars.ypos = 100

ext_name = "ReaChord Reader"

pre_chord_txt = ""
post_chord_txt = ""
chord_txt = ""
pre_simple_chord_txt = ""
post_simple_chord_txt = ""
simple_chord_txt = ""

pre_full_chord_txt = ""
post_full_chord_txt = ""
full_chord_txt = ""

-- Performance
local reaper = reaper

dofile(reaper.GetResourcePath() .. '/Scripts/ReaChord/ReaChord_Util.lua')
dofile(reaper.GetResourcePath() .. '/Scripts/ReaChord/ReaChord_Reaper.lua')

-- DEBUG
function Msg(value)
    if console then
        reaper.ShowConsoleMsg(tostring(value) .. "\n")
    end
end

-- Set ToolBar Button State
function SetButtonState(set)
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

--// COLOR FUNCTIONS //--
function INT2RGB(color_int)
    if color_int >= 0 then
        R, G, B = reaper.ColorFromNative(color_int)
    else
        R, G, B = 255, 255, 255
    end
    rgba(R, G, B, 255)
end

function rgba(r, g, b, a)
    if a ~= nil then gfx.a = a / 255 else a = 255 end
    gfx.r = r / 255
    gfx.g = g / 255
    gfx.b = b / 255
end

function HexToRGB(value)
    local hex = value:gsub("#", "")
    local R = tonumber("0x" .. hex:sub(1, 2))
    local G = tonumber("0x" .. hex:sub(3, 4))
    local B = tonumber("0x" .. hex:sub(5, 6))

    if R == nil then R = 0 end
    if G == nil then G = 0 end
    if B == nil then B = 0 end

    gfx.r = R / 255
    gfx.g = G / 255
    gfx.b = B / 255
end

function color(col)
    if string.find(col, "#.+") ~= nil then
        color2 = col
        HexToRGB(color2)
    end
    if col == "White" then HexToRGB("#FFFFFF") end
    if col == "Silver" then HexToRGB("#C0C0C0") end
    if col == "Gray" then HexToRGB("#808080") end
    if col == "Black" then HexToRGB("#000000") end
    if col == "Red" then HexToRGB("#FF0000") end
    if col == "Maroon" then HexToRGB("#800000") end
    if col == "Yellow" then HexToRGB("#FFFF00") end
    if col == "Olive" then HexToRGB("#808000") end
    if col == "Lime" then HexToRGB("#00FF00") end
    if col == "Green" then HexToRGB("#008000") end
    if col == "Aqua" then HexToRGB("#00FFFF") end
    if col == "Teal" then HexToRGB("#008080") end
    if col == "Blue" then HexToRGB("#0000FF") end
    if col == "Navy" then HexToRGB("#000080") end
    if col == "Fuchsia" then HexToRGB("#FF00FF") end
    if col == "Purple" then HexToRGB("#800080") end
end

--// ELEMENTS //--
function DrawProgressBar() -- Idea from Heda's Notes Reader
    progress_percent = (play_pos - region_start) / region_duration
    rect_h = gfx.h / 10

    INT2RGB(region_color)
    gfx.rect(0, 0, gfx.w, rect_h)

    rgba(255, 255, 255, 200)
    gfx.rect(0, 0, gfx.w * progress_percent, rect_h)
    gfx.y = rect_h * 2
end

function StringArea(string, ratio)
    gfx.setfont(1, font_name, 100)

    str_w, str_h = gfx.measurestr(string)
    fontsizefit = (gfx.w / (str_w + 50)) * 100 -- new font size needed to fit.
    fontsizefith = ((gfx.h - gfx.y) / (str_h + 0)) * 100 -- new font size needed to fit in vertical.

    font_size = math.min(fontsizefit, fontsizefith)
    gfx.setfont(1, font_name, font_size * ratio)
    str_w, str_h = gfx.measurestr(string)
    return str_w, str_h, font_size * ratio
end

function CenterAndResizeText(string)
    gfx.setfont(1, font_name, 100)

    str_w, str_h = gfx.measurestr(string)
    fontsizefit = (gfx.w / (str_w + 50)) * 100 -- new font size needed to fit.
    fontsizefith = ((gfx.h - gfx.y) / (str_h + 0)) * 100 -- new font size needed to fit in vertical.

    font_size = math.min(fontsizefit, fontsizefith)
    gfx.setfont(1, font_name, font_size)

    str_w, str_h = gfx.measurestr(string)
    gfx.x = gfx.w / 2 - str_w / 2
    gfx.y = gfx.y
end

function PrintLabelAndBreak(string)
    CenterAndResizeText(string)
    color("Gray")
    gfx.printf(string)
    gfx.y = gfx.y + font_size
end

function PrintChordAndBreak(pre, cur, post)
    local pre_w, pre_h, pre_size = StringArea(pre, 0.5)
    local cur_w, cur_h, cur_size = StringArea(cur, 1)
    local post_w, post_h, post_size = StringArea(post, 0.5)

    gfx.x = gfx.w / 2 - cur_w / 2 - pre_w
    gfx.setfont(1, font_name, pre_size)
    color("Gray")
    gfx.printf(pre)

    gfx.setfont(1, font_name, cur_size)
    color("White")
    gfx.printf(cur)

    gfx.setfont(1, font_name, post_size)
    color("Gray")
    gfx.printf(post)
    gfx.y = gfx.y + font_size
end

function DrawBackground()
    color(background_color)
    gfx.rect(0, 0, gfx.w, gfx.h)
end

--// INIT //--
function init()
    GetExtStates()
    gfx.init("ReaChord Reader", vars.wlen, vars.hlen, vars.docked, vars.xpos, vars.ypos) -- name,width,height,dockstate,xpos,ypos
    gfx.setfont(1, font_name, font_size, 'b')
    --color(text_color)
end

function DoExitFunctions()
    SetButtonState(-1)
    SaveState()
end

function SaveState()
    vars.docked, vars.xpos, vars.ypos, vars.wlen, vars.hlen = gfx.dock(-1, 0, 0, 0, 0)
    for k, v in pairs(vars) do
        SaveExtState(k, v)
    end
end

function SaveExtState(var, val)
    reaper.SetExtState(ext_name, var, tostring(val), true)
end

function GetExtState(var, val)
    if reaper.HasExtState(ext_name, var) then
        local t = type(val)
        val = reaper.GetExtState(ext_name, var)
        if t == "boolean" then
            val = toboolean(val)
        elseif t == "number" then
            val = tonumber(val)
        else
        end
    end
    return val
end

function GetExtStates()
    for k, v in pairs(vars) do
        vars[k] = GetExtState(k, v)
    end
end

--// MAIN //--
function run()
    offset = reaper.GetProjectTimeOffset(proj, false)

    DrawBackground()

    -- PLAY STATE
    play_state = reaper.GetPlayState()
    if play_state == 0 then play_pos = reaper.GetCursorPosition() else play_pos = reaper.GetPlayPosition() end

    --   -- IS REGION
    --   marker_idx, region_idx = reaper.GetLastMarkerAndCurRegion(0, play_pos)
    --   if region_idx >= 0 then -- IF LAST REGION

    --     retval, is_region, region_start, region_end, region_name, markrgnindexnumber, region_color = reaper.EnumProjectMarkers3(0, region_idx)
    --     buf = play_pos - region_start - offset
    --     buf = reaper.format_timestr_pos(buf, "", format)
    --     end_buf = region_end - play_pos - offset
    --     end_string = reaper.format_timestr_pos(end_buf, "", format)
    --     buf = buf .. " → " .. end_string
    --     region_duration = region_end - region_start
    --   else
    --     is_region = false
    --     gfx.y = 0
    --   end -- IF LAST REGION

    -- Try to get chord item, code structure same as the region clock
    -- is_region -> have item
    -- region_start -> item start
    -- region_end -> region_end
    -- region_name -> chord
    --
    is_region, region_start, region_end, region_name = R_GetChordItemInfoByPosition(play_pos)
    region_color = 0
    if is_region then
        region_duration = region_end - region_start
        local chord_split = StringSplit(region_name, NewLineTag())
        full_chord_txt = region_name
        chord_txt = chord_split[1]
        simple_chord_txt = chord_split[2]

        -- get pre post item
        ret_pre, _, _, pre_chord = R_GetChordItemInfoByPosition(region_start - 1)
        if ret_pre then
            local pre_chord_split = StringSplit(pre_chord, NewLineTag())
            pre_full_chord_txt = pre_chord
            pre_chord_txt = pre_chord_split[1]
            pre_simple_chord_txt = pre_chord_split[2]
        end

        ret_post, _, _, post_chord = R_GetChordItemInfoByPosition(region_end + 1)
        if ret_post then
            local post_chord_split = StringSplit(post_chord, NewLineTag())
            post_full_chord_txt = post_chord
            post_chord_txt = post_chord_split[1]
            post_simple_chord_txt = post_chord_split[2]
        end
    else
        gfx.y = 0
    end

    if gfx.mouse_cap == 2 and (not is_region or gfx.mouse_y < rect_h) then
        local dock = gfx.dock(-1) == 0 and "Dock" or "Undock"
        gfx.x = gfx.mouse_x
        gfx.y = gfx.mouse_y
        if gfx.showmenu(dock) == 1 then
            if gfx.dock(-1) == 0 then gfx.dock(1) else gfx.dock(0) end
        end
    end

    -- From SPK77's Clock script
    -- CHANGE FORMAT WITH A CLICK
    if mouse_state == 0 and gfx.mouse_cap == 2 and gfx.mouse_x > 5 and gfx.mouse_x < gfx.w - 5 and gfx.mouse_y > 5 and gfx.mouse_y < gfx.h - 5 then
        mouse_state = 1
        if format < 2 then
            format = format + 1
        else
            format = 0
        end
    end

    if gfx.mouse_cap == 0 then mouse_state = 0 end

    -- Left clik return cursor at the begining of the region smooth seek
    if gfx.mouse_cap == 1 then
        if is_region then
            if gfx.mouse_y < rect_h then
                reaper.SetEditCurPos(region_start, false, true)
            else
                reaper.Main_OnCommand(40616, 0)
            end
        end
    end

    -- DRAW
    if is_region == true then
        DrawProgressBar()
        if format>0 then
            PrintChordAndBreak(pre_chord_txt, chord_txt, post_chord_txt)
        else
            PrintChordAndBreak(pre_simple_chord_txt, simple_chord_txt, post_simple_chord_txt)
        end
    else
        PrintLabelAndBreak("No Chord")
    end

    gfx.update()

    char = gfx.getchar()
    if char == 27 or char == -1 then gfx.quit() else reaper.defer(run) end
end -- END DEFER

--// RUN //--

SetButtonState(1)
init()
run()
reaper.atexit(DoExitFunctions)
