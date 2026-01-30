XOverseaManager = XOverseaManager or {}
local Language = CS.XKuro.Localization.Data.Language 

local localregion = CS.XLocalizationManager.Instance.Language
function XOverseaManager.GetCurRegion()
    return localregion
end
function XOverseaManager.SetCurRegion(regiontype)
     localregion = regiontype
end
function XOverseaManager.IsJPRegion()
    return localregion == Language.JP
end
function XOverseaManager.IsTWRegion()
    return localregion == Language.TW
end
function XOverseaManager.IsENRegion()
    return localregion == Language.EN
end
function XOverseaManager.IsKRRegion()
    return localregion == Language.KR
end

function XOverseaManager.IsOverSeaRegion()
    return localregion ~= Language.CN
end

function XOverseaManager.IsJP_KR_ENRegion()
    return localregion == Language.EN or localregion == Language.KR or localregion == Language.JP
end

function XOverseaManager.IsJP_KRRegion()
    return localregion == Language.JP or localregion == Language.KR
end

function XOverseaManager.IsTW_ENRegion()
    return localregion == Language.EN or localregion == Language.TW
end
