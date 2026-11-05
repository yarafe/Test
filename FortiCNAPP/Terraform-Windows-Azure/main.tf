terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  command = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File Install-LWDataCollector.ps1 -MSIURL \"${var.lacework_msi_url}\" -AccessToken \"${var.lacework_token}\" -ServerURL \"${var.lacework_endpoint}\"${var.lacework_defender ? " -defender" : ""}"
}

resource "azurerm_virtual_machine_extension" "forticnapp" {
  lifecycle {
    precondition {
      condition     = var.vm_count == length(var.windows_vms)
      error_message = "vm_count must equal the number of entries in windows_vms. Add or remove VM entries to match."
    }
  }

  for_each             = var.windows_vms
  name                 = "LaceworkDC"
  virtual_machine_id   = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.resource_group_name}/providers/Microsoft.Compute/virtualMachines/${each.value.vm_name}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  protected_settings = jsonencode({
    commandToExecute = local.command
    fileUris         = [var.lacework_ps_script]
  })

  # Runs on the Windows workstation executing Terraform, before extension deletion.
  provisioner "local-exec" {
    when        = destroy
    on_failure  = fail
    quiet       = true
    interpreter = ["PowerShell.exe", "-NoProfile", "-NonInteractive", "-Command"]
    environment = {
      TARGET_VM_ID = self.virtual_machine_id
    }
    command = <<-POWERSHELL
    $ErrorActionPreference = 'Stop'
    $remoteScript = @'
    $ErrorActionPreference = 'Stop'
    try {
        # Fortinet's documented Windows PowerShell uninstall method.
        $apps = @(Get-WmiObject -Class Win32_Product -Filter "Name like '%Lacework%'" -ErrorAction Stop)
        if ($apps.Count -gt 1) {
            throw 'Multiple Lacework products matched. Review installed products before uninstalling.'
        }
        foreach ($app in $apps) {
            $result = $app.Uninstall()
            if ($result.ReturnValue -eq 3010) {
                throw 'Uninstall requires a reboot. Reboot the VM, then retry terraform destroy.'
            }
            if ($result.ReturnValue -ne 0) {
                throw "Fortinet uninstall failed with return code $($result.ReturnValue)."
            }
        }
        # Fortinet verification commands: inspect both agent service and driver.
        & sc.exe query lwdatacollector
        & sc.exe query lwdcs
        $remaining = @(Get-WmiObject -Class Win32_Product -Filter "Name like '%Lacework%'" -ErrorAction Stop)
        $svc = Get-Service -Name lwdatacollector -ErrorAction SilentlyContinue
        $driver = Get-CimInstance Win32_SystemDriver -Filter "Name='lwdcs'" -ErrorAction Stop
        if ($remaining.Count -ne 0 -or $svc -or $driver) {
            throw 'Agent product, service or driver is still registered. Check the uninstall result and reboot if pending, then retry destroy.'
        }
        Write-Output 'FORTICNAPP_UNINSTALL_VERIFIED'
    } catch {
        Write-Error $_ -ErrorAction Continue
        exit 1
    }
    '@
    $tempScript = $null
    try {
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            throw 'Azure CLI is required on the machine running Terraform.'
        }
        $tempScript = Join-Path ([IO.Path]::GetTempPath()) (([guid]::NewGuid().ToString()) + '.ps1')
        [IO.File]::WriteAllBytes($tempScript, [Text.Encoding]::UTF8.GetBytes($remoteScript))
        $resultText = & az vm run-command invoke --ids $env:TARGET_VM_ID --command-id RunPowerShellScript --scripts "@$tempScript" --output json --only-show-errors
        if ($LASTEXITCODE -ne 0) { throw 'Azure Run Command request failed.' }
        $result = ($resultText -join "`n") | ConvertFrom-Json
        $stdout = ($result.value | Where-Object { $_.code -match 'StdOut' } | ForEach-Object { $_.message }) -join "`n"
        if ($stdout -notmatch '(?m)^FORTICNAPP_UNINSTALL_VERIFIED\s*$') {
            $messages = ($result.value | ForEach-Object { $_.message }) -join "`n"
            throw "Agent removal was not verified. Remote output: $messages"
        }
        $parts = $env:TARGET_VM_ID -split '/'
        Write-Host ("[UNINSTALLED] VM={0} | RG={1}" -f $parts[8], $parts[4])
    } catch {
        Write-Error $_ -ErrorAction Continue
        exit 1
    } finally {
        if ($tempScript -and (Test-Path $tempScript)) { Remove-Item $tempScript -Force }
    }
    POWERSHELL
  }
}
