select
CIpkg.Content_ID,
CIpkg.PkgID,
CIpkg.ContentSubFolder,
UI.BulletinID,
UI.ArticleID,
UI.Title,
CItype.TypeName
from
CI_ContentPackages CIpkg
left join vSMS_CIToContent CI2C on CIpkg.Content_UniqueID=CI2C.Content_UniqueID
left join v_UpdateInfo UI on CI2C.CI_ID=UI.CI_ID
left join CI_TypeNames CItype on ui.CIType_ID = CItype.CIType_ID
where CIpkg.ContentSubFolder = '43da8a8e-387a-47cb-a8f8-5a62bb9dad09'
order by CIpkg.ContentSubFolder