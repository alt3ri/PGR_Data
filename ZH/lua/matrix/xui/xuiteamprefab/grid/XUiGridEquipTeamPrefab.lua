local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
---@class XUiGridEquipTeamPrefab : XUiGridEquip
local XUiGridEquipTeamPrefab = XClass(XUiGridEquip, "XUiGridEquipTeamPrefab")

-- 刷新装备格子
---@param equipId number 装备ID
function XUiGridEquipTeamPrefab:Refresh(equipId)
    self.EquipId = equipId
    local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
    self.Slot = equipSite
    
    -- 空装备处理
    if not XTool.IsNumberValid(equipId) then
        self:ShowEmptyState()
        return
    end
    
    -- 获取实际装备数据（预设仅存ID，实际属性从玩家装备中取）
    local equip = XMVCA.XEquip:GetEquip(equipId)
    if not equip then
        self:ShowEmptyState()
        return
    end
    
    -- 基础信息刷新（名称、图标等）
    XUiGridEquipTeamPrefab.Super.Refresh(self, equipId)
    
    -- 识别装备分类（武器/意识）
    local templateId = equip.TemplateId
    self.EquipClassify = XMVCA.XEquip:GetEquipClassifyByTemplateId(templateId)
    
    -- 刷新"正在使用"状态
    self:UpdateUsing()
end

-- 显示空状态
function XUiGridEquipTeamPrefab:ShowEmptyState()
    self.PanelEmpty.gameObject:SetActiveEx(true)
    self.PanelEquip.gameObject:SetActiveEx(false)
    self.PanelUsing.gameObject:SetActiveEx(false)
end

-- 更新"正在使用"标记（通过Parent访问父UI数据）
function XUiGridEquipTeamPrefab:UpdateUsing()
    -- 父UI通过Parent访问（父UI需传入self作为第二个参数）
    ---@type XTeamPrefab
    local teamPrefab = self.Parent.TeamPrefab
    local pos = self.Parent.CurrentPos  -- 队伍位置（1-3）
    if not teamPrefab or not pos then 
        return 
    end

    if self.PanelNowPreset then
        local isIn = false
        local targetCharId = nil
        local entityIds = teamPrefab:GetEntityIds()
        for i = 1, #entityIds, 1 do
            local charId = entityIds[i]
            isIn = XDataCenter.TeamManager.CheckEquipIdCharIdTeamIdIsInTeamPrefab(self.EquipId, charId, teamPrefab:GetId())
            if isIn then
                targetCharId = charId
                break
            end
        end
        self.PanelNowPreset.gameObject:SetActiveEx(isIn)
        if isIn then
            self.PanelNowPreset:GetObject("RImgRole"):SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(targetCharId))
        end
    end
end

-- 装备点击事件（通过Parent调用父UI方法）
function XUiGridEquipTeamPrefab:OnBtnClick()
    -- 父UI通过Parent访问
    local teamPrefab = self.Parent.TeamPrefab
    local pos = self.Parent.CurrentPos
    if not teamPrefab or not pos then return end
    
    -- 意识：打开替换界面（父UI的方法通过Parent调用）
    if self.EquipClassify == XEnumConst.EQUIP.CLASSIFY.AWARENESS then
        XLuaUiManager.Open("UiTeamPrefabEquipAwarenessReplace", teamPrefab, pos, self.Slot, function()
            self:Refresh(self.EquipId, self.Slot)
        end)
    -- 武器：打开武器详情（通过Parent调用父UI的方法）
    elseif self.EquipClassify == XEnumConst.EQUIP.CLASSIFY.WEAPON then
        self.Parent:OnWeaponGridClick(self.EquipId)  -- 父UI需实现OnWeaponGridClick方法
    end
end

return XUiGridEquipTeamPrefab