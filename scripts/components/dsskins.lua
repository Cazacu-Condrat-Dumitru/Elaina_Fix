
local Dsskins = Class(function(self,inst)
    self.inst = inst
	self.skins = nil
    self.skin = nil
	self.build = nil
	self.fx = nil
	self.inst:AddTag("dsskins")
end)

function Dsskins:OnSave()
	return {
	skin = self.skin,
	build = self.build,
	fx = self.fx,
	}
end
local function fly_do_trail(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    if not owner.entity:IsVisible() then
        return
    end

    local x, y, z = owner.Transform:GetWorldPosition()
    if owner.sg ~= nil and owner.sg:HasStateTag("moving") then
        local theta = -owner.Transform:GetRotation() * DEGREES
        local speed = owner.components.locomotor:GetRunSpeed() * .1
        x = x + speed * math.cos(theta)
        z = z + speed * math.sin(theta)
    end
	local map = GetWorld().Map
    local offset = FindValidPositionByFan(
        math.random() * 2 * PI,
         .5 + math.random() * .5,
        4,
        function(offset)
            local pt = Vector3(x + offset.x, 0, z + offset.z)
            return map:GetTileAtPoint(pt:Get())	
                and #TheSim:FindEntities(pt.x, 0, pt.z, .7, { "shadowtrail" }) <= 0 
        end
    )
    if offset ~= nil then
        local fx = SpawnPrefab("cane_ancient_fx") or SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(x + offset.x, 0, z + offset.z)
        end
    end
end
local function cane_equipped(inst,fx,owner)
	if fx == "cane_ancient_fx" then
		if inst._trailtask == nil then
			inst._trailtask = inst:DoPeriodicTask(6 * FRAMES, fly_do_trail, 2 * FRAMES)
		end
	elseif fx == "cane_victorian_fx" then
        if inst.victorian_fx == nil then
            inst.victorian_fx = SpawnPrefab(fx)
            inst.victorian_fx.entity:AddFollower()
        end
        inst.victorian_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -110, 0)	
	else
	    if inst.fire  ~= nil then
			owner:RemoveChild(inst.fire)
			inst.fire:Remove()
			inst.fire = nil
            inst.fire = SpawnPrefab( fx )
            inst.fire:AddTag("INTERIOR_LIMBO_IMMUNE")
            local follower = inst.fire.entity:AddFollower()
            follower:FollowSymbol( owner.GUID, "swap_object", 0, -110, 0 )			
		end
	end
end
local function cane_unequipped(inst)
    if inst._trailtask ~= nil then
        inst._trailtask:Cancel()
        inst._trailtask = nil
    end
    if inst.victorian_fx ~= nil then
        inst.victorian_fx:Remove()
        inst.victorian_fx = nil
    end
    if inst.fire ~= nil  then
        owner:RemoveChild(inst.fire)
        inst.fire:Remove()
        inst.fire = nil
    end
end
function Dsskins:Changeskin()
	if self.skin ~= nil  then
			self.inst.AnimState:SetBuild(self.skin)
			if self.inst.components.inventoryitem then	
				if  self.inst.prefab == "armorwood" or self.inst.prefab == "armorgrass" or self.inst.prefab == "armormarble" or self.inst.prefab == "armordragonfly" or self.inst.prefab == "armulet" then
					self.inst.AnimState:SetBank(self.skin)
					self.inst.AnimState:PlayAnimation("anim")
				end
				if self.inst.prefab == "krampus_sack" or self.inst.prefab == "icepack" or self.inst.prefab == "seasack" or self.inst.prefab == "piggyback" then -- Krampus sack and insulated packs use the standard backpack bank
					self.inst.AnimState:SetBank("backpack1")
				end
				if self.skin == "backcub" then
					self.inst.AnimState:SetBank(self.skin)
					self.inst.AnimState:PlayAnimation("anim",true)				
				end
				self.inst.components.inventoryitem.imagename = self.skin
				self.inst.components.inventoryitem.atlasname = "images/inventoryimages/"..self.skin..".xml"
					if self.inst.components.equippable then
						self.inst:ListenForEvent("equipped", function(inst,data)
							if data.owner ~= nil then
								if inst.components.equippable.equipslot == EQUIPSLOTS.HANDS then
									if self.build ~= nil then
										data.owner.AnimState:OverrideSymbol("swap_object", "swap_"..self.skin, self.build)
									end
									if self.fx ~= nil then
										cane_equipped(inst,self.fx,data.owner)
										inst:ListenForEvent("unequipped", cane_unequipped)
									end
								end
								if inst.components.equippable.equipslot == EQUIPSLOTS.BACK  then ---for  other mods
									data.owner.AnimState:OverrideSymbol("swap_body", self.skin, "swap_body")
								end
								if inst.components.equippable.equipslot == EQUIPSLOTS.BODY  then
									data.owner.AnimState:OverrideSymbol("swap_body", self.skin, "swap_body")
								end
								if inst.components.equippable.equipslot == EQUIPSLOTS.PACK then
									data.owner.AnimState:OverrideSymbol("swap_body", self.skin, "swap_body")
								end
                                if inst.components.equippable.equipslot == EQUIPSLOTS.NECK then
									data.owner.AnimState:OverrideSymbol("swap_body", self.skin, "swap_body") 
								end	
								if inst.components.equippable.equipslot == EQUIPSLOTS.HEAD then
									if  inst.prefab == "minerhat" then 
									return
									end
									data.owner.AnimState:OverrideSymbol("swap_hat", self.skin, "swap_hat")	
								end
							end
						end)
					end
			end
    end
end

function Dsskins:OnLoad(data)
	if data.skin ~= nil  then
        self.skin = data.skin
		if data.build ~= nil then
		self.build = data.build
		end
		if data.fx ~= nil then
		self.fx = data.fx
		end
		self:Changeskin()
	end
end
return Dsskins