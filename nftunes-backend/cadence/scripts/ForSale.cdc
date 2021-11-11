import Market from 0x36dec30520f41e9d

pub fun main() : [UInt64]{
    let acct1 = getAccount(0x871c79d89f81f691)

    let receiverRef = acct1.getCapability(/public/NFTunesSaleCollection).borrow<&{Market.SalePublic}>()
            ?? panic("Cannot borrow a reference to the recipient's NFT collection")

    
    return receiverRef.getIDs()
}