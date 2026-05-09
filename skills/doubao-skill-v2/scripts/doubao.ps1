param($a,$b,$c)
$K=$env:ARK_API_KEY
if(-not $K){Write-Host "Error:Set ARK_API_KEY";exit 1}
$U="https://ark.cn-beijing.volces.com/api/v3"

if($a-eq"img"){
  $j=@{model="doubao-seed-2-0-pro-260215";prompt=$b;n=1}
  $r=Invoke-RestMethod "$U/images/generations" -Method Post -Headers @{Authorization="Bearer $K"} -Body ($j|ConvertTo-Json)
  if($r.data -and $r.data[0].url){
    if(-not(Test-Path "data")){New-Item data|Out-Null}
    $f="data/img_"+(Get-Date -Format "yyyyMMdd_HHmmss")+".jpg"
    Invoke-WebRequest $r.data[0].url -OutFile $f
    Write-Host "Saved:$f"
  }else{Write-Host "Failed"}
}elseif($a-eq"vid"){
  $j=@{model="doubao-seed-2-0-pro-260215";prompt=$b}
  $r=Invoke-RestMethod "$U/video/generations" -Method Post -Headers @{Authorization="Bearer $K"} -Body ($j|ConvertTo-Json)
  if($r.data.task_id){
    Write-Host "TaskID:"+$r.data.task_id
    if($c-eq"sync"){
      for($i=1;$i-le 60;$i++){Start-Sleep 5
      $s=Invoke-RestMethod "$U/video/tasks/$($r.data.task_id)" -Headers @{Authorization="Bearer $K"}
      if($s.data.status -eq "succeeded"){
        if(-not(Test-Path "data")){New-Item data|Out-Null}
        $f="data/vid_"+(Get-Date -Format "yyyyMMdd_HHmmss")+".mp4"
        Invoke-WebRequest $s.data.video_url -OutFile $f
        Write-Host "Done:$f";break}
      Write-Host "$i/60 - $($s.data.status)"}
    }
  }else{Write-Host "Failed"}
}else{Write-Host "Usage:doubao.ps1 <img|vid> <prompt> [sync]"}
