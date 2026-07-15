--- 主线任务负责显示额外信息小关卡入口的组件
---@class XUiMainLine2PanelMessageCom: XUiNode
---@field protected _Control XMainLine2Control
---@field Parent
local XUiMainLine2PanelMessageCom = XClass(XUiNode, "XUiMainLine2PanelMessageCom")
local XUiGridMainLine2Message = require("XUi/XUiMainLine2/Component/UiMainLine2PanelMessageCom/XUiGridMainLine2Message")

function XUiMainLine2PanelMessageCom:OnStart(chapterId, stageId)
    self.ChapterId = chapterId
    self.StageId = stageId

    if self.MessageGrid then
        self.MessageGrid.gameObject:SetActiveEx(false)
    end
    
    ---@type table<number, XUiGridMainLine2Message>
    self._MessageGridDict = {}
    
    self:InitGrids()
end

function XUiMainLine2PanelMessageCom:OnEnable()
    self:Refresh()
    
    self._Control.MessageControl:AddEventListener(self._Control.MessageControl.EventIds.MessageStateChaned, self._OnMessageStateChangedEvent, self)
end

function XUiMainLine2PanelMessageCom:OnDisable()
    self._Control.MessageControl:RemoveEventListener(self._Control.MessageControl.EventIds.MessageStateChaned, self._OnMessageStateChangedEvent, self)
end

function XUiMainLine2PanelMessageCom:Refresh()
    if not XTool.IsTableEmpty(self._MessageGridDict) then
        for id, grid in pairs(self._MessageGridDict) do
            if self._Control.MessageControl:CheckMessageCanShowById(id) then
                grid:Open()
                grid:Refresh()
            else
                grid:Close()
            end
        end
    end 
end

function XUiMainLine2PanelMessageCom:InitGrids()
    local messagePositionIds = self._Control.MessageControl:GetCfgMessagePositionIdsById(self.ChapterId)

    if XTool.IsTableEmpty(messagePositionIds) then
        XLog.Error("[Mainline2][Message配置错误]章节：" .. tostring(self.ChapterId) .. '对应的MessageIds字段为空')
        return
    end

    if not self.MessageGrid then
        XLog.Error("[Mainline2][UI引用错误]不存在MessageGrid节点的引用")
        return
    end

    for i, id in pairs(messagePositionIds) do
        local uiPosIndex = self._Control.MessageControl:GetCfgMessagePosIndexById(id)

        if XTool.IsNumberValidEx(uiPosIndex) then
            local uiRoot = self:_GetMessageUiRootByIndex(uiPosIndex)

            if uiRoot then
                self:_SetMessageGridWithId(id, uiRoot.transform)
            end
        end
    end
end

function XUiMainLine2PanelMessageCom:_GetMessageUiRootByIndex(index)
    return self["MessagePos" .. index]
end

function XUiMainLine2PanelMessageCom:_SetMessageGridWithId(id, transformRoot)
    local go = XUiHelper.Instantiate(self.MessageGrid, transformRoot)

    go.transform:SetLocalPosition(0, 0, 0)
    go.transform:SetLocalScale(1, 1, 1)
    
    local grid = XUiGridMainLine2Message.New(go, self, id)
    
    -- 检查是否解锁
    if self._Control.MessageControl:CheckMessageCanShowById(id) then
        transformRoot.gameObject:SetActiveEx(true)
        grid:Open()
        grid:Refresh()
    else
        grid:Close()
        transformRoot.gameObject:SetActiveEx(false)
    end
    
    self._MessageGridDict[id] = grid
end

function XUiMainLine2PanelMessageCom:_OnMessageStateChangedEvent(messagePosId, newState)
    local grid = self._MessageGridDict[messagePosId]

    if grid then
        grid:Refresh()
    end
end

return XUiMainLine2PanelMessageCom