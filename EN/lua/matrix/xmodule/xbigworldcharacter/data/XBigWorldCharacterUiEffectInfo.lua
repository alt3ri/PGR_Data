---@class XBigWorldCharacterUiEffectInfo
local XBigWorldCharacterUiEffectInfo = XClass(nil, "XBigWorldCharacterUiEffectInfo")

function XBigWorldCharacterUiEffectInfo:Ctor(config)
    local effectIds = config.EffectIds

    self._Effects = {}
    self:SetFashionId(config.FashionId)
    self:SetActionId(config.ActionId)
    self:SetRootName(config.EffectRootName)
    self:SetIsIgnoreRotate(config.IsIgnoreRotate)

    if not XTool.IsTableEmpty(effectIds) then
        for _, effectId in ipairs(effectIds) do
            self:AddEffectId(effectId)
        end
    end
end

function XBigWorldCharacterUiEffectInfo:SetRootName(rootName)
    if not string.IsNilOrEmpty(rootName) then
        self._RootName = rootName
    end
end

function XBigWorldCharacterUiEffectInfo:SetFashionId(fashionId)
    if XTool.IsNumberValid(fashionId) then
        self._FashionId = fashionId
    end
end

function XBigWorldCharacterUiEffectInfo:SetActionId(actionId)
    if not string.IsNilOrEmpty(actionId) then
        self._ActionId = actionId
    end
end

function XBigWorldCharacterUiEffectInfo:SetIsIgnoreRotate(isIgnoreRotate)
    self._IsIgnoreRotate = isIgnoreRotate or false
end

function XBigWorldCharacterUiEffectInfo:GetRootName()
    return self._RootName or ""
end

function XBigWorldCharacterUiEffectInfo:GetFashionId()
    return self._FashionId or 0
end

function XBigWorldCharacterUiEffectInfo:GetActionId()
    return self._ActionId or ""
end

function XBigWorldCharacterUiEffectInfo:GetIsIgnoreRotate()
    return self._IsIgnoreRotate
end

function XBigWorldCharacterUiEffectInfo:AddEffectId(effectId)
    table.insert(self._Effects, effectId)
end

function XBigWorldCharacterUiEffectInfo:GetEffectIdByIndex(index)
    return self._Effects[index] or 0
end

function XBigWorldCharacterUiEffectInfo:GetEffectCount()
    if XTool.IsTableEmpty(self._Effects) then
        return 0
    end

    return #self._Effects
end

function XBigWorldCharacterUiEffectInfo:GetEffectPathByIndex(index)
    local effectId = self:GetEffectIdByIndex(index)

    if not XTool.IsNumberValid(effectId) then
        return ""
    end

    return XMVCA.XBigWorldResource:GetEffectUrl(effectId)
end

function XBigWorldCharacterUiEffectInfo:GetEffectDelayTimeByIndex(index)
    local effectId = self:GetEffectIdByIndex(index)

    if not XTool.IsNumberValid(effectId) then
        return 0
    end

    return XMVCA.XBigWorldResource:GetEffectDelayTime(effectId)
end

return XBigWorldCharacterUiEffectInfo