---@class XUiGridDlcRelinkSettlementCharacter : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiPanelDlcRelinkSettlementCharacter
local XUiGridDlcRelinkSettlementCharacter = XClass(XUiNode, "XUiGridDlcRelinkSettlementCharacter")

function XUiGridDlcRelinkSettlementCharacter:OnStart()
    self.GridTag.gameObject:SetActiveEx(false)
    self.BtnLike:AddEventListener(handler(self, self.OnBtnLikeClick), true, true, 0.5)
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
    self.BtnReport:AddEventListener(handler(self, self.OnBtnReportClick))

    ---@type UiObject[]
    self.GridTabList = {}
    self.IsLiked = false
end

function XUiGridDlcRelinkSettlementCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_LIKE_NOTIFY,
    }
end

function XUiGridDlcRelinkSettlementCharacter:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_RELINK_LIKE_NOTIFY then
        self:RefreshLikeBtn()
    end
end

---@param playerSettleResult XDlcRelinkPlayerSettleResult
---@param customDatas table<number, table<number, number>> @第一层是playerId-customdata
function XUiGridDlcRelinkSettlementCharacter:Refresh(playerSettleResult, customDatas, fixedScore)
    if not playerSettleResult then
        return
    end
    self.PlayerSettleResult = playerSettleResult

    -- 职业
    local occupationIcon = self._Control:GetCharacterOccupationIconTwo(playerSettleResult.CharacterId, playerSettleResult.StyleType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.RImgIconCareer:SetRawImage(occupationIcon)
    end
    -- 名称
    self.TxtName.text = playerSettleResult.Name
    -- 等级
    self.TxtLv.text = playerSettleResult.EquLevel
    -- 角色图标
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(playerSettleResult.CharacterId).DefaultNpcFashtionId
    local characterIcon = XDataCenter.FashionManager.GetRoleCharacterBigImage(fashionId)
    if not string.IsNilOrEmpty(characterIcon) then
        self.RImgCharacter:SetRawImage(characterIcon)
    end
    -- 分数
    self.TxtNum.text = fixedScore
    -- 战斗称号
    local battleTitleIds = self._Control:GetBattleTitleIdsByCustomData(customDatas, playerSettleResult.PlayerId)

    self:RefreshTag(battleTitleIds)
    -- 刷新按钮
    self:RefreshBtnActive()
    -- 刷新点赞按钮
    self:RefreshLikeBtn()
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
        local tagName = self._Control:GetMedalTagName(tagId)
        grid:GetObject("BtnTag"):SetNameByGroup(0, tagName)
        grid:GetObject("BtnTag"):AddEventListener(function()
            if self.Parent and self.Parent.Parent and self.Parent.Parent.OnShowPanelDetail then
                self.Parent.Parent:OnShowPanelDetail(grid.transform, tagId)
            end
        end)
    end

    local tagCount = XTool.GetTableCount(tagIds)

    for i = tagCount + 1, #self.GridTabList do
        local grid = self.GridTabList[i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridDlcRelinkSettlementCharacter:RefreshBtnActive()
    local isSelf = self.PlayerSettleResult.PlayerId == XPlayer.Id
    self.BtnAdd.gameObject:SetActiveEx(not isSelf)
    self.BtnReport.gameObject:SetActiveEx(not isSelf)
end

function XUiGridDlcRelinkSettlementCharacter:RefreshLikeBtn()
    local likeCount = self._Control:GetPlayerLikeCount(self.PlayerSettleResult.PlayerId)
    local isSelf = self.PlayerSettleResult.PlayerId == XPlayer.Id
    self.BtnLike.gameObject:SetActiveEx(likeCount > 0 or not isSelf)
    self.BtnLike:SetNameByGroup(0, string.format("×%d", likeCount))
    self.BtnLike:SetDisable(likeCount > 0, not isSelf and not self.IsLiked)
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
        self._Control:RequestLike(self.PlayerSettleResult.PlayerId, function()
            self.IsLiked = true
            self:RefreshLikeBtn()
            self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcRoomAddLikeSuccess"))
        end)
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
