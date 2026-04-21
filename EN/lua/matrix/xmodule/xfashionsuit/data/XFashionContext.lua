---@class XFashionContext 涂装上下文
local XFashionContext = XClass(nil, "XFashionContext")

local FashionStatus = XDataCenter.FashionManager.FashionStatus
local WeaponStatus = XDataCenter.WeaponFashionManager.FashionStatus

function XFashionContext:Ctor()
    self._IsGroup = false
    self._Handlers = {}
end

function XFashionContext:InitData(id)
    self.SourceId = id
    self.FashionGroup = XMVCA.XFashionSuit:GetFashionGroupByFashionId(id)
    self:UpdateData()
end

function XFashionContext:UpdateData()
    self.FashionId = nil
    self.WeaponFashionId = nil
    self.CharacterId = nil

    if self._IsGroup then
        self.FashionId = self.FashionGroup.FashionId
        self.WeaponFashionId = self.FashionGroup.WeaponFashionId
        self.CharacterId = self.FashionGroup.CharacterId
    else
        if XWeaponFashionConfigs.IsWeaponFashion(self.SourceId) then
            self.WeaponFashionId = self.SourceId
            local characterIds = XMVCA.XCharacter:GetCharacterIdsByWeaponFashion(self.WeaponFashionId)
            self.CharacterId = characterIds and characterIds[1] --注意：可能存在一个武器涂装对应多个角色的问题，这里取优先级最高的
        else
            self.FashionId = self.SourceId
            self.CharacterId = XFashionConfigs.GetFashionTemplate(self.FashionId).CharacterId
        end
    end
end

function XFashionContext:SwitchToGroup()
    self._IsGroup = true
    self:UpdateData()
end

function XFashionContext:SwitchToSingle()
    self._IsGroup = false
    self:UpdateData()
end

function XFashionContext:GetParams(id)
    return id == self.FashionGroup.FashionId and self.FashionGroup.FashionGainParams or self.FashionGroup.WeaponFashionGainParams
end

function XFashionContext:GetCurParams()
    return self:GetParams(self.SourceId)
end

---@param func fun(id:number,fashionType:number)
function XFashionContext:ApplyFashion(func)
    if self.FashionId then
        func(self.FashionId, XEnumConst.FashionSuit.FashionType.Character)
    end
    if self.WeaponFashionId then
        func(self.WeaponFashionId, XEnumConst.FashionSuit.FashionType.Weapon)
    end
end

function XFashionContext:GetAction()
    local params = {}
    if self.FashionId then
        local isHave = XDataCenter.FashionManager.CheckHasFashion(self.FashionId) and XDataCenter.FashionManager.IsFashionInTime(self.FashionId)
        if not isHave then
            table.insert(params, self.FashionId)
        end
    end
    if self.WeaponFashionId then
        local isHave = XDataCenter.WeaponFashionManager.CheckHasFashion(self.WeaponFashionId) and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.WeaponFashionId)
        if not isHave then
            table.insert(params, self.WeaponFashionId)
        end
    end
    if #params > 0 then
        return XEnumConst.FashionSuit.Action.Buy, params
    end

    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if character and character.RandomFashion then
        params = {}
        if self.FashionId and not XDataCenter.FashionManager.IsFashionRandom(self.FashionId) then
            table.insert(params, self.FashionId)
        end
        if self.WeaponFashionId and not XDataCenter.FashionManager.IsWeaponFashionRandom(self.WeaponFashionId) then
            table.insert(params, self.WeaponFashionId)
        end
        return XEnumConst.FashionSuit.Action.JoinRandom, params
    end

    params = {}
    if self.FashionId and not XMVCA.XFashionSuit:IsFashionDressed(self.FashionId) then
        table.insert(params, self.FashionId)
    end
    if self.WeaponFashionId and not XMVCA.XFashionSuit:IsWeaponFashionDressed(self.WeaponFashionId, self.CharacterId) then
        table.insert(params, self.WeaponFashionId)
    end
    return XEnumConst.FashionSuit.Action.Wear, params
end

---@param func fun(characterId:number,todoQueue:number[])
function XFashionContext:RegistActionHandlers(actionType, func)
    self._Handlers[actionType] = func
end

function XFashionContext:AppyActionHandler()
    local action, params = self:GetAction()
    if self._Handlers[action] then
        self._Handlers[action](self.CharacterId, params)
    end
end

return XFashionContext