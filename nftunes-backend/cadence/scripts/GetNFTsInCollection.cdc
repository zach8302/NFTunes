import NFTunes from 0x36dec30520f41e9d
pub fun main(): [UInt64] {
    let acct1 = getAccount(0x871c79d89f81f691)

    let receiverRef = acct1.getCapability(/public/NFTReceiver).borrow<&{NFTunes.NFTReceiver}>()
            ?? panic("Cannot borrow a reference to the recipient's NFT collection")

    return receiverRef.getIDs()
}
