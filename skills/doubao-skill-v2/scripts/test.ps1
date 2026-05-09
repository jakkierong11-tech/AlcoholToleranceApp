param($prompt)
$K=$env:ARK_API_KEY
if(-not $K){Write-Host "Error:Set ARK_API_KEY first";exit 1}

# Doubao 文生图 API
$endpoint="https://ark.cn-beijing.volces.com/api/v3/chat/completions"
$body=@{
    model="doubao-seed-2-0-pro-260215"
    messages=@(@{role="user";content="画一只可爱的小猫咪趴在沙发上"})
}|ConvertTo-Json -Depth 10

Write-Host "Calling API..."
try{
$r=Invoke-RestMethod $endpoint -Method Post -Headers @{
    "Content-Type"="application/json"
    "Authorization"="Bearer $K"
} -Body $body
Write-Host ($r|ConvertTo-Json -Depth 5)
}catch{
Write-Host "Error:"+$_ 
}
