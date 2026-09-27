local HuaPetLeash = Class(function(self, inst)
    self.inst = inst

    self.petprefab = nil
    self.pets = {}
    self.maxpets = 1
    self.numpets = 0
	
	self.travel = nil

    self.onspawnfn = nil
    self.ondespawnfn = nil

    self._onremovepet = function(pet)
        if self.pets[pet] ~= nil then
            self.pets[pet] = nil
            self.numpets = self.numpets - 1
        end
		if  self.inst.components.leader and self.inst.components.leader.followers[pet] then
			self.inst.components.leader:RemoveFollower(pet)
		end
    end
end)

function HuaPetLeash:SetPetPrefab(prefab)
    self.petprefab = prefab
end

function HuaPetLeash:SetOnSpawnFn(fn)
    self.onspawnfn = fn
end

function HuaPetLeash:SetOnDespawnFn(fn)
    self.ondespawnfn = fn
end

function HuaPetLeash:SetMaxPets(num)
    self.maxpets = num
end

function HuaPetLeash:GetMaxPets()
    return self.maxpets
end

function HuaPetLeash:GetNumPets()
    return self.numpets
end

function HuaPetLeash:IsFull()
    return self.numpets >= self.maxpets
end

function HuaPetLeash:HasPetWithTag(tag)
    for k, v in pairs(self.pets) do
        if v:HasTag(tag) then
            return true
        end
    end
    return false
end

function HuaPetLeash:GetPets()
    return self.pets
end

function HuaPetLeash:IsPet(pet)
    return self.pets[pet] ~= nil
end

function HuaPetLeash:LoadPet(pet)
    self.pets[pet] = pet
    self.numpets = self.numpets + 1
    self.inst:ListenForEvent("onremove", self._onremovepet, pet)
	
    if self.inst.components.leader ~= nil then
        self.inst.components.leader:AddFollower(pet)
    end
end

local function TravelPet(self,pet)
    local theta = math.random() * 2 * PI
    local pt = self.inst:GetPosition()
    local radius = 1
    local offset = FindWalkableOffset(pt, theta, radius, 6, true)
    if offset ~= nil then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    end
    if pet.Physics ~= nil then
        pet.Physics:Teleport(pt.x, 0, pt.z)
    elseif pet.Transform ~= nil then
        pet.Transform:SetPosition(pt.x, 0, pt.z)
    end
    if self.onspawnfn ~= nil then
        self.onspawnfn(self.inst, pet)
    end
	self.travel = nil
end

local function LinkPet(self, pet,skin)
	if skin ~= nil  and pet.components.dsskins then
		pet.components.dsskins.skin = skin
		pet.components.dsskins:Changeskin()
	end
end

function HuaPetLeash:SpawnPetAt(x, y, z, prefaboverride,skin)
    local petprefab = prefaboverride or self.petprefab
	local skin = skin or nil
    if self.numpets >= self.maxpets or petprefab == nil then
        return
    end
    local pet = SpawnPrefab(petprefab)
    if pet ~= nil then
        LinkPet(self, pet, skin)

        if pet.Physics ~= nil then
            pet.Physics:Teleport(x, y, z)
        elseif pet.Transform ~= nil then
            pet.Transform:SetPosition(x, y, z)
        end
        if self.onspawnfn ~= nil then
            self.onspawnfn(self.inst, pet)
        end
    end
end

function HuaPetLeash:DespawnPet(pet)
    if self.pets[pet] ~= nil then
        if self.ondespawnfn ~= nil then
            self.ondespawnfn(self.inst, pet)
        else
            pet:Remove()
        end
    end
end

function HuaPetLeash:DespawnAllPets()
    local toremove = {}
    for k, v in pairs(self.pets) do
        table.insert(toremove, v)
    end
    for i, v in ipairs(toremove) do
        self:DespawnPet(v)
    end
end

function HuaPetLeash:OnTravel()
	if next(self.pets) ~= nil then
        local data = {}
        for k, v in pairs(self.pets) do
            local saved--[[, refs]] = v:GetSaveRecord()
            table.insert(data, saved)
			v:Remove()
			self.travel = { pets = data }
        end
    end
end

function HuaPetLeash:OnSave()
	if self.travel ~= nil then
		return self.travel
    end
	return nil
end

function HuaPetLeash:OnLoad(data)
    if data ~= nil and data.pets ~= nil then
        for i, v in ipairs(data.pets) do
            local pet = SpawnSaveRecord(v)
            if pet ~= nil then
				TravelPet(self,pet)
            end
        end
    end
end

function HuaPetLeash:OnRemoveFromEntity()
    for k, v in pairs(self.pets) do
        self.inst:RemoveEventCallback("onremove", self._onremovepet, v)
    end
end
--c_gonext("critterlab")
HuaPetLeash.OnRemoveEntity = HuaPetLeash.DespawnAllPets

return HuaPetLeash
