
using 'main.bicep'

param application = 'blog'
param environment = 'prod'
param acaConfig = {
  url: 'domain.com'
  storageAccountName: ''
  smtpUserName: 'postmaster@domain.com'
}
param dbConfig = {
  serverName: 'servername'
  username: 'username'
  dbname: 'dbname'
}
param keyVaultName = 'keyVault'
param keyVaultResourceGroup = 'keyVaultRG'
param privateEndpoint = false
