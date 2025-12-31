---@diagnostic disable: undefined-global

function Initialize()
    MeterName = SELF:GetOption('TargetMeter')
end

local lastMatrix = ""
local lastPad = ""
local lastX = nil
local lastY = nil

function Update()
    local meter = SKIN:GetMeter(MeterName)
    if not meter then return end

    local currentW = meter:GetW()
    local currentH = meter:GetH()

    local padding = meter:GetOption('Padding') or ""
    local pL, pT, pR, pB = 0, 0, 0, 0

    if padding ~= "" then
        local p = {}
        for num in string.gmatch(padding, "[%-%d]+") do
            table.insert(p, tonumber(num))
        end
        if #p == 4 then
            pL, pT, pR, pB = p[1], p[2], p[3], p[4]
        end
    end

    local baseW = currentW - (pL + pR)
    local baseH = currentH - (pT + pB)

    if baseW <= 0 or baseH <= 0 then return end

    local angleDeg = tonumber(SKIN:GetVariable('Angle')) or 0
    local targetPctX = tonumber(SELF:GetOption('PosX')) or 0.5
    local targetPctY = tonumber(SELF:GetOption('PosY')) or 0.5

    local rad = math.rad(angleDeg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local rotatedW = math.abs(baseW * cos) + math.abs(baseH * sin)
    local rotatedH = math.abs(baseW * sin) + math.abs(baseH * cos)

    local padW = math.ceil(rotatedW - baseW)
    local padH = math.ceil(rotatedH - baseH)

    if padW < 0 then padW = 0 end
    if padH < 0 then padH = 0 end

    local newPL = math.floor(padW / 2)
    local newPR = padW - newPL
    local newPT = math.floor(padH / 2)
    local newPB = padH - newPT

    local newPadString = string.format("%d,%d,%d,%d", newPL, newPT, newPR, newPB)

    local totalW = baseW + newPL + newPR
    local totalH = baseH + newPT + newPB

    local cx = totalW / 2
    local cy = totalH / 2

    local tx = cx - (cx * cos) + (cy * sin)
    local ty = cy - (cx * sin) - (cy * cos)

    local matrix = string.format("%f;%f;%f;%f;%f;%f", cos, sin, -sin, cos, tx, ty)

    local screenW = tonumber(SKIN:GetVariable('SCREENAREAWIDTH'))
    local screenH = tonumber(SKIN:GetVariable('SCREENAREAHEIGHT'))
    local workX = tonumber(SKIN:GetVariable('SCREENAREAX'))
    local workY = tonumber(SKIN:GetVariable('SCREENAREAY'))

    local targetScreenX = workX + (screenW * targetPctX)
    local targetScreenY = workY + (screenH * targetPctY)

    local finalX = math.floor(targetScreenX - cx)
    local finalY = math.floor(targetScreenY - cy)

    if matrix ~= lastMatrix then
        SKIN:Bang('!SetOption', MeterName, 'TransformationMatrix', matrix)
        SKIN:Bang('!SetVariable', 'GlobalMatrix', matrix)
        lastMatrix = matrix
    end

    if newPadString ~= lastPad then
        SKIN:Bang('!SetOption', MeterName, 'Padding', newPadString)
        lastPad = newPadString
    end

    if finalX ~= lastX or finalY ~= lastY then
        SKIN:Bang('!Move', finalX, finalY)
        lastX = finalX
        lastY = finalY
    end

    return totalW .. "x" .. totalH
end
