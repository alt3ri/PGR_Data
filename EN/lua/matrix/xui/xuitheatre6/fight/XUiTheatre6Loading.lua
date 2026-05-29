---@class XUiTheatre6Loading : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6Loading = XLuaUiManager.Register(XLuaUi, "UiTheatre6Loading")

function XUiTheatre6Loading:OnStart()
    local roomData = self._Control:GetCurRoomData()
    local monsterId = roomData.SelectedMonsterId
    local characterId = self._Control:GetMonsterConfig(monsterId).CharacterId
    local characterConfig = self._Control:GetCharacterConfig(characterId)
    local portrait = self._Control:GetFashionConfig(characterConfig.FashionIds[1]).BigPortrait
    
    local starCount = 0
    if XTool.IsNumberValid(roomData.FightId) then
        local fightConfig = self._Control:GetStageFightCfgById(roomData.FightId)
        if fightConfig.EasyMonsterId == monsterId then
            starCount = self._Control:GetIntClientConfigValue("EasyMonsterStar")
        else
            starCount = self._Control:GetIntClientConfigValue("HardMonsterStar")
        end
    else
        XLog.Error(string.format("FightId无效 房间索引【%s】房间类型【%s】", roomData.RoomIdx, roomData.RoomType))
    end

    self.TxtName.text = characterConfig.Name
    self.RImgEnemy:SetRawImage(portrait)
    self.ImgStat.gameObject:SetActiveEx(false)
    XUiHelper.RefreshCustomizedList(self.ImgStat.parent, self.ImgStat, starCount, nil, true)

    --LevelId暂时没用到
    XMVCA.XTheatre6.Battle:RequestDlcSingleEnterFight(0, function()
        XLuaUiManager.SafeClose("UiTheatre6RoomBoss")
    end, function()
        self:Close()
    end)
end

return XUiTheatre6Loading