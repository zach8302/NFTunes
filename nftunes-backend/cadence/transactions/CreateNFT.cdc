import NFTunes from 0x36dec30520f41e9d

transaction {
    // local variable for the admin reference
    let adminRef: &NFTunes.Admin
    let packID: UInt32
    let songID: UInt32
    let recipientAddr: Address

    prepare(acct: AuthAccount) {
        self.packID = UInt32(1)
        self.songID = UInt32(8)
        self.recipientAddr = 0x7157334c071d526f
        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&NFTunes.Admin>(from: /storage/Admin)!
    }

    execute {
        // Borrow a reference to the specified set
        let packRef = self.adminRef.borrowPack(packID: self.packID)

        // Mint a new NFT
        let NFT1 <- packRef.mintNFT(songID: self.songID)

        // get the public account object for the recipient
        let recipient = getAccount(self.recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(/public/NFTReceiver).borrow<&{NFTunes.NFTReceiver}>()
            ?? panic("Cannot borrow a reference to the recipient's NFT collection")
        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-NFT1)
    }
}