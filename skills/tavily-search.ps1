param($query, $count=5)
$API_KEY="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"
$U="https://api.tavily.com/search"
$B=@{
    api_key=$API_KEY
    query=$query
    max_results=$count
    search_depth="basic"
    include_answer=$false
    include_images=$false
}|ConvertTo-Json

try{
$r=Invoke-RestMethod $U -Method Post -ContentType "application/json" -Body $B
Write-Host "Tavily Search Results for: '$query'" -ForegroundColor Cyan
Write-Host "Found $($r.results.Count) results`n" -ForegroundColor Green

$i=1
foreach($result in $r.results){
    Write-Host "$i. $($result.title)" -ForegroundColor Yellow
    Write-Host "   URL: $($result.url)"
    Write-Host "   $($result.content)"
    Write-Host ""
    $i++
}

if($r.answer){
    Write-Host "Tavily Summary:" -ForegroundColor Magenta
    Write-Host $r.answer
}
}catch{
Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
