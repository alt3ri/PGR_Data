local XUiGridDlcRelinkCharacterAttribute = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterAttribute")
---@class XUiDlcRelinkPopupCharacterAttributeDetail : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupCharacterAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupCharacterAttributeDetail")

function XUiDlcRelinkPopupCharacterAttributeDetail:OnAwake()
    self.GridAttributeDetail.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupCharacterAttributeDetail:OnStart(characterId, isNotSelf)
    self.CharacterId = characterId
    self.IsNotSelf = isNotSelf or false
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupCharacterAttributeDetail:OnEnable()
    -- 角色图像
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId).DefaultNpcFashtionId
    self.RImgHead:SetRawImage(XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId))
    -- 刷新属性列表
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupCharacterAttributeDetail:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAttributeDetails)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkCharacterAttribute, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupCharacterAttributeDetail:SetupDynamicTable()
    self.AttributeDataList = self:GetAttributeDataList()
    if XTool.IsTableEmpty(self.AttributeDataList) then
        return
    end

    self.DynamicTable:SetDataSource(self.AttributeDataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkCharacterAttribute
function XUiDlcRelinkPopupCharacterAttributeDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshAttributeDetail(self.AttributeDataList[index])
        grid:SetBg(index % 2 ~= 0)
    end
end

-- 获取玩家等级
function XUiDlcRelinkPopupCharacterAttributeDetail:GetPlayerLevel()
    if self.IsNotSelf then
        return self._Control.OtherMemberControl:GetPlayerLevel()
    else
        return self._Control:GetCurrentPlayerLevel()
    end
end

-- 获取装备Uid列表
function XUiDlcRelinkPopupCharacterAttributeDetail:GetEquipUids()
    if self.IsNotSelf then
        return self._Control.OtherMemberControl:GetWearEquipUids()
    else
        return self._Control:GetWearEquipUidsByCharacterId(self.CharacterId)
    end
end

-- 获取属性集合 (包含角色基础属性、玩家等级属性、装备属性)
---@return { AttrStr: string, CurValue:number, EquipValue:number }[]
function XUiDlcRelinkPopupCharacterAttributeDetail:GetAttributeDataList()
    local curPlayerLevel = self:GetPlayerLevel()
    local equipUids = self:GetEquipUids()
    local totalAttributes = self._Control:GetTotalAttributes(self.CharacterId, curPlayerLevel, equipUids, self.IsNotSelf)

    local attributeDataList = {}
    for index, attribute in ipairs(totalAttributes) do
        attributeDataList[index] = {
            AttrStr = attribute.AttrStr,
            CurValue = attribute.CharacterValue + attribute.PlayerValue,
            EquipValue = attribute.EquipValue
        }
    end
    return attributeDataList
end

function XUiDlcRelinkPopupCharacterAttributeDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkPopupCharacterAttributeDetail:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupCharacterAttributeDetail
