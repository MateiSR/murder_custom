param([string]$WorkshopId)

if (!$WorkshopId -or $WorkshopId -notmatch "^[0-9]+$") {
	throw "Usage: ./publish.ps1 -WorkshopId <numeric-id>"
}

..\..\..\bin\gmpublish.exe update -addon packed.gma -id $WorkshopId
