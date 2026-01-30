local XUiPanelEquipV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiPanelEquipV2P6")
local XUiGridEquipTeamPrefab = require("XUi/XUiTeamPrefab/Grid/XUiGridEquipTeamPrefab")
local XUiGridResonanceSkillTeamPrefab = require("XUi/XUiTeamPrefab/Grid/XUiGridResonanceSkillTeamPrefab")

-- 预设专用装备面板（继承自原版装备面板）
---@class XUiPanelTeamPrefabEquip:XUiPanelEquipV2P6
local XUiPanelTeamPrefabEquip = XClass(XUiPanelEquipV2P6, "XUiPanelTeamPrefabEquip")

-- 初始化预设数据
--- func desc
---@param teamPrefab XTeamPrefab
function XUiPanelTeamPrefabEquip:InitTeamPrefabData(teamPrefab, pos)
    self.TeamPrefab = teamPrefab
    self.CurrentPos = pos
    self.CharacterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)
    self.IsShowPanelAwareness = true
end

-- 刷新意识面板
function XUiPanelTeamPrefabEquip:UpdateAwarenessView()
    local characterId = self.CharacterId
    local curr = 0
    local haveAwareness = false
    for _, equipSite in pairs(XEnumConst.EQUIP.EQUIP_SITE.AWARENESS) do
        self.WearingAwarenessGrids[equipSite] = self.WearingAwarenessGrids[equipSite] or XUiGridEquipTeamPrefab.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), self.RootUi)
        self.WearingAwarenessGrids[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)

        local eqpData = self.TeamPrefab:GetAwarenessData(self.CurrentPos, equipSite)
        local equipId = eqpData and eqpData.EquipId
        if not equipId then
            self.WearingAwarenessGrids[equipSite]:Close()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            haveAwareness = true
            self.WearingAwarenessGrids[equipSite]:Open()
            self["BtnAwarenessReplace" .. equipSite].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(false)
            self.WearingAwarenessGrids[equipSite]:Refresh(equipId)

            -- 检查有多少个激活的公约标识
            local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite)
            if chapterData and chapterData:IsOccupy() then
                for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
                    local bindCharId = XMVCA.XEquip:GetResonanceBindCharacterId(equipId, i)
                    local awaken = XMVCA.XEquip:IsEquipPosAwaken(equipId, i)
                    if awaken and bindCharId == characterId then
                        curr = curr + 1
                    end
                end
            end
        end
    end
    self.BtnAutoTakeOff.gameObject:SetActiveEx(haveAwareness)
    
    -- 公约加成
    self.TxtOcuupyHarm.text =  CS.XTextManager.GetText("AwarenessTotalHarm", curr)

    -- 套装数量
    self:UpdatePanelSuitCount()

    -- 共鸣技能
    self:UpdatePanelResonanceSkill()
end

-- 刷新套装数量列表
function XUiPanelTeamPrefabEquip:UpdatePanelSuitCount()
    if not self.SuitItemList then
        self.SuitItemList = {self.SuitItem}
    end

    -- 隐藏所有
    for _, suitItem in ipairs(self.SuitItemList) do
        suitItem.gameObject:SetActiveEx(false)
    end
    self.SuitOverrunItem.gameObject:SetActiveEx(false)

    -- 套装列表
    local suitInfoList = self.TeamPrefab:GetWearingSuitInfoListByPos(self.CurrentPos)

    local itemIndex = 1
    local haveSuit = false
    for i, suitInfo in ipairs(suitInfoList) do
        if suitInfo.Count ~= 1 then
            haveSuit = true
            local itemGo
            if suitInfo.IsOverrun then
                itemGo = self.SuitOverrunItem
            else
                itemGo = self.SuitItemList[itemIndex]
                if not itemGo then
                    itemGo = XUiHelper.Instantiate(self.SuitItem, self.SuitItem.transform.parent)
                    table.insert(self.SuitItemList, itemGo)
                end
                itemIndex = itemIndex + 1
            end

            itemGo.gameObject:SetActiveEx(true)
            itemGo.transform:SetAsLastSibling()
            local uiObj = itemGo:GetComponent("UiObject")
            uiObj:GetObject("TxtSuitName").text = suitInfo.Name
            uiObj:GetObject("TxtSuitCount").text = suitInfo.Count
        end
    end
    self.PanelNoAddition.gameObject:SetActiveEx(not haveSuit)
    self.BtnAddition.gameObject:SetActiveEx(haveSuit)
end

-- 刷新共鸣技能面板
function XUiPanelTeamPrefabEquip:UpdatePanelResonanceSkill()
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.DoubleResonanceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridDoubleResonanceSkill, self.PanelResonanceSkill)
            grid = XUiGridResonanceSkillTeamPrefab.New(go, self.RootUi)
            self.DoubleResonanceList[index] = grid
            grid.GameObject:SetActive(true)
        end

        grid:SetForbidGotoEquip(true)
        grid:RefreshBySite(self.CharacterId, index)
    end
end

function XUiPanelTeamPrefabEquip:OnBtnAutoTakeOffClick()
    self.TeamPrefab:ClearAwarenessData(self.CurrentPos)
    self:UpdateAwarenessView()
end

function XUiPanelTeamPrefabEquip:OnAwarenessClick(site)
    if self.ForbidGotoEquip then return end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Equip) then
        return
    end

    XLuaUiManager.Open("UiTeamPrefabEquipAwarenessReplace", self.TeamPrefab, self.CurrentPos, site,  true)
end

function XUiPanelTeamPrefabEquip:OnBtnAwarenessSuitClick()
    XLuaUiManager.Open("UiEquipAwarenessSuitPrefab", self.CharacterId, function(equipIds)
        if XLuaUiManager.IsUiShow("UiEquipAwarenessPopup") then
            XLuaUiManager.Close("UiEquipAwarenessPopup")
        end
        
        local conflictInfoList, doUpdate = self.TeamPrefab:UpdateAwarenessEquipList(self.CurrentPos, equipIds)
        if conflictInfoList and doUpdate then
            XLuaUiManager.Open("UiEquipSuitPrefabConflict", conflictInfoList, function ()
                doUpdate()
                self:UpdateAwarenessView()
            end)
        else
            self:UpdateAwarenessView()
        end
    end, true)
end

-- 替换原OnPanelAdditionClick方法中的打开逻辑
function XUiPanelTeamPrefabEquip:OnPanelAdditionClick()
    XLuaUiManager.Open("UiTeamPrefabEquipSuitSkill", self.TeamPrefab, self.CurrentPos)
end

return XUiPanelTeamPrefabEquip
