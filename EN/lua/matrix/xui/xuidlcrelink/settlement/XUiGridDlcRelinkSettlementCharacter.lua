---@class XUiGridDlcRelinkSettlementCharacter : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiPanelDlcRelinkSettlementCharacter
local XUiGridDlcRelinkSettlementCharacter = XClass(XUiNode, "XUiGridDlcRelinkSettlementCharacter")

function XUiGridDlcRelinkSettlementCharacter:OnStart()
    self.GridTag.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnLike, self.OnBtnLikeClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnReport, self.OnBtnReportClick, true, true)

    ---@type UiObject[]
    self.GridTabList = {}
    self.IsLiked = false
    self.LikeCount = 0
end

function XUiGridDlcRelinkSettlementCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_ADD_LIKE_NOTIFY,
    }
end

function XUiGridDlcRelinkSettlementCharacter:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_ROOM_ADD_LIKE_NOTIFY then
        local fromPlayerId = args[1]
        local toPlayerId = args[2]
        if self.PlayerSettleResult and self.PlayerSettleResult.PlayerId == toPlayerId and self.Parent.GetPlayerNameById then
            self:RefreshLinkBtn()
            local playerName = self.Parent:GetPlayerNameById(fromPlayerId)
            local desc = string.format(self._Control:GetClientConfig("LikeSuccessDesc"), playerName)
            self._Control:OpenCommonLeftTipDialog(desc)
        end
    end
end

---@param playerSettleResult XDlcRelinkPlayerSettleResult
function XUiGridDlcRelinkSettlementCharacter:Refresh(playerSettleResult)
    if not playerSettleResult then
        return
    end
    self.PlayerSettleResult = playerSettleResult

    -- 职业
    local occupationType = playerSettleResult.OccType
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupationType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.RImgIconCareer:SetRawImage(occupationIcon)
    end
    -- 名称
    self.TxtName.text = playerSettleResult.Name
    -- 等级
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), playerSettleResult.EquLevel)
    -- 角色图标
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(playerSettleResult.CharacterId).DefaultNpcFashtionId
    local characterIcon = XDataCenter.FashionManager.GetRoleCharacterBigImage(fashionId)
    if not string.IsNilOrEmpty(characterIcon) then
        self.RImgCharacter:SetRawImage(characterIcon)
    end
    -- 分数
    self.TxtNum.text = playerSettleResult.Score
    -- 战斗称号
    self:RefreshTag(playerSettleResult.BattleTitle)
    -- 刷新按钮
    self:RefreshBtnActive()
end

function XUiGridDlcRelinkSettlementCharacter:RefreshTag(tagIds)
    if XTool.IsTableEmpty(tagIds) then
        self.ListTag.gameObject:SetActiveEx(false)
        return
    end

    self.ListTag.gameObject:SetActiveEx(true)
    for _, tagId in pairs(tagIds) do
        local grid = self.GridTabList[tagId]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTag, self.ListTag)
            self.GridTabList[tagId] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtName").text = self._Control:GetMedalTagName(tagId)
    end

    for i = #tagIds + 1, #self.GridTabList do
        local grid = self.GridTabList[i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridDlcRelinkSettlementCharacter:RefreshBtnActive()
    local isSelf = self.PlayerSettleResult.PlayerId == XPlayer.Id
    self.BtnLike.gameObject:SetActiveEx(not isSelf)
    self.BtnAdd.gameObject:SetActiveEx(not isSelf)
    self.BtnReport.gameObject:SetActiveEx(not isSelf)
end

function XUiGridDlcRelinkSettlementCharacter:RefreshLinkBtn()
    self.LikeCount = self.LikeCount + 1
    self.TxtLikeNum.gameObject:SetActiveEx(self.LikeCount > 1)
    self.BtnLike:SetDisable(true)
end

function XUiGridDlcRelinkSettlementCharacter:SetTagBest(isBest)
    self.TagBest.gameObject:SetActiveEx(isBest)
    self.PanelTips.gameObject:SetActiveEx(not isBest)
end

function XUiGridDlcRelinkSettlementCharacter:OnBtnLikeClick()
    if not self.PlayerSettleResult then
        return
    end
    if self.PlayerSettleResult.PlayerId == XPlayer.Id then
        return
    end

    if not self.IsLiked then
        self.IsLiked = true
        XMVCA.XDlcRoom:AddLike(self.PlayerSettleResult.PlayerId)
        self:RefreshLinkBtn()
    end
end

function XUiGridDlcRelinkSettlementCharacter:OnBtnAddClick()
    if not self.PlayerSettleResult then
        return
    end
    if self.PlayerSettleResult.PlayerId == XPlayer.Id then
        return
    end

    XDataCenter.SocialManager.ApplyFriend(self.PlayerSettleResult.PlayerId)
end

function XUiGridDlcRelinkSettlementCharacter:OnBtnReportClick()
    if not self.PlayerSettleResult then
        return
    end
    if self.PlayerSettleResult.PlayerId == XPlayer.Id then
        return
    end

    local data = {
        Id = self.PlayerSettleResult.PlayerId,
        TitleName = self.PlayerSettleResult.Name,
    }
    XLuaUiManager.Open("UiReport", data, nil, nil, XReportConfigs.EnterType.DlcMultiplayer)
end

return XUiGridDlcRelinkSettlementCharacter
