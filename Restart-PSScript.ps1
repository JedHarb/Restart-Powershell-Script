# Notes
# Any method of restarting the script from within the script will change a few automatic variables, nothing you can do about it. There is no way to have a totally pure script restart besides actually starting a new instance.
# The headers of most tables output to the console only once (see https://github.com/PowerShell/PowerShell/issues/2228). I haven't found a way to reset that behavior, so you may not see headers again after a script restart unless you use out-host.



# Method 1

# End of script
if ((Read-Host "`nEnter Y to restart this script") -eq "Y") {
	.$PSCommandPath # Start the script from the beginning.
}
# Pro: very simple
# Con: leaves all variables as they are. Depending on the script, restarting with some variables already set can cause issues.



# Method 2

# End of script
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
		Remove-Variable -Name (Compare-Object (Get-Variable) ((& powershell "Get-Variable") | ConvertFrom-String -PropertyNames Name) -Property Name | Where-Object SideIndicator -eq "<=").Name -ErrorAction SilentlyContinue
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
# More comprehensive but more complex than Method 1.
# Pro: will reset (most) initial variables to their starting values, and remomve all additional variables created in the session.
# Con: gets automatic variables from a NEW powershell session and attempts to set the CURRENT session variables to the same thing. It's unlikely, but possible, that (depending on your automatic variables) this is not the behavior you want. In that case, use Method 3.



# Method 3

# Start of script 
# Give it a long variable name so it's unlikely to be used/overwritten in normal scripting
if (!$AllInitialLocalPowerShellVariables) {
	$AllInitialLocalPowerShellVariables = Get-Variable
}


# End of script
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
# Pro: avoids the Con in Method 2.
# Con: requires a line of code at the very beginning of the script in addition to the ending block.