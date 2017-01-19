﻿function Send-GmailMessage {
    [cmdletbinding()]
    Param
    (
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $User=$Script:PSGSuite.AdminEmail,
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]
      $From=$Script:PSGSuite.AdminEmail,
      [parameter(Mandatory=$true)]
      [string]
      $Subject,
      [parameter(Mandatory=$true)]
      [string]
      $Body,
      [parameter(Mandatory=$true)]
      [string[]]
      $To,
      [parameter(Mandatory=$false)]
      [string[]]
      $CC,
      [parameter(Mandatory=$false)]
      [string[]]
      $BCC,
      [parameter(Mandatory=$false)]
      [String]
      $AccessToken,
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]
      $P12KeyPath = $Script:PSGSuite.P12KeyPath,
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]
      $AppEmail = $Script:PSGSuite.AppEmail
    )
if (!$AccessToken)
    {
    $AccessToken = Get-GSToken -P12KeyPath $P12KeyPath -Scopes "https://mail.google.com/" -AppEmail $AppEmail -AdminEmail $User
    }
$header = @{
    Authorization="Bearer $AccessToken"
    }
$URI = "https://www.googleapis.com/gmail/v1/users/$User/messages/send"

$raw = "Subject: $Subject
From: $From
To: $($To -join ",")
"
if ($CC){$raw += "Cc: $($CC -join ",")
"}
if ($BCC){$raw += "Bcc: $($BCC -join ",")
"}
$raw += "Content-Type: text/plain

$Body"

$raw = ($raw -join "`n") | Convert-Base64 -From NormalString -To WebSafeBase64String

$reqBody = @{
    raw = $raw
    } | ConvertTo-Json
try
    {
    Write-Verbose "Constructed URI: $URI"
    $response = Invoke-RestMethod -Method Post -Uri $URI -Headers $header -Body $reqBody -ContentType "application/json" -Verbose:$false
    }
catch
    {
    try
        {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $resp = $reader.ReadToEnd()
        $response = $resp | ConvertFrom-Json | 
            Select-Object @{N="Error";E={$Error[0]}},@{N="Code";E={$_.error.Code}},@{N="Message";E={$_.error.Message}},@{N="Domain";E={$_.error.errors.domain}},@{N="Reason";E={$_.error.errors.reason}}
        Write-Error "$(Get-HTTPStatus -Code $response.Code): $($response.Domain) / $($response.Message) / $($response.Reason)"
        return
        }
    catch
        {
        Write-Error $resp
        return
        }
    }
return $response
}