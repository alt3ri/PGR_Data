local XUiEnvelopeGuessingOpenPackage = require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingOpenPackage")
local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiPanelEnvelopeGuessingEnvelopeCard = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingEnvelopeCard")

---@class XUiPanelEnvelopeGuessingClueInvitation : XUiNode
---@field private _Control XEnvelopeGuessingControl
---@field Parent XUiEnvelopeGuessingInvitation
local XUiPanelEnvelopeGuessingClueInvitation = XClass(XUiNode, "XUiPanelEnvelopeGuessingClueInvitation")

function XUiPanelEnvelopeGuessingClueInvitation:OnStart(setupConfirmButton, closeParent)
    self._RefreshConfirmButton = setupConfirmButton(
        self.PanelBtnConfirm,
        handler(self, self._OpenEnvelope),
        {
            {
                CheckFunction = handler(self._Control, self._Control.CheckTicketItemEnough),
                CountTextGroupId = 1
            }
        })

    self._CloseParent = closeParent

    self._DynTable = XDynamicTableCurve.New(self.PanelClueInvitationList)
    self._DynTable:SetProxy(XUiPanelEnvelopeGuessingEnvelopeCard, self)
    self._DynTable:SetDelegate(self)
    self._DefaultLerpDuration = self._DynTable.Imp.LerpDuration
end

function XUiPanelEnvelopeGuessingClueInvitation:OnEnable()
    -- 注意：这里allEnvelopes必须key为连续且ID有序递增，是一个数组，如果不连续，则应该先转换为数组并根据Id排序
    local allEnvelopes = self._Control:GetAllEnvelopes()

    self._AllEnvelopesCount = #allEnvelopes

    self._EnvelopesNotOpened = XTool.FilterList(allEnvelopes, function(e)
        return not self._Control:IsCharacterOpened(e.CharacterId)
    end)

    if XTool.IsTableEmpty(self._EnvelopesNotOpened) then
        self._CloseParent()
        return
    end

    local prevOpenedEnvelopeId = self:_GetPrevOpenedEnvelopeId()
    if prevOpenedEnvelopeId then
        local _, max = XTool.MaxBy(self._EnvelopesNotOpened, function(_, v)
            return v.Id
        end)

        local slicePoint
        if prevOpenedEnvelopeId <= max.Id then
            for i, v in ipairs(self._EnvelopesNotOpened) do
                if v.Id > prevOpenedEnvelopeId then
                    slicePoint = i
                    break
                end
            end
        end

        if slicePoint then
            local right = XTool.ArraySliceCopy(self._EnvelopesNotOpened, 1, slicePoint - 1)
            local left = XTool.ArraySliceCopy(self._EnvelopesNotOpened, slicePoint, #self._EnvelopesNotOpened)
            self._EnvelopesNotOpened = XTool.MergeArray(left, right)
        end
    end

    self._DynTable:SetDataSource(self._EnvelopesNotOpened)
    self._DynTable:ReloadData(1)
    self._RefreshConfirmButton()
    self:_RefreshParallax()
end

function XUiPanelEnvelopeGuessingClueInvitation:RandomSelect()
    if self._RandomSelectSchedule then
        XScheduleManager.UnSchedule(self._RandomSelectSchedule)
        self._RandomSelectSchedule = nil
    end

    XLuaUiManager.SetMask(true)

    local minDistance = CS.XGame.ClientConfig:GetInt("EnvelopeGuessingClueInvitionRandomMinGrids")
    local maxDistance = CS.XGame.ClientConfig:GetInt("EnvelopeGuessingClueInvitionRandomMaxGrids")
    local distance = math.random(minDistance, maxDistance)
    local duration = CS.XGame.ClientConfig:GetInt("EnvelopeGuessingClueInvitionRandomAnimationDuration")

    self:_ClearParallax()
    local startIndex = self._DynTable.Imp.StartIndex
    self._DynTable.Imp.LerpDuration = duration / 1000.0
    self._DynTable.Imp:TweenToIndex(startIndex + distance)

    self._RandomSelectSchedule = XScheduleManager.ScheduleOnce(function()
        self._RandomSelectSchedule = nil
        XLuaUiManager.SetMask(false)
        self._DynTable.Imp.LerpDuration = self._DefaultLerpDuration
        self:_RefreshParallax()
    end, duration)
end

---@field grid XUiPanelEnvelopeGuessingEnvelopeCard
function XUiPanelEnvelopeGuessingClueInvitation:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._EnvelopesNotOpened[(index - 1) % #self._EnvelopesNotOpened + 1])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.Parent:ClearRandomSelectFlag()
        self._DynTable.Imp:TweenToIndex(index)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        self.Parent:ClearRandomSelectFlag()
        self:_ClearParallax()
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER or evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_END_DRAG then
        self:_RefreshParallax()
    end
end

function XUiPanelEnvelopeGuessingClueInvitation:_ClearParallax()
    local grids = self._DynTable:GetGrids() or {}
    for _, grid in pairs(grids) do
        grid:SetParallaxEnabled(false)
    end
end

-- 刷新动态列表所有可视卡片的视差(陀螺仪)开关
function XUiPanelEnvelopeGuessingClueInvitation:_RefreshParallax()
    local startIndex = self._DynTable.Imp.StartIndex
    local grids = self._DynTable:GetGrids() or {}
    for curveIndex, grid in pairs(grids) do
        grid:SetParallaxEnabled(curveIndex == startIndex)
    end
end

function XUiPanelEnvelopeGuessingClueInvitation:_GetPrevOpenedEnvelopeId()
    local envelopeId = XSaveTool.GetData(self._Control:GetPrevOpenedEnvelopeStorageKey())
    local allEnvelopes = self._Control:GetAllEnvelopes()
    if allEnvelopes[envelopeId] then
        return envelopeId
    end
    return nil
end

---@return XUiPanelEnvelopeGuessingEnvelopeCard|nil
function XUiPanelEnvelopeGuessingClueInvitation:_GetSelectedEnvelopeGrid()
    local startIndex = self._DynTable.Imp.StartIndex
    for curveIndex, grid in pairs(self._DynTable:GetGrids() or {}) do
        if curveIndex == startIndex then
            return grid
        end
    end

    return nil
end

function XUiPanelEnvelopeGuessingClueInvitation:_OpenEnvelope(fastOpen)
    local ticketEnough = self._Control:CheckTicketItemEnough()

    if not ticketEnough then
        XUiManager.TipText("UiEnvelopeGuessingInvitationTicketNotEnough")
        return
    end

    local selected = self:_GetSelectedEnvelopeGrid()

    if selected then
        local envelope, _ = selected:GetData()
        local maxTiltAngle = selected:GetMaxTiltAngle()
        self._Control:EnvelopeOpenRequest(envelope.Id, function()
            self.Parent:ReportOpenCard(self.Parent.ReportOpenType.Clue, envelope.CharacterId, fastOpen, maxTiltAngle)
            XLuaUiManager.Open("UiEnvelopeGuessingOpenPackage", XUiEnvelopeGuessingOpenPackage.OpenType.Clue, envelope, fastOpen)
            XSaveTool.SaveData(self._Control:GetPrevOpenedEnvelopeStorageKey(), envelope.Id)
        end)
    end
end

return XUiPanelEnvelopeGuessingClueInvitation
