--- 通用角色属性格子，内容为简单的属性名称和数值描述，接受XPBRCharacterStatusParams作为数据源
---@class XUiPBRCommonRoleGridAttribute : XUiNode
local XUiPBRCommonRoleGridAttribute = XClass(XUiNode, "XUiPBRCommonRoleGridAttribute")

function XUiPBRCommonRoleGridAttribute:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonRoleGridAttribute:OnEnable()
end

function XUiPBRCommonRoleGridAttribute:OnDisable()
end

function XUiPBRCommonRoleGridAttribute:OnDestroy()
end

function XUiPBRCommonRoleGridAttribute:InitComponents()
    -- 默认隐藏推荐图标
    if self.ImgRecommend then
        self.ImgRecommend.gameObject:SetActiveEx(false)
    end
end

---@param info XPBRCharacterStatusParams
function XUiPBRCommonRoleGridAttribute:Refresh(info)
    self.TxtName.text = info.Name
    self.TxtNum.text = info.ValueDesc

    if self.ImgIcon and not string.IsNilOrEmpty(info.Icon) then
        self.ImgIcon:SetImage(info.Icon)
    end

    if self.ImgRecommend then
        self.ImgRecommend.gameObject:SetActiveEx(info.IsRecommend or false)
    end
end

function XUiPBRCommonRoleGridAttribute:SetBgDisplayByIndex(index)
    local isOddNum = math.fmod(index, 2) ~= 0

    if self.ImgBase then
        self.ImgBase.gameObject:SetActiveEx(isOddNum)
    end
end

return XUiPBRCommonRoleGridAttribute
