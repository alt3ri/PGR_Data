---@class XUiGridTheatre6Skill : XUiNode 技能格子
---@field _Control XTheatre6Control
---@field ImgBgActive UnityEngine.UI.Image
---@field RImgIcon UnityEngine.UI.RawImage
---@field RawImgSelect UnityEngine.RectTransform
---@field ImgUpArrow UnityEngine.RectTransform
---@field Tag UnityEngine.RectTransform
---@field GridStar UnityEngine.RectTransform
---@field PanelNew UnityEngine.RectTransform
---@field ImgMask UnityEngine.UI.Image
---@field BtnGridSkill XUiComponent.XUiButton
local XUiGridTheatre6Skill = XClass(XUiNode, "XUiGridTheatre6Skill")
local XUiSimpleDrag = require("XUi/XUiTheatre6/Stage/Panel/XUiSimpleDrag")
local DragAction = XEnumConst.Theatre6.DragAction
local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg",
}
local SkillTypeHighlightConfig = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4LightMask",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3LightMask",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1LightMask",
}
function XUiGridTheatre6Skill:OnStart()
    self.SkillTypes = {}
    self:ResetClickListener()
end

function XUiGridTheatre6Skill:ResetClickListener()
    if not self.BtnGridSkill then
        return
    end
    self.BtnGridSkill:AddEventListener(nil)
    self.BtnGridSkill:AddEventListener(handler(self, self.OnBtnGridSkillClick))
end

function XUiGridTheatre6Skill:UpdateTypeIcons(buildTagCfgs)
    self.TagUis = {}
    XUiHelper.RefreshCustomizedList(self.Tag.parent, self.Tag, #buildTagCfgs,
        function(i, grid)
            local cfg = buildTagCfgs[i]
            local ui = {}
            XTool.InitUiObjectByUi(ui, grid)
            if cfg.Icon then
                ui.RImgIcon:SetRawImage(cfg.Icon)
            end
            if ui.HighLight then
                ui.HighLight.gameObject:SetActiveEx(false)
            end
            self.TagUis[cfg.Id] = ui
        end)
    if self._LastTagEffectIds then
        self:ShowTagEffect(self._LastTagEffectIds)
    end
end

function XUiGridTheatre6Skill:UpdateStarList(starCount)
    XUiHelper.RefreshCustomizedList(self.GridStar.transform.parent, self.GridStar, starCount, function(index, go)
        local ui = {}
        XTool.InitUiObjectByUi(ui, go)
        if ui.Animation then
            ui.Animation.gameObject:SetActiveEx(false)
            if index == starCount then
                self.GridStarAnim = ui.Animation
            end
        end
    end)
    if self._ShowUpgradeEffect and self.GridStarAnim then
        self.GridStarAnim.gameObject:SetActiveEx(true)
    end
end

---@param skillId number 技能ID
---@param readOnly boolean 是否只读(只读时不查询升星状态,避免参数/存档模式下访问实时玩法数据)
function XUiGridTheatre6Skill:Update(skillId, readOnly)
    if self._SkillId ~= skillId then
        self._LastTagEffectIds = nil
    end
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)

    self.RImgIcon:SetRawImage(skillConfig.Icon)
    -- XUiHelper.SetQualityIcon(nil, self.ImgBgActive, )
    local spriteName = ""
    self.SlotTypes = self._Control:GetSkillInstallSlots(skillId)
    if self.SlotTypes then
        local slotType = self.SlotTypes[1] --默认第一个槽位
        if slotType then
            spriteName = self._Control:GetClientConfigValue(SkillTypeBgConfigName[slotType], skillConfig.Quality)
        end
    else
        spriteName = self._Control:GetQualityIcon(skillConfig.Quality)
    end

    self.ImgBgActive:SetRawImage(spriteName)
    -- self.PanelNew.gameObject:SetActiveEx(shopData.IsNew)
    -- self.ImgMask.gameObject:SetActiveEx(shopData.IsLocked)
    local buildTagCfg = self._Control:GetShowBuildTagWithSort(skillConfig.BuildTags)
    self:UpdateTypeIcons(buildTagCfg)
    self:UpdateStarList(skillConfig.Level)
    if readOnly then
        self:CanUpgrade(false)
    else
        self:CanUpgrade(self._Control:CharacterHasCanUpGradeSkills(skillId))
    end
end

function XUiGridTheatre6Skill:UpdateBossSkill(skillId)
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)

    self.RImgIcon:SetRawImage(skillConfig.Icon)
    local spriteName = self._Control:GetQualityIcon(skillConfig.Quality)
    self.ImgBgActive:SetRawImage(spriteName)

    self.RawImgSelect.gameObject:SetActiveEx(false)
    self:ClearNewFlag()
    self.ImgMask.gameObject:SetActiveEx(false)
    local buildTagCfg = self._Control:GetShowBuildTagWithSort(skillConfig.BuildTags)
    self:UpdateTypeIcons(buildTagCfg)
    self:UpdateStarList(skillConfig.Level) --星数量
end

--状态2：可升星
function XUiGridTheatre6Skill:CanUpgrade(value)
    self.ImgUpArrow.gameObject:SetActiveEx(value)
end

--状态3有同流派
function XUiGridTheatre6Skill:HasSameSchool(value)
    for key, typeGo in pairs(self.SkillTypes) do
        typeGo.Selected.gameObject:SetActiveEx(value)
    end
end

--激活同流派动画
function XUiGridTheatre6Skill:PlaySameSchoolAnimation()
    if self.EffectGo then
        self.EffectGo.gameObject:SetActiveEx(true)
        XScheduleManager.ScheduleOnce(function()
            if not XTool.UObjIsNil(self.EffectGo) then
                self.EffectGo.gameObject:SetActiveEx(false)
            end
        end, XScheduleManager.SECOND)
    end
end

function XUiGridTheatre6Skill:SetClickCb(cb)
    self._ClickCb = cb
end

function XUiGridTheatre6Skill:ShowTagEffect(ids)
    self._LastTagEffectIds = ids
    for _, ui in pairs(self.TagUis) do
        if ui.HighLight then
            ui.HighLight.gameObject:SetActiveEx(false)
        end
    end
    for k, id in pairs(ids) do
        if self.TagUis[id] and self.TagUis[id].HighLight then
            self.TagUis[id].HighLight.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridTheatre6Skill:ShowUpgradeEffect(value)
    self._ShowUpgradeEffect =  value
end

function XUiGridTheatre6Skill:OnBtnGridSkillClick()
    if self._ClickCb then
        self._ClickCb(self._SkillId)
        return
    end

    -- 打开技能详情
    if self._SkillId then
        self._Control:OpenSkillTip(self._SkillId, self.Transform)
    end
end

--禁用选中
function XUiGridTheatre6Skill:DisableDragSelect(value)
    self._Drag:GetCloneUi().ImgMask.gameObject:SetActiveEx(value)
end

function XUiGridTheatre6Skill:ShowSelected(value)
    if value and SkillTypeHighlightConfig[self.SlotTypes[1]] then
        self.RawImgSelect:SetRawImage(self._Control:GetClientConfigValue(SkillTypeHighlightConfig[self.SlotTypes[1]]))
    end
    self.RawImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridTheatre6Skill:ShowDragSelected(value)
    if value and SkillTypeHighlightConfig[self.SlotTypes[1]] then
        self._Drag:GetCloneUi().RawImgSelect:SetRawImage(self._Control:GetClientConfigValue(SkillTypeHighlightConfig
            [self.SlotTypes[1]]))
    end
    self._Drag:GetCloneUi().RawImgSelect.gameObject:SetActiveEx(value)
end

--region 拖拽

function XUiGridTheatre6Skill:SetDragCb(area, cloneParent, startCb, endCb, enterCb, leaveCb)
    self._StartDragCb = startCb
    self._EndDragCb = endCb
    self._EnterDragCb = enterCb
    self._LeaveDragCb = leaveCb
    if self._Drag then
        self._Drag:ClearTargetAreas()
        if area then
            for index, areaObj in pairs(area) do
                if areaObj and areaObj.transform then
                    self._Drag:AddTargetArea(areaObj.transform, index)
                end
            end
        end
        return
    end
    if not area or not cloneParent then
        return
    end
    self:InitDrag(cloneParent, area)
end

function XUiGridTheatre6Skill:AddDragTargetArea(rectTransform, areaId)
    if self._Drag then
        self._Drag:AddTargetArea(rectTransform, areaId)
    end
end

function XUiGridTheatre6Skill:ClearDrag(restoreClick)
    if self._Drag then
        self._Drag:Destroy()
        self._Drag = nil
    end
    self._StartDragCb = nil
    self._EndDragCb = nil
    self._EnterDragCb = nil
    self._LeaveDragCb = nil
    if restoreClick ~= false then
        self:ResetClickListener()
    end
end

function XUiGridTheatre6Skill:InitDrag(cloneParent, area)
    if self._Drag then
        return
    end
    self._Drag = XUiSimpleDrag.New(self.Transform, self)
    self._Drag:Setup(self.Transform, cloneParent)
    self._Drag:SetTriggerDelay(0.2)
    self.BtnGridSkill:AddEventListener(nil)
    self._Drag:RegisterCallback(DragAction.Click, handler(self, self.OnBtnGridSkillClick))
    self._Drag:RegisterCallback(DragAction.Start, handler(self, self.OnStartChoose))
    self._Drag:RegisterCallback(DragAction.EnterTargetArea, handler(self, self.OnEnterChooseArea))
    self._Drag:RegisterCallback(DragAction.LeaveTargetArea, handler(self, self.OnLeaveChooseArea))
    self._Drag:RegisterCallback(DragAction.End, handler(self, self.OnEndChoose))
    for index, areaObj in pairs(area) do
        if areaObj.transform then
            self._Drag:AddTargetArea(areaObj.transform, index)
        end
    end
end

function XUiGridTheatre6Skill:OnStartChoose()
    self:ShowDragSelected(true)
    if self._StartDragCb then
        self._StartDragCb()
    end
end

function XUiGridTheatre6Skill:OnEnterChooseArea(id)
    if self._EnterDragCb then
        self._EnterDragCb(id)
    end
end

function XUiGridTheatre6Skill:OnLeaveChooseArea()
    self:DisableDragSelect(false)
    if self._LeaveDragCb then
        self._LeaveDragCb()
    end
end

function XUiGridTheatre6Skill:OnEndChoose(id)
    self:ShowDragSelected(false)
    self:DisableDragSelect(false)
    if self._EndDragCb then
        self._EndDragCb(id)
    end
end

function XUiGridTheatre6Skill:GetBuyPrice()
    return self._Control:GetSkillCfgById(self._SkillId).BuyPrice
end

function XUiGridTheatre6Skill:GetDesc()
    return self._Control:GetSkillDesc(self._SkillId, true)
end

function XUiGridTheatre6Skill:GetSkillId()
    return self._SkillId
end

function XUiGridTheatre6Skill:OnDestroy()
    self:ClearDrag(false)
    self.GameObject:SetActiveEx(false)
end

function XUiGridTheatre6Skill:ClearNewFlag()
    self.PanelNew.gameObject:SetActiveEx(false)
end

--endregion

return XUiGridTheatre6Skill
