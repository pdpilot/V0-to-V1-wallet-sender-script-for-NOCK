#!/bin/bash
TXS_DIR="$(pwd)/txs"

# Conversion constant
NICKS_PER_NOCK=65536

echo "========================================"
echo "       Pdpilots auto send nock script"
echo "========================================"
echo

# Parse optional --index argument
index=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --index)
      index="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# Prompt inputs
read -rp $'📤 Sender pubkey (v0 or v1):\n> ' sender
read -rp $'📥 Recipient pubkey:\n> ' recipient

# Check if sender is v0 (longer) or v1 (shorter)
sender_length=${#sender}
if [ "$sender_length" -gt 60 ]; then
  # This is a v0 pubkey, we need a refund PKH
  echo "⚠️  Detected v0 wallet - you need a v1 PKH address for refunds"
  read -rp $'🔄 Refund PKH address (v1 format):\n> ' refund_pkh
  use_refund=true
else
  # This is likely a v1 PKH, use it for refund
  refund_pkh="$sender"
  use_refund=false
fi

# Export notes CSV
csvfile="notes-${sender}.csv"
echo -e "\n📂 Exporting notes CSV..."
if ! nockchain-wallet list-notes-by-address-csv "$sender" >/dev/null 2>&1; then
  echo "❌ Failed to export notes CSV."
  exit 1
fi

echo -n "⏳ Waiting for notes file ($csvfile)... "
while [ ! -f "$csvfile" ]; do sleep 1; done
echo "Found!"

# Calculate total available assets
total_nicks=0
note_count=0
while IFS=',' read -r version name_first name_last assets block_height source_hash; do
  [[ "$version" == "version" ]] && continue  # Skip header
  total_nicks=$((total_nicks + assets))
  note_count=$((note_count + 1))
done < "$csvfile"

# Convert to NOCK for display
total_nock=$((total_nicks / NICKS_PER_NOCK))
total_nock_decimal=$(awk "BEGIN {printf \"%.2f\", $total_nicks / $NICKS_PER_NOCK}")

echo -e "\n💰 Wallet Summary:"
echo "   📝 Total notes: $note_count"
echo "   💎 Total assets: $total_nock_decimal NOCK ($total_nicks nicks)"
echo

# Prompt for send amount and fee in NOCK
read -rp $'💸 Amount to send (in NOCK):\n> ' send_nock
read -rp $'⚡ Fee amount (in NOCK):\n> ' fee_nock

# Validate inputs are numbers (can be decimal)
if ! [[ "$send_nock" =~ ^[0-9]+\.?[0-9]*$ ]] || ! [[ "$fee_nock" =~ ^[0-9]+\.?[0-9]*$ ]]; then
  echo "❌ Amount and fee must be valid numbers."
  exit 1
fi

# Function to create transaction
create_transaction() {
  local send_nock=$1
  local fee_nock=$2
  
  # Convert NOCK to nicks
  send_nicks=$(awk "BEGIN {printf \"%.0f\", $send_nock * $NICKS_PER_NOCK}")
  fee_nicks=$(awk "BEGIN {printf \"%.0f\", $fee_nock * $NICKS_PER_NOCK}")
  total_needed=$((send_nicks + fee_nicks))

  echo -e "\n📊 Transaction Summary:"
  echo "   💵 Sending: $send_nock NOCK ($send_nicks nicks)"
  echo "   ⚡ Fee: $fee_nock NOCK ($fee_nicks nicks)"
  echo "   ➕ Total needed: $(awk "BEGIN {printf \"%.2f\", $total_needed / $NICKS_PER_NOCK}") NOCK ($total_needed nicks)"
  if [ "$use_refund" = true ]; then
    echo "   🔄 Refund address: $refund_pkh"
  fi
  echo

  # Check if we have enough funds
  if [ "$total_nicks" -lt "$total_needed" ]; then
    echo "❌ Insufficient funds!"
    echo "   Available: $total_nock_decimal NOCK ($total_nicks nicks)"
    echo "   Needed: $(awk "BEGIN {printf \"%.2f\", $total_needed / $NICKS_PER_NOCK}") NOCK ($total_needed nicks)"
    exit 1
  fi

  # Select notes until we have enough to cover the total needed
  selected_notes=()
  selected_assets=0
  while IFS=',' read -r version name_first name_last assets block_height source_hash; do
    [[ "$version" == "version" ]] && continue  # Skip header
    selected_notes+=("$name_first $name_last")
    selected_assets=$((selected_assets + assets))
    if [ "$selected_assets" -ge "$total_needed" ]; then break; fi
  done < "$csvfile"

  echo "✅ Selected ${#selected_notes[@]} note(s) with total assets: $(awk "BEGIN {printf \"%.2f\", $selected_assets / $NICKS_PER_NOCK}") NOCK ($selected_assets nicks)"
  echo

  # Build --names argument
  names_arg=""
  for note in "${selected_notes[@]}"; do
    if [[ -n "$names_arg" ]]; then
      names_arg+=","
    fi
    names_arg+="[$note]"
  done

  # Build --recipient argument using JSON format
  recipient_arg="{\"kind\":\"p2pkh\",\"address\":\"$recipient\",\"amount\":$send_nicks}"

  # Prepare transaction folder
  mkdir -p "$TXS_DIR"
  echo "🧹 Cleaning transaction folder ($TXS_DIR)..."
  rm -f "$TXS_DIR"/*
  echo "🗑️ Folder cleaned."
  echo

  # Create transaction
  echo "🛠️ Creating draft transaction..."

  local output
  local temp_output_file=$(mktemp)
  
  if [[ -n "$index" ]]; then
    echo "Command: nockchain-wallet create-tx --names $names_arg --recipient $recipient_arg --fee $fee_nicks --refund-pkh $refund_pkh --index $index"
    nockchain-wallet create-tx \
      --names "$names_arg" \
      --recipient "$recipient_arg" \
      --fee "$fee_nicks" \
      --refund-pkh "$refund_pkh" \
      --index "$index" > "$temp_output_file" 2>&1
    local exit_code=$?
  else
    echo "Command: nockchain-wallet create-tx --names $names_arg --recipient $recipient_arg --fee $fee_nicks --refund-pkh $refund_pkh"
    nockchain-wallet create-tx \
      --names "$names_arg" \
      --recipient "$recipient_arg" \
      --fee "$fee_nicks" \
      --refund-pkh "$refund_pkh" > "$temp_output_file" 2>&1
    local exit_code=$?
  fi

  output=$(cat "$temp_output_file")
  rm -f "$temp_output_file"

  # Check for minimum fee error
  if echo "$output" | grep -q "Min fee not met"; then
    # Extract the minimum fee from the error message
    min_fee_nicks=$(echo "$output" | grep -oP 'at least: \K[0-9]+' | head -n 1)
    
    if [[ -n "$min_fee_nicks" ]]; then
      min_fee_nock=$(awk "BEGIN {printf \"%.2f\", $min_fee_nicks / $NICKS_PER_NOCK}")
      echo -e "\n⚠️  Minimum fee requirement not met!"
      echo "   Required minimum: $min_fee_nock NOCK ($min_fee_nicks nicks)"
      echo "   Your fee: $fee_nock NOCK ($fee_nicks nicks)"
      echo
      read -rp "Do you want to use the minimum fee of $min_fee_nock NOCK? (y/n): " use_min_fee
      
      if [[ "$use_min_fee" =~ ^[Yy]$ ]]; then
        # Retry with the minimum fee
        create_transaction "$send_nock" "$min_fee_nock"
        return $?
      else
        echo "❌ Transaction cancelled."
        exit 1
      fi
    else
      echo -e "\n❌ Failed to extract minimum fee from error message."
      echo "Error output:"
      echo "$output"
      exit 1
    fi
  fi

  # Check if transaction creation failed for other reasons
  if [[ $exit_code -ne 0 ]]; then
    echo -e "\n❌ Error creating transaction:"
    echo "$output"
    exit 1
  fi

  # Return success
  return 0
}

# Call the function
create_transaction "$send_nock" "$fee_nock"

# Pick any .tx file in txs directory
txfile=$(find "$TXS_DIR" -maxdepth 1 -type f -name '*.tx' | head -n 1)
if [[ -z "$txfile" ]]; then
  echo "❌ No transaction file found after creating draft."
  exit 1
fi

echo "✅ Draft transaction created: $txfile"
echo

# Send TX
echo "🚀 Sending transaction..."
output=$(nockchain-wallet send-tx "$txfile" 2>&1)
if [[ $? -eq 0 ]]; then
  echo -e "\n📝 Transaction details:\n$output"
  echo -e "\n✅ Transaction sent successfully!"
else
  echo -e "\n❌ Error details:\n$output"
  echo "❌ Failed to send transaction."
  exit 1
fi
