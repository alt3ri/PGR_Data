local XUiLineArithmetic2MainStageGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2MainStageGrid")

---@class XUiLineArithmetic2Chapter : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2Chapter = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2Chapter")

function XUiLineArithmetic2Chapter:Ctor()
    ---@type XUiLineArithmetic2MainChapterGrid[]
    self._GridChapters = {}
end

function XUiLineArithmetic2Chapter:OnAwake()
    self:BindExitBtns()
    self.GridChapter.gameObject:SetActiveEx(false)
    self:BindHelpBtn(self.BtnHelp, "LineArithmeticHelp")
    local bgName = "Img01"
    local bg = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/" .. bgName, "RectTransform")
    if bg then
        bg.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmetic2Chapter:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_STAGE, self.Update, self)
    self:Update()
    self:UpdateTitle()

    local uiData = self._Control:GetUiData()
    if uiData.IsDefaultSelectDirty then
        self._Control:SetDefaultSelectDirty(false)
        local index = uiData.DefaultSelectStageIndex
        self:ScrollToCurrentGame(index)
    end

    self:PlayStageAnimation()
end

function XUiLineArithmetic2Chapter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_STAGE, self.Update, self)
end

function XUiLineArithmetic2Chapter:Update()
    self._Control:UpdateStage()
    local uiData = self._Control:GetUiData()
    local stages = uiData.Stage
    for i = 1, #stages do
        ---@type XUiLineArithmetic2MainChapterGrid
        local grid = self._GridChapters[i]
        if not grid then
            local parent = self["Chapter" .. i]
            if not parent then
                XLog.Error("[XUiLineArithmetic2Main] 章节节点不够了， 加多个吧:", i)
                break
            end
            local ui = CS.UnityEngine.Object.Instantiate(self.GridChapter, parent.transform)
            ui.localPosition = Vector3.zero
            grid = XUiLineArithmetic2MainStageGrid.New(ui, self)
            self._GridChapters[i] = grid
        end
        grid:Open()
        grid:Update(stages[i])
    end
    for i = #stages + 1, #self._GridChapters do
        local grid = self._GridChapters[i]
        grid:Close()
    end

    self.TxtTitle.text = uiData.CurrentChapterName
    self.TxtStar.text = uiData.CurrentChapterStar

    local bgName = uiData.ChapterBg
    local bg = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/" .. bgName, "RectTransform")
    if bg then
        bg.gameObject:SetActiveEx(true)
    end

    -- 根据关卡数量控制content长度
    ---@type UnityEngine.Rect
    local rect = self.ListBarrier.content.transform
    if #stages < 7 then
        rect:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 2900)
    end
end

function XUiLineArithmetic2Chapter:ScrollToCurrentGame(index)
    if not index then
        return
    end
    local grid = self._GridChapters[index]
    if grid then
        -----@type UnityEngine.UI.ScrollRect
        --local listChapter = self.ListBarrier
        -----@type UnityEngine.RectTransform
        --local listRectTransform = listChapter.transform
        --local worldPosition = grid.Transform:TransformPoint(Vector3.zero)
        --local localPosition = listChapter.content.transform:InverseTransformPoint(worldPosition)
        --local contentWidth = listChapter.content.rect.width
        --
        --local w1 = contentWidth
        --local w2 = listRectTransform.rect.width
        --local x = localPosition.x
        --local v = (2 * w1 - 2 * x - w2) / (w1 - w2)
        --v = CS.UnityEngine.Mathf.Clamp(v, 0, 1)
        --listChapter.horizontalNormalizedPosition = v

        ---@type UnityEngine.UI.ScrollRect
        local listChapter = self.ListBarrier
        local worldPosition = grid.Transform:TransformPoint(Vector3.zero)
        local localPosition = listChapter.content.transform:InverseTransformPoint(worldPosition)
        local contentWidth = listChapter.content.transform.rect.width - listChapter.transform.rect.width
        local value = (localPosition.x - listChapter.transform.rect.width / 2) / contentWidth
        value = CS.UnityEngine.Mathf.Clamp(value, 0, 1)
        listChapter.horizontalNormalizedPosition = value
    end
end

function XUiLineArithmetic2Chapter:UpdateTitle()
    self._Control:UpdateChapterTitle()
    local uiData = self._Control:GetUiData()
    --self.TxtTitle:SetRawImage(uiData.ChapterTitleImg)
    --self.TxtTitle.text = uiData.ChapterTitle
end

function XUiLineArithmetic2Chapter:PlayStageAnimation()
    local grids = self._GridChapters
    for i = 1, #grids do
        local grid = grids[i]
        if grid:IsNodeShow() then
            grid:Close()
            local timer
            timer = XScheduleManager.ScheduleOnce(function()
                grid:Open()
                grid:PlayAnimation("GridChapterEnable")
                self:_RemoveTimerIdAndDoCallback(timer)
            end, 100 * (i - 1))
            self:_AddTimerId(timer)
        end
    end
end

return XUiLineArithmetic2Chapter
