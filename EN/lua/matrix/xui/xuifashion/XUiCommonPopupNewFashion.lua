local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiCommonPopupNewFashion : XLuaUi 快捷涂装穿戴弹框
local XUiCommonPopupNewFashion = XLuaUiManager.Register(XLuaUi, "UiCommonPopupNewFashion")

function XUiCommonPopupNewFashion:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiCommonPopupNewFashion:OnStart(rewardGoodDict)
    ---@type table<XTableFashionGroup,number[]>
    self._GroupRewards = {}
    self._NormalRewards = {}
    self:InitData(rewardGoodDict)
    self:ShowGroupList()
    self:ShowNormalList()
end

function XUiCommonPopupNewFashion:InitData(rewardGoodDict)
    for id, rewardData in pairs(rewardGoodDict) do
        self._NormalRewards[id] = rewardData
    end
    for id, reward in pairs(rewardGoodDict) do
        if reward.RewardType == XRewardManager.XRewardType.Fashion then
            local fashionGroup = XMVCA.XFashionSuit:GetFashionGroupByFashionId(id)
            if fashionGroup then
                local weaponFashionId = fashionGroup.WeaponFashionId
                local rewardData = rewardGoodDict[weaponFashionId]
                if rewardData then
                    --[1]=角色涂装 [2]=武器涂装
                    self._GroupRewards[fashionGroup] = { reward, rewardData }
                    self._NormalRewards[id] = nil
                    self._NormalRewards[weaponFashionId] = nil
                end
            end
        end
    end
end

function XUiCommonPopupNewFashion:ShowGroupList()
    if XTool.IsTableEmpty(self._GroupRewards) then
        self.ListFashionGroup.gameObject:SetActiveEx(false)
        return
    end
    
    self.ListFashionGroup.gameObject:SetActiveEx(true)
    local i = 1
    for fashionGroup, rewardDatas in pairs(self._GroupRewards) do
        --是否开启随机套装
        local characterId = fashionGroup.CharacterId
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        local randomFashion = character and character.RandomFashion

        local fashionIds = { fashionGroup.FashionId, fashionGroup.WeaponFashionId }
        local list = i == 1 and self.ListFashionGroup or XUiHelper.Instantiate(self.ListFashionGroup, self.ListFashionGroup.parent)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, list)
        XUiHelper.RefreshCustomizedList(uiObject.GridCommon.parent, uiObject.GridCommon, #fashionIds, function(i, go)
            local grid = XUiGridCommon.New(self, go)
            grid:Refresh(rewardDatas[i], { Disable = true }, nil, false)
            grid:ShowCount(false)
        end, true)
        --注册点击按钮
        if randomFashion then
            uiObject.BtnRandom:AddEventListener(function()
                self:OnJoinRandom(characterId, fashionIds[1], fashionIds[2], uiObject.BtnRandom)
            end)
        else
            uiObject.BtnWear:AddEventListener(function()
                self:OnWearFashions(characterId, fashionIds, uiObject.BtnWear)
            end)
        end
        uiObject.BtnRandom.gameObject:SetActiveEx(randomFashion)
        uiObject.BtnWear.gameObject:SetActiveEx(not randomFashion)
        i = i + 1
    end
end

function XUiCommonPopupNewFashion:ShowNormalList()
    if XTool.IsTableEmpty(self._NormalRewards) then
        self.ListFashion.gameObject:SetActiveEx(false)
        return
    end
    
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(self._NormalRewards)
    self.ListFashion.gameObject:SetActiveEx(true)
    XUiHelper.RefreshCustomizedList(self.GridCommon.parent, self.GridCommon, #rewards, function(i, go)
        local data = rewards[i]
        local isWeaponFashion = data.RewardType ~= XRewardManager.XRewardType.Fashion
        local id = isWeaponFashion and XDataCenter.ItemManager.GetWeaponFashionId(data.TemplateId) or data.TemplateId
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(data, { Disable = true }, nil, false)
        grid:ShowCount(false)
        --根据涂装Id获取角色Id
        local characterId
        if isWeaponFashion then
            local characterIds = XMVCA.XCharacter:GetCharacterIdsByWeaponFashion(id)
            characterId = characterIds and characterIds[1] --注意：可能存在一个武器涂装对应多个角色的问题，这里取优先级最高的
        else
            characterId = XDataCenter.FashionManager.GetCharacterId(id)
        end
        --是否开启随机套装
        local character = XMVCA.XCharacter:GetCharacter(characterId)
        local randomFashion = character and character.RandomFashion
        --注册点击按钮
        if randomFashion then
            grid.BtnRandom:AddEventListener(function()
                if isWeaponFashion then
                    self:OnJoinRandom(characterId, nil, id, grid.BtnRandom)
                else
                    self:OnJoinRandom(characterId, id, nil, grid.BtnRandom)
                end
            end)
        else
            grid.BtnWear:AddEventListener(function()
                self:OnWearFashion(characterId, id, grid.BtnWear)
            end)
        end
        grid.BtnRandom.gameObject:SetActiveEx(randomFashion)
        grid.BtnWear.gameObject:SetActiveEx(not randomFashion)
    end)
end

---@param btn XUiComponent.XUiButton 穿戴按钮
function XUiCommonPopupNewFashion:OnWearFashions(characterId, fashionIds, btn)
    XMVCA.XFashionSuit:RecursionUseFashion(characterId, fashionIds, function()
        XUiManager.TipText("UseSuccess")
        if btn then
            btn:SetDisable(true, false)
        end
    end)
end

---@param btn XUiComponent.XUiButton 穿戴按钮
function XUiCommonPopupNewFashion:OnWearFashion(characterId, fashionId, btn)
    XMVCA.XFashionSuit:UseFashion(characterId, fashionId, function()
        XUiManager.TipText("UseSuccess")
        if btn then
            btn:SetDisable(true, false)
        end
    end)
end

---@param btn XUiComponent.XUiButton 随机涂装按钮
function XUiCommonPopupNewFashion:OnJoinRandom(characterId, fashionId, weaponFashionId, btn)
    XMVCA.XFashionSuit:JoinFashionToRandom(characterId, fashionId, weaponFashionId, function()
        XUiManager.TipText("FashionAddToRandomTip")
        if btn then
            btn:SetDisable(true, false)
        end
    end)
end

return XUiCommonPopupNewFashion