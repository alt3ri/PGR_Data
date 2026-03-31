local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")

---@class XDlcActivityAgency : XFubenActivityAgency
local XDlcActivityAgency = XClass(XFubenActivityAgency, "XDlcActivityAgency")

function XDlcActivityAgency:DlcCheckClickHrefCanEnter(roomId, nodeId, worldId, levelId, createTime)
    if not self:DlcCheckActivityInTime() then
        XUiManager.TipText("CommonActivityEnd")
        return false
    end

    if XTime.GetServerNowTimestamp() > createTime + XMVCA.XDlcRoom:GetInviteChatCacheTime() then
        XUiManager.TipText("RoomHrefDisabled")
        return false
    end

    if not self:DlcCheckCustomEnterCondition(roomId, nodeId, worldId, levelId, createTime) then
        return false
    end

    return true
end

function XDlcActivityAgency:DlcCheckCustomEnterCondition(roomId, nodeId, worldId, levelId, createTime)
    return true
end

function XDlcActivityAgency:DlcGetRoomProxy()
    return XDlcRoom.New()
end

function XDlcActivityAgency:DlcGetFightEvent()
    return XDlcWorldFight.New()
end

function XDlcActivityAgency:DlcReconnect()
    XMVCA.XDlcRoom:ReconnectToWorld()
end

function XDlcActivityAgency:DlcActivityTimeOutRunMain()
    XLuaUiManager.RunMain(true)
    XUiManager.TipText("CommonActivityEnd")
end

function XDlcActivityAgency:DlcGetPlayerCustomData()
    return nil
end

function XDlcActivityAgency:DlcInitFight()
    XMVCA.XDlcRoom:InitFight()
end

function XDlcActivityAgency:DlcCheckActivityInTime()
    return false
end

function XDlcActivityAgency:DlcRegisterActivity()
    self:RegisterActivityAgency()
    XMVCA.XDlcWorld:RegisterActivity(self:DlcGetWorldType(), self:GetId())
end

function XDlcActivityAgency:DlcGetWorldType()
    return nil
end

function XDlcActivityAgency:DlcGetNonnegativeAttribs()
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
        [XDlcNpcAttribType.RebootValue] = true,
        [XDlcNpcAttribType.SignalSkillDmgAmpP] = true,
        [XDlcNpcAttribType.CoreSkillDmgAmpP] = true,
        [XDlcNpcAttribType.NormalAtkDmgAmpP] = true,
        [XDlcNpcAttribType.ExSkillDmgAmpP] = true,
        [XDlcNpcAttribType.DodgeEnergy] = true,
    }
end

function XDlcActivityAgency:DlcGetEnlargedAttribs()
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

function XDlcActivityAgency:DlcGetWorldNpcBornMagicLevelMap(worldNpcData)
    return {}
end

function XDlcActivityAgency:DlcGetNpcAttrib(worldNpcData)
    local npcId = worldNpcData.Id
    local attribId = self:DlcGetAttribIdByNpcId(npcId)
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

---@param level Npc等级
function XDlcActivityAgency:DlcGetBaseAttrib(npcId, level)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    local attribId = template.AttribId
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

function XDlcActivityAgency:DlcGetAttribIdByNpcId(npcId)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    return template.AttribId
end

function XDlcActivityAgency:DlcParseToXAttribs(attribConfig)
    local attribCount = 0
    local attribValues = {}
    local nonnegativeAttribs = self:DlcGetNonnegativeAttribs() or {}
    local enlargedAttribs = self:DlcGetEnlargedAttribs() or {}

    for attribStr, attribId in pairs(XDlcNpcAttribType) do
        attribValues[attribId] = 0
        attribCount = attribCount + 1
    end
    local attribs = CS.StatusSyncFight.XAttrib.CreateArray(attribCount)
    for attrStr, attrValue in pairs(attribConfig) do
        if attrValue then
            local attribId = XDlcNpcAttribType[attrStr]

            if attribId then
                if enlargedAttribs[attribId] then
                    attribValues[attribId] = attrValue * 1000
                else
                    attribValues[attribId] = attrValue
                end
            end
        end
    end
    for attribId, attrValue in pairs(attribValues) do
        local allowNegative = not (nonnegativeAttribs[attribId] or false)

        -- 必须取整，因为XAttrib.Value为int
        attrValue = math.floor(attrValue + 0.5)
        CS.StatusSyncFight.XAttrib.CtorToArray(attribs, attribId, attrValue, allowNegative)
    end

    --- 特殊处理 先保留例子
    -- xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))

    return attribs
end

function XDlcActivityAgency:DlcOpenInviteUi(inviteData)
    XLuaUiManager.Open("UiDlcMultiPlayerInvitationPopup", inviteData)
end

function XDlcActivityAgency:DlcCheckInviteUiShow()
    return XLuaUiManager.IsUiShow("UiDlcMultiPlayerInvitationPopup")
end

return XDlcActivityAgency
