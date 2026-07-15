---@class XUiTheatre6PopupPVPCompare : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PopupPVPCompare = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupPVPCompare")

local XUiPanelTheatre6CharacterAttrDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail")

function XUiTheatre6PopupPVPCompare:OnAwake()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnNext:AddEventListener(handler(self, self.OnBtnNextClick))
    self.BtnLast:AddEventListener(handler(self, self.OnBtnLastClick))
end

---@param roundIndex number 默认查看的场次序号 1-3
---@param lineupDataList table 阵容数据列表
function XUiTheatre6PopupPVPCompare:OnStart(roundIndex, lineupDataList)
    self._RoundIndex = roundIndex
    self._LineupDataList = lineupDataList or {}
    self._TotalRound = #self._LineupDataList

    self:Refresh()
end

function XUiTheatre6PopupPVPCompare:Refresh()
    self:RefreshTitle()
    self:RefreshSwitchButtons()
    self:RefreshContent()
end

function XUiTheatre6PopupPVPCompare:RefreshTitle()
    local titleFormat = self._Control:GetPvpClientConfigValue("CompareRoundTitle")
    self.TxtTitle.text = string.format(titleFormat, XTool.ConvertNumberString(self._RoundIndex))
end

function XUiTheatre6PopupPVPCompare:RefreshSwitchButtons()
    self.BtnLast.gameObject:SetActiveEx(self._RoundIndex > 1)
    self.BtnNext.gameObject:SetActiveEx(self._RoundIndex < self._TotalRound)
end

---@param detail XUiPanelTheatre6CharacterAttrDetail
---@param panel UnityEngine.GameObject
---@param fileData any
---@return XUiPanelTheatre6CharacterAttrDetail
function XUiTheatre6PopupPVPCompare:RefreshRoleDetail(detail, panel, fileData)
    if fileData then
        if not detail then
            detail = XUiPanelTheatre6CharacterAttrDetail.New(panel, self, fileData)
            detail:Open()
        else
            detail:Open()
            detail:SetData(fileData)
        end
    else
        if detail then
            detail:Close()
        else
            panel.gameObject:SetActiveEx(false)
        end
    end
    return detail
end

function XUiTheatre6PopupPVPCompare:RefreshContent()
    local lineupData = self._LineupDataList[self._RoundIndex]
    local myFileData = lineupData and lineupData.MyFileData
    local enemyFileData = lineupData and lineupData.EnemyFileData
    local isMist = lineupData and lineupData.IsMist

    self._MyRoleDetail = self:RefreshRoleDetail(self._MyRoleDetail, self.PanelRoleDetailMe, myFileData)
    self.TxtEmpty.gameObject:SetActiveEx(not myFileData)

    self.ImgMask.gameObject:SetActiveEx(isMist)
    local enemyData = (not isMist) and enemyFileData or nil
    self._EnemyRoleDetail = self:RefreshRoleDetail(self._EnemyRoleDetail, self.PanelRoleDetailEnemy, enemyData)
end

function XUiTheatre6PopupPVPCompare:OnBtnNextClick()
    if self._RoundIndex < self._TotalRound then
        self._RoundIndex = self._RoundIndex + 1
        self:Refresh()
    end
end

function XUiTheatre6PopupPVPCompare:OnBtnLastClick()
    if self._RoundIndex > 1 then
        self._RoundIndex = self._RoundIndex - 1
        self:Refresh()
    end
end

return XUiTheatre6PopupPVPCompare
