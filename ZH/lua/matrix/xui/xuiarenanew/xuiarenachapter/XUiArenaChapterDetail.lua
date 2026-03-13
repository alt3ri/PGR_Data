local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArenaChapterDetailGridBuff = require("XUi/XUiArenaNew/XUiArenaChapter/XUiArenaChapterDetailGridBuff")

---@class XUiArenaChapterDetail : XLuaUi
---@field PanelAsset UnityEngine.RectTransform
---@field BtnFight XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtTips UnityEngine.UI.Text
---@field PanelBuff UnityEngine.RectTransform
---@field GridBuff UnityEngine.RectTransform
---@field ListTitle XUiButtonGroup
---@field GridTitle XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field TxtEnvironment UnityEngine.UI.Text
---@field TxtBestRecord UnityEngine.UI.Text
---@field TxtNew UnityEngine.UI.Text
---@field PanelTitle UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaChapterDetail = XLuaUiManager.Register(XLuaUi, "UiArenaChapterDetail")

-- region 生命周期

function XUiArenaChapterDetail:OnAwake()
    ---@type XUiArenaChapterDetailGridBuff[]
    self._BuffGridList = {}
    ---@type XUiComponent.XUiButton[]
    self._BtnListTitleList = {}
    ---@type XArenaAreaData
    self._AreaData = nil
    ---@type XUiArenaScene
    self._Scene = nil
    self._CurrentSelectBuffIndex = 1
    self._CurrentSelectZoneIndex = 1
    self._IsReOpen = false

    self:_InitUi()
    self:_RegisterButtonClicks()
end

---@param areaData XArenaAreaData
function XUiArenaChapterDetail:OnStart(areaData, selectIndex, scene)
    self._AreaData = areaData
    self._CurrentSelectZoneIndex = selectIndex
    self._Scene = scene

    self._Scene:SetZonesSelectEvent(Handler(self, self.OnZoneSelectClick))
    self._Scene:RefreshPlayerGrid(selectIndex, self:_GetCurrentAreaShowData())
    self._Control:RestoreSelectBuffIndex()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiArenaChapterDetail:OnEnable()
    self:_RefreshBuffList()
    self:_RefreshStageDatail()
    if self._IsReOpen then
        self._Scene:PlayRankAnimation()
    end
    self._IsReOpen = true
end

-- endregion

function XUiArenaChapterDetail:Close()
    self.Super.Close(self)
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_RESHOW_MAIN_UI)
end

-- region 按钮事件

function XUiArenaChapterDetail:OnBtnFightClick()
    local areaId = self:_GetCurrentAreaId()

    self._Control:SetCurrentEnterAreaId(areaId)
    self._Control:ChangeCurrentSelectBuffIndex(self._CurrentSelectBuffIndex)

    local stageId = self._Control:GetAreaStageLastStageIdById(areaId)
    self._Control:OpenBattleRoleRoom(stageId)
end

function XUiArenaChapterDetail:OnListTitleClick(index)
    local areaId = self:_GetCurrentAreaId()

    self._CurrentSelectBuffIndex = index
    self._Control:SetLocalSelectBuffIndex(areaId, index)
    
    -- 更新区域历史最高分显示
    self:_UpdateBestRecord(areaId, index)
end

function XUiArenaChapterDetail:OnZoneSelectClick(index)
    self._CurrentSelectZoneIndex = index
    self._CurrentSelectBuffIndex = 1
    self:_RefreshBuffList()
    self:_RefreshStageDatail()
    self:PlayAnimation("AnimSwitch")
    self._Scene:RefreshPlayerGrid(index, self:_GetCurrentAreaShowData())
end

function XUiArenaChapterDetail:OnBtnAttributeDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", nil, XEnumConst.UiCharacterAttributeDetail.BtnTab.Damage)
end

-- endregion

-- region 私有方法

function XUiArenaChapterDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick, true)
    if self.BtnBack and self.BtnMainUi then
        self:BindExitBtns(self.BtnBack, self.BtnMainUi)
        self.BtnClose.gameObject:SetActiveEx(false) 
        self.BtnCloseTarget.gameObject:SetActiveEx(false) 
    else
        self.BtnClose.gameObject:SetActiveEx(true) 
        self.BtnCloseTarget.gameObject:SetActiveEx(true) 
        self:RegisterClickEvent(self.BtnClose, self.Close, true)
        XUiHelper.RegisterPassClickEvent(self, self.BtnCloseTarget, self.BtnClose)
    end
    self.BtnAttributeDetail:AddEventListener(handler(self, self.OnBtnAttributeDetailClick))
end

function XUiArenaChapterDetail:_RefreshBuffList()
    local groupEventId = self._AreaData:GetGroupFightEventIdByAreaId(self:_GetCurrentAreaId())
    local groupEvents = self._Control:GetFightEventsByGroupId(groupEventId)

    if not XTool.IsTableEmpty(groupEvents) then
        self.PanelBuff.gameObject:SetActiveEx(true)
        for i, eventId in pairs(groupEvents) do
            local grid = self._BuffGridList[i]

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridBuff, self.PanelBuff)

                grid = XUiArenaChapterDetailGridBuff.New(gridObject, self)
                self._BuffGridList[i] = grid
            end

            grid:Open()
            grid:Refresh(eventId)
        end
        for i = #groupEvents + 1, #self._BuffGridList do
            self._BuffGridList[i]:Close()
        end
    else
        self.PanelBuff.gameObject:SetActiveEx(false)
    end
end

function XUiArenaChapterDetail:_RefreshStageDatail()
    local areaId = self:_GetCurrentAreaId()
    local stageBuffNameList = self._Control:GetAreaStageBuffNameListByAreaId(areaId)

    self.TxtTips.text = self._Control:GetAreaStageDescByAreaId(areaId)
    
    -- 显示区域历史最高分（使用当前选中的Buff索引）
    if #stageBuffNameList == 1 then
        local currentBuffIndex = self._Control:GetLocalSelectBuffIndex(areaId) or 1
        self:_UpdateBestRecord(areaId, currentBuffIndex)
        
        self.PanelTitle.gameObject:SetActiveEx(true)
        self.ListTitle.gameObject:SetActiveEx(false)

        self.TxtTitle.text = stageBuffNameList[1]
        self.TxtEnvironment.text = self._Control:GetAreaStageBuffDescByAreaIdAndIndex(areaId, 1) or ""
    else
        self.PanelTitle.gameObject:SetActiveEx(false)
        self.ListTitle.gameObject:SetActiveEx(true)

        for i, name in pairs(stageBuffNameList) do
            local button = self._BtnListTitleList[i]

            if not button then
                local gridObject = XUiHelper.Instantiate(self.GridTitle.gameObject, self.ListTitle.transform)

                button = gridObject.transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
                self._BtnListTitleList[i] = button
            end

            local buffDesc = self._Control:GetAreaStageBuffDescByAreaIdAndIndex(areaId, i) or ""

            button:SetNameByGroup(0, name)
            button:SetNameByGroup(1, buffDesc)
        end

        self.GridTitle.gameObject:SetActiveEx(false)
        self.ListTitle:Init(self._BtnListTitleList, Handler(self, self.OnListTitleClick))
        self.ListTitle:SelectIndex(self._Control:GetLocalSelectBuffIndex(areaId))
    end
end

function XUiArenaChapterDetail:_InitUi()
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiArenaChapterDetail:_GetCurrentAreaId()
    local areaData = self:_GetCurrentAreaShowData()

    return areaData and areaData:GetAreaId() or 0
end

function XUiArenaChapterDetail:_GetCurrentAreaShowData()
    local index = self._CurrentSelectZoneIndex

    return self._AreaData:GetAreaShowDataByIndex(index)
end

--- 更新区域历史最高分显示
---@param areaId number 区域ID
---@param index number DistributeType数组的索引（对应OnListTitleClick中的index）
function XUiArenaChapterDetail:_UpdateBestRecord(areaId, index)
    if not self.TxtBestRecord then
        return
    end

    -- 切换子页签的情况，可能别的在播历史分数动画，先关掉
    self:StopBestRecordTweenTimer()
    
    local distributeTypeList = self._Control:GetAreaStageDistributeTypeByAreaId(areaId)
    local maxPoint = nil
    local isNewRecord = false
    local oldMaxPoint = 0
    
    -- 使用index获取DistributeType数组中对应的值
    if distributeTypeList and not XTool.IsTableEmpty(distributeTypeList) then
        local distributeType = distributeTypeList[index]
        if distributeType then
            maxPoint = self._AreaData:GetAreaDistributeMaxPointByDistributeType(distributeType)
            oldMaxPoint = self._Control:GetOldAreaDistributeMaxPointByDistributeType(distributeType) or 0

            -- 检查是否是新纪录
            if XTool.IsNumberValidEx(maxPoint) then
                if maxPoint and maxPoint > oldMaxPoint then
                    isNewRecord = true
                    
                    self._Control:UpdateOldAreaDistributeMaxPointByDistributeType(distributeType, maxPoint)
                end
            end
        end
    end
    
    if maxPoint and maxPoint > 0 then
        if isNewRecord then
            local diffPoint = maxPoint - oldMaxPoint
            
            self:StopBestRecordTweenTimer()

            self._BestRecordTweenTimer = self:Tween(1, function(progress)
                if XTool.UObjIsNil(self.Transform) or not self.TxtBestRecord then
                    return
                end

                -- 计算当前显示的分数（从 旧分数 到目标分数）
                local currentScore = math.floor(progress * diffPoint) + oldMaxPoint
                self.TxtBestRecord.text = tostring(currentScore)
            end, function()
                -- 动画结束，确保显示最终分数
                if not XTool.UObjIsNil(self.Transform) and self.TxtBestRecord then
                    self.TxtBestRecord.text = tostring(maxPoint)
                end
            end)
        else
            self.TxtBestRecord.text = tostring(maxPoint)
        end
    else
        self.TxtBestRecord.text = "--"
    end
    
    -- 显示/隐藏新纪录标记
    if self.TxtNew then
        self.TxtNew.gameObject:SetActiveEx(isNewRecord)
    end
end

function XUiArenaChapterDetail:StopBestRecordTweenTimer()
    if self._BestRecordTweenTimer then
        XScheduleManager.UnSchedule(self._BestRecordTweenTimer)
        self:_RemoveTimerIdAndDoCallback(self._BestRecordTweenTimer)
        
        self._BestRecordTweenTimer = nil
    end
end

-- endregion

return XUiArenaChapterDetail
