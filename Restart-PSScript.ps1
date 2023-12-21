# Disclaimers
# Any method of restarting the script from within the script will change a few automatic variables, nothing you can do about it. There is no way to have a totally pure script restart besides actually starting a new instance.
# The headers of most tables output to the console only once (see https://github.com/PowerShell/PowerShell/issues/2228). I haven't found a way to reset that behavior, so you may not see headers again after a script restart unless you use out-host.


# Method 1 (add to the end of your script)

# Offer to restart the script https://github.com/JedHarb/Restart-Powershell-Script/blob/main/Restart-PSScript.ps1
if ((Read-Host "`nEnter Y to restart this script") -eq "Y") {.$PSCommandPath}

# Pro: Very simple
# Con: Leaves all variables as they are. Depending on the script, restarting with already-set variables could cause an issue.



# Method 2 (add to the end of your script)
# A more comprehensive reset, but more complex than Method 1.

# Offer to restart the script https://github.com/JedHarb/Restart-Powershell-Script/blob/main/Restart-PSScript.ps1
if ((Read-Host "`nEnter Y to restart this script") -eq "Y") {
	# Reset most of the local automatic variables that started with powershell back to their initial values (some are read-only).
	try {
		((& powershell "Get-Variable") | Select-Object -Skip 3 | ConvertFrom-String -PropertyNames Name, Value).ForEach({
			Set-Variable -Name $_.Name -Value $_.Value -ErrorAction SilentlyContinue
		})
	}
	catch {}

	# Remove all additional variables created in this session.
	try {
		Remove-Variable -Name (Compare-Object (Get-Variable) ((& powershell "Get-Variable") | 
  		ConvertFrom-String -PropertyNames Name) -Property Name | 
    		Where-Object SideIndicator -eq "<=").Name -ErrorAction SilentlyContinue
	}
	catch {}

	# Reset the last few stragglers
	# $Error.Clear() # Every once in awhile, this throws a "Method invocation failed because [System.String] does not contain a method named 'Clear'." and I haven't been able to pin down why.
	$$, $StackTrace = ""

	# The automatic variable $^ can't be manually removed, reset, or changed in any way (at least in all of my testing).
	# It will become equal to the literal text 'try' at this point, and change with each command run from here (as usual).
 	
	.$PSCommandPath # Start the script from the beginning.
}

# Pro: Will reset almost all initial variables to their starting values, and remomve all additional variables created in the session.
# Con: Gets automatic variable values from a NEW powershell session and attempts to set the CURRENT session variables to the same thing. It's very unlikely that this isn't the behavior you want. In that case, use Method 3.



# Method 3 (add the first line to the start of your script, and the rest to the end of your script)

# Save all initial variables to a long name so it's unlikely to be used/overwritten in normal scripting
if (!$AllInitialLocalPowerShellVariables) {$AllInitialLocalPowerShellVariables = Get-Variable}

# Code goes here

# Offer to restart the script https://github.com/JedHarb/Restart-Powershell-Script/blob/main/Restart-PSScript.ps1
if ((Read-Host "`nEnter Y to restart this script") -eq "Y") {
	# Reset most of the local automatic variables that started with powershell back to their initial values (some are read-only).
	try {
		($AllInitialLocalPowerShellVariables).ForEach({
			Set-Variable -Name $_.Name -Value $_.Value -ErrorAction SilentlyContinue
		})
	}
	catch {}

	# Remove all additional variables created in this session.
	try {
		Remove-Variable -Name (Compare-Object (Get-Variable) ($AllInitialLocalPowerShellVariables) -Property Name | Where-Object ({$_.SideIndicator -eq "<="} -and {$_.Name -ne "AllInitialLocalPowerShellVariables"})).Name -ErrorAction SilentlyContinue
	}
	catch {}

	# Reset the last few stragglers
	# $Error.Clear() # Every once in awhile, this throws a "Method invocation failed because [System.String] does not contain a method named 'Clear'." and I haven't been able to pin down why.
	$$, $StackTrace = ""

	# The automatic variable $^ can't be manually removed, reset, or changed in any way (at least in all of my testing).
	# It will become equal to the literal text 'try' at this point, and change with each command run from here (as usual).
	
	# Start the script from the beginning.
	.$PSCommandPath
}

# Pro: Avoids the Con in Method 2.
# Con: Requires an additional line of code at the very beginning of the script.
