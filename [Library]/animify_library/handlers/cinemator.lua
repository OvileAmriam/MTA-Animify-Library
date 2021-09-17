----------------------------------------------------------------
--[[ Resource: Animify Library
     Script: handlers: cinemator.lua
     Server: -
     Author: OvileAmriam
     Developer: -
     DOC: 08/09/2021 (OvileAmriam)
     Desc: Cinemator Handler ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

local prevLMBClickState, prevRMBClickState = false, false
local cinemationData = {
    pedData = {
        createdPed = false,
        boneData = false,
        skin = 0,
        position = {1483.508544921875, -1466.627685546875, 40.5234375},
        rotation = 90,
        cameraMatrix = {1480.912963867188, -1466.779541015625, 40.06010055541992, 1481.8369140625, -1466.725463867188, 40.23865585327148, 0, 80}
    },
    boneIndicator = {
        size = 10,
        focussedColor = tocolor(255, 255, 255, 255),
        unfocussedColor = tocolor(255, 255, 255, 10),
        bgPath = dxCreateTexture(":beautify_library/files/assets/images/canvas/circle.rw", "argb", true, "clamp")
    },
    axisRings = {
        x = {
            color = {255, 0, 0}
        },
        y = {
            color = {0, 255, 0}
        },
        z = {
            color = {0, 0, 255}
        }
    }
}


-------------------------------------
--[[ Function: Renders Cinemator ]]--
-------------------------------------

local boneRotCache = false
local function renderCinemator()

    local isLCTRLOnHold = false
    local isLMBClicked, isRMBClicked = false, false
    if not GuiElement.isMTAWindowActive() then
        isLCTRLOnHold = getKeyState("lctrl")
        if not prevLMBClickState then
            if getKeyState("mouse1") then
                isLMBClicked = true
                prevLMBClickState = true
            end
        else
            if not getKeyState("mouse1") then
                prevLMBClickState = false
            end
        end
        if not prevRMBClickState then
            if getKeyState("mouse2") then
                isRMBClicked = true
                prevRMBClickState = true
            end
        else
            if not getKeyState("mouse2") then
                prevRMBClickState = false
            end
        end
    end

    local _, _, pedRotation = getElementRotation(cinemationData.pedData.createdPed)
    for i, j in pairs(availablePedBones) do
        local isBoneSelected = cinemationData.pedData.boneData and (cinemationData.pedData.boneData.boneID == i)
        local bone_posVector = Vector3(getPedBonePosition(cinemationData.pedData.createdPed, i))
        if isBoneSelected then
            setElementPosition(cinemationData.axisRings.x.object, bone_posVector)
            setElementPosition(cinemationData.axisRings.y.object, bone_posVector)
            setElementPosition(cinemationData.axisRings.z.object, bone_posVector)
            setElementRotation(cinemationData.axisRings.y.object, 0, 0, pedRotation)
            setElementRotation(cinemationData.axisRings.y.object, 0, 90, pedRotation)
            setElementRotation(cinemationData.axisRings.z.object, 90, 0, pedRotation)
        end
        local x, y = getScreenFromWorldPosition(bone_posVector)
        if x and y then
            local indicatorSize = cinemationData.boneIndicator.size
            local indicatorX, indicatorY = x - (indicatorSize*0.5), y - (indicatorSize*0.5)
            if isRMBClicked then
                boneRotCache = false
                cinemationData.pedData.boneData = false
            else
                if not isBoneSelected then
                    if isLMBClicked and isMouseOnPosition(indicatorX, indicatorY, indicatorSize, indicatorSize) then
                        boneRotCache = false
                        cinemationData.pedData.boneData = {
                            boneID = i,
                            axisID = false
                        }
                    end
                end
            end
            dxDrawImage(indicatorX, indicatorY, indicatorSize, indicatorSize, cinemationData.boneIndicator.bgPath, 0, 0, 0, (isBoneSelected and cinemationData.boneIndicator.focussedColor) or cinemationData.boneIndicator.unfocussedColor, false)
        end
    end

    local focussedAxis = false
    if cinemationData.pedData.boneData then
        if not cinemationData.pedData.boneData.axisID or not isLCTRLOnHold then
            local cursorX, cursorY = getAbsoluteCursorPosition()
            local sightData = {processLineOfSight(Vector3(getWorldFromScreenPosition(cursorX, cursorY, 0)), Vector3(getWorldFromScreenPosition(cursorX, cursorY, 5)), false, false, false, true, false, false, false, false, cinemationData.pedData.createdPed)}
            if sightData[1] and sightData[5] then
                focussedAxis = sightData[5]
            end
        else
            if isLCTRLOnHold then
                --local yaw, pitch, roll = getElementBoneRotation(cinemationData.pedData.createdPed, cinemationData.pedData.boneData.boneID)
                if not boneRotCache then
                    boneRotCache = {getElementBoneRotation(cinemationData.pedData.createdPed, cinemationData.pedData.boneData.boneID)}
                end
                if cinemationData.pedData.boneData.axisID == "x" then
                    if getKeyState("arrow_l") then
                        boneRotCache[1] = boneRotCache[1] - 1
                    elseif getKeyState("arrow_r") then
                        boneRotCache[1] = boneRotCache[1] + 1
                    end
                elseif cinemationData.pedData.boneData.axisID == "y" then
                    if getKeyState("arrow_l") then
                        boneRotCache[2] = boneRotCache[2] - 1
                    elseif getKeyState("arrow_r") then
                        boneRotCache[2] = boneRotCache[2] + 1
                    end
                elseif cinemationData.pedData.boneData.axisID == "z" then
                    if getKeyState("arrow_l") then
                        boneRotCache[3] = boneRotCache[3] - 1
                    elseif getKeyState("arrow_r") then
                        boneRotCache[3] = boneRotCache[3] + 1
                    end
                end
            end
        end
    end
    for i, j in pairs(cinemationData.axisRings) do
        if (focussedAxis == j.object) and (cinemationData.pedData.boneData.axisID ~= focussedAxis) then
            if isLMBClicked then
                cinemationData.pedData.boneData.axisID = i
            end
        end
        dxSetShaderValue(j.shader, "axisAlpha", (not cinemationData.pedData.boneData and 0) or (((cinemationData.pedData.boneData and (cinemationData.pedData.boneData.axisID == i)) or (j.object == focussedAxis)) and 1) or 0.05)
    end

    for i, j in ipairs(coreUI.viewportUI.sliders) do
        local _, sliderPercent = beautify.slider.getPercent(j.createdElement)
        if sliderPercent then
            sliderPercent = sliderPercent/100
            if j.sliderType == "ped_rotation" then
                setElementRotation(cinemationData.pedData.createdPed, 0, 0, sliderPercent*360)
            elseif j.sliderType == "camera_fov" then
                cinemationData.pedData.cameraMatrix[8] = 40 + (sliderPercent*40)
            end
        end
    end
    showChat(false)
    setCameraMatrix(unpack(cinemationData.pedData.cameraMatrix))

end
addEventHandler("onClientPedsProcessed", getRootElement(), function()
    if boneRotCache then
        setElementBoneRotation(cinemationData.pedData.createdPed, cinemationData.pedData.boneData.boneID, unpack(boneRotCache))
        updateElementRpHAnim(cinemationData.pedData.createdPed)
    end
end)



-----------------------------------------
--[[ Function: Initializes Cinemator ]]--
-----------------------------------------

function initCinemator()

    initModels()
    cinemationData.pedData.createdPed = createPed(cinemationData.pedData.skin, cinemationData.pedData.position[1], cinemationData.pedData.position[2], cinemationData.pedData.position[3], cinemationData.pedData.rotation)
    for i = 0, 17 do
        removePedClothes(cinemationData.pedData.createdPed, i)
    end

    for i, j in pairs(cinemationData.axisRings) do
        j.object = createObject(Animify_Models["axisRing"].modelID, 0, 0, 0)
        setElementCollidableWith(j.object, cinemationData.pedData.createdPed, false)
        j.shader = dxCreateShader(Animify_Shaders["Axisifier"])
        engineApplyShaderToWorldTexture(j.shader, "animify_axis_ring", j.object)
        dxSetShaderValue(j.shader, "axisColor", j.color[1]/255, j.color[2]/255, j.color[3]/255, 1)
        for k, v in pairs(cinemationData.axisRings) do
            if v.object and (j.object ~= v.object) then
                setElementCollidableWith(j.object, v.object, false)
            end
        end
    end
    beautify.render.create(renderCinemator)
    return true

end
