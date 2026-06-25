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
    local worldId = self._Control:GetWorldId()
    XMVCA.XTheatre6.Battle:RequestDlcSingleEnterFight(worldId, 0, false, false, function()
        self:Close()
    end)

    --多指触屏处理：一个手指选中BOSS，另一个手指点击任意按钮打开弹框，这时松开第一只手，就会把弹框界面带入战斗
    --方案一：Input.multiTouchEnabled；方案二：加Mask屏蔽点击；方案三：进战斗时销毁所有界面，退出时再恢复......
    --v4.5这里采取风险和修改最少的方案
    XLuaUiManager.SafeClose("UiTheatre6BubbleBuffDetail")
    XLuaUiManager.SafeClose("UiTheatre6BubbleRelicDetail")
    XLuaUiManager.SafeClose("UiTheatre6BubbleTagDetail")
    XLuaUiManager.SafeClose("UiTheatre6BubbleSkillDetail")
    XLuaUiManager.SafeClose("UiTheatre6BubbleAttackDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupGoodsDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupBossCompare")
    XLuaUiManager.SafeClose("UiTheatre6PopupRoleDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupSanDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupRelicDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupCommon")
    XLuaUiManager.SafeClose("UiTheatre6PopupBuffDetail")
    XLuaUiManager.SafeClose("UiTheatre6PopupGetBuff")
    XLuaUiManager.SafeClose("UiTheatre6PopupSellSkill")
    XLuaUiManager.SafeClose("UiTheatre6PopupSkillLevelUp")
    XLuaUiManager.SafeClose("UiTheatre6BossPreview")
end

return XUiTheatre6Loading
