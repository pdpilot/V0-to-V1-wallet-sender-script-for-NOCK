A Simple, Interactive NOCK Transaction Sender for Nockchain Wallets

NockSender.sh is a lightweight, user-friendly Bash script that streamlines the creation and submission of Nockchain transactions.
It provides clear prompts, validates inputs, constructs transactions using nockchain-wallet, and automatically handles refunds and minimum fee requirements.
This script is designed for both v0 and v1 wallet formats, and is especially helpful for users transitioning from early v0 pubkey wallets.

🚀 Features
Interactive guided send flow
Supports both v0 (legacy) and v1 pubkeys
Automatic notes CSV export
Intelligent note selection (UTXO-style)
Fee validation & automatic minimum-fee adjustment
Refund/change address support
Clear, readable transaction summaries
Draft transaction creation + automatic broadcast

⚠️ Critical Notice for v0 Wallet Users
### If you are sending from a v0 wallet (long pubkey), you must specify a v1 PKH refund address.
This is because:
v0 wallets cannot receive refund/change outputs.
Nockchain uses a UTXO-like note system.
Notes cannot be partially spent.
Any unused portion of selected notes is returned as refund/change outputs.

🔥 IMPORTANT — Refunds go to the specified v1 refund address.
If your transaction selects large notes, the unused balance is returned in one or more outputs to the refund address you provide.
❗ This means:
If you send from a v0 wallet → recipient is v1 → refund address is the same v1 recipient, the recipient will receive ALL change outputs.

Example scenario:
You intend to send 1000 NOCK
The script selects notes totaling 35,000+ NOCK
You set the recipient address as the refund address
The recipient will receive the full remaining 34,000+ NOCK
This is normal UTXO behavior, but you must choose your refund address carefully when sending from v0 wallets.

🧠 How Note Selection Works (UTXO Model)
Nockchain uses a Bitcoin-like model:
A “note” is like a UTXO: it is spent fully or not at all.
To pay X NOCK + fee, the script selects notes sequentially until the total ≥ required amount.
Any leftover value is automatically refunded to a specified v1 address.
This refund/change output is not optional — it is protocol-level behavior.

📦 Requirements
nockchain-wallet installed and in $PATH
Bash 4+
awk installed
Network connectivity to a Nockchain node (public or private)

🛠 Usage
Make the script executable:
chmod +x NockSender.sh
Run it(in the nockchain DIR, make sure the executable is there):
./NockSender.sh

The script will walk you through:
Sender pubkey (v0 or v1)
Recipient pubkey (always v1 for receiving)
Refund PKH (required for v0 senders)
Amount to send (NOCK)
Fee (NOCK)

It will:
Export your wallet notes
Calculate balances
Select notes
Create a draft transaction
Apply minimum fee rules if necessary
Broadcast the transaction


🧯 Best Practices
✔ For v0 wallets:
Always set your own v1 PKH as the refund address unless you intentionally want the recipient to receive all leftover funds.
✔ For frequent sends:
Consider migrating from v0 → v1 to simplify refund/change handling.
✔ If you want smaller notes:
You can split your large notes by sending to yourself, creating multiple smaller UTXOs.

🤝 Contributions
Its a Fork from Robinhood https://github.com/RobinhoodNock/NockGUIWallet and adjusted specifically for V0 to V1 wallets.
📬 Support
If you encounter issues or want help adding features, open a GitHub issue or reach out on Nockchain community channels.
