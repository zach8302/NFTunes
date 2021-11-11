import Note from 0x36dec30520f41e9d

transaction {
  prepare(acct: AuthAccount) {
    acct.link<&Note.Vault{Note.Receiver, Note.Balance}>(/public/MainReceiver, target: /storage/MainVault)

    log("Public Receiver reference created!")
  }

  post {
    getAccount(0x36dec30520f41e9d).getCapability<&Note.Vault{Note.Receiver}>(/public/MainReceiver)
                    .check():
                    "Vault Receiver Reference was not created correctly"
    }
}