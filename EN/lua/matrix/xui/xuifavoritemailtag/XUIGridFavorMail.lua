local XUIGridFavorMail = XClass(nil, "XUIGridFavorMail")
local TITLE_MAX_LENGTH = 18 --标题最大容纳字符窜长度
local TITLE_MAX_LENGTHJP = 14 --标题最大容纳字符窜长度

function XUIGridFavorMail:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUIGridFavorMail:UpdateView(baseUI,favorMailData,cb)
    self.BaseUI = baseUI
    self.FavorMailData = favorMailData
    self.BtnTabPrefab:SetRawImage(favorMailData.MailIcon)
    if XOverseaManager.IsJP_KRRegion() then
        TITLE_MAX_LENGTH = TITLE_MAX_LENGTHJP
    end
    local title = favorMailData.Title
    if XOverseaManager.IsOverSeaRegion() then
        if string.Utf8LenCustomOverSea(title) > TITLE_MAX_LENGTH then
            title = string.Utf8SubCustomOverSea(title, 1, TITLE_MAX_LENGTH) .. "..."
        end
    else
        if string.Utf8LenCustom(title) > TITLE_MAX_LENGTH then
            title = string.Utf8SubCustom(title, 1, TITLE_MAX_LENGTH) .. "..."
        end
    end
    self.BtnTabPrefab:SetNameByGroup(0, title)
    self.BtnTabPrefab:SetNameByGroup(1, CsXTextManagerGetText("CollectionBoxFavorMailTime",favorMailData.ShowTime))
    self.BtnTabPrefab.CallBack = cb
end

function XUIGridFavorMail:SetSelect(selected)
    if selected then
        self.BtnTabPrefab:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnTabPrefab:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUIGridFavorMail