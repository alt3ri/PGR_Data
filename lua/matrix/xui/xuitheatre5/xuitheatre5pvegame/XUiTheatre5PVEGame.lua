---@class XUiTheatre5PVEGame: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEGame = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEGame')
local XUiTheatre5PVEChapterEventItem = require("XUi/XUiTheatre5/XUiTheatre5PVEGame/XUiTheatre5PVEChapterEventItem")
local XUiTheatre5PVEChapterLevelItem = require("XUi/XUiTheatre5/XUiTheatre5PVEGame/XUiTheatre5PVEChapterLevelItem")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
function XUiTheatre5PVEGame:OnAwake()
    self:AddUIListener()
    self:AddEventListener()
end

---@param chapterData XTheatre5PveChapterData
function XUiTheatre5PVEGame:OnStart(chapterData, chapterBattlePromoteCb)
    self._chapterData = chapterData
    self._eventGridList = {}
    self._ChapterBattlePromoteCb = chapterBattlePromoteCb
end

function XUiTheatre5PVEGame:OnEnable()
    self:_RefreshAll()
end

function XUiTheatre5PVEGame:OnDisable()

end

function XUiTheatre5PVEGame:AddUIListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBack, true)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5') --先占坑
end

function XUiTheatre5PVEGame:AddEventListener()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_EVENT_SELECT, self.OnEventSelect, self)
end

function XUiTheatre5PVEGame:OnEventSelect(eventId)
    --第一次选择的时候也发，选哪个id返回哪个id
    XMVCA.XTheatre5.PVEAgency:RequestPveEventPromote(eventId, nil, function(success)
        if success then
            if self._ChapterBattlePromoteCb then
                self._ChapterBattlePromoteCb(XMVCA.XTheatre5.EnumConst.PVENodeType.Event, eventId)
            end    
        end    
    end)
end

function XUiTheatre5PVEGame:_RefreshAll()
    self:_RefreshNoraml()
    self:_RefreshResourceBar()
    self:_RefreshEvents()
    self:_RefreshLevels()
end

function XUiTheatre5PVEGame:_RefreshNoraml()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(self._chapterData.ChapterId)
    self.TxtTitle.text = chapterCfg.Title
    self.RawImgBg:SetRawImage(chapterCfg.BgAsset)
    --复刷章节
    local curStoryEntranceId = self._Control.PVEControl:GetCurStoryEntranceId()
    if XTool.IsNumberValid(curStoryEntranceId) then
        self.PanelClue.gameObject:SetActiveEx(false)
        return
    end    
    local curContentId = self._Control.PVEControl:GetStoryLineContentId(self._Control.PVEControl:GetCurPveStoryLineId())
    local storyLineContentCfg = self._Control.PVEControl:GetStoryLineContentCfg(curContentId)
    local isDeduce = storyLineContentCfg and storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle 
        and XTool.IsNumberValid(storyLineContentCfg.NextScript)
    self.PanelClue.gameObject:SetActiveEx(isDeduce)
    if not isDeduce then
        return
    end

    local scriptCfg = self._Control.PVEControl:GetDeduceScriptCfg(storyLineContentCfg.NextScript)
    local clueCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId)
    local unLockCount = self._Control.PVEControl:GetUnlockDeduceScriptCount(storyLineContentCfg.NextScript)
    self.TxtClueNum.text = string.format("%d/%d", unLockCount, #clueCfgs)  
end

function XUiTheatre5PVEGame:_RefreshResourceBar()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(self._chapterData.ChapterId)
    self.TxtLifeNum.text = string.format("%d/%d", self._Control:GetHealth(), chapterCfg.Hp)
    self.TxtCoinNum.text = self._Control:GetGoldNum()
end

function XUiTheatre5PVEGame:_RefreshEvents()
    local eventDatas = {}
    local runEvents = self._chapterData.CurPveChapterLevel.RunEvents
    if XTool.IsTableEmpty(runEvents) then --目前只存在事件初始状态
        for _, eventId in pairs(self._chapterData.CurPveChapterLevel.RandomEvents) do
            table.insert(eventDatas, {EventId = eventId, IsNew = not self:_IsEventCompleted(eventId)})
        end
    else
        --table.insert(eventDatas, {EventId = runEvents[1], IsNew = not self:_IsEventCompleted(runEvents[#runEvents])})
    end
    XTool.UpdateDynamicItem(self._eventGridList, eventDatas, self.GridCard, XUiTheatre5PVEChapterEventItem, self)    
end

--关卡刷新
function XUiTheatre5PVEGame:_RefreshLevels()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(self._chapterData.ChapterId)
    local chapterLevelCfgs = self._Control.PVEControl:GetPveChapterLevelCfgs(chapterCfg.LevelGroup)
    self._DynamicTable = XDynamicTableNormal.New(self.DynamicTable)
    self._DynamicTable:SetProxy(XUiTheatre5PVEChapterLevelItem, self)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetDataSource(chapterLevelCfgs)
    self._DynamicTable:ReloadDataSync()
end

function XUiTheatre5PVEGame:_IsEventCompleted(targetEventId)
    local finishEvents = self._Control.PVEControl:GetHistoryFinishEvents(self._chapterData.ChapterId)
    if not finishEvents then
        return false
    end
    for _, eventId in pairs(finishEvents) do
        if eventId == targetEventId then
            return true
        end    
    end
    return false    
end

function XUiTheatre5PVEGame:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curChapterLevel = self._chapterData.CurPveChapterLevel.Level
        local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(self._chapterData.ChapterId)
        local targetLevelState = XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Running
        if index > curChapterLevel then
            targetLevelState = XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Lock
        elseif index < curChapterLevel then
            targetLevelState = XMVCA.XTheatre5.EnumConst.PVEChapterLevelState.Completed
        end        
        local targetChapterLevelCfg = self._Control.PVEControl:GetChapterLevelCfg(chapterCfg.LevelGroup, index)
        grid:Update(targetChapterLevelCfg, targetLevelState, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local scrollIndex = self._chapterData.CurPveChapterLevel.Level - 2
        if scrollIndex <= 0 then
            scrollIndex = 1
        end    
        self._DynamicTable:ScrollToIndex(scrollIndex, 0)

        local grids = self._DynamicTable:GetGrids()
        if XTool.IsTableEmpty(grids) then
            return
        end    
        for i,grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        for i,grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/Enable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                end        
            end, 100 * i)
        end
    end        
end

function XUiTheatre5PVEGame:OnBack()
    self._Control:ReturnTheatre5Main()
end

function XUiTheatre5PVEGame:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_PVE_EVENT_SELECT, self.OnEventSelect, self)
    self._chapterData = nil
    self._eventGridList = nil
    self._ChapterBattlePromoteCb = nil
end

return XUiTheatre5PVEGame