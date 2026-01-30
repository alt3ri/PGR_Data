--- 一个玩家的排行展示，兼容自己和其他玩家
---@class XUiGridTheatre5PVPRankItem: XUiNode
---@field private _Control XTheatre5Control
local XUiGridTheatre5PVPRankItem = XClass(XUiNode, 'XUiGridTheatre5PVPRankItem')
local XUiGridTheatre5PVPRank = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/PVP/XUiGridTheatre5PVPRank')

function XUiGridTheatre5PVPRankItem:OnStart()
    ---@type XUiGridTheatre5PVPRank
    self.Rank = XUiGridTheatre5PVPRank.New(self.UiTheatre5GridDan, self, true)

    if self.BtnHead then
        self.BtnHead.CallBack = handler(self, self.OnBtnHeadClickEvent) 
    end
end

function XUiGridTheatre5PVPRankItem:RefreshShow(rank, playerData, characterLimit)
    self.PlayerId = playerData.Id
    
    -- 排名
    if self.TxtRank then
        if XTool.IsNumberValid(rank) then
            self.TxtRank.text = rank
        else
            self.TxtRank.text = self._Control:GetClientConfigNoRankTips()
        end
    end
    
    -- 头像
    if self.Head then
        XUiPlayerHead.InitPortrait(playerData.HeadPortraitId, playerData.HeadFrameId, self.Head)
    end
    
    -- 名称
    if self.TxtName then
        self.TxtName.text = playerData.Name
    end
    
    -- 积分
    if self.TxtPoint then
        self.TxtPoint.text = playerData.Score
    end
    
    -- 段位
    self.Rank:RefreshByScore(playerData.Score, true, true)
    
    -- 使用的角色 
    local isShowUsedChara = not characterLimit and XTool.IsNumberValid(playerData.Theatre5RankCharacterId)
    
    -- 无有效排名及积分时，总榜也不显示角色
    if not XTool.IsNumberValid(rank) and not XTool.IsNumberValid(playerData.Score) then
        isShowUsedChara = false
    end
    
    self.PanelCharacter.gameObject:SetActiveEx(isShowUsedChara)

    if isShowUsedChara then
        ---@type XTableTheatre5Character
        local charaCfg = self._Control:GetTheatre5CharacterCfgById(playerData.Theatre5RankCharacterId)

        if charaCfg then
            local fashionId = XTool.IsNumberValid(charaCfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Special]) 
                    and charaCfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Special] or 
                    charaCfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
            
            local portrait = self._Control.CharacterControl:GetPortraitByFashionId(fashionId)

            if not string.IsNilOrEmpty(portrait) then
                self.RImgHeadIcon:SetRawImage(portrait)
            end
        end
    end
end

function XUiGridTheatre5PVPRankItem:RefreshRankPercentShow(rank, total)
    -- 实际排名-100 扣除上榜的数量计算百分比
    local percent = math.ceil((rank - 100) * 100 / total)

    if self.TxtRank then
        self.TxtRank.text = XUiHelper.FormatText(self._Control.PVPControl:GetClientConfigRankPercentLabel(), percent)
    end
end

function XUiGridTheatre5PVPRankItem:OnBtnHeadClickEvent()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

return XUiGridTheatre5PVPRankItem