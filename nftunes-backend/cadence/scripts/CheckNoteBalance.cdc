import Note from 0x36dec30520f41e9d
pub fun main(): UFix64 {
    let acct1 = getAccount(0x36dec30520f41e9d)

    let acct1ReceiverRef = acct1.getCapability<&Note.Vault{Note.Balance}>(/public/MainReceiver)
        .borrow()
        ?? panic("Could not borrow a reference to the acct1 receiver")

    log("Account 1 Balance")
    log(acct1ReceiverRef.balance)
    return acct1ReceiverRef.balance
}
