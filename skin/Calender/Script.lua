---@diagnostic disable: undefined-global

function Initialize()
    local now = os.time()
    local utcDate = os.date("!*t", now)
    local localDate = os.date("*t", now)
    local localTime = os.time(localDate)
    local utcTime = os.time(utcDate)
    TimezoneOffset = os.difftime(localTime, utcTime)
end

function Update()
    local StartHour = tonumber(SKIN:GetVariable('StartTime'))
    local EndHour = tonumber(SKIN:GetVariable('EndTime'))

    local HourWidth = SKIN:ParseFormula(SKIN:GetVariable('HourWidth'))
    local RowHeight = SKIN:ParseFormula(SKIN:GetVariable('RowHeight'))
    local GridX = SKIN:ParseFormula(SKIN:GetVariable('GridX'))
    local GridY = SKIN:ParseFormula(SKIN:GetVariable('GridY'))

    local ScaleFactor = SKIN:ParseFormula(SKIN:GetVariable('ScaleFactor'))
    local TextPadding = 8 * ScaleFactor
    local Margin = 2

    local now = os.time()
    local t = os.date("*t", now)

    local daysFromMon = t.wday - 2
    if t.wday == 1 then daysFromMon = 6 end

    local tMidnight = os.time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
    local weekStart = tMidnight - (daysFromMon * 86400)
    local weekEnd = weekStart + (7 * 86400)

    local filePath = SKIN:MakePathAbsolute(SKIN:GetVariable('CalendarFile'))
    local file = io.open(filePath, "r")
    if not file then
        print("Error: Calendar file not found at " .. filePath)
        return
    end
    local content = file:read("*all")
    file:close()

    local events = {}
    local currentEvent = {}
    local inEvent = false

    for line in content:gmatch("[^\r\n]+") do
        if line:find("BEGIN:VEVENT") then
            inEvent = true
            currentEvent = {}
        elseif inEvent then
            if line:find("END:VEVENT") then
                inEvent = false
                if currentEvent.dtstart and currentEvent.dtend then
                    if currentEvent.dtend > weekStart and currentEvent.dtstart < weekEnd then
                        table.insert(events, currentEvent)
                    end
                end
            elseif line:find("^DTSTART") then
                currentEvent.dtstart = ParseISODate(line:match(":(.*)"))
            elseif line:find("^DTEND") then
                currentEvent.dtend = ParseISODate(line:match(":(.*)"))
            elseif line:find("^SUMMARY") then
                -- Unescape commas if present (replace \, with ,)
                local summary = line:match("SUMMARY:(.*)")
                currentEvent.summary = summary:gsub("\\,", ",")
            elseif line:find("^LOCATION") then
                -- Grab the location and unescape commas
                local loc = line:match("LOCATION:(.*)")
                currentEvent.location = loc:gsub("\\,", ",")
            end
        end
    end

    table.sort(events, function(a, b) return a.dtstart < b.dtstart end)

    for i = 1, 30 do
        SKIN:Bang('!SetOption', 'MeterEvent' .. i, 'Hidden', '1')
    end

    local Colors = {
        "255,216, 217",
        "215,254,223",
        "216,227,255",
        "254,254,227",
        "255,235,216",
        "242,216,255"
    }

    local count = 0

    for i, e in ipairs(events) do
        local d = os.date("*t", e.dtstart)
        local dayIndex = d.wday - 2
        if d.wday == 1 then dayIndex = 6 end

        if dayIndex >= 0 and dayIndex <= 4 then
            local startDecimal = d.hour + (d.min / 60)
            local durationSeconds = e.dtend - e.dtstart
            local durationHours = durationSeconds / 3600
            local endDecimal = startDecimal + durationHours

            if endDecimal > StartHour and startDecimal < EndHour then
                count = count + 1
                if count > 30 then break end

                local drawStart = math.max(startDecimal, StartHour)
                local drawEnd = math.min(endDecimal, EndHour)
                local drawDuration = drawEnd - drawStart

                local w = (drawDuration * HourWidth) - (TextPadding * 2)
                local h = RowHeight - (Margin * 2) - (TextPadding * 2)

                local x = GridX + ((drawStart - StartHour) * HourWidth)
                local y = GridY + (dayIndex * RowHeight) + Margin

                local m = 'MeterEvent' .. count

                local displayText = e.summary or "No Title"
                if e.location and e.location ~= "" then
                    displayText = displayText .. "#CRLF#" .. e.location
                end

                SKIN:Bang('!SetOption', m, 'X', x)
                SKIN:Bang('!SetOption', m, 'Y', y)
                SKIN:Bang('!SetOption', m, 'W', w)
                SKIN:Bang('!SetOption', m, 'H', h)
                SKIN:Bang('!SetOption', m, 'Text', displayText)
                SKIN:Bang('!SetOption', m, 'ToolTipText',
                    displayText .. " (" .. d.hour .. ":" .. string.format("%02d", d.min) .. ")")

                local colorIdx = (count % #Colors) + 1
                SKIN:Bang('!SetOption', m, 'SolidColor', Colors[colorIdx])
                SKIN:Bang('!SetOption', m, 'Hidden', '0')
            end
        end
    end

    SKIN:Bang('!UpdateMeterGroup', 'Events')
    SKIN:Bang('!Redraw')
end

function ParseISODate(iso)
    if not iso then return os.time() end

    iso = iso:gsub("%s+", "")

    local year = tonumber(iso:sub(1, 4))
    local month = tonumber(iso:sub(5, 6))
    local day = tonumber(iso:sub(7, 8))
    local hour = 0
    local min = 0
    local sec = 0

    local tPos = iso:find("T")
    if tPos then
        hour = tonumber(iso:sub(tPos + 1, tPos + 2))
        min = tonumber(iso:sub(tPos + 3, tPos + 4))
        sec = tonumber(iso:sub(tPos + 5, tPos + 6))
    end

    local time = os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })

    if iso:sub(-1) == "Z" then
        time = time + TimezoneOffset
    end

    return time
end
