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


## Testing results

```bash
[PASS] test_should_vest_correctly_every_10_days_over_entire_period() (gas: 533096)
Logs:
  Day 0: Claimable Amount: 250 ETH, Already Claimed: 0 ETH
  Day 10: Claimable Amount: 13 ETH, Already Claimed: 250 ETH
  Day 20: Claimable Amount: 43 ETH, Already Claimed: 263 ETH
  Day 30: Claimable Amount: 43 ETH, Already Claimed: 306 ETH
  Day 40: Claimable Amount: 43 ETH, Already Claimed: 349 ETH
  Day 50: Claimable Amount: 43 ETH, Already Claimed: 393 ETH
  Day 60: Claimable Amount: 43 ETH, Already Claimed: 436 ETH
  Day 70: Claimable Amount: 43 ETH, Already Claimed: 479 ETH
  Day 80: Claimable Amount: 43 ETH, Already Claimed: 523 ETH
  Day 90: Claimable Amount: 43 ETH, Already Claimed: 566 ETH
  Day 100: Claimable Amount: 43 ETH, Already Claimed: 609 ETH
  Day 110: Claimable Amount: 43 ETH, Already Claimed: 653 ETH
  Day 120: Claimable Amount: 43 ETH, Already Claimed: 696 ETH
  Day 130: Claimable Amount: 43 ETH, Already Claimed: 739 ETH
  Day 140: Claimable Amount: 43 ETH, Already Claimed: 783 ETH
  Day 150: Claimable Amount: 43 ETH, Already Claimed: 826 ETH
  Day 160: Claimable Amount: 43 ETH, Already Claimed: 869 ETH
  Day 170: Claimable Amount: 43 ETH, Already Claimed: 913 ETH
  Final Day 180: Claimable Amount: 43 ETH, Already Claimed: 956 ETH
  --------------------------------
  Remaining Claimable: 0 ETH
  Total Claimed: 1000 ETH
  Balance of claimer1: 1000 ETH
```

```bash
[PASS] test_should_vest_correctly_over_entire_period_after_cliff_claimed() (gas: 2870630)
Logs:
  Day 1: New Claimable: 4 ETH, Already Claimed: 250 ETH
  Day 2: New Claimable: 4 ETH, Already Claimed: 254 ETH
  Day 3: New Claimable: 4 ETH, Already Claimed: 258 ETH
  Day 4: New Claimable: 4 ETH, Already Claimed: 263 ETH
  Day 5: New Claimable: 4 ETH, Already Claimed: 267 ETH
  Day 6: New Claimable: 4 ETH, Already Claimed: 271 ETH
  Day 7: New Claimable: 4 ETH, Already Claimed: 276 ETH
  Day 8: New Claimable: 4 ETH, Already Claimed: 280 ETH
  Day 9: New Claimable: 4 ETH, Already Claimed: 284 ETH
  Day 10: New Claimable: 4 ETH, Already Claimed: 289 ETH
  Day 11: New Claimable: 4 ETH, Already Claimed: 293 ETH
  Day 12: New Claimable: 4 ETH, Already Claimed: 297 ETH
  Day 13: New Claimable: 4 ETH, Already Claimed: 302 ETH
  Day 14: New Claimable: 4 ETH, Already Claimed: 306 ETH
  Day 15: New Claimable: 4 ETH, Already Claimed: 310 ETH
  Day 16: New Claimable: 4 ETH, Already Claimed: 315 ETH
  Day 17: New Claimable: 4 ETH, Already Claimed: 319 ETH
  Day 18: New Claimable: 4 ETH, Already Claimed: 323 ETH
  Day 19: New Claimable: 4 ETH, Already Claimed: 328 ETH
  Day 20: New Claimable: 4 ETH, Already Claimed: 332 ETH
  Day 21: New Claimable: 4 ETH, Already Claimed: 336 ETH
  Day 22: New Claimable: 4 ETH, Already Claimed: 341 ETH
  Day 23: New Claimable: 4 ETH, Already Claimed: 345 ETH
  Day 24: New Claimable: 4 ETH, Already Claimed: 349 ETH
  Day 25: New Claimable: 4 ETH, Already Claimed: 354 ETH
  Day 26: New Claimable: 4 ETH, Already Claimed: 358 ETH
  Day 27: New Claimable: 4 ETH, Already Claimed: 362 ETH
  Day 28: New Claimable: 4 ETH, Already Claimed: 367 ETH
  Day 29: New Claimable: 4 ETH, Already Claimed: 371 ETH
  Day 30: New Claimable: 4 ETH, Already Claimed: 375 ETH
  Day 31: New Claimable: 4 ETH, Already Claimed: 380 ETH
  Day 32: New Claimable: 4 ETH, Already Claimed: 384 ETH
  Day 33: New Claimable: 4 ETH, Already Claimed: 388 ETH
  Day 34: New Claimable: 4 ETH, Already Claimed: 393 ETH
  Day 35: New Claimable: 4 ETH, Already Claimed: 397 ETH
  Day 36: New Claimable: 4 ETH, Already Claimed: 401 ETH
  Day 37: New Claimable: 4 ETH, Already Claimed: 406 ETH
  Day 38: New Claimable: 4 ETH, Already Claimed: 410 ETH
  Day 39: New Claimable: 4 ETH, Already Claimed: 414 ETH
  Day 40: New Claimable: 4 ETH, Already Claimed: 419 ETH
  Day 41: New Claimable: 4 ETH, Already Claimed: 423 ETH
  Day 42: New Claimable: 4 ETH, Already Claimed: 427 ETH
  Day 43: New Claimable: 4 ETH, Already Claimed: 432 ETH
  Day 44: New Claimable: 4 ETH, Already Claimed: 436 ETH
  Day 45: New Claimable: 4 ETH, Already Claimed: 440 ETH
  Day 46: New Claimable: 4 ETH, Already Claimed: 445 ETH
  Day 47: New Claimable: 4 ETH, Already Claimed: 449 ETH
  Day 48: New Claimable: 4 ETH, Already Claimed: 453 ETH
  Day 49: New Claimable: 4 ETH, Already Claimed: 458 ETH
  Day 50: New Claimable: 4 ETH, Already Claimed: 462 ETH
  Day 51: New Claimable: 4 ETH, Already Claimed: 466 ETH
  Day 52: New Claimable: 4 ETH, Already Claimed: 471 ETH
  Day 53: New Claimable: 4 ETH, Already Claimed: 475 ETH
  Day 54: New Claimable: 4 ETH, Already Claimed: 479 ETH
  Day 55: New Claimable: 4 ETH, Already Claimed: 484 ETH
  Day 56: New Claimable: 4 ETH, Already Claimed: 488 ETH
  Day 57: New Claimable: 4 ETH, Already Claimed: 492 ETH
  Day 58: New Claimable: 4 ETH, Already Claimed: 497 ETH
  Day 59: New Claimable: 4 ETH, Already Claimed: 501 ETH
  Day 60: New Claimable: 4 ETH, Already Claimed: 505 ETH
  Day 61: New Claimable: 4 ETH, Already Claimed: 510 ETH
  Day 62: New Claimable: 4 ETH, Already Claimed: 514 ETH
  Day 63: New Claimable: 4 ETH, Already Claimed: 518 ETH
  Day 64: New Claimable: 4 ETH, Already Claimed: 523 ETH
  Day 65: New Claimable: 4 ETH, Already Claimed: 527 ETH
  Day 66: New Claimable: 4 ETH, Already Claimed: 531 ETH
  Day 67: New Claimable: 4 ETH, Already Claimed: 536 ETH
  Day 68: New Claimable: 4 ETH, Already Claimed: 540 ETH
  Day 69: New Claimable: 4 ETH, Already Claimed: 544 ETH
  Day 70: New Claimable: 4 ETH, Already Claimed: 549 ETH
  Day 71: New Claimable: 4 ETH, Already Claimed: 553 ETH
  Day 72: New Claimable: 4 ETH, Already Claimed: 557 ETH
  Day 73: New Claimable: 4 ETH, Already Claimed: 562 ETH
  Day 74: New Claimable: 4 ETH, Already Claimed: 566 ETH
  Day 75: New Claimable: 4 ETH, Already Claimed: 570 ETH
  Day 76: New Claimable: 4 ETH, Already Claimed: 575 ETH
  Day 77: New Claimable: 4 ETH, Already Claimed: 579 ETH
  Day 78: New Claimable: 4 ETH, Already Claimed: 583 ETH
  Day 79: New Claimable: 4 ETH, Already Claimed: 588 ETH
  Day 80: New Claimable: 4 ETH, Already Claimed: 592 ETH
  Day 81: New Claimable: 4 ETH, Already Claimed: 596 ETH
  Day 82: New Claimable: 4 ETH, Already Claimed: 601 ETH
  Day 83: New Claimable: 4 ETH, Already Claimed: 605 ETH
  Day 84: New Claimable: 4 ETH, Already Claimed: 609 ETH
  Day 85: New Claimable: 4 ETH, Already Claimed: 614 ETH
  Day 86: New Claimable: 4 ETH, Already Claimed: 618 ETH
  Day 87: New Claimable: 4 ETH, Already Claimed: 622 ETH
  Day 88: New Claimable: 4 ETH, Already Claimed: 627 ETH
  Day 89: New Claimable: 4 ETH, Already Claimed: 631 ETH
  Day 90: New Claimable: 4 ETH, Already Claimed: 635 ETH
  Day 91: New Claimable: 4 ETH, Already Claimed: 640 ETH
  Day 92: New Claimable: 4 ETH, Already Claimed: 644 ETH
  Day 93: New Claimable: 4 ETH, Already Claimed: 648 ETH
  Day 94: New Claimable: 4 ETH, Already Claimed: 653 ETH
  Day 95: New Claimable: 4 ETH, Already Claimed: 657 ETH
  Day 96: New Claimable: 4 ETH, Already Claimed: 661 ETH
  Day 97: New Claimable: 4 ETH, Already Claimed: 666 ETH
  Day 98: New Claimable: 4 ETH, Already Claimed: 670 ETH
  Day 99: New Claimable: 4 ETH, Already Claimed: 674 ETH
  Day 100: New Claimable: 4 ETH, Already Claimed: 679 ETH
  Day 101: New Claimable: 4 ETH, Already Claimed: 683 ETH
  Day 102: New Claimable: 4 ETH, Already Claimed: 687 ETH
  Day 103: New Claimable: 4 ETH, Already Claimed: 692 ETH
  Day 104: New Claimable: 4 ETH, Already Claimed: 696 ETH
  Day 105: New Claimable: 4 ETH, Already Claimed: 700 ETH
  Day 106: New Claimable: 4 ETH, Already Claimed: 705 ETH
  Day 107: New Claimable: 4 ETH, Already Claimed: 709 ETH
  Day 108: New Claimable: 4 ETH, Already Claimed: 713 ETH
  Day 109: New Claimable: 4 ETH, Already Claimed: 718 ETH
  Day 110: New Claimable: 4 ETH, Already Claimed: 722 ETH
  Day 111: New Claimable: 4 ETH, Already Claimed: 726 ETH
  Day 112: New Claimable: 4 ETH, Already Claimed: 731 ETH
  Day 113: New Claimable: 4 ETH, Already Claimed: 735 ETH
  Day 114: New Claimable: 4 ETH, Already Claimed: 739 ETH
  Day 115: New Claimable: 4 ETH, Already Claimed: 744 ETH
  Day 116: New Claimable: 4 ETH, Already Claimed: 748 ETH
  Day 117: New Claimable: 4 ETH, Already Claimed: 752 ETH
  Day 118: New Claimable: 4 ETH, Already Claimed: 757 ETH
  Day 119: New Claimable: 4 ETH, Already Claimed: 761 ETH
  Day 120: New Claimable: 4 ETH, Already Claimed: 765 ETH
  Day 121: New Claimable: 4 ETH, Already Claimed: 770 ETH
  Day 122: New Claimable: 4 ETH, Already Claimed: 774 ETH
  Day 123: New Claimable: 4 ETH, Already Claimed: 778 ETH
  Day 124: New Claimable: 4 ETH, Already Claimed: 783 ETH
  Day 125: New Claimable: 4 ETH, Already Claimed: 787 ETH
  Day 126: New Claimable: 4 ETH, Already Claimed: 791 ETH
  Day 127: New Claimable: 4 ETH, Already Claimed: 796 ETH
  Day 128: New Claimable: 4 ETH, Already Claimed: 800 ETH
  Day 129: New Claimable: 4 ETH, Already Claimed: 804 ETH
  Day 130: New Claimable: 4 ETH, Already Claimed: 809 ETH
  Day 131: New Claimable: 4 ETH, Already Claimed: 813 ETH
  Day 132: New Claimable: 4 ETH, Already Claimed: 817 ETH
  Day 133: New Claimable: 4 ETH, Already Claimed: 822 ETH
  Day 134: New Claimable: 4 ETH, Already Claimed: 826 ETH
  Day 135: New Claimable: 4 ETH, Already Claimed: 830 ETH
  Day 136: New Claimable: 4 ETH, Already Claimed: 835 ETH
  Day 137: New Claimable: 4 ETH, Already Claimed: 839 ETH
  Day 138: New Claimable: 4 ETH, Already Claimed: 843 ETH
  Day 139: New Claimable: 4 ETH, Already Claimed: 848 ETH
  Day 140: New Claimable: 4 ETH, Already Claimed: 852 ETH
  Day 141: New Claimable: 4 ETH, Already Claimed: 856 ETH
  Day 142: New Claimable: 4 ETH, Already Claimed: 861 ETH
  Day 143: New Claimable: 4 ETH, Already Claimed: 865 ETH
  Day 144: New Claimable: 4 ETH, Already Claimed: 869 ETH
  Day 145: New Claimable: 4 ETH, Already Claimed: 874 ETH
  Day 146: New Claimable: 4 ETH, Already Claimed: 878 ETH
  Day 147: New Claimable: 4 ETH, Already Claimed: 882 ETH
  Day 148: New Claimable: 4 ETH, Already Claimed: 887 ETH
  Day 149: New Claimable: 4 ETH, Already Claimed: 891 ETH
  Day 150: New Claimable: 4 ETH, Already Claimed: 895 ETH
  Day 151: New Claimable: 4 ETH, Already Claimed: 900 ETH
  Day 152: New Claimable: 4 ETH, Already Claimed: 904 ETH
  Day 153: New Claimable: 4 ETH, Already Claimed: 908 ETH
  Day 154: New Claimable: 4 ETH, Already Claimed: 913 ETH
  Day 155: New Claimable: 4 ETH, Already Claimed: 917 ETH
  Day 156: New Claimable: 4 ETH, Already Claimed: 921 ETH
  Day 157: New Claimable: 4 ETH, Already Claimed: 926 ETH
  Day 158: New Claimable: 4 ETH, Already Claimed: 930 ETH
  Day 159: New Claimable: 4 ETH, Already Claimed: 934 ETH
  Day 160: New Claimable: 4 ETH, Already Claimed: 939 ETH
  Day 161: New Claimable: 4 ETH, Already Claimed: 943 ETH
  Day 162: New Claimable: 4 ETH, Already Claimed: 947 ETH
  Day 163: New Claimable: 4 ETH, Already Claimed: 952 ETH
  Day 164: New Claimable: 4 ETH, Already Claimed: 956 ETH
  Day 165: New Claimable: 4 ETH, Already Claimed: 960 ETH
  Day 166: New Claimable: 4 ETH, Already Claimed: 965 ETH
  Day 167: New Claimable: 4 ETH, Already Claimed: 969 ETH
  Day 168: New Claimable: 4 ETH, Already Claimed: 973 ETH
  Day 169: New Claimable: 4 ETH, Already Claimed: 978 ETH
  Day 170: New Claimable: 4 ETH, Already Claimed: 982 ETH
  Day 171: New Claimable: 4 ETH, Already Claimed: 986 ETH
  Day 172: New Claimable: 4 ETH, Already Claimed: 991 ETH
  Day 173: New Claimable: 4 ETH, Already Claimed: 995 ETH
  --------------------------------
  Remaining Claimable: 0 ETH
  Total Claimed: 1000 ETH
  Balance of claimer1: 1000 ETH
```

