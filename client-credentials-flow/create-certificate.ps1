
######################################################
### Made by Cédric Braekevelt (hybridbrothers.com) ###
######################################################

### Create self-signed certificate and store in user certificate store ###
$certificateParams = @{
    Subject           = "hybridbrothers-demo"
    CertStoreLocation = "Cert:\CurrentUser\My"
}
$certificate = New-SelfSignedCertificate  @certificateParams

### Export the public key to be uploaded into your app registration ###
Export-Certificate -Cert $certificate -FilePath "public.cer" -Force

### Export the private key to use to generate a JWT ###
Export-PfxCertificate -Cert $certificate -FilePath "private.pfx" -Password $password -Force