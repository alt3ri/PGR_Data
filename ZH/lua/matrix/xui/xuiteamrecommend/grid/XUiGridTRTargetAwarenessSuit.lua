-- 引用LuaUi：UiTeamRecommendMain、UiTeamRecommendDetail
---@class XUiGridTRTargetAwarenessSuit : XUiNode 目标卡片意识套装格子（按套装分组，死数据）
local XUiGridTRTargetAwarenessSuit = XClass(XUiNode, "XUiGridTRTargetAwarenessSuit")

-- 注册意识套装点击事件
function XUiGridTRTargetAwarenessSuit:OnStart()
    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

---@param suitId number 套装ID
---@param count number 该套装件数
---@param resonanceSkillList table[] {{ SkillId, ResonanceType, Count }, ...} 已排序的共鸣技能列表
function XUiGridTRTargetAwarenessSuit:Refresh(suitId, count, resonanceSkillList)
    if not XTool.IsNumberValid(suitId) then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.SuitId = suitId

    -- 图标（用套装图标）
    self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipSuitIconPath(suitId))

    -- 名称（用套装名）
    self.TxtName.text = XMVCA.XEquip:GetSuitName(suitId)

    -- 品质底图
    local quality = XMVCA.XEquip:GetSuitQuality(suitId)
    XUiHelper.SetQualityIcon(self.Parent, self.ImgQuality, quality)

    -- 件数
    if self.TxtCount then
        self.TxtCount.transform.parent.gameObject:SetActiveEx(true)
        self.TxtCount.gameObject:SetActiveEx(true)
        self.TxtCount.text = "×" .. count
    end

    -- 共鸣技能格子
    self:RefreshResonanceSkills(resonanceSkillList)
end

local function OnResonanceSkillGridClick(grid)
    grid.Parent:OnResonanceSkillClick(grid.SkillData)
end

--- 刷新共鸣技能格子列表
---@param resonanceSkillList table[] {{ SkillId, ResonanceType, Count }, ...} 已排序的共鸣技能列表
function XUiGridTRTargetAwarenessSuit:RefreshResonanceSkills(resonanceSkillList)
    if not self.GridResnanceSkill then
        return
    end
    self.GridResnanceSkill.gameObject:SetActiveEx(false)
    if not self.ResonanceGridList then
        self.ResonanceGridList = {}
    end
    -- 隐藏所有已有格子
    for _, grid in ipairs(self.ResonanceGridList) do
        grid.GameObject:SetActiveEx(false)
    end
    -- 无共鸣技能
    if not resonanceSkillList or #resonanceSkillList == 0 then
        return
    end

    for i, skillData in ipairs(resonanceSkillList) do
        local grid = self.ResonanceGridList[i]
        if not grid then
            local go
            if i == 1 then
                go = self.GridResnanceSkill
            else
                go = XUiHelper.Instantiate(self.GridResnanceSkill, self.GridResnanceSkill.transform.parent)
            end
            grid = { GameObject = go.gameObject, Transform = go.transform }
            XTool.InitUiObject(grid)
            grid.Parent = self
            XUiHelper.RegisterClickEvent(grid, grid.RImgResonanceSkill, OnResonanceSkillGridClick)
            self.ResonanceGridList[i] = grid
        end
        grid.SkillData = skillData
        grid.GameObject:SetActiveEx(true)
        grid.Transform:SetAsLastSibling()

        -- 图标：归一化数据已包含ResonanceType
        local skillId = skillData.SkillId
        local rType = skillData.ResonanceType
        local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(rType, skillId)
        if skillInfo and skillInfo.Icon and grid.RImgResonanceSkill then
            grid.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
        end

        -- 个数标签
        if grid.TagNum then
            grid.TagNum.gameObject:SetActiveEx(skillData.Count > 0)
        end
        if grid.TxtNum then
            grid.TxtNum.text = skillData.Count
        end

        if grid.PanelAwaken then
            grid.PanelAwaken.gameObject:SetActiveEx(false)
        end
    end
end

-- 打开聚合共鸣技能首个对应槽位
function XUiGridTRTargetAwarenessSuit:OnResonanceSkillClick(skillData)
    self.Parent:OnAwarenessResonanceSkillClick(self.SuitId, skillData)
end

-- 打开意识套装获取详情
function XUiGridTRTargetAwarenessSuit:OnBtnClick()
    if XTool.IsNumberValid(self.SuitId) then
        XLuaUiManager.Open("UiTeamRecommendEquipItemInfo", self.SuitId, true)
    end
end

return XUiGridTRTargetAwarenessSuit
