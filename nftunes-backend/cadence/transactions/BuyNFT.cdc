import Note from 0x36dec30520f41e9d
import NFTunes from 0x36dec30520f41e9d
import Market from 0x36dec30520f41e9d

// This transaction is for a user to purchase a NFT that another user
// has for sale in their sale collection

// Parameters
//
// sellerAddress: the Flow address of the account issuing the sale of a NFT
// tokenID: the ID of the NFT being purchased
// purchaseAmount: the amount for which the user is paying for the NFT; must not be less than the NFT's price

transaction() {

    // Local variables for the NFTunes collection object and token provider
    let collectionRef: &NFTunes.Collection
    let providerRef: &Note.Vault{Note.Provider}
    let sellerAddress: Address
    let tokenID: UInt64
    let purchaseAmount: UFix64
    
    prepare(acct: AuthAccount) {
        self.sellerAddress = 0x871c79d89f81f691
        self.tokenID = 6
        self.purchaseAmount = UFix64(100)

        // borrow a reference to the signer's collection
        self.collectionRef = acct.borrow<&NFTunes.Collection>(from: /storage/NFTCollection)
            ?? panic("Could not borrow reference to the NFT Collection")

        // borrow a reference to the signer's fungible token Vault
        self.providerRef = acct.borrow<&Note.Vault{Note.Provider}>(from: /storage/MainVault)!   
    }

    execute {

        // withdraw tokens from the signer's vault
        let tokens <- self.providerRef.withdraw(amount: self.purchaseAmount) as! @Note.Vault

        // get the seller's public account object
        let seller = getAccount(self.sellerAddress)

        // borrow a public reference to the seller's sale collection
        let NFTunesSaleCollection = seller.getCapability(/public/NFTunesSaleCollection)
            .borrow<&{Market.SalePublic}>()
            ?? panic("Could not borrow public sale reference")
    
        // purchase the NFT
        let purchasedToken <- NFTunesSaleCollection.purchase(tokenID: self.tokenID, buyTokens: <-tokens)

        // deposit the purchased NFT into the signer's collection
        self.collectionRef.deposit(token: <-purchasedToken)
    }
}