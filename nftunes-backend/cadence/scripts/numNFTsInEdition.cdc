import NFTunes from 0x36dec30520f41e9d

pub fun main(packID: UInt32, songID: UInt32): {String:String} {

    let num = NFTunes.getNumNFTsInEdition(packID: packID, songID: songID)

    log(num)

    return {"yuh": "yuh"}
}