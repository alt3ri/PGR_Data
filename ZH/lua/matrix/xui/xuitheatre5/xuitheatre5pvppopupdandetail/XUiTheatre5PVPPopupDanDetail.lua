--- 段位详情界面
---@class XUiTheatre5PVPPopupDanDetail: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVPPopupDanDetail = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVPPopupDanDetail')
local XUiGridTheatre5PVPRankDetail = require('XUi/XUiTheatre5/XUiTheatre5PVPPopupDanDetail/XUiGridTheatre5PVPRankDetail')

function XUiTheatre5PVPPopupDanDetail:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = self.BtnBack.CallBack
end

function XUiTheatre5PVPPopupDanDetail:OnStart(charaConfigId)
    self.CharaConfigId = charaConfigId
    self.TxtDescription.text = self._Control.PVPControl:GetPVPRankDetailDescFromClientConfig()
    
    self:InitRankMajors()
end

function XUiTheatre5PVPPopupDanDetail:InitRankMajors()
    local majorCfgs = self._Control.PVPControl:GetPVPRankMajorCfgs()
    
    local characterData = self._Control.PVPControl:GetPVPCharacterDataById(self.CharaConfigId, true)
    
    local curMajorId = characterData and self._Control.PVPControl:GetPVPRankMajorIdByRatingScore(characterData.Rating) or -1
    
    self.RankGrids = {}
    
    XUiHelper.RefreshCustomizedList(self.ListDan, self.GridDan, majorCfgs and #majorCfgs or 0, function(index, go)
        local grid = self.RankGrids[go]

        if not grid then
            grid = XUiGridTheatre5PVPRankDetail.New(go, self)
            self.RankGrids[go] = grid
        end
        
        grid:Open()
        
        local majorCfg = majorCfgs[index]
        local state

        if curMajorId == majorCfg.Id then
            state = XMVCA.XTheatre5.EnumConst.RankMajorState.Belong
        elseif curMajorId < majorCfg.Id then
            state = XMVCA.XTheatre5.EnumConst.RankMajorState.Below
        else
            state = XMVCA.XTheatre5.EnumConst.RankMajorState.Beyond
        end
        
        grid:RefreshShow(majorCfg, self.CharaConfigId, state)
    end)
end

return XUiTheatre5PVPPopupDanDetail