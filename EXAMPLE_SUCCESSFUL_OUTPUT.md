user@server:~/nockchain/v0-to-v1-sender$ ./NockSender.sh
========================================
       Pdpilot’s Auto Send NOCK Script
========================================

📤 Sender pubkey (v0 or v1):
> 7fXwFTU52nPdZqY4Ef9qgP7N3yJDJhH9QjCx9XzE3m8WfBs6wYcTqH8Q3qBav4pUjZtx7PxksrVmqyD1m8jZQsLne9QWP3bTdM4fWyAQp3WJQmchPRTi38QJzSjXfG99Q
📥 Recipient pubkey:
> CzT4qFezNY8saqwsZmzHyHPjT1RafgYvuomjHfPBYTW42s3yFD8YZxA8

⚠️ Detected v0 wallet — v1 refund PKH required
🔄 Refund PKH:
> CzT4qFezNY8saqwsZmzHyHPjT1RafgYvuomjHfPBYTW42s3yFD8YZxA8

📂 Exporting notes CSV...
⏳ Waiting for notes file... Found!

💰 Wallet Summary:
   📝 Total notes: 4
   💎 Total assets: 52,410.88 NOCK (3445886976 nicks)

💸 Amount to send (in NOCK):
> 51,900
⚡ Fee amount (in NOCK):
> 50

📊 Transaction Summary:
   💵 Sending: 51,900 NOCK (3397386240 nicks)
   ⚡ Fee: 50 NOCK (3276800 nicks)
   ➕ Total needed: 51,950 NOCK (3400663040 nicks)
   🔄 Refund address: CzT4qFezNY8saqwsZmzHyHPjT1RafgYvuomjHfPBYTW42s3yFD8YZxA8

✅ Selected 1 note with total assets: 52,407.33 NOCK (3445669888 nicks)

🧹 Cleaning transaction folder (/home/user/nockchain/txs)...
🗑️ Folder cleaned.

🛠️ Creating draft transaction...
Command: nockchain-wallet create-tx --names [RT2L... 8Wfs...] --recipient {"kind":"p2pkh","address":"CzT4qFezNY8saqwsZmzHyHPjT1RafgYvuomjHfPBYTW42s3yFD8YZxA8","amount":3397386240} --fee 3276800 --refund-pkh CzT4qFezNY8saqwsZmzHyHPjT1RafgYvuomjHfPBYTW42s3yFD8YZxA8
./NockSender.sh: warning: ignored null byte in input
✅ Draft transaction created: /home/user/nockchain/txs/7bNqZr99LKncPq2QeWUrbm8WccfDtXpQ1Kc9cKea9dZcQs1LppzP7G.tx

🚀 Sending transaction...

📝 Transaction details:
I (12:44:20) kernel: starting…
I (12:44:20) Connecting to public NockApp gRPC endpoint…
I (12:44:21) Received balance update from same block
Sent Tx
- Validation for TX 8QAzmKb9T4KxQqpLMfxJf4n5Nh6CpLdZ3fm7AaNnztuQjd48sW8RzQ passed. TX submitted to node.

I (12:44:24) Command executed successfully

🎉 **Transaction sent successfully!**
