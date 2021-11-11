import Note from 0x36dec30520f41e9d
import Market from 0x36dec30520f41e9d
import NFTunes from 0x36dec30520f41e9d

// This transaction puts a NFT owned by the user up for sale

// Parameters:
//
// tokenReceiverPath: token capability for the account who will receive tokens for purchase
// beneficiaryAccount: the Flow address of the account where a cut of the purchase will be sent
// cutPercentage: how much in percentage the beneficiary will receive from the sale
// NFTID: ID of NFT to be put on sale
// price: price of NFT

transaction() {

    // Local variables for the NFTunes collection and market sale collection objects
    let collectionRef: &NFTunes.Collection
    let marketSaleCollectionRef: &Market.SaleCollection
    let NFTID: UInt64
    let price: UFix64
    
    prepare(acct: AuthAccount) {
        self.NFTID = 3
        self.price = UFix64(100)

        // check to see if a sale collection already exists
        if acct.borrow<&Market.SaleCollection>(from: /storage/NFTunesSaleCollection) == nil {

            // get the fungible token capabilities for the owner and beneficiary

            let ownerCapability = acct.getCapability(/public/MainReceiver)

            // create a new sale collection
            let NFTunesSaleCollection <- Market.createSaleCollection(ownerCapability: ownerCapability)
            
            // save it to storage
            acct.save(<-NFTunesSaleCollection, to: /storage/NFTunesSaleCollection)
        
            // create a public link to the sale collection
            acct.link<&Market.SaleCollection{Market.SalePublic}>(/public/NFTunesSaleCollection, target: /storage/NFTunesSaleCollection)
        }
        
        // borrow a reference to the seller's NFT collection
        self.collectionRef = acct.borrow<&NFTunes.Collection>(from: /storage/NFTCollection)
            ?? panic("Could not borrow from NFTCollection in storage")

        // borrow a reference to the sale
        self.marketSaleCollectionRef = acct.borrow<&Market.SaleCollection>(from: /storage/NFTunesSaleCollection)
            ?? panic("Could not borrow from sale in storage")
    }

    execute {

        // withdraw the NFT to put up for sale
        let token <- self.collectionRef.withdraw(withdrawID: self.NFTID) as! @NFTunes.NFT
        
        // the the NFT for sale
        self.marketSaleCollectionRef.listForSale(token: <-token, price: UFix64(self.price))
    }
}