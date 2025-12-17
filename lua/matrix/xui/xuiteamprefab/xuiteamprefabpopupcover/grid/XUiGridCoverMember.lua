---@class XUiGridCoverMember
local XUiGridCoverMember = XClass(XUiNode, "XUiGridCoverMember")

---@param xTeam XTeam
---@param pos number
function XUiGridCoverMember:RefreshByRealTeam(xTeam, pos)
    local characterId = xTeam:GetEntityIdByTeamPos(pos)
    local isCharValid = XTool.IsNumberValid(characterId)
    if isCharValid then
        self.BtnHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        self.IconLeader.gameObject:SetActiveEx(xTeam:GetCaptainPos() == pos)
        self.TagFirst.gameObject:SetActiveEx(xTeam:GetFirstFightPos() == pos)

        -- 品质
        self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))

        -- 意识
        if not self.SuitItemList then
            self.SuitItemList = {self.SuitItem}
        end
        -- 隐藏所有
        for _, suitItem in ipairs(self.SuitItemList) do
            suitItem.gameObject:SetActiveEx(false)
        end
        self.SuitOverrunItem.gameObject:SetActiveEx(false)

        -- 套装列表
        local suitInfoList = XMVCA.XEquip:GetWearingSuitInfoList(characterId)
        local itemIndex = 1
        local haveSuit = false
        for i, suitInfo in ipairs(suitInfoList) do
            if suitInfo.Count ~= 1 then
                haveSuit = true
                local itemGo
                if suitInfo.IsOverrun then
                    itemGo = self.SuitOverrunItem
                else
                    itemGo = self.SuitItemList[itemIndex]
                    if not itemGo then
                        itemGo = XUiHelper.Instantiate(self.SuitItem, self.SuitItem.transform.parent)
                        table.insert(self.SuitItemList, itemGo)
                    end
                    itemIndex = itemIndex + 1
                end

                itemGo.gameObject:SetActiveEx(true)
                itemGo.transform:SetAsLastSibling()
                local uiObj = itemGo:GetComponent("UiObject")
                uiObj:GetObject("TxtSuitName").text = suitInfo.Name
                uiObj:GetObject("TxtSuitCount").text = suitInfo.Count
            end
        end
        self.PanelNoneAwareness.gameObject:SetActiveEx(not haveSuit)

        -- 武器
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.Parent)
        self.WeaponGrid:Open()
        local usingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
        self.WeaponGrid:Refresh(usingWeaponId)

        -- 辅助机
        local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
        self.PanelHavePartner.gameObject:SetActiveEx(partner)
        self.PanelNonePartner.gameObject:SetActiveEx(not partner)
        if partner then
            self.RImgPartner:SetRawImage(partner:GetIcon())
            self.ImgPartnerBreakthrough:SetSprite(partner:GetBreakthroughIcon())
            self.PartnerRImgRank:SetRawImage(partner:GetCharacterQualityIcon())
        end
    end
    self.PanelNormal.gameObject:SetActiveEx(isCharValid)
    self.PanelNone.gameObject:SetActiveEx(not isCharValid)
end

---@param xTeamPrefab XTeamPrefab
---@param pos number
function XUiGridCoverMember:RefreshByTeamPrefab(xTeamPrefab, pos)
    local characterId = xTeamPrefab:GetEntityIdByTeamPos(pos)
    local isCharValid = XTool.IsNumberValid(characterId)
    if isCharValid then
        self.BtnHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        self.IconLeader.gameObject:SetActiveEx(xTeamPrefab:GetCaptainPos() == pos)
        self.TagFirst.gameObject:SetActiveEx(xTeamPrefab:GetFirstFightPos() == pos)

        -- 品质
        self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))

        -- 意识
        if not self.SuitItemList then
            self.SuitItemList = {self.SuitItem}
        end
        -- 隐藏所有
        for _, suitItem in ipairs(self.SuitItemList) do
            suitItem.gameObject:SetActiveEx(false)
        end
        self.SuitOverrunItem.gameObject:SetActiveEx(false)
        -- 套装列表
        local suitInfoList = xTeamPrefab:GetWearingSuitInfoListByPos(pos)
        local itemIndex = 1
        local haveSuit = false
        for i, suitInfo in ipairs(suitInfoList) do
            if suitInfo.Count ~= 1 then
                haveSuit = true
                local itemGo
                if suitInfo.IsOverrun then
                    itemGo = self.SuitOverrunItem
                else
                    itemGo = self.SuitItemList[itemIndex]
                    if not itemGo then
                        itemGo = XUiHelper.Instantiate(self.SuitItem.gameObject, self.SuitItem.transform.parent)
                        table.insert(self.SuitItemList, itemGo)
                    end
                    itemIndex = itemIndex + 1
                end
    
                itemGo.gameObject:SetActiveEx(true)
                itemGo.transform:SetAsLastSibling()
                local uiObj = itemGo:GetComponent("UiObject")
                uiObj:GetObject("TxtSuitName").text = suitInfo.Name
                uiObj:GetObject("TxtSuitCount").text = suitInfo.Count
            end
        end
        self.PanelNoneAwareness.gameObject:SetActiveEx(not haveSuit)

        -- 武器
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        local weaponData = xTeamPrefab:GetWeaponData(pos)
        self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.Parent)
        local usingWeaponId = (weaponData and weaponData.EquipId) or XMVCA.XEquip:GetCharacterWeaponId(characterId)
        self.WeaponGrid:Refresh(usingWeaponId)

        -- 辅助机
        local partnerPrefabData = xTeamPrefab:GetPartnerData()
        local partnerId = partnerPrefabData and partnerPrefabData:GetPartnerIdByPos(pos)
        local partner = partnerId and XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
        self.PanelHavePartner.gameObject:SetActiveEx(partner)
        self.PanelNonePartner.gameObject:SetActiveEx(not partner)
        if partner then
            self.RImgPartner:SetRawImage(partner:GetIcon())
            self.ImgPartnerBreakthrough:SetSprite(partner:GetBreakthroughIcon())
            self.PartnerRImgRank:SetRawImage(partner:GetCharacterQualityIcon())
        end
    end
    self.PanelNormal.gameObject:SetActiveEx(isCharValid)
    self.PanelNone.gameObject:SetActiveEx(not isCharValid)
end

return XUiGridCoverMember