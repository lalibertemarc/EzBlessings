-- Undead accent for EzBlessings' announce lines: the undead path of EzAccent's Accent.lua (its hand port of
-- AccentTranslator's rules.accented()), trimmed to locked jaw and jawless, as EzMinion's Accent.lua. Keep the copies in step.
-- The tables come from AccentRules.lua (EzAccent's tools/gen_rules.py --accents undead).
--   ns.Speak(accent, line, max) -> the line in that accent: "locked" (locked jaw), "jawless", or "none" (left alone)
-- Chat links (|H...|h...|h and other | escapes), {placeholder} tokens and %t are never touched.
local _, ns = ...

local random = math.random
local concat = table.concat

local function Pick(list)
    return list[random(#list)]
end

---------------------------------------------------------------------------
-- Protected tokens: swapped for {1}, {2}... while the accent works, put back at the end.
---------------------------------------------------------------------------
local ESCAPES = { "^|c[^|]*|H.-|h.-|h|r", "^|H.-|h.-|h", "^|T.-|t", "^|A.-|a", "^|K.-|k", "^|c%x%x%x%x%x%x%x%x",
                  "^|r" }

local function Protect(line)
    local saved, out, i = {}, {}, 1
    while i <= #line do
        local c, s, e = line:sub(i, i)
        if c == "|" then
            for _, p in ipairs(ESCAPES) do
                s, e = line:find(p, i)
                if s then break end
            end
        elseif c == "{" then
            s, e = line:find("^{[^{}]*}", i)
        elseif c == "%" then
            s, e = line:find("^%%%a", i)
        end
        if s then
            saved[#saved + 1] = line:sub(s, e)
            out[#out + 1] = "{" .. #saved .. "}"
            i = e + 1
        else
            out[#out + 1] = c
            i = i + 1
        end
    end
    return concat(out), saved
end

local function Restore(line, saved)
    return (line:gsub("{(%d+)}", function(n) return saved[tonumber(n)] end))
end

---------------------------------------------------------------------------
-- rules.respell: spelling swaps, then a strained sound at the end
---------------------------------------------------------------------------
local function Respell(line, swaps)
    local low, out, i, n = line:lower(), {}, 1, #line
    while i <= n do
        local hit
        for _, sw in ipairs(swaps) do
            local e = i + #sw.from - 1
            if low:sub(i, e) == sw.from and (not sw.ahead or low:find("^" .. sw.ahead, e + 1)) then
                hit = sw
                break
            end
        end
        if hit then
            local to = hit.to
            if line:find("^%u", i) then
                local k = to:sub(1, 1) == "'" and 2 or 1
                to = to:sub(1, k - 1) .. to:sub(k, k):upper() .. to:sub(k + 1)
            end
            out[#out + 1] = to
            i = i + #hit.from
        else
            out[#out + 1] = line:sub(i, i)
            i = i + 1
        end
    end
    return concat(out)
end

-- rules.SOUND_AT_END, by hand: a line already ending in a gurgle or strain gets no second one.
local SOUNDS = { "^gh+k+$", "^hh+r*k+$", "^hhh+$", "^n+gh$", "^m+f$", "^hk+$", "^nnn+$", "^sss+$" }
local function IsSound(word)
    if not word then return false end
    for _, p in ipairs(SOUNDS) do
        if word:find(p) then return true end
    end
    return false
end

local function EndsInSound(line)
    local last = line:lower():gsub("[^%w_]*$", ""):match("([%w_]+%-?[%w_]*)$")
    if not last then return false end
    local head, tail = last:match("^([%w_]+)%-([%w_]+)$")
    if head then return IsSound(head) or IsSound(tail) end
    return IsSound(last)
end

-- rules.drool: one of sounds at a comma (", ghk, ") or between two sentences (". Ghk. ").
local function Drool(line, sounds)
    local breaks = {}
    for s, mark, e in line:gmatch("()([,.!?]+)%s+()") do
        if e <= #line then breaks[#breaks + 1] = { s, mark, e } end
    end
    if #breaks == 0 then return line end
    local b, d = Pick(breaks), Pick(sounds)
    local ins = b[2] == "," and ", " .. d .. ", " or b[2] .. " " .. d:sub(1, 1):upper() .. d:sub(2) .. ". "
    return line:sub(1, b[1] - 1) .. ins .. line:sub(b[3])
end

-- rules.stutter: one word of three letters or more starting with a consonant, its first letter caught: w-would.
local function Stutter(line)
    local words = {}
    for s, w in line:gmatch("()([%w_]+)") do
        if line:sub(s - 1, s - 1) ~= "{" and line:sub(s - 1, s - 1) ~= "'" and #w >= 3
                and w:find("^[b-df-hj-np-tv-zB-DF-HJ-NP-TV-Z]") then
            words[#words + 1] = { s, w }
        end
    end
    if #words == 0 then return line end
    local s, w = unpack(Pick(words))
    return line:sub(1, s - 1) .. w:sub(1, 1) .. "-" .. w:sub(1, 1):lower() .. line:sub(s + 1)
end

-- The odd s hisses through the teeth: jusst, thiss.
local function Hiss(line)
    local words = {}
    for s, w, e in line:gmatch("()([%w_]+)()") do
        if line:sub(s - 1, s - 1) ~= "{" and line:sub(e, e) ~= "}" and w:find("s", 2, true) then
            words[#words + 1] = { s, e, w }
        end
    end
    if #words == 0 then return line end
    local pick = Pick(words)
    local w = pick[3]
    local at = w:match("^.*()s")
    return line:sub(1, pick[1] - 1) .. w:sub(1, at) .. w:sub(at) .. line:sub(pick[2])
end

---------------------------------------------------------------------------
-- rules.accented, undead only. The closing sound is dropped when the line would pass max bytes.
---------------------------------------------------------------------------
function ns.Speak(accent, line, max)
    if accent ~= "locked" and accent ~= "jawless" then return line end
    local thick = accent == "jawless"
    local text, saved = Protect(line)
    if not thick and random() < 0.5 then text = Hiss(text) end
    if not thick and random() < ns.STUTTER_CHANCE then text = Stutter(text) end
    text = Respell(text, thick and ns.JAWLESS or ns.LOCKED)
    if random() < (thick and ns.DROOL_CHANCE or ns.CLENCH_CHANCE) then
        text = Drool(text, thick and ns.DROOLS or ns.CLENCHES)
    end
    local core = Restore(text, saved)
    if EndsInSound(text) then return core end
    local out = Restore(text .. " " .. Pick(thick and ns.GURGLES or ns.STRAINS), saved)
    if max and #out > max then return core end
    return out
end
