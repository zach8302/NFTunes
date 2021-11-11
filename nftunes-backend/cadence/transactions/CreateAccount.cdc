import NFTunes from 0x36dec30520f41e9d

// This transaction sets up an account to use Top Shot
// by storing an empty NFT collection and creating
// a public capability for it

transaction {

    prepare(acct: AuthAccount) {

      
              // First, check to see if a NFT collection already exists
              if acct.borrow<&NFTunes.Collection>(from: /storage/NFTCollection) == nil {
      
                  // create a new NFTunes Collection
                  let collection <- NFTunes.createEmptyCollection() as! @NFTunes.Collection
      
                  // Put the new Collection in storage
                  acct.save(<-collection, to: /storage/NFTCollection)
      
                  // create a public capability for the collection
                  acct.link<&{NFTunes.NFTReceiver}>(/public/NFTReceiver, target: /storage/NFTCollection)
              }
              
              if acct.borrow<&Note.Vault>(from: /storage/MainVault) == nil {
                  let vaultA <- Note.createEmptyVault()
            
                acct.save<@Note.Vault>(<-vaultA, to: /storage/MainVault)
      
                let ReceiverRef = acct.link<&Note.Vault{Note.Receiver, Note.Balance}>(/public/MainReceiver, target: /storage/MainVault)
      
              }
      
              if acct.borrow<&Market.SaleCollection>(from: /storage/NFTunesSaleCollection)== nil {
                  let ownerCapability = acct.getCapability(/public/MainReceiver)
      
                  let collection <- Market.createSaleCollection(ownerCapability: ownerCapability)
              
                  acct.save(<-collection, to: /storage/NFTunesSaleCollection)
              
                  acct.link<&Market.SaleCollection{Market.SalePublic}>(/public/NFTunesSaleCollection, target: /storage/NFTunesSaleCollection)
              }
      
          }
      }