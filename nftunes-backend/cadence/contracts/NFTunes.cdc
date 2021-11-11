pub contract NFTunes {

    access(self) var songDatas: {UInt32: Song}

    access(self) var packDatas: {UInt32: PackData}

    access(self) var packs: @{UInt32: Pack}

    pub var nextSongID: UInt32

    pub var nextPackID: UInt32

    pub var totalSupply: UInt64

    pub struct NFTData {
        pub let packID: UInt32

        pub let songID: UInt32

        pub let serialNumber: UInt32

        init(packID: UInt32, songID: UInt32, serialNumber: UInt32) {
            self.packID = packID
            self.songID = songID
            self.serialNumber = serialNumber
        }

    }

  pub resource NFT {

        pub let id: UInt64

        pub let data: NFTData

        init(packID: UInt32, songID: UInt32, serialNumber: UInt32) {
            NFTunes.totalSupply = NFTunes.totalSupply + UInt64(1)

            self.id = NFTunes.totalSupply

            self.data = NFTData(packID: packID, songID: songID, serialNumber: serialNumber)
        }
  }

    pub resource interface NFTReceiver {
        pub fun deposit(token: @NFTunes.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NFTunes.NFT
    }

    pub resource Collection: NFTReceiver{ 
 
        pub var ownedNFTs: @{UInt64: NFTunes.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NFTunes.NFT {

            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: Moment does not exist in the collection")

            return <-token
        }

        pub fun deposit(token: @NFTunes.NFT) {
            
            let token <- token as! @NFTunes.NFT

            let id = token.id

            let oldToken <- self.ownedNFTs[id] <- token

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NFTunes.NFT {
            return &self.ownedNFTs[id] as &NFTunes.NFT
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub struct Song {

        pub let songID: UInt32

        pub let metadata: {String: String}

        init(metadata: {String: String}) {
            pre {
                metadata.length != 0: "New Song metadata cannot be empty"
            }
            self.songID = NFTunes.nextSongID
            self.metadata = metadata

            // Increment the ID so that it isn't used again
            NFTunes.nextSongID = NFTunes.nextSongID + UInt32(1)
        }
    }

    pub struct PackData {

        pub let packID: UInt32

        pub let name: String

        init(name: String) {
            pre {
                name.length > 0: "New Pack name cannot be empty"
            }
            self.packID = NFTunes.nextPackID
            self.name = name

            // Increment the packID so that it isn't used again
            NFTunes.nextPackID = NFTunes.nextPackID + UInt32(1)
        }
    }

    pub resource Pack {

        pub let packID: UInt32

        pub var songs: [UInt32]

        pub var numberMintedPerSong: {UInt32: UInt32}

        init(name: String) {
            self.packID = NFTunes.nextPackID

            self.songs = []
            self.numberMintedPerSong = {}

            NFTunes.packDatas[self.packID] = PackData(name: name)
        }

        pub fun addSong(songID: UInt32) {
            pre {
                NFTunes.songDatas[songID] != nil: "Cannot add the Song to Pack: Song doesn't exist."
                self.numberMintedPerSong[songID] == nil: "The song has already beed added to the pack."
            }

            self.songs.append(songID)

            self.numberMintedPerSong[songID] = 0
        }

        pub fun addSongs(songIDs: [UInt32]) {
            for song in songIDs {
                self.addSong(songID: song)
            }
        }

        pub fun mintNFT(songID: UInt32): @NFT {
            let numInSong = self.numberMintedPerSong[songID]!

            let newNFT: @NFT <- create NFT(packID: self.packID,
                                            songID: songID,
                                              serialNumber: numInSong + UInt32(1))

            self.numberMintedPerSong[songID] = numInSong + UInt32(1)

            return <-newNFT
        }

        pub fun batchMintNFT(songID: UInt32, quantity: UInt64): @Collection {
            let newCollection <- create Collection()

            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <-self.mintNFT(songID: songID))
                i = i + UInt64(1)
            }

            return <-newCollection
        }
    }

    pub resource Admin {

        pub fun createSong(metadata: {String: String}): UInt32 {
            var newSong = Song(metadata: metadata)
            let newID = newSong.songID

            NFTunes.songDatas[newID] = newSong

            return newID
        }

        pub fun createPack(name: String) {
            var newPack <- create Pack(name: name)

            NFTunes.packs[newPack.packID] <-! newPack
        }

        pub fun borrowPack(packID: UInt32): &Pack {
            pre {
                NFTunes.packs[packID] != nil: "Cannot borrow Pack: The Pack doesn't exist"
            }
            
            return &NFTunes.packs[packID] as &Pack
        }

        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }
     pub fun getAllSongs(): [NFTunes.Song] {
        return NFTunes.songDatas.values
    }

    pub fun getSongMetaData(songID: UInt32): {String: String}? {
        return self.songDatas[songID]?.metadata
    }

    pub fun getSongMetaDataByField(songID: UInt32, field: String): String? {
        if let song = NFTunes.songDatas[songID] {
            return song.metadata[field]
        } else {
            return nil
        }
    }

    pub fun getPackName(packID: UInt32): String? {
        return NFTunes.packDatas[packID]?.name
    }

    pub fun getPackIDsByName(packName: String): [UInt32]? {
        var packIDs: [UInt32] = []

        for packData in NFTunes.packDatas.values {
            if packName == packData.name {
                // If the name is found, return the ID
                packIDs.append(packData.packID)
            }
        }

        // If the name isn't found, return nil
        // Don't force a revert if the packName is invalid
        if packIDs.length == 0 {
            return nil
        } else {
            return packIDs
        }
    }

    pub fun getSongsInPack(packID: UInt32): [UInt32]? {
        // Don't force a revert if the packID is invalid
        return NFTunes.packs[packID]?.songs
    }


    pub fun getNumNFTsInEdition(packID: UInt32, songID: UInt32): UInt32? {

        if let packToRead <- NFTunes.packs.remove(key: packID) {

            let amount = packToRead.numberMintedPerSong[songID]

            NFTunes.packs[packID] <-! packToRead

            return amount
        } else {
            return nil
        }
    }

    pub fun createEmptyCollection(): @NFTunes.Collection {
        return <-create NFTunes.Collection()
    }


  init() {

        self.songDatas = {}
        self.packDatas = {}
        self.packs <- {}
        self.nextSongID = 1
        self.nextPackID = 1
        self.totalSupply = 0

        self.account.save<@Collection>(<- create Collection(), to: /storage/NFTCollection)
        self.account.link<&{NFTReceiver}>(/public/NFTReceiver, target: /storage/NFTCollection)
        self.account.save<@Admin>(<- create Admin(), to: /storage/Admin)
	}
}