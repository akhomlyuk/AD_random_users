# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory

# For GeneratePassword method from System.Web.Security.Membership
Add-Type -AssemblyName System.Web  

# Define UPN
$UPN = "codeby.cdb"

# Define and create Org. Units
$random_ous = @('Human Relations', 'Information Security', 'Managers', 'Development', 'Finance', 'Logistics', 'Information Technology Services')

foreach ($ou_name in $random_ous) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou_name'")) {
        New-ADOrganizationalUnit -Name $ou_name -PassThru
    }
    else {
        Write-Host "OU '$ou_name' already exists. Skipping creation."
    }
}

# Define cities
$random_cities = @('Moscow', 'St. Petersburg', 'Novosibirsk', 'Kazan', 'Irkutsk', 'Vladivostok', 'Ekaterinburg', 'Gatchina', 'V. Novgorod')

$users_count = Get-Random -Minimum 118 -Maximum 197

#For names Titlecase
$TextInfo = (Get-Culture).TextInfo

for ($i = 0; $i -ne $users_count; $i++)  {

    # Create random OU's, cities, etc.
    $random_ou = Get-Random -InputObject $random_ous
    $random_city = Get-Random -InputObject $random_cities
    $gender = 0,1 | Get-Random

    # Russian male translited names and surnames
    $ru_male_name = Get-Content $HOME\Desktop\Names\russian_male_trans_names.txt | Get-Random
    $ru_male_surname = Get-Content $HOME\Desktop\Names\russian_trans_male_surnames.txt | Get-Random

    # Russian female translited names and surnames
    $ru_female_name = Get-Content $HOME\Desktop\Names\russian_female_trans_names.txt | Get-Random
    $ru_female_surname = Get-Content $HOME\Desktop\Names\russian_trans_female_surnames.txt | Get-Random
    
    if ($gender -eq 0) {
    
        $firstname = $TextInfo.ToTitleCase($ru_male_name)
        $lastname = $TextInfo.ToTitleCase($ru_male_surname)
        $username = $ru_male_name + "." + $ru_male_surname
        $email = $username + "@codeby.cdb"
    }
    else {

        $firstname = $TextInfo.ToTitleCase($ru_female_name)
        $lastname = $TextInfo.ToTitleCase($ru_female_surname)
        $username = $ru_female_name + "." + $ru_female_surname
        $email = $username + "@codeby.cdb"
    }
    
    $password = ([System.Web.Security.Membership]::GeneratePassword(14,1))
    $city = $random_city
    $country = "RU"
    $company = "Codeby"
    $department = $random_ou
    $description = "Domain user"

    # Check to see if the user already exists in AD
    if (Get-ADUser -Filter "SamAccountName -eq '$username'") {
        
        # If user does exist, give a warning
        Write-Warning "A user account with username $username already exists in Active Directory."
    }
    else {

        New-ADUser `
            -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Enabled $True `
            -DisplayName "$firstname $lastname" `
            -Path "OU=$random_ou,DC=codeby,DC=cdb" `
            -City $city `
            -Country $country `
            -Company $company `
            -EmailAddress $email `
            -Department $department `
            -Description $description `
            -Verbose `
            -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -ChangePasswordAtLogon $False -CannotChangePassword $True -PasswordNeverExpires $True    
    }
    Write-Host "[+] The user account $username with password $password in the $random_ou is created." -ForegroundColor White
}

Get-ADUser -Filter * | Format-List username, SamAccountName
Write-Host "[+] $users_count users created"
Write-Host "Users count:" (Get-ADUser -Filter *).Count
