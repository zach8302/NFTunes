import NFTunes from 0x36dec30520f41e9d

pub fun main(songID: UInt32): {String:String} {

    let metadata = NFTunes.getSongMetaData(songID: songID) ?? panic("Song doesn't exist")

    log(metadata)

    return metadata
}