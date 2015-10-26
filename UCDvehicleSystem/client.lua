local resX, resY = guiGetScreenSize()
local blip = {}
playerVehicles = {}

function draw()
	local target = localPlayer:getTarget()
	if (target and target:getType() == "vehicle" and localPlayer:getControlState("aim_weapon")) then
		if (not ((localPlayer:getWeaponSlot() ~= 0 and localPlayer:getWeaponSlot() ~= 1) and
		(localPlayer:getWeaponSlot() ~= 7) and (localPlayer:getWeaponSlot() ~= 8) and
		(localPlayer:getWeaponSlot() ~= 9) and (localPlayer:getWeaponSlot() ~= 11) and
		(localPlayer:getWeaponSlot() ~= 12))) then return end
		--local vX, vY, vZ = getElementPosition(target)
		local v = target:getPosition()
		--local pX, pY, pZ = getElementPosition(localPlayer)
		local p = localPlayer:getPosition()
		
		if isElementOnScreen(target) then
			--local dist = getDistanceBetweenPoints3D(vX, vY, vZ, pX, pX, pX)
			local dist = getDistanceBetweenPoints3D(v.x, v.y, v.z, p.x, p.y, p.z)
			--local tX, tY = getScreenFromWorldPosition(vX, vY, vZ + 1, 0, false)
			local tX, tY = getScreenFromWorldPosition(v.x, v.y, v.z + 1, 0, false)
			if tX and tY and isLineOfSightClear(p.x, p.y, p.z, v.x, v.y, v.z, true, false, false, true, true, false, false, target) and dist < 30 then
				local theText = target:getData("owner")
				local width = dxGetTextWidth(tostring(theText), 0.6, "bankgothic")
				dxDrawText(tostring(theText).."'s vehicle", tX - width / 2, tY, resX, resY, tocolor(255, 0, 0), 1)
			end
		end
	end
end
addEventHandler("onClientRender", root, draw)

function syncIdToVehicle(tbl)
	idToVehicle = tbl
end
addEvent("UCDvehicleSystem.syncIdToVehicle", true)
addEventHandler("UCDvehicleSystem.syncIdToVehicle", root, syncIdToVehicle)

-- Sync the idToVehicle table when the resource starts
triggerServerEvent("UCDvehicleSystem.getIdToVehicleTable", localPlayer)
-- Sync the playerVehicles table when the resource starts
triggerServerEvent("UCDvehicleSystem.loadPlayerVehicles", localPlayer)

function onClientVehicleEnter(theVehicle, seat)
	if (source ~= localPlayer) then return end
	local owner = theVehicle:getData("owner")
	if (not owner or seat ~= 0 or localPlayer:getName() == owner) then return end
	
	exports.UCDdx:new("This vehicle is owned by "..owner, 0, 255, 0)
end
addEventHandler("onClientPlayerVehicleEnter", localPlayer, onClientVehicleEnter)

GUIEditor = {gridlist = {}, window = {}, button = {}, label = {}}

function updateVehicleGrid(vehicleID)
	if (not vehicleID) then return end
	outputDebugString("Updating grid for vehicleID = "..vehicleID)
	if (not vehicles[vehicleID].row) then
		vehicles[vehicleID].row = guiGridListAddRow(GUIEditor.gridlist[1]) -- make oop
	end
	local row = vehicles[vehicleID].row
	
	if (idToVehicle[vehicleID]) then
		local vehicleEle = idToVehicle[vehicleID]
		model = getVehicleNameFromModel(vehicleEle:getModel())
		health = exports.UCDutil:mathround(vehicleEle:getHealth() / 10)
		fuel = 100
	else
		model = getVehicleNameFromModel(getVehicleData(vehicleID, "model")) -- Wait until this is oop
		health = exports.UCDutil:mathround(getVehicleData(vehicleID, "health") / 10)
		fuel = 100 --idToVehicle[vehicleID] -- Get the fuel later
	end
	
	if (health <= 40) then
		hR, hG, hB = 255, 50, 50
	elseif (health > 40) and (health <= 65) then
		hR, hG, hB = 255, 150, 0
	elseif (health > 65) and (health <= 85) then
		hR, hG, hB = 255, 255, 0
	else
		hR, hG, hB = 0, 255, 0
	end
	if (fuel <= 40) then
		fR, fG, fB = 255, 50, 50
	elseif (fuel > 40) and (fuel <= 65) then
		hR, hG, hB = 255, 150, 0
	elseif (fuel > 65) and (fuel <= 85) then
		hR, hG, hB = 255, 255, 0
	else
		fR, fG, fB = 0, 255, 0
	end
	
	guiGridListSetItemText(GUIEditor.gridlist[1], row, 1, tostring(model), false, false)
	guiGridListSetItemText(GUIEditor.gridlist[1], row, 2, tostring(health).."%", false, false)
	guiGridListSetItemText(GUIEditor.gridlist[1], row, 3, tostring(fuel), false, false)
		
	guiGridListSetItemColor(GUIEditor.gridlist[1], row, 2, hR, hG, hB, 255)
	guiGridListSetItemColor(GUIEditor.gridlist[1], row, 3, fR, fG, fB, 255)
	
	guiGridListSetItemData(GUIEditor.gridlist[1], row, 1, vehicleID) -- Vehicle ID
end

function populateGridList()
	--guiGridListClear(GUIEditor.gridlist[1])
	for i, v in pairs(vehicles) do
		if v.ownerID == localPlayer:getData("accountID") then
			updateVehicleGrid(i)
		end
	end
end

function createGUI()
	GUIEditor.window[1] = guiCreateWindow(586, 330, 326, 333, "UCD | Vehicles", false)
	guiWindowSetSizable(GUIEditor.window[1], false)
	guiSetVisible(GUIEditor.window[1], false)
	GUIEditor.gridlist[1] = guiCreateGridList(11, 31, 305, 186, false, GUIEditor.window[1])
	guiGridListAddColumn(GUIEditor.gridlist[1], "Vehicle", 0.5)
	guiGridListAddColumn(GUIEditor.gridlist[1], "HP", 0.2)
	guiGridListAddColumn(GUIEditor.gridlist[1], "Fuel", 0.2)
	guiSetProperty(GUIEditor.gridlist[1], "SortSettingEnabled", "False")
	
	GUIEditor.button[1] = guiCreateButton(11, 247, 66, 32, "Recover", false, GUIEditor.window[1])
	GUIEditor.button[2] = guiCreateButton(91, 247, 66, 32, "Toggle blip", false, GUIEditor.window[1])
	GUIEditor.button[3] = guiCreateButton(171, 247, 66, 32, "Toggle lock", false, GUIEditor.window[1])
	GUIEditor.button[4] = guiCreateButton(251, 247, 66, 32, "Sell", false, GUIEditor.window[1])
	
	GUIEditor.button[5] = guiCreateButton(11, 289, 66, 32, "Spawn", false, GUIEditor.window[1])
	GUIEditor.button[6] = guiCreateButton(91, 289, 66, 32, "Hide", false, GUIEditor.window[1])
	GUIEditor.button[7] = guiCreateButton(171, 289, 66, 32, "Spectate", false, GUIEditor.window[1])
	GUIEditor.button[8] = guiCreateButton(251, 290, 66, 32, "Close", false, GUIEditor.window[1])
	
	--GUIEditor.label[1] = guiCreateLabel(11, 223, 303, 18, "Selected: NRG-500 - LV, Julius Thruway South", false, GUIEditor.window[1])  
	GUIEditor.label[1] = guiCreateLabel(12, 222, 303, 18, "Selected: N/A", false, GUIEditor.window[1])  

	populateGridList()
end
addEventHandler("onClientResourceStart", resourceRoot, createGUI)

function toggleGUI()
	if (not isElement(GUIEditor.window[1])) then
		createGUI()
		--triggerServerEvent("UCDvehicleSystem.getPlayerVehicleTable", localPlayer)
	end
	if (not guiGetVisible(GUIEditor.window[1])) then
		guiSetVisible(GUIEditor.window[1], true)
		--[[for i, v in pairs(vehicles) do
			if v.ownerID == localPlayer:getData("accountID") then
				if idToVehicle[i] then
					updateVehicleGrid(i)
				end
			end
		end
		--]]
		-- We use more memory, but we don't have to loop through the whole vehicle table
		-- Though we should only sync the vehicles that the player owns in the first place, so we just loop through the vehicles table regardless as it won't be massive
		-- This is temporary until we do so
		for i, v in pairs(playerVehicles[localPlayer]) do
			if (idToVehicle[v]) then
				updateVehicleGrid(v)
			end
		end
	else
		guiSetVisible(GUIEditor.window[1], false)
	end
	showCursor(not isCursorShowing())
end
addCommandHandler("vehicles", toggleGUI, false, false)
bindKey("F3", "down", "vehicles")

function handleInput(button, state)
	if (source:getParent() == GUIEditor.gridlist[1] or source:getParent() == GUIEditor.window[1]) then
		local row = guiGridListGetSelectedItem(GUIEditor.gridlist[1])
		-- Instead of nesting this in every elseif
		if (row == -1 or not row or row == nil) then
			GUIEditor.label[1]:setText("Selected: N/A") -- If there is no row we don't display the data
			if (source:getParent() == GUIEditor.window[1] and (source ~= GUIEditor.gridlist[1] and source ~= GUIEditor.button[8])) then
				exports.UCDdx:new("You did not select a vehicle from the list", 255, 0, 0)
				return
			end
			return
		end

		-- We use this throughout the rest of the function
		local vehicleID = guiGridListGetItemData(GUIEditor.gridlist[1], row, 1)
		
		-- The label
		if idToVehicle[vehicleID] then
			local x, y, z = getElementPosition(idToVehicle[vehicleID])
			GUIEditor.label[1]:setText("Selected: "..getVehicleNameFromModel(getVehicleData(vehicleID, "model")).." - "..exports.UCDutil:getCityZoneFromXYZ(x, y, z)..", "..getZoneName(x, y, z))
		else
			local x, y, z = unpack(fromJSON(getVehicleData(vehicleID, "xyz")))
			GUIEditor.label[1]:setText("Selected: "..getVehicleNameFromModel(getVehicleData(vehicleID, "model")).." - "..exports.UCDutil:getCityZoneFromXYZ(x, y, z)..", "..getZoneName(x, y, z))
		end
		
		-- No action can be taken on vehicles that aren't spawned in [EXCEPTION: SELLING THE VEHICLE]
		
		if (source == GUIEditor.button[2]) then
			if (button == "left") and (state == "up") then
				if (idToVehicle == nil or idToVehicle[vehicleID] == nil or not idToVehicle or not idToVehicle[vehicleID]) then
						exports.UCDdx:new("The selected vehicle is not spawned", 255, 0, 0)
						return
				end
				if (blip[vehicleID]) then
					blip[vehicleID]:destroy()
					blip[vehicleID] = nil
				else
					-- Create blip for vehicle
					local vehicle = idToVehicle[vehicleID]
					blip[vehicleID] = createBlipAttachedTo(vehicle, 55)
				end
			end
		elseif (source == GUIEditor.button[3]) then
			if (button == "left") and (state == "up") then
				if (idToVehicle == nil or idToVehicle[vehicleID] == nil or not idToVehicle or not idToVehicle[vehicleID]) then
						exports.UCDdx:new("The selected vehicle is not spawned", 255, 0, 0)
						return
				end
				triggerServerEvent("UCDvehicleSystem.toggleLock", localPlayer, vehicleID)
				outputDebugString("Triggered server UCDvehicleSystem.toggleLock")
			end
		elseif (source == GUIEditor.button[5]) then
			if (button == "left") and (state == "up") then
				triggerServerEvent("UCDvehicleSystem.spawnVehicle", localPlayer, vehicleID)
				outputDebugString("triggered UCDvehicleSystem.spawnVehicle with vehicleID = "..vehicleID)
			end
		elseif (source == GUIEditor.button[6]) then
			if (button == "left") and (state == "up") then
				if (idToVehicle == nil or idToVehicle[vehicleID] == nil or not idToVehicle or not idToVehicle[vehicleID]) then
						exports.UCDdx:new("The selected vehicle is not spawned", 255, 0, 0)
						return
				end
				if (blip[vehicleID]) then
					blip[vehicleID]:destroy()
					blip[vehicleID] = nil
				end
				triggerServerEvent("UCDvehicleSystem.hideVehicle", localPlayer, vehicleID)
			end
		elseif (source == GUIEditor.button[8]) then
			if (button == "left") and (state == "up") then
				toggleGUI()
			end
		end
	end
end
addEventHandler("onClientGUIClick", guiRoot, handleInput)

addEvent("UCDvehicleSystem.playerVehiclesTable", true) 
addEventHandler("UCDvehicleSystem.playerVehiclesTable", root, 
	function (tbl)
		if (type(tbl) ~= "table") then outputDebugString("playerVehicles did not pass table - ["..tostring(tbl).."]") return end
		if (not playerVehicles[source]) then
			playerVehicles[source] = {}
		end
		playerVehicles[source] = tbl
	end
)


--[[
function populateGridList(vehicleTable)
	if (not vehicleTable) then return end
	if (not isElement(GUIEditor.window[1])) then return end
	if (source ~= localPlayer) then return end
	guiGridListClear(GUIEditor.gridlist[1])

	for i, v in pairs(vehicleTable) do
		if (v.ownerID == localPlayer:getData("accountID")) then
			local row = guiGridListAddRow(GUIEditor.gridlist[1])
			local modelID, health, fuel = getVehicleNameFromModel(v.model), v.health, v.fuel
			local health = health / 10
			
			if (health <= 35) then
				hR, hG, hB = 255, 0, 0
			elseif (health > 35) and (health <= 65) then
				hR, hG, hB = 255, 150, 0
			elseif (health > 65) and (health <= 90) then
				hR, hG, hB = 150, 150, 0
			else
				hR, hG, hB = 0, 255, 0
			end
			
			if (fuel <= 35) then
				fR, fG, fB = 255, 0, 0
			elseif (fuel > 35) and (fuel <= 65) then
				fR, fG, fB = 255, 0
			elseif (fuel > 65) and (fuel <= 90) then
				fR, fG, fB = 150, 150, 0
			else
				fR, fG, fB = 0, 255, 0
			end
			
			guiGridListSetItemText(GUIEditor.gridlist[1], row, 1, tostring(modelID), false, false)
			guiGridListSetItemText(GUIEditor.gridlist[1], row, 2, tostring(health).."%", false, false)
			guiGridListSetItemText(GUIEditor.gridlist[1], row, 3, tostring(fuel), false, false)
			
			guiGridListSetItemColor(GUIEditor.gridlist[1], row, 2, hR, hG, hB, 255)
			guiGridListSetItemColor(GUIEditor.gridlist[1], row, 3, fR, fG, fB, 255)
			
			guiGridListSetItemData(GUIEditor.gridlist[1], row, 1, i) -- Vehicle ID
		end
	end
end
addEvent("UCDvehicleSystem.populateGridList", true)
addEventHandler("UCDvehicleSystem.populateGridList", root, populateGridList)


function toggleGUI()
	if (not isElement(GUIEditor.window[1])) then
		createGUI()
		--triggerServerEvent("UCDvehicleSystem.getPlayerVehicleTable", localPlayer)
	end
	if (not guiGetVisible(GUIEditor.window[1])) then
		guiSetVisible(GUIEditor.window[1], true)
		
		-- Sync the vehicle data
		local vehicleTable = {}
		for i, v in pairs(vehicles) do -- vehicles is defined in vehicleData.lua
			if v.ownerID == localPlayer:getData("accountID") then
				if (idToVehicle[i]) then
					vehicleTable[i] = {ownerID = v.ownerID, model = idToVehicle[i]:getModel(), health = idToVehicle[i]:getHealth(), fuel = 100} -- change the 100 to be a way to get fuel
				else
					vehicleTable[i] = v
				end				
			end
		end
		--outputDebugString("gui open")
		if (vehicleTable and #vehicleTable >= 1) then
			triggerEvent("UCDvehicleSystem.populateGridList", localPlayer, vehicleTable)
		end
	else
		guiSetVisible(GUIEditor.window[1], false)
	end
	showCursor(not isCursorShowing())
end
addCommandHandler("vehicles", toggleGUI, false, false)
bindKey("F3", "down", "vehicles")

function createGUI()
	GUIEditor.window[1] = guiCreateWindow(586, 330, 349, 333, "UCD | Vehicles", false)
	guiWindowSetSizable(GUIEditor.window[1], false)
	guiSetVisible(GUIEditor.window[1], false)
	GUIEditor.gridlist[1] = guiCreateGridList(11, 31, 225, 206, false, GUIEditor.window[1])
	guiGridListAddColumn(GUIEditor.gridlist[1], "Name:", 0.5)
	guiGridListAddColumn(GUIEditor.gridlist[1], "Health", 0.2)
	guiGridListAddColumn(GUIEditor.gridlist[1], "Fuel", 0.2)
	guiSetProperty(GUIEditor.gridlist[1], "SortSettingEnabled", "False")
	GUIEditor.button[1] = guiCreateButton(11, 247, 70, 32, "Recover", false, GUIEditor.window[1])
	GUIEditor.button[2] = guiCreateButton(91, 247, 70, 32, "Toggle blip", false, GUIEditor.window[1])
	GUIEditor.button[3] = guiCreateButton(11, 289, 70, 32, "Pick", false, GUIEditor.window[1])
	GUIEditor.button[4] = guiCreateButton(171, 248, 66, 31, "(un)lock", false, GUIEditor.window[1])
	GUIEditor.button[5] = guiCreateButton(91, 289, 67, 32, "Hide", false, GUIEditor.window[1])
	GUIEditor.button[6] = guiCreateButton(171, 290, 66, 31, "Close", false, GUIEditor.window[1])
	populateGridList()
end
addEventHandler("onClientResourceStart", resourceRoot, createGUI)

	GUIEditor.button[1] = guiCreateButton(11, 247, 66, 32, "Recover", false, GUIEditor.window[1])
	GUIEditor.button[2] = guiCreateButton(91, 247, 66, 32, "Toggle blip", false, GUIEditor.window[1])
	GUIEditor.button[4] = guiCreateButton(171, 247, 66, 32, "(un)lock", false, GUIEditor.window[1])
	GUIEditor.button[7] = guiCreateButton(251, 247, 66, 32, "Close", false, GUIEditor.window[1])
	
	GUIEditor.button[3] = guiCreateButton(11, 289, 66, 32, "Pick", false, GUIEditor.window[1])
	GUIEditor.button[5] = guiCreateButton(91, 289, 66, 32, "Hide", false, GUIEditor.window[1])
	GUIEditor.button[6] = guiCreateButton(171, 289, 66, 32, "Close", false, GUIEditor.window[1])
	GUIEditor.button[8] = guiCreateButton(251, 290, 66, 32, "Close", false, GUIEditor.window[1])
--]]
