import Market from 0x36dec30520f41e9d

// This transaction creates a public sale collection capability that any user can interact with

// Parameters:
//
// tokenReceiverPath: token capability for the account who will receive tokens for purchase

transaction {

    prepare(acct: AuthAccount) {
        
        let ownerCapability = acct.getCapability(/public/MainReceiver)

        let collection <- Market.createSaleCollection(ownerCapability: ownerCapability)
        
        acct.save(<-collection, to: /storage/topshotSaleCollection)
        
        acct.link<&Market.SaleCollection{Market.SalePublic}>(/public/topshotSaleCollection, target: /storage/topshotSaleCollection)
    }
}