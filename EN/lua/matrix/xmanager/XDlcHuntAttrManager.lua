local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")

XDlcHuntAttrManagerCreator = function()
    local XDlcHuntAttrManager = {}

    local pairs = pairs
    local XDlcNpcAttribType = XDlcNpcAttribType
    local XAttrib = CS.StatusSyncFight.XAttrib
    -- 特定属性 非负
    local AttrNonnegative = {
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
    }

    local function ToXAttrib(attrTable)
        local result = {}
        for attrStr, attrId in pairs(XDlcNpcAttribType) do
            result[attrId + 1] = 0
        end
        for attrStr, attrValue in pairs(attrTable) do
            if attrValue then
                local attrId = XDlcNpcAttribType[attrStr]
                if attrId then
                    if attrId == XDlcNpcAttribType.Speed or attrId == XDlcNpcAttribType.JumpSpeed or 
                        attrId == XDlcNpcAttribType.RunSpeed or attrId == XDlcNpcAttribType.RunSpeedCOE or 
                        attrId == XDlcNpcAttribType.JumpSpeedCOE or attrId == XDlcNpcAttribType.IdleJumpSpeedCOE or
                        attrId == XDlcNpcAttribType.WalkJumpSpeedCOE or attrId == XDlcNpcAttribType.SprintJumpSpeedCOE or
                        attrId == XDlcNpcAttribType.RunStartJumpSpeedCOE or attrId == XDlcNpcAttribType.SprintStartJumpSpeedCOE or
                        attrId == XDlcNpcAttribType.RotationSpeed or attrId == XDlcNpcAttribType.WalkSpeed or
                        attrId == XDlcNpcAttribType.WalkSpeedCOE or attrId == XDlcNpcAttribType.SprintSpeed or
                        attrId == XDlcNpcAttribType.SprintSpeedCOE
                    then
                        result[attrId + 1] = attrValue * 1000
                    else
                        result[attrId + 1] = attrValue
                    end
                end
            end
        end
        for attrId, attrValue in pairs(result) do
            local allowNegative = true
            if AttrNonnegative[attrId] then
                allowNegative = false
            end
            -- 必须取整，因为XAttrib.Value为int
            attrValue = math.floor(attrValue + 0.5)
            result[attrId] = XAttrib.Ctor(attrValue, allowNegative)
        end

        --- 特殊处理 先保留例子
        -- xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))

        return result
    end

    function XDlcHuntAttrManager.GetNpcBaseAttrib(npcTemplateId)
        local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcTemplateId)
        if not template then
            return {}
        end
        local attrId = template.AttribId
        local attrTable = XDlcHuntAttrConfigs.GetAttrTable(attrId)
        return ToXAttrib(attrTable)
    end

    function XDlcHuntAttrManager.GetNpcAttrib(worldNpcData)
        local npcId = worldNpcData.Id
        local character = XDataCenter.DlcHuntCharacterManager.GetCharacterByNpcId(npcId)
        local attrTable
        if not character then
            attrTable = {}
        else
            attrTable = character:GetBaseAttrTable()
        end

        for i, chipData in pairs(worldNpcData.Chips) do
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New()
            chip:SetData(chipData)
            if not chip:IsEmpty() then
                local attrTableAssistant = chip:GetAttrTable()
                attrTable = XUiDlcHuntUtil.GetSumAttrTable(attrTable, attrTableAssistant)
            end
        end

        return ToXAttrib(attrTable)
    end

    function XDlcHuntAttrManager.GetWorldNpcBornMagicLevelMap(worldNpcData)
        local magicDict = {}
        for i, chipData in pairs(worldNpcData.Chips) do
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New()
            chip:SetData(chipData)
            if not chip:IsEmpty() then
                local magicList = chip:GetMagicEventIds()
                -- local magicLevel = chip:GetMagicLevel()
                for j = 1, #magicList do
                    local magicId = magicList[j]
                    magicDict[magicId] = (magicDict[magicId] or 0) + 1
                end
            end
        end
        return magicDict
    end

    -- XDlcHuntAttrManager.Init()
    return XDlcHuntAttrManager
end
