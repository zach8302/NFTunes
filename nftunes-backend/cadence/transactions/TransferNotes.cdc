import Note from 0x36dec30520f41e9d

transaction(receiver: Address, amount: UFix64) {
  var temporaryVault: @Note.Vault

  prepare(acct: AuthAccount) {
    let vaultRef = acct.borrow<&Note.Vault>(from: /storage/MainVault)
        ?? panic("Could not borrow a reference to the owner's vault")
      
    self.temporaryVault <- vaultRef.withdraw(amount: amount)
  }

  execute {
    let recipient = getAccount(receiver)

    let receiverRef = recipient.getCapability(/public/MainReceiver)
                      .borrow<&Note.Vault{Note.Receiver}>()
                      ?? panic("Could not borrow a reference to the receiver")

    receiverRef.deposit(from: <-self.temporaryVault)

    log("Transfer succeeded!")
  }
}