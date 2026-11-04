-- Checks the announce lines outside the game (Lua 5.1, also in CI): lua tests/lines.lua [print]
-- Every built-in line uses only %t, %b and %p; and every line, said live in every accent the way Core.lua's
-- FormatMessage() does it (ns.Speak on the unfilled line, then the fills), keeps its placeholders and leaves no
-- stray braces, and stays inside the chat limit with long words filled in, at least plain. "print" also prints
-- the first line of each pool in each accent.
local ns = {}
GetBuildInfo = function() return "1.60.1", "0", "", 16001 end
for _, file in ipairs({ "Data.lua", "Lines.lua", "AccentRules.lua", "Accent.lua" }) do
    assert(loadfile(file))("EzBlessings", ns)
end
local show = arg[1] == "print"
local MAX = 255

local failures = 0
local function Fail(msg)
    failures = failures + 1
    print("FAIL: " .. msg)
end

-- The longest words a line can get: a long full name, a long blessing, a long paladin's name.
local LONG = { t = "Bartholomewsy Thunderhammer", b = "Greater Blessing of Sanctuary", p = "Bartholomewsy" }
local function Fill(s) return (s:gsub("%%(%a)", function(k) return LONG[k] end)) end
local function Count(s, k) return select(2, s:gsub("%%" .. k, "")) end

-- Every pool Core.lua picks from: name -> list of lines.
local pools = { { "ACCENT_SAMPLE", { ns.ACCENT_SAMPLE } } }
for _, name in ipairs({ "LINES", "UNWORTHY_LINES", "MIGHT_ON_CASTER_LINES", "RENEW_OTHER_LINES", "REFRESH_LINES" }) do
    pools[#pools + 1] = { name, ns[name] }
end
for _, name in ipairs({ "BLESSING_LINES", "CLASS_LINES" }) do
    local keys = {}
    for key in pairs(ns[name]) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do pools[#pools + 1] = { name .. "." .. key, ns[name][key] } end
end

local lines = 0
for _, pool in ipairs(pools) do
    if #pool[2] == 0 then Fail(pool[1] .. ": empty") end
    for i, text in ipairs(pool[2]) do
        lines = lines + 1
        local where = pool[1] .. "#" .. i
        for k in text:gmatch("%%(.)") do
            if not LONG[k] then Fail(where .. ": %" .. k .. " is never filled") end
        end
        if text:find("[{}|]") then Fail(where .. ": braces or | in a line") end
        if #Fill(text) > MAX then Fail(where .. ": too long even plain") end
    end
end

-- Every accent the options offer ("race" picks one of them), light and thick.
math.randomseed(1)
local said, plain = 0, 0
for _, a in ipairs(ns.ACCENTS) do
    if a.key ~= "race" and a.key ~= "none" then
        for _, pool in ipairs(pools) do
            for i, text in ipairs(pool[2]) do
                local where = a.key .. ": " .. pool[1] .. "#" .. i
                local max = MAX - (#Fill(text) - #text)
                for n = 1, 4 do
                    local thick = n > 2 -- light twice, thick twice
                    local out = ns.Speak(a.key, text, thick, max)
                    said = said + 1
                    for k in pairs(LONG) do
                        if Count(out, k) ~= Count(text, k) then Fail(where .. ": %" .. k .. " lost: " .. out) end
                    end
                    if out:find("[{}]") then Fail(where .. ": stray brace: " .. out) end
                    if #out > max then plain = plain + 1 end -- goes out plain: fine, but counted
                    if show and (n == 1 or n == 3) and i == 1 then
                        print(where .. (thick and " (thick)" or "") .. "  " .. Fill(out))
                    end
                end
            end
        end
    end
end

print(("%d lines, %d accented sayings (%d too long, said plain), %d failures"):format(lines, said, plain, failures))
os.exit(failures == 0 and 0 or 1)
