import NFTunes from 0x36dec30520f41e9d

pub fun main(): [NFTunes.Song] {
    return NFTunes.getAllSongs()
}