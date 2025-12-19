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

    local originalW = currentW - (pL + pR)
    local originalH = currentH - (pT + pB)

    if originalW <= 0 then return end

    local angleDeg = tonumber(SKIN:GetVariable('Angle')) or 0
    local targetPctX = tonumber(SELF:GetOption('PosX')) or 0.5
    local targetPctY = tonumber(SELF:GetOption('PosY')) or 0.5

    local rad = math.rad(angleDeg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local x1, y1 = 0, 0
    local x2, y2 = (originalW * cos), (originalW * sin)
    local x3, y3 = (originalW * cos) - (originalH * sin), (originalW * sin) + (originalH * cos)
    local x4, y4 = -(originalH * sin), (originalH * cos)

    local minX = math.min(x1, x2, x3, x4)
    local maxX = math.max(x1, x2, x3, x4)
    local minY = math.min(y1, y2, y3, y4)
    local maxY = math.max(y1, y2, y3, y4)

    local newW = maxX - minX
    local newH = maxY - minY

    local tx = -minX
    local ty = -minY

    local matrix = string.format("%f;%f;%f;%f;%f;%f", cos, sin, -sin, cos, tx, ty)

    local padR = math.ceil(newW - originalW)
    local padB = math.ceil(newH - originalH)
    if padR < 0 then padR = 0 end
    if padB < 0 then padB = 0 end

    local newPadString = '0,0,' .. padR .. ',' .. padB

    local screenW = tonumber(SKIN:GetVariable('SCREENAREAWIDTH'))
    local screenH = tonumber(SKIN:GetVariable('SCREENAREAHEIGHT'))
    local workX = tonumber(SKIN:GetVariable('SCREENAREAX'))
    local workY = tonumber(SKIN:GetVariable('SCREENAREAY'))

    local finalX = math.floor(workX + (screenW * targetPctX) - tx)
    local finalY = math.floor(workY + (screenH * targetPctY) - ty)

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

    return newW .. "x" .. newH
end
