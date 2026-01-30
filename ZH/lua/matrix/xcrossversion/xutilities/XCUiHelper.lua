XUiHelper = XUiHelper or {}

-- 因为主干会公用这个方法, 先注入即可, 后续删除时在相应的调用处恢复即可
-- BP入口, 通过配置文件决定打开哪一个BP
function XUiHelper.OpenPassport()
    if CS.XGame.ClientConfig:GetInt("IsCombBP") == 0 then
        XLuaUiManager.Open("UiPassport")
    else
        XLuaUiManager.Open("UiPassportComb")
    end
end