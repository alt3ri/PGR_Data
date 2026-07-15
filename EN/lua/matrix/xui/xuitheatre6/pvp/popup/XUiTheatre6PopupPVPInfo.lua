---@class XUiTheatre6PopupPVPInfo : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6PopupPVPInfo = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupPVPInfo")

local XUiGridTheatre6PvpMember = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpMember")
local XUiGridTheatre6PvpRank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank")
local XUiPanelTheatre6CharacterAttrDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail")

function XUiTheatre6PopupPVPInfo:OnAwake()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnBack:AddEventListener(handler(self, self.Close))

    self.PanelRoleDetail.gameObject:SetActiveEx(false)
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

---@param playerData table 玩家数据，包含玩家基本信息、段位信息、防守阵容等
function XUiTheatre6PopupPVPInfo:OnStart(playerData)
    self._PlayerData = playerData
    ---@type XUiGridTheatre6PvpMember
    self._MemberGrid = nil
    ---@type XUiGridTheatre6PvpRank
    self._RankGrid = nil
    ---@type table<number, XUiPanelTheatre6CharacterAttrDetail>
    self._RoleDetailPanelList = {}
end

function XUiTheatre6PopupPVPInfo:OnEnable()
    self:RefreshPlayer()
    self:RefreshRoleDetail()
    self:RefreshEnvironment()
end

function XUiTheatre6PopupPVPInfo:RefreshPlayer()
    if not self._MemberGrid then
        self._MemberGrid = XUiGridTheatre6PvpMember.New(self.GridMember, self)
    end
    self._MemberGrid:Open()
    self._MemberGrid:Refresh(self._PlayerData.Name, self._PlayerData.HeadPortraitId, self._PlayerData.HeadFrameId, self._PlayerData.PlayerId)

    if not self._RankGrid then
        self._RankGrid = XUiGridTheatre6PvpRank.New(self.GridRank, self)
    end
    self._RankGrid:Open()
    self._RankGrid:SetData(self._PlayerData.RankId)
    self._RankGrid:SetRankScore(self._PlayerData.Score)
end

function XUiTheatre6PopupPVPInfo:RefreshRoleDetail()
    local fileDataList = self._PlayerData.FileDataList or {}
    local count = #fileDataList
    if count <= 0 then
        self.ListRoleDetail.gameObject:SetActiveEx(false)
        return
    end
    self.ListRoleDetail.gameObject:SetActiveEx(true)
    for i = 1, count do
        local grid = self._RoleDetailPanelList[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.PanelRoleDetail, self.ListRoleDetail)
            grid = XUiPanelTheatre6CharacterAttrDetail.New(go, self, fileDataList[i])
            self._RoleDetailPanelList[i] = grid
        end
        grid:Open()
    end
    for i = count + 1, #self._RoleDetailPanelList do
        local grid = self._RoleDetailPanelList[i]
        if grid then
            grid:Close()
        end
    end
end

function XUiTheatre6PopupPVPInfo:RefreshEnvironment()
    local buffId = self._PlayerData.BuffId or 0
    if not XTool.IsNumberValid(buffId) then
        self.PanelEnvironment.gameObject:SetActiveEx(false)
        return
    end
    local buffConfig = self._Control:GetPvpBuffConfig(buffId)
    if not buffConfig then
        self.PanelEnvironment.gameObject:SetActiveEx(false)
        return
    end
    self.PanelEnvironment.gameObject:SetActiveEx(true)
    self.TxtName.text = buffConfig.Name
    self.TxtDesc.text = self._Control:GetPvpBuffDesc(buffId)
    self.BtnEnvironment:SetRawImageEx(buffConfig.Icon)
end

return XUiTheatre6PopupPVPInfo
