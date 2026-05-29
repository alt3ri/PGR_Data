local XUiFashionSuitLobbyGridTab = require("XUi/XUiFashionSuit/XUiFashionSuitLobby/XUiFashionSuitLobbyGridTab")
local XUiFashionSuitLobbyPanelRight = require("XUi/XUiFashionSuit/XUiFashionSuitLobby/XUiFashionSuitLobbyPanelRight")
local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")

---@field _Control XFashionSuitControl
---@field BtnBack XUiButton
---@field BtnMainUi XUiButton
---@field GridTab UiObject
---@field Grid256New UiObject
---@field BtnTongBlue XUiButton
---@field PanelRight UiObject
---@class XUiFashionSuitLobby : XLuaUi
local XUiFashionSuitLobby = XLuaUiManager.Register(XLuaUi, "UiFashionSuitLobby")
--[=====[AUTO GENERATED END: CLASS]=====]

--[=====[AUTO GENERATED START: LIFECYCLE]=====]
function XUiFashionSuitLobby:OnAwake()
    self:InitComponents()
end

function XUiFashionSuitLobby:InitComponents()
    -- Back Mainui Help
    self:BindExitBtns()

    -- Button
    self.BtnTongBlue:AddEventListener(function() self:OnBtnTongBlueClick() end)

    -- XUiNode
    self.PanelRight = XUiFashionSuitLobbyPanelRight.New(self.PanelRight, self)
    self.NewUiRImgPics = {self.UiRImgPic1,self.UiRImgPic2}
    self.CurUiRImgPics  = {self.UiRImgPic3,self.UiRImgPic4}
    self.NewUiRimgPicCGs  = {self.UiRImgPicCG3,self.UiRImgPicCG4}
    self.CurUiRimgPicCGs   = {self.UiRImgPicCG1,self.UiRImgPicCG2}    
end

function XUiFashionSuitLobby:OnStart(...)       
    self:InitGridTabs()
    self._IsFirstEnable = true
    self:Update()
    if self._Control:GetNoticeFashionSuitIds() then
        XLuaUiManager.Open("UiFashionSuitPopupNew", self._Control:GetNoticeFashionSuitIds())
    end
end

function XUiFashionSuitLobby:OnEnable()
    if self._IsFirstEnable then
        self._IsFirstEnable = false
        return
    end
    self:Update()
end

function XUiFashionSuitLobby:OnDisable()
end

function XUiFashionSuitLobby:OnDestroy()
end

--[=====[AUTO GENERATED END: LIFECYCLE]=====]

--[=====[AUTO GENERATED START: INIT_COMPONENTS]=====]
function XUiFashionSuitLobby:Update()
    if not self._DynamicTable then
        return
    end
    self._TabCfgs = self._Control:GetFashionSuitConfigsSort() or {}
    self._DynamicTable:SetDataSource(self._TabCfgs)
    if XTool.IsTableEmpty(self._TabCfgs) then
        self._CurSelectIndex = 0
        return
    end

    local curCfg = self._TabCfgs[self._CurSelectIndex]
    if not curCfg or curCfg.Type == self._Control.FashionSuitType.Lock then
        self._CurSelectIndex = self:GetDefaultSelectIndex()
    end

    self._DynamicTable:ReloadData(self._CurSelectIndex - 1)
    self:ApplyCurrentSelection()
end

function XUiFashionSuitLobby:InitGridTabs()
    self.GridTab.gameObject:SetActiveEx(false)
    if self._DynamicTable or self._IsDynamicTableInitFailed then
        return
    end

    self._DynamicTable = XDynamicTableCurve.New(self.PanelCdList)
    if not self._DynamicTable then
        self._IsDynamicTableInitFailed = true
        return
    end
    self._DynamicTable.Imp.MoveType = CS.XDynamicTableCurve.MovementType.Elastic
    self._DynamicTable:SetProxy(XUiFashionSuitLobbyGridTab, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiFashionSuitLobby:GetDefaultSelectIndex()
    if XTool.IsTableEmpty(self._TabCfgs) then
        return 0
    end

    local defaultIndex = 1
    for index, cfg in ipairs(self._TabCfgs) do
        if cfg.Type ~= self._Control.FashionSuitType.Lock then
            defaultIndex = index
            break
        end
    end

    return defaultIndex
end

function XUiFashionSuitLobby:GetLuaIndexByCurveIndex(curveIndex)
    local totalCount = self._TabCfgs and #self._TabCfgs or 0
    if totalCount <= 0 or curveIndex < 0 or curveIndex >= totalCount then
        return 0
    end
    return curveIndex + 1
end

function XUiFashionSuitLobby:RefreshTabSelection()
    if not self._DynamicTable then
        return
    end

    local startIndex = self._DynamicTable.Imp.StartIndex
    for curveIndex, grid in pairs(self._DynamicTable:GetGrids() or {}) do
        grid:SetSelect(curveIndex == startIndex)
    end
end

function XUiFashionSuitLobby:ApplyCurrentSelection()
    if not self._DynamicTable then
        return
    end

    local luaIndex = self:GetLuaIndexByCurveIndex(self._DynamicTable.Imp.StartIndex)
    local cfg = self._TabCfgs[luaIndex]
    if cfg then
        self._CurSelectIndex = luaIndex
    end
    self:RefreshTabSelection()
    if cfg then
        self:OnGridTabClick(cfg)
    end
end

---@param grid XUiFashionSuitLobbyGridTab
function XUiFashionSuitLobby:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local luaIndex = self:GetLuaIndexByCurveIndex(index)
        local cfg = self._TabCfgs[luaIndex]
        if not cfg then
            return
        end
        grid:Update(cfg)
        grid:SetSelect(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local luaIndex = self:GetLuaIndexByCurveIndex(self._DynamicTable.Imp.StartIndex)
        local cfg = self._TabCfgs[luaIndex]
        if cfg and cfg.Type == self._Control.FashionSuitType.Lock then
            XUiManager.TipMsg(XUiHelper.GetText("FashionSuitProgress2"))
            if XTool.IsNumberValid(self._CurSelectIndex) then
                self._DynamicTable.Imp:TweenToIndex(self._CurSelectIndex - 1)
            end
            return
        end
        self:ApplyCurrentSelection()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:TrySelectTab(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        for _, g in pairs(self._DynamicTable:GetGrids() or {}) do
            g:SetSelect(false)
        end
    end
end

---@param grid XUiFashionSuitLobbyGridTab
function XUiFashionSuitLobby:TrySelectTab(curveIndex, grid)
    local cfg = self._TabCfgs[self:GetLuaIndexByCurveIndex(curveIndex)]
    if not cfg then
        return
    end

    if self._DynamicTable.Imp.StartIndex == curveIndex then
        self:ApplyCurrentSelection()
        return
    end

    self._DynamicTable.Imp:TweenToIndex(curveIndex)
end

--[=====[AUTO GENERATED END: INIT_COMPONENTS]=====]

function XUiFashionSuitLobby:OnBtnTongBlueClick()
    XLuaUiManager.Open("UiFashionSuitPopupNew")
end
function XUiFashionSuitLobby:OnGridTabClick(cfg)
    if cfg.Type == self._Control.FashionSuitType.Lock then
        XUiManager.TipMsg(XUiHelper.GetText("FashionSuitProgress2"))
        return
    end
    if self.CurSelectCfg then
        if self.CurSelectCfg.Sort < cfg.Sort then
            self:PlayAnimationWithMask("TabToLeft")
        elseif self.CurSelectCfg.Sort > cfg.Sort then
            self:PlayAnimationWithMask("TabToRight")
        end
    end

    self:UpdateUiRimgPic(cfg)
    self.CurSelectCfg = cfg
    self.PanelRight:Refresh(cfg)
end

local function SetRawImageList(rimgList, path)
    for _, rimg in ipairs(rimgList) do
        rimg:SetRawImage(path)
    end
end

function XUiFashionSuitLobby:UpdateUiRimgPic(cfg)
    local newUiCfg = self._Control:GetFashionSuitUiConfigById(cfg.Id)
    if not self.CurSelectCfg then
        SetRawImageList(self.CurUiRImgPics, newUiCfg.SuitBackground)
        SetRawImageList(self.CurUiRimgPicCGs, newUiCfg.FirstBg)
        SetRawImageList(self.NewUiRImgPics, newUiCfg.SuitBackground)
        return
    end

    local oldUiCfg = self._Control:GetFashionSuitUiConfigById(self.CurSelectCfg.Id)
    SetRawImageList(self.CurUiRImgPics, oldUiCfg.SuitBackground)
    SetRawImageList(self.NewUiRimgPicCGs, oldUiCfg.FirstBg)
    SetRawImageList(self.NewUiRImgPics, newUiCfg.SuitBackground)
    SetRawImageList(self.CurUiRimgPicCGs, newUiCfg.FirstBg)
end

return XUiFashionSuitLobby
