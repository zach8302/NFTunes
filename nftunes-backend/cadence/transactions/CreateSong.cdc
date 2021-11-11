import NFTunes from 0x36dec30520f41e9d

transaction(){

    let adminRef: &NFTunes.Admin
    let currSongID: UInt32
    let name: String
    let artist: String
    let album: String
    let uri: String


    prepare(acct: AuthAccount) {
        self.name = "Purple Haze"
        self.artist = "Doja Cat"
        self.album = "Codebase"
        self.uri = "QmNNsJBg6oHzCxvrGb8dAfHsvRELNeQ6dAkJqyL6wne6Fq"

        // borrow a reference to the admin resource
        self.currSongID = NFTunes.nextSongID;
        self.adminRef = acct.borrow<&NFTunes.Admin>(from: /storage/Admin)
            ?? panic("No admin resource in storage")
    }

    execute {

        self.adminRef.createSong(metadata: {"name": self.name,
          "artist": self.artist, 
          "album": self.album, 
          "uri": self.uri})        
    }

    post {
        
        NFTunes.getSongMetaData(songID: self.currSongID) != nil:
            "songID doesnt exist"
    }
}