--
-- Seasonal famring script!!
--

require "Farming/ISUI/ISFarmingMenu"

HCFarmingMenu = {}
HCFarmingMenu.secondMenu = false



HCFarmingMenu.doFarmingMenu = function(player, context, worldobjects, test)
    local sq = nil;
   	local p = getSpecificPlayer(player)
	local currentPlant = nil
	for i,obj in ipairs(worldobjects) do
		sq = obj:getSquare()
		currentPlant = CFarmingSystem.instance:getLuaObjectOnSquare(sq)
		if currentPlant then
			break
		end
	end
	if currentPlant == nil then
		-- fix for plants behind objects
		local x = getMouseXScaled()
		local y = getMouseYScaled()
		local z = p:getZ()
		wx,wy = ISCoordConversion.ToWorld(x, y, z)
		local sq = getCell():getGridSquare(wx,wy,z)
		if sq then
			currentPlant = CFarmingSystem.instance:getLuaObjectOnSquare(sq)
			if currentPlant then
				HCFarmingMenu.secondMenu = true
				ISFarmingMenu.doFarmingMenu2(player, context, {currentPlant}, test)
				HCFarmingMenu.secondMenu = false
			end
		end
	end
	if currentPlant == nil then
		return
	end

	if test and ISWorldObjectContextMenu.Test then return true end

	-- add to the existing farm submenu
	local subMenu = nil
	local farmOption = nil
	for i,v in ipairs(context.options) do
		if v.name == getText("ContextMenu_Sow_Seed") then
			farmOption = v
			subMenu = context:getSubMenu(farmOption.subOption)
		end
	end

end
Events.OnFillWorldObjectContextMenu.Add(HCFarmingMenu.doFarmingMenu)