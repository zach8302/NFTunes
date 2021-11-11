import Note from 0x36dec30520f41e9d

transaction {
	prepare(acct: AuthAccount) {
		let vaultA <- Note.createEmptyVault()
			
		acct.save<@Note.Vault>(<-vaultA, to: /storage/MainVault)

    log("Empty Vault stored")

		let ReceiverRef = acct.link<&Note.Vault{Note.Receiver, Note.Balance}>(/public/MainReceiver, target: /storage/MainVault)

    log("References created")
	}

    post {
        getAccount(0x01).getCapability<&Note.Vault{Note.Receiver}>(/public/MainReceiver)
                        .check():  
                        "Vault Receiver Reference was not created correctly"
    }
}