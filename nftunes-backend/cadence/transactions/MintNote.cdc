import Note from 0x36dec30520f41e9d

transaction {
    let mintingRef: &Note.VaultMinter

    var receiver: Capability<&Note.Vault{Note.Receiver}>

	prepare(acct: AuthAccount) {
        self.mintingRef = acct.borrow<&Note.VaultMinter>(from: /storage/MainMinter)
            ?? panic("Could not borrow a reference to the minter")
        
        let recipient = getAccount(0x36dec30520f41e9d)
      
        self.receiver = recipient.getCapability<&Note.Vault{Note.Receiver}>
(/public/MainReceiver)

	}

    execute {
        self.mintingRef.mintTokens(amount: UFix64(1000), recipient: self.receiver)

        log("tokens minted and deposited to account 0x36dec30520f41e9d")
    }
}