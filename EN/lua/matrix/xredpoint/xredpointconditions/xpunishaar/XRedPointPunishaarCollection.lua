local XRedPointPunishaarCollection = {}

function XRedPointPunishaarCollection.GetSubEvents()
    return { XRedPointEventElement.New(XEventId.EVENT_PUNISHAAR_COLLECTION_RED_POINT_CHANGE),}
end

function XRedPointPunishaarCollection.Check(args)
    if not XMVCA.XPunishaar:GetIsActivityOpen(false) then
        return false
    end

    if type(args) == "table" then
        return XMVCA.XPunishaar:CheckCollectionCardRedPoint(args.CatalogType, args.CardId)
    end

    -- 传分类时，只检测该分类
    if args then
        return XMVCA.XPunishaar:CheckCollectionRedPoint(args)
    end

    -- 不传分类时，检测全部四类
    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    for catalogType = CatalogType.Character, CatalogType.Resonance do
        if XMVCA.XPunishaar:CheckCollectionRedPoint(catalogType) then
            return true
        end
    end

    return false
end

return XRedPointPunishaarCollection