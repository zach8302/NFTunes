import NFTunes from 0x36dec30520f41e9d

transaction {
    // local variable for the admin reference
    let adminRef: &NFTunes.Admin

    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&NFTunes.Admin>(from: /storage/Admin)!
    }

    execute {
        // Borrow a reference to the specified set
        let packRef = self.adminRef.borrowPack(packID: 1)

        packRef.addSong(songID: 8)
    }
}