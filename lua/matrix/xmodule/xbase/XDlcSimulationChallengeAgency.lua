local XFubenSimulationChallengeAgency = require("XModule/XBase/XFubenSimulationChallengeAgency")
local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")

---@class XDlcSimulationChallengeAgency : XFubenSimulationChallengeAgency
local XDlcSimulationChallengeAgency = XClass(XFubenSimulationChallengeAgency, "XDlcSimulationChallengeAgency")

function XDlcSimulationChallengeAgency:DlcCheckClickHrefCanEnter(roomId, nodeId, worldId, createTime)
    if not self:DlcCheckActivityInTime() then
        XUiManager.TipText("CommonActivityEnd")
        return false
    end

    if XTime.GetServerNowTimestamp() > createTime + XMVCA.XDlcRoom:GetInviteChatCacheTime() then
        XUiManager.TipText("RoomHrefDisabled")
        return false
    end

    return true
end

function XDlcSimulationChallengeAgency:DlcGetRoomProxy()
    return XDlcRoom.New()
end

function XDlcSimulationChallengeAgency:DlcGetFightEvent()
    return XDlcWorldFight.New()
end

function XDlcSimulationChallengeAgency:DlcReconnect()
    XMVCA.XDlcRoom:ReconnectToWorld()
end

function XDlcSimulationChallengeAgency:DlcActivityTimeOutRunMain()
    XLuaUiManager.RunMain(true)
    XUiManager.TipText("CommonActivityEnd")
end

function XDlcSimulationChallengeAgency:DlcGetPlayerCustomData()
    return nil
end

function XDlcSimulationChallengeAgency:DlcInitFight()
    XMVCA.XDlcRoom:InitFight()
end

function XDlcSimulationChallengeAgency:DlcCheckActivityInTime()
    return false
end

function XDlcSimulationChallengeAgency:DlcRegisterChapter()
    self:RegisterChapterAgency()
    XMVCA.XDlcWorld:RegisterActivity(self:DlcGetWorldType(), self:GetId())
end

function XDlcSimulationChallengeAgency:DlcGetWorldType()
    return nil
end

function XDlcSimulationChallengeAgency:DlcGetNonnegativeAttribs()
    return {
        [XDlcNpcAttribType.Life] = true,
        [XDlcNpcAttribType.CharacterValue] = true,
        [XDlcNpcAttribType.ExSkillPoint] = true,
        [XDlcNpcAttribType.IdleSpinningSpeed] = true,
        [XDlcNpcAttribType.RunSpinningSpeed] = true,
        [XDlcNpcAttribType.CustomEnergyGroup1] = true,
        [XDlcNpcAttribType.CustomEnergyGroup2] = true,
        [XDlcNpcAttribType.CustomEnergyGroup3] = true,
        [XDlcNpcAttribType.CustomEnergyGroup4] = true,
        [XDlcNpcAttribType.Speed] = true,
        [XDlcNpcAttribType.JumpSpeed] = true,
        [XDlcNpcAttribType.RunSpeed] = true,
        [XDlcNpcAttribType.RunSpeedCOE] = true,
        [XDlcNpcAttribType.JumpSpeedCOE] = true,
        [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
        [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RotationSpeed] = true,
        [XDlcNpcAttribType.WalkSpeed] = true,
        [XDlcNpcAttribType.WalkSpeedCOE] = true,
        [XDlcNpcAttribType.SprintSpeed] = true,
        [XDlcNpcAttribType.SprintSpeedCOE] = true,
        [XDlcNpcAttribType.BreakGauge] = true,
        [XDlcNpcAttribType.OverDrive] = true,
    }
end

function XDlcSimulationChallengeAgency:DlcGetEnlargedAttribs()
    return {
        [XDlcNpcAttribType.Speed] = true,
        [XDlcNpcAttribType.JumpSpeed] = true,
        [XDlcNpcAttribType.RunSpeed] = true,
        [XDlcNpcAttribType.RunSpeedCOE] = true,
        [XDlcNpcAttribType.JumpSpeedCOE] = true,
        [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
        [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RotationSpeed] = true,
        [XDlcNpcAttribType.WalkSpeed] = true,
        [XDlcNpcAttribType.WalkSpeedCOE] = true,
        [XDlcNpcAttribType.SprintSpeed] = true,
        [XDlcNpcAttribType.SprintSpeedCOE] = true,
    }
end

function XDlcSimulationChallengeAgency:DlcGetWorldNpcBornMagicLevelMap(worldNpcData)
    return {}
end

function XDlcSimulationChallengeAgency:DlcGetNpcAttrib(worldNpcData)
    local npcId = worldNpcData.Id
    local attribId = self:DlcGetAttribIdByNpcId(npcId)
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

function XDlcSimulationChallengeAgency:DlcGetBaseAttrib(npcId)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    local attribId = template.AttribId
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

function XDlcSimulationChallengeAgency:DlcGetAttribIdByNpcId(npcId)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    return template.AttribId
end

function XDlcSimulationChallengeAgency:DlcParseToXAttribs(attribConfig)
    local result = {}
    local nonnegativeAttribs = self:DlcGetNonnegativeAttribs() or {}
    local enlargedAttribs = self:DlcGetEnlargedAttribs() or {}

    for attribStr, attribId in pairs(XDlcNpcAttribType) do
        result[attribId + 1] = 0
    end
    for attrStr, attrValue in pairs(attribConfig) do
        if attrValue then
            local attribId = XDlcNpcAttribType[attrStr]

            if attribId then
                if enlargedAttribs[attribId] then
                    result[attribId + 1] = attrValue * 1000
                else
                    result[attribId + 1] = attrValue
                end
            end
        end
    end
    for attribId, attrValue in pairs(result) do
        local allowNegative = not (nonnegativeAttribs[attribId - 1] or false)

        -- 必须取整，因为XAttrib.Value为int
        attrValue = math.floor(attrValue + 0.5)
        result[attribId] = CS.StatusSyncFight.XAttrib.Ctor(attrValue, allowNegative)
    end

    --- 特殊处理 先保留例子
    -- xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))

    return result
end

function XDlcSimulationChallengeAgency:DlcOpenInviteUi(inviteData)
    XLuaUiManager.Open("UiDlcMultiPlayerInvitationPopup", inviteData)
end

function XDlcSimulationChallengeAgency:DlcCheckInviteUiShow()
    return XLuaUiManager.IsUiShow("UiDlcMultiPlayerInvitationPopup")
end

return XDlcSimulationChallengeAgency
