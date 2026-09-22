-- 一键养成消耗材料 Grid：装备（GridEquip）与道具（GridExpItem）二选一展示，含兑换标签
---@class XUiGridConsume:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field GridEquip UnityEngine.RectTransform
---@field GridExpItem UnityEngine.RectTransform
---@field ImgExchange UnityEngine.RectTransform
---@field TagStar UnityEngine.RectTransform 星级折叠标签（2/3/4 星武器合并时显）
---@field TxtTagStar UnityEngine.UI.Text 星级折叠文本「N星武器」
local XUiGridConsume = XClass(XUiNode, "XUiGridConsume")

function XUiGridConsume:OnStart()
    -- 参考 XUiGridEquipStrengthenConsumptionV2P6：用 InitUiObjectByUi 绑两套子布局节点
    self.EquipGrid = XTool.InitUiObjectByUi({}, self.GridEquip)
    self.ItemGrid = XTool.InitUiObjectByUi({}, self.GridExpItem)
end

--- 刷新一条消耗材料
---@param data table { ItemId, NeedCount, HaveCount, IsEquip, IsExchange, IsStarMerged, Star }
function XUiGridConsume:Update(data)
    self.Data = data
    local isEquip = data.IsEquip == true
    self.GridEquip.gameObject:SetActiveEx(isEquip)
    self.GridExpItem.gameObject:SetActiveEx(not isEquip)

    if isEquip then
        self:_RefreshEquip(data)
    else
        self:_RefreshItem(data)
    end

    -- 兑换标签：该材料需通过商店兑换补足时展示
    if self.ImgExchange then
        self.ImgExchange.gameObject:SetActiveEx(data.IsExchange == true)
    end

    self:_RefreshStarTag(data)
end

-- 星级折叠标签
function XUiGridConsume:_RefreshStarTag(data)
    if not self.TagStar then
        return
    end
    local isStarMerged = data.IsStarMerged == true
    self.TagStar.gameObject:SetActiveEx(isStarMerged)
    if isStarMerged and self.TxtTagStar then
        self.TxtTagStar.text = CS.XTextManager.GetText("EquipOneClickCultureStar", data.Star or 0)
    end
end

-- 武器材料展示
function XUiGridConsume:_RefreshEquip(data)
    local grid = self.EquipGrid
    local templateId = data.ItemId
    grid.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(templateId))
    grid.ImgEquipQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(templateId))
    grid.TxtLevel.text = "x" .. tostring(data.Count or data.NeedCount or 0)
end

-- 道具/经验材料展示
function XUiGridConsume:_RefreshItem(data)
    local grid = self.ItemGrid
    local itemId = data.ItemId
    if not XTool.IsNumberValid(itemId) then
        XLog.Error("XUiGridConsume._RefreshItem: 道具材料 ItemId 无效")
        return
    end
    grid.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    local quality = XDataCenter.ItemManager.GetItemQuality(itemId)
    grid.ImgEquipQuality:SetSprite(XArrangeConfigs.GeQualityPath(quality))
    grid.TxtLevel.text = "x" .. tostring(data.Count or data.NeedCount or 0)
end

return XUiGridConsume
