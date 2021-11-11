/*

    MarketNFTunes.cdc

    Description: Contract definitions for users to sell their NFTs

    Marketplace is where users can create a sale collection that they
    store in their account storage. In the sale collection, 
    they can put their NFTs up for sale with a price and publish a 
    reference so that others can see the sale.

    If another user sees an NFT that they want to buy,
    they can send fungible tokens that equal or exceed the buy price
    to buy the NFT.  The NFT is transferred to them when
    they make the purchase.

    Each user who wants to sell tokens will have a sale collection 
    instance in their account that holds the tokens that they are putting up for sale

    They can give a reference to this collection to a central contract
    so that it can list the sales in a central place

    When a user creates a sale, they will supply three arguments:
    - A Note.Receiver capability as the place where the payment for the token goes.
    
*/

import Note from 0x36dec30520f41e9d
import NFTunes from 0x36dec30520f41e9d

pub contract Market {

    // -----------------------------------------------------------------------
    // NFTunes Market contract Event definitions
    // -----------------------------------------------------------------------

    // emitted when a NFTunes NFT is listed for sale
    pub event NFTListed(id: UInt64, price: UFix64, seller: Address?)
    // emitted when the price of a listed NFT has changed
    pub event NFTPriceChanged(id: UInt64, newPrice: UFix64, seller: Address?)
    // emitted when a token is purchased from the market
    pub event NFTPurchased(id: UInt64, price: UFix64, seller: Address?)
    // emitted when a NFT has been withdrawn from the sale
    pub event NFTWithdrawn(id: UInt64, owner: Address?)

    // SalePublic 
    //
    // The interface that a user can publish a capability to their sale
    // to allow others to access their sale
    pub resource interface SalePublic {
        pub fun purchase(tokenID: UInt64, buyTokens: @Note.Vault): @NFTunes.NFT {
            post {
                result.id == tokenID: "The ID of the withdrawn token must be the same as the requested ID"
            }
        }
        pub fun getPrice(tokenID: UInt64): UFix64?
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NFTunes.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // SaleCollection
    //
    // This is the main resource that token sellers will store in their account
    // to manage the NFTs that they are selling. The SaleCollection
    // holds a NFTunes Collection resource to store the NFTs that are for sale.
    // The SaleCollection also keeps track of the price of each token.
    // 
    pub resource SaleCollection: SalePublic {

        // A collection of the NFTs that the user has for sale
        access(self) var forSale: @NFTunes.Collection

        // Dictionary of the low low prices for each NFT by ID
        access(self) var prices: {UInt64: UFix64}

        // The fungible token vault of the seller
        // so that when someone buys a token, the tokens are deposited
        // to this Vault
        access(self) var ownerCapability: Capability


        init (ownerCapability: Capability) {
            pre {
                // Check that both capabilities are for fungible token Vault receivers
                ownerCapability.borrow<&{Note.Receiver}>() != nil: 
                    "Owner's Receiver Capability is invalid!"
            }
            
            // create an empty collection to store the NFTs that are for sale
            self.forSale <- NFTunes.createEmptyCollection() as! @NFTunes.Collection
            self.ownerCapability = ownerCapability
            // prices are initially empty because there are no NFTs for sale
            self.prices = {}
        }

        // listForSale lists an NFT for sale in this sale collection
        // at the specified price
        //
        // Parameters: token: The NFT to be put up for sale
        //             price: The price of the NFT
        pub fun listForSale(token: @NFTunes.NFT, price: UFix64) {

            // get the ID of the token
            let id = token.id

            // Set the token's price
            self.prices[token.id] = price

            // Deposit the token into the sale collection
            self.forSale.deposit(token: <-token)

            emit NFTListed(id: id, price: price, seller: self.owner?.address)
        }

        // Withdraw removes a NFT that was listed for sale
        // and clears its price
        //
        // Parameters: tokenID: the ID of the token to withdraw from the sale
        //
        // Returns: @NFTunes.NFT: The nft that was withdrawn from the sale
        pub fun withdraw(tokenID: UInt64): @NFTunes.NFT {

            // Remove and return the token.
            // Will revert if the token doesn't exist
            let token <- self.forSale.withdraw(withdrawID: tokenID) as! @NFTunes.NFT

            // Remove the price from the prices dictionary
            self.prices.remove(key: tokenID)

            // Set prices to nil for the withdrawn ID
            self.prices[tokenID] = nil
            
            // Emit the event for withdrawing a NFT from the Sale
            emit NFTWithdrawn(id: token.id, owner: self.owner?.address)

            // Return the withdrawn token
            return <-token
        }

        // purchase lets a user send tokens to purchase an NFT that is for sale
        // the purchased NFT is returned to the transaction context that called it
        //
        // Parameters: tokenID: the ID of the NFT to purchase
        //             butTokens: the fungible tokens that are used to buy the NFT
        //
        // Returns: @NFTunes.NFT: the purchased NFT
        pub fun purchase(tokenID: UInt64, buyTokens: @Note.Vault): @NFTunes.NFT {
            pre {
                self.forSale.ownedNFTs[tokenID] != nil && self.prices[tokenID] != nil:
                    "No token matching this ID for sale!"           
                buyTokens.balance == (self.prices[tokenID] ?? UFix64(0)):
                    "Not enough tokens to buy the NFT!"
            }

            // Read the price for the token
            let price = self.prices[tokenID]!

            // Set the price for the token to nil
            self.prices[tokenID] = nil

            // Deposit the remaining tokens into the owners vault
            self.ownerCapability.borrow<&{Note.Receiver}>()!
                .deposit(from: <-buyTokens)

            emit NFTPurchased(id: tokenID, price: price, seller: self.owner?.address)

            // Return the purchased token
            return <-self.withdraw(tokenID: tokenID)
        }

        // changePrice changes the price of a token that is currently for sale
        //
        // Parameters: tokenID: The ID of the NFT's price that is changing
        //             newPrice: The new price for the NFT
        pub fun changePrice(tokenID: UInt64, newPrice: UFix64) {
            pre {
                self.prices[tokenID] != nil: "Cannot change the price for a token that is not for sale"
            }
            // Set the new price
            self.prices[tokenID] = newPrice

            emit NFTPriceChanged(id: tokenID, newPrice: newPrice, seller: self.owner?.address)
        }


        // changeOwnerReceiver updates the capability for the sellers fungible token Vault
        //
        // Parameters: newOwnerCapability: The new fungible token capability for the account 
        //                                 who received tokens for purchases
        pub fun changeOwnerReceiver(_ newOwnerCapability: Capability) {
            pre {
                newOwnerCapability.borrow<&{Note.Receiver}>() != nil: 
                    "Owner's Receiver Capability is invalid!"
            }
            self.ownerCapability = newOwnerCapability
        }

        // getPrice returns the price of a specific token in the sale
        // 
        // Parameters: tokenID: The ID of the NFT whose price to get
        //
        // Returns: UFix64: The price of the token
        pub fun getPrice(tokenID: UInt64): UFix64? {
            return self.prices[tokenID]
        }

        // getIDs returns an array of token IDs that are for sale
        pub fun getIDs(): [UInt64] {
            return self.forSale.getIDs()
        }

        // borrowNFT Returns a borrowed reference to a NFT in the collection
        // so that the caller can read data from it
        //
        // Parameters: id: The ID of the NFT to borrow a reference to
        //
        // Returns: &NFTunes.NFT? Optional reference to a NFT for sale 
        //                        so that the caller can read its data
        //
        pub fun borrowNFT(id: UInt64): &NFTunes.NFT? {
            let ref = self.forSale.borrowNFT(id: id)
            return ref
        }

        // If the sale collection is destroyed, 
        // destroy the tokens that are for sale inside of it
        destroy() {
            destroy self.forSale
        }
    }

    // createCollection returns a new collection resource to the caller
    pub fun createSaleCollection(ownerCapability: Capability): @SaleCollection {
        return <- create SaleCollection(ownerCapability: ownerCapability)
    }
}