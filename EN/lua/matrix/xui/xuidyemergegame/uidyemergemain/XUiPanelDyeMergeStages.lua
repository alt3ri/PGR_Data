---@class XUiPanelDyeMergeStages: XUiNode
---@field protected _Control XDyeMergeGameControl
---@field Parent
local XUiPanelDyeMergeStages = XClass(XUiNode, "XUiPanelDyeMergeStages")

function XUiPanelDyeMergeStages:OnStart()
    self._StageGridList = {}
    self._StageId2GridDict = {}

    self.GridStage.gameObject:SetActiveEx(false)
    ---@type XPool
    self._GridStagePool = XPool.New(handler(self, self._GetNewGridStage), handler(self, self._RecycleGridStage), false)
    
    ---@type XUiInputSignalMediator
    self._InputMeditor = require("XUi/XUiCommon/XUiInputSignalMediator").New(self.GameObject, self, self._Control.EnumConst.UIInputTypes)

    self._InputMeditor:RegisterSignalHandler(self._Control.EnumConst.UIInputTypes.SelectStage, handler(self, self._OnSelectStageSignal))

    self._StageGridClickHandler = function(stageId)
        self._InputMeditor:ReceiveInputSignal(self._Control.EnumConst.UIInputTypes.SelectStage, stageId)
    end
end

function XUiPanelDyeMergeStages:OnEnable()
    self._InputMeditor:StartInputSignalUpdateTimer()
    
    self:RefreshStagesOnly()
end

function XUiPanelDyeMergeStages:OnDisable()
    self._InputMeditor:StopInputSignalUpdateTimer()
end

--- 刷新当前关卡的状态，不改变数据从属
function XUiPanelDyeMergeStages:RefreshStagesOnly()
    if not XTool.IsTableEmpty(self._StageGridList) then
        for i, v in pairs(self._StageGridList) do
            v:RefreshOwnState()
        end
    end
end

function XUiPanelDyeMergeStages:RefreshStagesByChapterId(chapterId)
    -- 回收上次使用的对象
    if not XTool.IsTableEmpty(self._StageGridList) then
        for i = #self._StageGridList, 1, -1 do
            local grid = self._StageGridList[i]

            self._StageId2GridDict[grid.StageId] = nil
            self._StageGridList[i] = nil

            self._GridStagePool:ReturnItemToPool(grid)
        end
    end
    
    local chapterCfg = XMVCA.XDyeMergeGame:GetTableDyeMergeChapterById(chapterId)

    if chapterCfg and not XTool.IsTableEmpty(chapterCfg.StageIds) then
        local stageIndex = 1
        
        for _, stageId in pairs(chapterCfg.StageIds) do
            local rootUi = self["Stage" .. tostring(stageIndex)]

            if rootUi then
                ---@type XUiGridDyeMergeStage
                local grid = self._GridStagePool:GetItemFromPool()
                
                grid:SetTransformParent(rootUi)
                grid:Open()
                grid:Refresh(stageId, chapterId)

                table.insert(self._StageGridList, grid)
                self._StageId2GridDict[stageId] = grid

                stageIndex = stageIndex + 1
            end
        end
    end
end

function XUiPanelDyeMergeStages:_GetNewGridStage()
    local go = XUiHelper.Instantiate(self.GridStage, self.GridStage.transform.parent)

    ---@type XUiGridDyeMergeStage
    local grid = require("XUi/XUiDyeMergeGame/UiDyeMergeMain/XUiGridDyeMergeStage").New(go, self, self._StageGridClickHandler)
    
    return grid
end

function XUiPanelDyeMergeStages:_RecycleGridStage(grid)
    grid:Close()
end

--region 信号输入处理

function XUiPanelDyeMergeStages:_OnSelectStageSignal(stageId)
    local isUnlock, lockDesc = XMVCA.XDyeMergeGame:GetIsStageUnlockById(stageId)

    if isUnlock then
        XMVCA.XDyeMergeGame.Network:DoDyeMergeTryEnterStageRequest(stageId, function(success)
            if success then
                XLuaUiManager.Open("UiDyeMergeGame", stageId)
            end
        end)
    else
        XUiManager.TipMsg(lockDesc)    
    end
end

--endregion

--- 根据 stageId 返回对应的关卡格节点，若当前章节无此关卡则返回 nil
---@param stageId number
---@return XUiGridDyeMergeStage|nil
function XUiPanelDyeMergeStages:GetStageGridByStageId(stageId)
    return self._StageId2GridDict[stageId]
end

return XUiPanelDyeMergeStages