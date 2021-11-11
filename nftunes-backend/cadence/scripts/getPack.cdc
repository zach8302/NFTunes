import NFTunes from 0x36dec30520f41e9d

pub fun main(): String {

    let name = NFTunes.getPackName(packID: 1)
        ?? panic("Could not find the specified pack")
        
    return name
}