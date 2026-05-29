---@class XUiGridTheatre6Skill: XUiNode 技能格子
---@field _Control     XTheatre6Control
---@field ImgBgActive  UnityEngine.UI.Image
---@field RImgIcon     UnityEngine.UI.RawImage
---@field RawImgSelect UnityEngine.RectTransform
---@field ImgUpArrow   UnityEngine.RectTransform
---@field Tag          UnityEngine.RectTransform
---@field GridStar     UnityEngine.RectTransform
---@field PanelNew     UnityEngine.RectTransform
---@field ImgMask      UnityEngine.UI.Image
---@field BtnGridSkill XUiComponent.XUiButton
local XUiGridTheatre6Skill = XClass(XUiNode, "XUiGridTheatre6Skill")
local XUiSimpleDrag = require("XUi/XUiTheatre6/Stage/Panel/XUiSimpleDrag")
local DragAction = XEnumConst.Theatre6.DragAction
local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg"
}
local SkillTypeHighlightConfig = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4LightMask",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3LightMask",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1LightMask"
}
function XUiGridTheatre6Skill:OnStart()
    self:ResetClickListener()
    if self.HightLight then
        self.HightLight.gameObject:SetActiveEx(false)
    end
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
    XUiHelper.RefreshCustomizedList(self.Tag.parent, self.Tag, #buildTagCfgs, function (i, grid)
        local cfg = buildTagCfgs[i]
        local ui = {}
        XTool.InitUiObjectByUi(ui, grid)
        if cfg.Icon then
            ui.RImgIcon:SetRawImage(cfg.Icon)
        end
        if ui.HighLight then
            ui.HighLight.gameObject:SetActiveEx(false)
        end
        if ui.TriggerFx then
            ui.TriggerFx.gameObject:SetActiveEx(false)
        end
        self.TagUis[cfg.Id] = ui
    end)
    if self._LastHighLightTagIds then
        self:ShowTagHightLight(self._LastHighLightTagIds)
    end
end

function XUiGridTheatre6Skill:UpdateStarList(starCount)
    self:ClearLevelUpHideTimer()
    if self.GridStarLevelUp and not XTool.UObjIsNil(self.GridStarLevelUp) then
        self.GridStarLevelUp.gameObject:SetActiveEx(false)
    end
    if self.GridStarAnim and not XTool.UObjIsNil(self.GridStarAnim) then
        self.GridStarAnim.gameObject:SetActiveEx(false)
    end
    self.GridStarAnim = nil
    self.GridStarLevelUp = nil
    self.PreUpStarGo = nil
    XUiHelper.RefreshCustomizedList(self.GridStar.transform.parent, self.GridStar, starCount, function (index, go)
        local ui = {}
        XTool.InitUiObjectByUi(ui, go)
        if ui.Animation then
            ui.Animation.gameObject:SetActiveEx(false)
            local animUi = {}
            XTool.InitUiObjectByUi(animUi, ui.Animation)
            if animUi.LevelUp then
                animUi.LevelUp.gameObject:SetActiveEx(false)
            end
            if index == starCount then
                self.GridStarAnim = ui.Animation
                self.GridStarLevelUp = animUi.LevelUp
            end
        end
    end)
    if self._ShowUpgradeEffect then
        self:TryPlayUpgradeEffect()
    end
end

---@param skillId  number  技能ID
---@param readOnly boolean 是否只读(只读时不查询升星状态,避免参数/存档模式下访问实时玩法数据)
function XUiGridTheatre6Skill:Update(skillId, readOnly)
    if self._SkillId ~= skillId then
        self._LastHighLightTagIds = nil
    end
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)

    self.RImgIcon:SetRawImage(skillConfig.Icon)
    -- XUiHelper.SetQualityIcon(nil, self.ImgBgActive, )
    local spriteName = ""
    self.SlotTypes = self._Control:GetSkillInstallSlots(skillId)
    if self.SlotTypes then
        local slotType = self.SlotTypes[1] -- 默认第一个槽位
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
    self:UpdateStarList(skillConfig.Level) -- 星数量
end

-- 状态2：可升星
function XUiGridTheatre6Skill:CanUpgrade(value)
    self.ImgUpArrow.gameObject:SetActiveEx(value)
end

function XUiGridTheatre6Skill:SetClickCb(cb)
    self._ClickCb = cb
end

function XUiGridTheatre6Skill:ShowTagHightLight(ids)
    self._LastHighLightTagIds = ids
    for id, ui in pairs(self.TagUis) do
        if ui.HighLight then
            -- if ui.HighLight.gameObject.name == "HighLight20" then
            --     XLog.Debug("skillid:", self._SkillId, "tagId:", id, "高亮源ids:", ids)
            --     XLog.Debug("技能格子显示高亮",id,ids, table.contains(ids, id),ui.HighLight.name,self.TagUis)
            -- end
            ui.HighLight.gameObject:SetActiveEx(ids and table.contains(ids, id))
        end
    end
end

function XUiGridTheatre6Skill:ShowUpgradeEffect(value)
    self._ShowUpgradeEffect = value
    if value then
        self:TryPlayUpgradeEffect()
    else
        self:ClearLevelUpHideTimer()
        if self.GridStarLevelUp and not XTool.UObjIsNil(self.GridStarLevelUp) then
            self.GridStarLevelUp.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridTheatre6Skill:ClearLevelUpHideTimer()
    if self._LevelUpHideTimer then
        XScheduleManager.UnSchedule(self._LevelUpHideTimer)
        self._LevelUpHideTimer = nil
    end
end

function XUiGridTheatre6Skill:TryPlayUpgradeEffect()
    if not self.GridStarAnim or XTool.UObjIsNil(self.GridStarAnim) then
        return false
    end

    self:ClearLevelUpHideTimer()
    self._ShowUpgradeEffect = false
    self.GridStarAnim.gameObject:SetActiveEx(true)

    local gridStarLevelUp = self.GridStarLevelUp
    if gridStarLevelUp and not XTool.UObjIsNil(gridStarLevelUp) then
        gridStarLevelUp.gameObject:SetActiveEx(true)
        self._LevelUpHideTimer = XScheduleManager.ScheduleOnce(function ()
            self._LevelUpHideTimer = nil
            if not XTool.UObjIsNil(gridStarLevelUp) then
                gridStarLevelUp.gameObject:SetActiveEx(false)
            end
        end, XScheduleManager.SECOND)
    end
    return true
end

-- region 特效
--- 播放 tag 触发特效(2 秒临时态),不影响持久高亮 _LastHighLightTagIds
function XUiGridTheatre6Skill:TriggerTagEffect(ids)
    if not self.TagUis then return end
    for _, ui in pairs(self.TagUis) do
        if ui.TriggerFx then
            ui.TriggerFx.gameObject:SetActiveEx(false)
        end
    end
    local showFx = {}
    for _, id in pairs(ids) do
        if self.TagUis[id] and self.TagUis[id].TriggerFx then
            self.TagUis[id].TriggerFx.gameObject:SetActiveEx(true)
            table.insert(showFx, self.TagUis[id].TriggerFx)
        end
    end
    if #showFx > 0 and self.HightLight then
        if self.GetTimelineTransform("SkillHightLight") then
            self.PlayAnimation("SkillHightLight")
        end

        -- self.HightLight.gameObject:SetActiveEx(true)
        -- table.insert(showFx, self.HightLight)
    end
    XScheduleManager.ScheduleOnce(function ()
        for _, fx in pairs(showFx) do
            if not XTool.UObjIsNil(fx) then
                fx.gameObject:SetActiveEx(false)
            end
        end
    end, XScheduleManager.SECOND * 2)
end

function XUiGridTheatre6Skill:ShowPreLevelUpEffect()
    if self.PreUpStarGo then
        self.PreUpStarGo.transform:SetAsLastSibling()
    else
        self.PreUpStarGo = XUiHelper.Instantiate(self.GridStar, self.GridStar.transform.parent)
        self.PreUpStarUi = {}
        XTool.InitUiObjectByUi(self.PreUpStarUi, self.PreUpStarGo)
    end
    if self.PreUpStarUi.Animation then
        self.PreUpStarUi.Animation.gameObject:SetActiveEx(true)
        XTool.InitUiObjectByUi(self.PreUpStarUi, self.PreUpStarUi.Animation)
        if self.PreUpStarUi.LevelUpTips then
            self.PreUpStarUi.LevelUpTips.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridTheatre6Skill:TriggerLevelUpEffect()
    if not self.PreUpStarUi then
        XLog.Error("未找到预升星特效UI，无法播放升星特效")
        return
    end
    if self.PreUpStarUi.LevelUpTips then
        self.PreUpStarUi.LevelUpTips.gameObject:SetActiveEx(false)
    end
    if self.PreUpStarUi.LevelUpEnable then
        self.PreUpStarUi.LevelUpEnable.gameObject:SetActiveEx(true)
    end
end

--- endregion
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

-- 禁用选中
function XUiGridTheatre6Skill:DisableDragSelect(value)
    self._Drag:GetCloneUi().ImgMask.gameObject:SetActiveEx(value)
end

function XUiGridTheatre6Skill:ShowSelected(value)
    if value and SkillTypeHighlightConfig[self.SlotTypes[1]] then
        local imgKey = self._Control.ImgHighlightKey
        local imgPath = nil
        if self.SlotTypes[1] == XEnumConst.Theatre6.SlotType.Special then
            local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
            local skillType = skillConfig.Type

            if skillType == XEnumConst.Theatre6.SkillType.Insert then
                imgPath = self._Control:GetClientConfigValue(SkillTypeHighlightConfig
                    [XEnumConst.Theatre6.SlotType.Insert], imgKey)
            else
                imgPath = self._Control:GetClientConfigValue(SkillTypeHighlightConfig[self.SlotTypes[1]], imgKey)
            end
        else
            imgPath = self._Control:GetClientConfigValue(SkillTypeHighlightConfig[self.SlotTypes[1]], imgKey)
        end
        self.RawImgSelect:SetRawImage(imgPath)
    end
    self.RawImgSelect.gameObject:SetActiveEx(value)
end

function XUiGridTheatre6Skill:ShowDragSelected(value)
    local imgKey = self._Control.ImgHighlightKey
    if value and SkillTypeHighlightConfig[self.SlotTypes[1]] then
        self._Drag:GetCloneUi().RawImgSelect:SetRawImage(self._Control:GetClientConfigValue(SkillTypeHighlightConfig
                [self.SlotTypes[1]], imgKey))
    end
    self._Drag:GetCloneUi().RawImgSelect.gameObject:SetActiveEx(value)
end

-- region 拖拽

function XUiGridTheatre6Skill:SetDragCb(area, cloneParent, startCb, endCb, enterCb, leaveCb, scrollRect)
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
    self:InitDrag(cloneParent, area, scrollRect)
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

function XUiGridTheatre6Skill:InitDrag(cloneParent, area, scrollRect)
    if self._Drag then
        return
    end
    self._Drag = XUiSimpleDrag.New(self.Transform, self)
    self._Drag:Setup(self.Transform, cloneParent, scrollRect)
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
    local isValid = true
    if self._EnterDragCb then
        if self._EnterDragCb(id) == false then
            isValid = false
        end
    end
    self:DisableDragSelect(not isValid)
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
    self:ClearLevelUpHideTimer()
    self.GameObject:SetActiveEx(false)
    -- XUiHelper.Destroy(self.PreUpStarUi.gameObject)
    
    self.PreUpStarUi = nil
end

function XUiGridTheatre6Skill:ClearNewFlag()
    self.PanelNew.gameObject:SetActiveEx(false)
end

-- endregion

return XUiGridTheatre6Skill
