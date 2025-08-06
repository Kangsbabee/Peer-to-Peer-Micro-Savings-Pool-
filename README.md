# 💰 Peer-to-Peer Micro-Savings Pool (Digital ROSCA/Ajo)

> 🤝 A trustless digital savings circle powered by Stacks blockchain smart contracts

## 🎯 Overview

This smart contract implements a digital version of traditional rotating savings and credit associations (ROSCA/Ajo), enabling trusted peer-to-peer micro-savings pools with automated payouts and penalty enforcement.

## ✨ Features

- 🔒 **Trustless Automation**: Smart contracts handle all fund management
- 🔄 **Rotating Payouts**: Automated payout scheduling based on member positions
- ⚡ **Penalty System**: Built-in enforcement for defaulting members
- 🔄 **Position Transfer**: Members can transfer their position to another person
- 👥 **Flexible Pool Size**: Support for 2-20 members per pool
- 💎 **Transparent**: All transactions and balances are publicly verifiable

## 🚀 Quick Start

### Creating a Pool

```clarity
(contract-call? .Peer-to-Peer-Micro-Savings-Pool create-pool u1000000 u5 u144)
```
- `u1000000`: Contribution amount in µSTX (1 STX)
- `u5`: Maximum 5 members
- `u144`: Payout every 144 blocks (~24 hours)

### Joining a Pool

```clarity
(contract-call? .Peer-to-Peer-Micro-Savings-Pool join-pool u1)
```

### Making Contributions

```clarity
(contract-call? .Peer-to-Peer-Micro-Savings-Pool contribute u1)
```

### Claiming Your Payout

```clarity
(contract-call? .Peer-to-Peer-Micro-Savings-Pool claim-payout u1)
```

### Transferring Your Position

```clarity
(contract-call? .Peer-to-Peer-Micro-Savings-Pool transfer-position u1 'SP1234ABCD...)
```

## 📋 Core Functions

### 🏗️ Pool Management

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-pool` | Create a new savings pool | `contribution-amount` `max-members` `payout-schedule` |
| `join-pool` | Join an existing pool | `pool-id` |
| `transfer-position` | Transfer your position to another member | `pool-id` `recipient` |
| `advance-cycle` | Move to next payout cycle (creator only) | `pool-id` |

### 💳 Financial Operations

| Function | Description | Parameters |
|----------|-------------|------------|
| `contribute` | Make your cycle contribution | `pool-id` |
| `claim-payout` | Claim payout when it's your turn | `pool-id` |
| `penalize-member` | Apply penalty to defaulting member | `pool-id` `member` |

### 📊 View Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-pool` | Get pool information | Pool details |
| `get-member-info` | Get member details | Member status |
| `get-pool-stats` | Get pool statistics | Stats summary |

## 🔄 How It Works

1. **Pool Creation** 🎯
   - Creator sets contribution amount, member limit, and payout schedule
   - Pool remains inactive until full

2. **Member Joining** 👋
   - Members join and receive a position number
   - Pool activates when reaching member limit

3. **Contribution Cycle** 💰
   - All members contribute the fixed amount each cycle
   - Funds accumulate in the pool balance

4. **Payout Distribution** 🎁
   - Member with current cycle position claims the full pot
   - Payouts rotate through all members

5. **Completion** ✅
   - Pool deactivates after all members receive payouts

## 📐 Pool Structure

```
Cycle 1: Member 1 → Claims (5 × contribution)
Cycle 2: Member 2 → Claims (5 × contribution)
Cycle 3: Member 3 → Claims (5 × contribution)
Cycle 4: Member 4 → Claims (5 × contribution)
Cycle 5: Member 5 → Claims (5 × contribution)
```

## ⚠️ Important Notes

- 🔐 **Security**: All funds are held by the smart contract
- ⏰ **Timing**: Pool creator manages cycle advancement
- 🚫 **No Double Contribution**: One contribution per member per cycle
- 📍 **Position Matters**: Payout order determined by join sequence
- 💸 **Full Commitment**: Members must contribute every cycle

## 🛡️ Error Codes

| Code | Meaning |
|------|---------|
| u100 | Owner only function |
| u101 | Pool not found |
| u102 | Already exists |
| u103 | Insufficient funds |
| u104 | Pool is full |
| u105 | Not a pool member |
| u106 | Already a member |
| u107 | Pool is active |
| u108 | Pool is inactive |
| u109 | Invalid amount |
| u110 | Payout not ready |
| u111 | Already contributed |
| u112 | Not your turn |
| u113 | Cannot transfer to self |
| u114 | Recipient already member |

## 🧪 Testing

```bash
npm install
npm test
```

## 📄 License

MIT License - Build the future of collaborative savings! 🚀

---

*Empowering communities through decentralized financial cooperation* 🌍
