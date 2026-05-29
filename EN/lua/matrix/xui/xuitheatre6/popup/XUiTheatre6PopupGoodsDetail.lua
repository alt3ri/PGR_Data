---@class XUiTheatre6PopupGoodsDetail : XLuaUi 材料详情弹窗（Ui为UiTheatre6PopupRewardDetail）
---@field _Control XTheatre6Control
local XUiTheatre6PopupGoodsDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupGoodsDetail")

local GetName = 1
local GetIcon = 2
local GetDesc = 3
local GetUseDesc = 4

function XUiTheatre6PopupGoodsDetail:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))

    self._Handlers = {
        [XEnumConst.Theatre6.EventRewardType.Coin] = {
            [GetName] = handler(self, self.GetGoldName),
            [GetIcon] = handler(self, self.GetGoldIcon),
            [GetDesc] = handler(self, self.GetGoldDesc),
            [GetUseDesc] = handler(self, self.GetGoldUseDesc),
        },
        [XEnumConst.Theatre6.EventRewardType.Hp] = {
            [GetName] = handler(self, self.GetHealthName),
            [GetIcon] = handler(self, self.GetHealthIcon),
            [GetDesc] = handler(self, self.GetHealthDesc),
            [GetUseDesc] = handler(self, self.GetHealthUseDesc),
        },
        [XEnumConst.Theatre6.EventRewardType.Goods] = {
            [GetName] = handler(self, self.GetGoodsName),
            [GetIcon] = handler(self, self.GetGoodsIcon),
            [GetDesc] = handler(self, self.GetGoodsDesc),
            [GetUseDesc] = handler(self, self.GetGoodsUseDesc),
        },
        [XEnumConst.Theatre6.EventRewardType.BuffPool] = {
            [GetName] = handler(self, self.GetBuffPoolName),
            [GetIcon] = handler(self, self.GetBuffPoolIcon),
            [GetDesc] = handler(self, self.GetBuffPoolDesc),
            [GetUseDesc] = handler(self, self.GetBuffPoolUseDesc),
        },
        [XEnumConst.Theatre6.EventRewardType.SkillPool] = {
            [GetName] = handler(self, self.GetSkillPoolName),
            [GetIcon] = handler(self, self.GetSkillPoolIcon),
            [GetDesc] = handler(self, self.GetSkillPoolDesc),
            [GetUseDesc] = handler(self, self.GetSkillPoolUseDesc),
        },
    }
end

function XUiTheatre6PopupGoodsDetail:OnStart(eventRewardType, id)
    self._EventRewardType = eventRewardType
    self._Id = id

    self.RImgIcon:SetRawImage(self:ApplyHandler(GetIcon))
    self.TxtName.text = self:ApplyHandler(GetName)
    self.TxtDescription.text = self:ApplyHandler(GetUseDesc)
    self.TxtWorldDesc.text = self:ApplyHandler(GetDesc)
    self.CountTitle.gameObject:SetActiveEx(false)
    self.TxtCount.gameObject:SetActiveEx(false)
end

function XUiTheatre6PopupGoodsDetail:ApplyHandler(action)
    if self._Handlers[self._EventRewardType] and self._Handlers[self._EventRewardType][action] then
        return self._Handlers[self._EventRewardType][action](self._Id)
    end
    return nil
end

--region 金币
function XUiTheatre6PopupGoodsDetail:GetGoldIcon()
    return self._Control:GetCoinIcon()
end

function XUiTheatre6PopupGoodsDetail:GetGoldDesc()
    return self._Control:GetGoldDetail()
end

function XUiTheatre6PopupGoodsDetail:GetGoldUseDesc()
    return self._Control:GetClientConfigValue("UseDescGold")
end

function XUiTheatre6PopupGoodsDetail:GetGoldName()
    return self._Control:GetClientConfigValue("NameGold")
end
--endregion

--region 健康值
function XUiTheatre6PopupGoodsDetail:GetHealthIcon()
    return self._Control:GetHpIcon()
end

function XUiTheatre6PopupGoodsDetail:GetHealthDesc()
    return self._Control:GetHpDetail()
end

function XUiTheatre6PopupGoodsDetail:GetHealthUseDesc()
    return self._Control:GetClientConfigValue("UseDescHealth")
end

function XUiTheatre6PopupGoodsDetail:GetHealthName()
    return self._Control:GetClientConfigValue("NameHealth")
end
--endregion

--region 材料
function XUiTheatre6PopupGoodsDetail:GetGoodsIcon(id)
    local config = self._Control:GetStageGoodsConfig(id)
    return config.Icon
end

function XUiTheatre6PopupGoodsDetail:GetGoodsDesc(id)
    local config = self._Control:GetStageGoodsConfig(id)
    return config.Desc
end

function XUiTheatre6PopupGoodsDetail:GetGoodsUseDesc(id)
    local config = self._Control:GetStageGoodsConfig(id)
    return config.UseDesc
end

function XUiTheatre6PopupGoodsDetail:GetGoodsName(id)
    local config = self._Control:GetStageGoodsConfig(id)
    return config.Name
end
--endregion

--region Buff池
function XUiTheatre6PopupGoodsDetail:GetBuffPoolIcon(id)
    local config = self._Control:GetStageBuffPoolShow(id)
    return config.Icon
end

function XUiTheatre6PopupGoodsDetail:GetBuffPoolDesc(id)
    local config = self._Control:GetStageBuffPoolShow(id)
    return config.Desc
end

function XUiTheatre6PopupGoodsDetail:GetBuffPoolUseDesc(id)
    local config = self._Control:GetStageBuffPoolShow(id)
    return config.UseDesc
end

function XUiTheatre6PopupGoodsDetail:GetBuffPoolName(id)
    local config = self._Control:GetStageBuffPoolShow(id)
    return config.Name
end
--endregion

--region 技能遗物池
function XUiTheatre6PopupGoodsDetail:GetSkillPoolIcon(id)
    local config = self._Control:GetRandomPoolConfig(id)
    return config.Icon
end

function XUiTheatre6PopupGoodsDetail:GetSkillPoolDesc(id)
    local config = self._Control:GetRandomPoolConfig(id)
    return config.Desc
end

function XUiTheatre6PopupGoodsDetail:GetSkillPoolUseDesc(id)
    local config = self._Control:GetRandomPoolConfig(id)
    return config.UseDesc
end

function XUiTheatre6PopupGoodsDetail:GetSkillPoolName(id)
    local config = self._Control:GetRandomPoolConfig(id)
    return config.Name
end
--endregion

return XUiTheatre6PopupGoodsDetail