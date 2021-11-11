import NFTunes from 0x36dec30520f41e9d

transaction {
    
    let adminRef: &NFTunes.Admin
    let currPackID: UInt32
    let packName: String

    prepare(acct: AuthAccount) {

        self.packName = "REUNIØN"

        self.adminRef = acct.borrow<&NFTunes.Admin>(from: /storage/Admin)
            ?? panic("Could not borrow a reference to the Admin resource")
        self.currPackID = NFTunes.nextPackID;

    }

    execute {      
        self.adminRef.createPack(name: self.packName)
    }

    post {  
        NFTunes.getPackName(packID: self.currPackID) == self.packName:
          "Could not find the specified set"
    }
}