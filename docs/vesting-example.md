# Token Vesting Schedule Example

This example is based on a total allocation of 1000 tokens vesting over 180 days with a 7-day cliff period.

## Vesting Parameters
- Total Allocation: 1000 tokens
- Total Duration: 180 days
- Cliff Period: 7 days
- Initial Unlock: 25% (250 tokens)
- Linear Vesting: 75% (750 tokens) over 173 days

## How It Works

### Cliff Period (Days 0-7)
During the first 7 days:
- Initial 25% (250 tokens) can be claimed once during this period
- Linear vesting portion (75%) is locked during cliff
- After claiming initial 25%, no more tokens are claimable until cliff ends
- Total Claimable during cliff: 250 tokens (one-time claim)

### Initial Unlock + Linear Vesting (After Day 7)
After the cliff period ends:
- If initial 25% wasn't claimed during cliff, it's still available
- Linear vesting of remaining 75% (750 tokens) begins
- Daily vesting rate: 750 tokens / 173 days ≈ 4.34 tokens per day
- For precision in blockchain calculations, we round down to 4 tokens per day

Example timeline (assuming initial 25% was claimed during cliff):
Day 0-7: Initial 25% claimed (250 tokens)
Day 8: New Claimable: 4 tokens, Total Available: 4 tokens
Day 9: New Claimable: 4 tokens, Total Available: 8 tokens
Day 10: New Claimable: 4 tokens, Total Available: 12 tokens
// ... continues daily until day 180

By day 180:
- 250 tokens from initial unlock (claimed during cliff)
- 692 tokens from daily vesting (173 days × 4 tokens)
- 58 tokens remaining from rounding differences
- Total: 1000 tokens (100% of allocation)

Why We Round Numbers in Blockchain Systems
----------------------------------------

Rounding is essential in blockchain systems because most tokens and cryptocurrencies have a minimum denomination (like how cents are the smallest unit of dollars). For example, ETH's smallest unit is wei (1 ETH = 10^18 wei).

Consider our vesting schedule without rounding:
750 tokens / 173 days = 4.335260115606936 tokens per day

This creates several problems:

1. Precision Loss Example:
   ```solidity
   // This would cause issues
   uint256 dailyAmount = 750 * 10**18 / 173;  // = 4.335260115606936 tokens
   
   // After 173 days, due to precision loss:
   4.335260115606936 * 173 = 749.999999999999928 tokens
   // We've lost 0.000000000000072 tokens due to decimal truncation
   ```

2. Integer Math Requirements:
   - Blockchain systems use integer math for deterministic results
   - Floating point operations can produce slightly different results across different systems
   - The above calculation would actually be stored as:
     4335260115606936127 wei (truncated at 18 decimal places)

By rounding down to 4 tokens per day, we:
- Ensure consistent results across all blockchain nodes
- Prevent accumulation errors
- Guarantee we never exceed the total allocation
- Work with clean integer numbers (4 * 10^18 wei)

The 58 tokens remaining after all claims (1000 - 250 - 692) can be handled in a final claim after the vesting period ends.