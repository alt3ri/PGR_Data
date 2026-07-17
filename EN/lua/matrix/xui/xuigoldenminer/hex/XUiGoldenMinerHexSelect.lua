---@class XUiGoldenMinerHexSelect : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerHexSelect = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerHexSelect")
local XUiGridGoldenMinerHex = require('XUi/XUiGoldenMiner/Hex/XUiGridGoldenMinerHex')
local XUiPanelGoldenMinerOwnHex = require('XUi/XUiGoldenMiner/Hex/XUiPanelGoldenMinerOwnHex')

function XUiGoldenMinerHexSelect:OnAwake()
    self:AddBtnListener()
    self._PanelOverview = XUiPanelGoldenMinerOwnHex.New(self.PanelOverview, self)
    self._PanelOverview:Open()
end

function XUiGoldenMinerHexSelect:OnStart()
    self:InitTimes()
    self._CurState = self._Control:GetMainDb():GetCurrentState()
    local isCurStateCoreHex = self._CurState == XMVCA.XGoldenMiner.EnumConst.GameState.CoreHexSelect
    
    self.TxtNameCommon.gameObject:SetActiveEx(not isCurStateCoreHex)
    self.TxtNameHex.gameObject:SetActiveEx(isCurStateCoreHex)
    
    self.BtnRefresh.gameObject:SetActiveEx(not isCurStateCoreHex)
    self.TxtTip.gameObject:SetActiveEx(not isCurStateCoreHex)
end

function XUiGoldenMinerHexSelect:OnEnable()
    self:RefreshAll()
end

function XUiGoldenMinerHexSelect:RefreshAll()
    self._PanelOverview:RefreshOwnHexShow()
    self:RefreshHexList(self._SelectIndex)
    self:UpdateTitleScore()
    self:UpdateRefreshTimes()
end

--region Activity - AutoClose
function XUiGoldenMinerHexSelect:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Ui - HexList
function XUiGoldenMinerHexSelect:RefreshHexList(defaultIndex)
    self._SelectHex = nil
    self._SelectIndex = nil
    self._CurState = self._Control:GetMainDb():GetCurrentState()

    if self._CurState == XMVCA.XGoldenMiner.EnumConst.GameState.CoreHexSelect then
        self._HexList = self._Control:GetMainDb():GetCoreGenerateResults()
    elseif self._CurState == XMVCA.XGoldenMiner.EnumConst.GameState.CommonHexSelect then
        self._HexList = self._Control:GetMainDb():GetCommonGenerateResults()
    else
        XLog.Error('错误的游戏状态：'..tostring(self._CurState))
    end

    if self._GridHexDict == nil then
        self._GridHexDict = {}
    else
        for i, v in pairs(self._GridHexDict) do
            v:Close()
        end
    end
    
    self._GridHexList = {}
    local buttonList = {}
    
    XUiHelper.RefreshCustomizedList(self.PanelHexList.transform, self.GridHex, self._HexList and #self._HexList or 0, function(index, go)
        local grid = self._GridHexDict[go]

        if not grid then
            grid = XUiGridGoldenMinerHex.New(go, self)
            self._GridHexDict[go] = grid
        end
        grid:Open()
        self:RefreshHexGrid(self._HexList[index], grid)
        
        table.insert(self._GridHexList, grid)

        local btn = grid:GetButton()

        if btn then
            table.insert(buttonList, btn)
        end
    end)

    if not XTool.IsTableEmpty(buttonList) then
        self.PanelHexList:Init(buttonList, handler(self, self.SelectHex))
        
        local index = defaultIndex

        if self:CheckGridIsHaveByIndex(index) then
            index = self:GetFirstNotHaveGridIndex()
        end
        
        self.PanelHexList:SelectIndex(index)
    end
end

function XUiGoldenMinerHexSelect:SelectHex(index)
    if self._SelectHex == self._HexList[index] then
        return
    end
    if self:CheckGridIsHaveByIndex(index) then
            XUiManager.TipMsg(self._Control:GetClientHexSelectAgainTips(self._HexList[index].Type))
        return
    end
    self._SelectHex = self._HexList[index]
    self._SelectIndex = index
end

function XUiGoldenMinerHexSelect:RefreshHexGrid(hexData, grid)
    local itemType = hexData.Type
    local showId = hexData.Id
    local showType = XMVCA.XGoldenMiner.EnumConst.ItemShowType.CoreHex

    if itemType == XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Hex then
        if self._Control:GetCfgHexType(showId) == XMVCA.XGoldenMiner.EnumConst.HexType.Core then
            showType = XMVCA.XGoldenMiner.EnumConst.ItemShowType.CoreHex
        else
            showType = XMVCA.XGoldenMiner.EnumConst.ItemShowType.CommonHex
        end
    else
        showType = XMVCA.XGoldenMiner.EnumConst.ItemShowType.Update
    end

    grid:RefreshShow(showType, itemType, showId)
end

function XUiGoldenMinerHexSelect:GetFirstNotHaveGridIndex()
    for i, v in ipairs(self._GridHexList) do
        if not v:GetIsHave() then
            return i
        end
    end
end

function XUiGoldenMinerHexSelect:CheckGridIsHaveByIndex(index)
    local grid = self._GridHexList[index]

    if grid then
        return grid:GetIsHave()
    end
    
    return true
end
--endregion

--region Ui - TitleScore
function XUiGoldenMinerHexSelect:UpdateTitleScore()
    if not self.TextCurScore then
        return
    end
    self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", self._Control:GetMainDb():GetStageScores())
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerHexSelect:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
    self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClick))
end

function XUiGoldenMinerHexSelect:OnBtnBackClick()
    self._Control:OpenGiveUpGameTip()
end

function XUiGoldenMinerHexSelect:OnBtnSelectClick()
    if XTool.IsTableEmpty(self._SelectHex) then
        XUiManager.TipErrorWithKey("GoldenMinerPleaseSelectHex")
        return
    end
    
    local grid = self._GridHexList[self._SelectIndex or 0]

    if grid and grid:GetIsHave() then
        -- 目前按钮组组件不会选中到disable的格子，先不做表现
        return
    end
    
    if self._SelectHex.Type == XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Hex then
        -- 核心海克斯不能超过上限
        if self._Control:GetCfgHexType(self._SelectHex.Id) == XMVCA.XGoldenMiner.EnumConst.HexType.Core then
            -- 选择前需要判断自己的海克斯有没达到上限
            local hexCount = self._Control:GetSelectedCoreHexCount()
            local hexSlotCount = self._Control:GetClientHexOwnCount()

            if hexCount >= hexSlotCount then
                XUiManager.TipMsg(self._Control:GetClientHexSelectTipsInNoEmptySlot())
                return
            end
        end
        
        local lastState = self._CurState
        
        self._Control:RequestGoldenMinerSelectHex(self._SelectHex.Id, function()
            if lastState == XMVCA.XGoldenMiner.EnumConst.GameState.CommonHexSelect and self._Control:GetCommonHexSelectLeftCount() > 0 then
                self:RefreshAll()
            else
                self._Control:OpenGameUi()
            end
        end)
    elseif self._SelectHex.Type == XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Update then
        local lastState = self._CurState
        
        self._Control:RequestGoldenMinerHexUpgrade(self._SelectHex.Id, function()
            if lastState == XMVCA.XGoldenMiner.EnumConst.GameState.CommonHexSelect and self._Control:GetCommonHexSelectLeftCount() > 0 then
                self:RefreshAll()
            else
                self._Control:OpenGameUi()
            end
        end)    
    end
end

function XUiGoldenMinerHexSelect:OnBtnRefreshClick()
    if self._Control:CheckCanRefreshCommonHexSelect() then
        self._Control:RequestGoldenMinerRefreshCommonRandom(function()
            self:RefreshAll()
        end)
    else
        XUiManager.TipMsg(self._Control:GetClientCommonHexRefreshTimesOverTips())
    end
end
--endregion

function XUiGoldenMinerHexSelect:UpdateRefreshTimes()
    if self._CurState == XMVCA.XGoldenMiner.EnumConst.GameState.CommonHexSelect then
        self.TxtNum.text = self._Control:GetCommonHexSelectLeftCount()
        self.BtnRefresh:SetNameByGroup(0, XUiHelper.FormatText(self._Control:GetClientCommonHexRefreshLabel(), self._Control:GetCommonHexRefreshLeftCount(), self._Control:GetCommonHexRefreshMaxCount()))
    end
end

return XUiGoldenMinerHexSelect