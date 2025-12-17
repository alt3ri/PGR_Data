---@class XUiTheatre5PVEClueBoard: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEClueBoard = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEClueBoard')
local XUiTheatre5PVEMainClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMainClue")
local XUiTheatre5PVEMinorClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVEMinorClue")
local MainClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVESimpleMainClue")
local MinorClue = require("XUi/XUiTheatre5/XUiTheatre5PVEClue/XUiTheatre5PVESimpleMinorClue")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre5PVEClueBoardTag = require("XUi/XUiTheatre5/XUiTheatre5PVEClueBoard/XUiTheatre5PVEClueBoardTag")
local XUiTheatre5PVEClueBoardMoveScale = require("XUi/XUiTheatre5/XUiTheatre5PVEClueBoard/XUiTheatre5PVEClueBoardMoveScale")
local tableInsert = table.insert

function XUiTheatre5PVEClueBoard:OnAwake()
    self._ClueBoardCfgs = nil
    self._CurSelectClueBoardId = nil
    self._CurSelectIndex = nil
    self._EnterMainClueId = nil
    self._FirstMainClueList = {}
    self._FirstMinorClueList = {}
    self._SecondMainClueList = {}
    self._SecondMinorClueList = {}
    self._IsDetailsShow = true --用于打开切换
    self._LastRecordPage = nil --战斗、剧情销毁界面前的页签
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5')
    self:RegisterClickEvent(self.BtnHandbook, self.OnClickHandbook, true)
end

function XUiTheatre5PVEClueBoard:OnStart(mainClueId)
    self._EnterMainClueId = mainClueId
    ---@type XUiTheatre5PVEClueBoardMoveScale
    self.UiTheatre5PVEClueBoardMoveScale = XUiTheatre5PVEClueBoardMoveScale.New(self.GameObject, self)
    self:InitClueBoardList()
end

function XUiTheatre5PVEClueBoard:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CLUE_BOARD_TAG, self.OnClickClueBoardTag, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLUE_BOARD_SWITCH, self.OnSwitchClueShow, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_SIMPLE_CLUE, self.OnClickSimpleClue, self)
    if XTool.IsNumberValid(self._CurSelectIndex) then
        -- 延迟，等待动画播放结束，再刷新
        if not self._TimerDelayRefresh then
            self._TimerDelayRefresh = XScheduleManager.ScheduleOnce(function()
                self:OnClickClueBoardTag(self._CurSelectIndex, false)
            end, 500)
        end
    end    
end

function XUiTheatre5PVEClueBoard:OnDisable()
    if self._TimerDelayRefresh then
        XScheduleManager.UnSchedule(self._TimerDelayRefresh)
        self._TimerDelayRefresh = nil
    end
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CLUE_BOARD_TAG, self.OnClickClueBoardTag, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLUE_BOARD_SWITCH, self.OnSwitchClueShow, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_SIMPLE_CLUE, self.OnClickSimpleClue, self)
end

function XUiTheatre5PVEClueBoard:OnReleaseInst()
    return self._CurSelectIndex
end

function XUiTheatre5PVEClueBoard:OnResume(index)
    if XTool.IsNumberValid(index) then
        self._LastRecordPage = index
    end    
end

function XUiTheatre5PVEClueBoard:InitClueBoardList()
    if self.ListTab.Grid then
       self.ListTab.Grid.gameObject:SetActiveEx(false)
    end    
    self._ClueBoardCfgs = self._Control.PVEControl:GetDeduceClueBoardCfgs()
    self._DynamicTable = XDynamicTableNormal.New(self.ListTab)
    self._DynamicTable:SetProxy(XUiTheatre5PVEClueBoardTag, self)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetDataSource(self._ClueBoardCfgs)
    self._DynamicTable:ReloadDataSync()
end

function XUiTheatre5PVEClueBoard:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then        
        grid:Update(self._ClueBoardCfgs[index], index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
          --默认选中第一个解锁的页签
        if not XTool.IsTableEmpty(self._ClueBoardCfgs) then
            local selectIndex = XTool.IsNumberValid(self._LastRecordPage) and self._LastRecordPage or self:GetDefaultSelectIndex()
            if XTool.IsNumberValid(selectIndex) then
                self._CurSelectIndex = selectIndex
                self:OnClickClueBoardTag(selectIndex, false)
            end    
            self:SwitchClueShow(not self._IsDetailsShow)
        end    
    end       
end

function XUiTheatre5PVEClueBoard:OnClickClueBoardTag(index, playAnimation)
    local clueBoardCfg = self._ClueBoardCfgs[index]
    self._CurSelectClueBoardId = clueBoardCfg.Id
    self._CurSelectIndex = index
    self:RefreshSelected()
    
    -- 播放动画
    if playAnimation ~= false then
        self.UiTheatre5PVEClueBoardMoveScale:SetDragAreaEnable(false)
        self.UiTheatre5PVEClueBoardMoveScale:PlayAnimationMaskTween(0.45, function()
            -- 这里故意做一个偏移, 在选中相同坐标时, 也产生镜头移动效果
            local localPosition = self.DragArea.transform.localPosition
            localPosition.x = localPosition.x - 600
            localPosition.y = localPosition.y - 600
            self.DragArea.transform.localPosition = localPosition

            -- 在黑色遮罩遮住之后, 才刷新地图
            self:RefreshClueBoardShow(clueBoardCfg.Id, index)
        end)
        self:PlayAnimationWithMask("Switch", function()
            self.UiTheatre5PVEClueBoardMoveScale:SetDragAreaEnable(true)
        end)
    else
        self:RefreshClueBoardShow(clueBoardCfg.Id, index)
    end
end

function XUiTheatre5PVEClueBoard:OnSwitchClueShow(isSwitchToDetails)
    if self._IsDetailsShow == isSwitchToDetails then
        return
    end
    self:SwitchClueShow(isSwitchToDetails, true)
end

function XUiTheatre5PVEClueBoard:SwitchClueShow(isSwitchToDetails, plauSwitchAnim)
    if self._IsDetailsShow == isSwitchToDetails then
        return
    end
    self._IsDetailsShow = isSwitchToDetails
    local clueBoardCfg = self._Control.PVEControl:GetDeduceClueBoardCfg(self._CurSelectClueBoardId)
    local clueGroupCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(clueBoardCfg.ClueGroupId)
    local mainClueCfgs = {}
    local minorClueCfgs = {}
    for _, clueGroupCfg in pairs(clueGroupCfgs) do
        local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueGroupCfg.ClueId)
        if clueCfg.Type ==  XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
            tableInsert(mainClueCfgs, clueCfg)
        else
            tableInsert(minorClueCfgs, clueCfg)
        end 
    end
    self:RefreshLayerClues(mainClueCfgs, minorClueCfgs, plauSwitchAnim) 
end

function XUiTheatre5PVEClueBoard:OnClickSimpleClue(clueId)
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    local postTrans = XUiHelper.TryGetComponent(self.LayerClueFirst, tostring(clueCfg.Index), nil)
    if postTrans then
        self.UiTheatre5PVEClueBoardMoveScale:FocusToDetailClue(postTrans)
    end    
end

function XUiTheatre5PVEClueBoard:RefreshSelected()
    local grids = self._DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:SetSelect(self._CurSelectClueBoardId)
    end
end

function XUiTheatre5PVEClueBoard:RefreshClueBoardShow(clueBoardId, index)
    local clueBoardCfg = self._Control.PVEControl:GetDeduceClueBoardCfg(clueBoardId)
    local clueGroupCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(clueBoardCfg.ClueGroupId)
    local mainClueCfgs = {}
    local minorClueCfgs = {}
    local allClueCfgs = {}
    for _, clueGroupCfg in pairs(clueGroupCfgs) do
        local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueGroupCfg.ClueId)
        if clueCfg.Type ==  XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
            tableInsert(mainClueCfgs, clueCfg)
        else
            tableInsert(minorClueCfgs, clueCfg)
        end    
        tableInsert(allClueCfgs, clueCfg)   
    end
    self:RefreshLines(index, mainClueCfgs, allClueCfgs)
    self:RefreshLayerClues(mainClueCfgs, minorClueCfgs)
    self.UiTheatre5PVEClueBoardMoveScale:Update(mainClueCfgs)
end

function XUiTheatre5PVEClueBoard:RefreshLines(index, mainClueCfgs, allClueCfgs)
    local curLineTrans
    local count = self.ListLine.transform.childCount
    for i = 1, count do
        local child = self.ListLine.transform:GetChild(i - 1)
        child.gameObject:SetActiveEx(i == index)
        if i == index then
            curLineTrans = child
        end    
    end
    if not curLineTrans then
        return
    end
    local mainClueLineListTrans = XUiHelper.TryGetComponent(curLineTrans, "ListClueLine", nil)
    if not mainClueLineListTrans then
        return
    end
    for _,mainClueCfg in ipairs(mainClueCfgs) do
        local clueState = self._Control.PVEControl:GetClueState(mainClueCfg.Id)
        local mainClueLineTrans = XUiHelper.TryGetComponent(mainClueLineListTrans, tostring(mainClueCfg.Index), nil)
        if mainClueLineTrans then
            mainClueLineTrans.gameObject:SetActiveEx(clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow)
        end    
    end
    self:RefreshLineRelation(curLineTrans, allClueCfgs)
end

function XUiTheatre5PVEClueBoard:RefreshLineRelation(curLineTrans, allClueCfgs)
   for i = 1, curLineTrans.childCount do
        local childGo = curLineTrans:GetChild(i - 1)
        local name = childGo.name
        if string.find(name, "_") then
            local active = true
            for part in string.gmatch(name, "[^_]+") do
                local clueState = self:GetClueStateByIndex(allClueCfgs, part)
                if clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.Unlock and clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce
                    and clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.Completed then
                        active = false
                        break
                end        
            end
            childGo.gameObject:SetActiveEx(active)
        end    
   end
   
end

function XUiTheatre5PVEClueBoard:RefreshLayerClues(mainClueCfgs, minorClueCfgs, playAnim)
    self:RefreshClueCells(self._FirstMainClueList, self.LayerClueFirst, mainClueCfgs, self.UiTheatre5MainClue, XUiTheatre5PVEMainClue, true, playAnim)
    self:RefreshClueCells(self._FirstMinorClueList, self.LayerClueFirst, minorClueCfgs, self.UiTheatre5MinorClue, XUiTheatre5PVEMinorClue, true, playAnim)

    self:RefreshClueCells(self._SecondMainClueList, self.LayerClueSecond, mainClueCfgs, self.MainClue, MainClue, false, playAnim)
    self:RefreshClueCells(self._SecondMinorClueList, self.LayerClueSecond, minorClueCfgs, self.MinorClue, MinorClue, false, playAnim)
end

function XUiTheatre5PVEClueBoard:RefreshClueCells(clueCellList, parentTrans, dataList, grid, class, isDetailsShow, playAnim)
    local clueIds = {}
    for i,cfg in ipairs(dataList) do
        tableInsert(clueIds, cfg.Id)
    end
    XTool.UpdateDynamicItem(clueCellList, clueIds, grid, class, self)
    for i = 1, #clueIds do
        local cell = clueCellList[i]
        local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueIds[i])
        local postTrans = XUiHelper.TryGetComponent(parentTrans, tostring(clueCfg.Index), nil)
        local clueState = self._Control.PVEControl:GetClueState(clueCfg.Id)
        local visible = clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow and isDetailsShow == self._IsDetailsShow
        if postTrans then
            cell:UpdateCuleBoard(postTrans.localPosition, visible, playAnim)
        else
            XLog.Error(string.format("线索板上线索对应的位置节点不存在,Index:%s", clueCfg.Index))
        end         
    end
end

--打开默认选择有推演的页签
function XUiTheatre5PVEClueBoard:GetDefaultSelectIndex()
    if XTool.IsTableEmpty(self._ClueBoardCfgs) then
        return
    end
    --先找第一个能推演的
    local canDeduceIndex = 0
    for i = 1, #self._ClueBoardCfgs do
        local clueGroupCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(self._ClueBoardCfgs[i].ClueGroupId)
        if not XTool.IsTableEmpty(clueGroupCfgs) then
            for _, clueGroupCfg in pairs(clueGroupCfgs) do
                local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueGroupCfg.ClueId)
                if clueCfg.Type ==  XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
                    local clueState = self._Control.PVEControl:GetClueState(clueCfg.Id)
                    if clueCfg.Id == self._EnterMainClueId then --指定进入的优先级最高
                        return i
                    end    
                    if not XTool.IsNumberValid(canDeduceIndex) and clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce then
                        canDeduceIndex = i
                    end    
                end 
            end
        end    
    end

    if XTool.IsNumberValid(canDeduceIndex) then --然后选第一个能推演的
        return canDeduceIndex
    end    

    --推演的没有找第一个解锁的
    for i = 1, #self._ClueBoardCfgs do
        if self._Control.PVEControl:IsUnlockDeduceClueBoard(self._ClueBoardCfgs[i].Id) then
            return i
        end      
    end 
end

function XUiTheatre5PVEClueBoard:GetClueStateByIndex(allClueCfgs, indexStr)
    local index = tonumber(indexStr)
    if not XTool.IsNumberValid(index) then
        return
    end    
   for _, clueCfg in pairs(allClueCfgs) do
        if clueCfg.Index == index then
            return self._Control.PVEControl:GetClueState(clueCfg.Id)
        end    
   end
end

function XUiTheatre5PVEClueBoard:IsDetailsShow()
    return self._IsDetailsShow
end

function XUiTheatre5PVEClueBoard:OnClickHandbook()
    --XMVCA.XArchive:OpenUiArchiveMain()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) then
        return
    end
    --资源检测
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    --local storySkipPage = self._Control.PVEControl:GetStorySkipPage()
    --XLuaUiManager.Open("UiArchiveStory", storySkipPage)
    XLuaUiManager.Open("UiTheatre5Story")
end

function XUiTheatre5PVEClueBoard:OnDestroy()
    self._ClueBoardCfgs = nil
    self._CurSelectClueBoardId = nil
    self._FirstMainClueList = nil
    self._FirstMinorClueList = nil
    self._SecondMainClueList = nil
    self._SecondMinorClueList = nil
    self._IsDetailsShow = nil
    self._CurSelectIndex = nil
    self._LastRecordPage = nil
    self._EnterMainClueId = nil
end


return XUiTheatre5PVEClueBoard