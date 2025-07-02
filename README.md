# 🆔 Refugee ID and Fund Access Platform

> 🌍 **Empowering displaced individuals with verifiable digital identities and direct aid access**

## 📋 Overview

The Refugee ID and Fund Access Platform is a humanitarian blockchain solution built on Stacks that enables displaced individuals to create verifiable digital identities and receive aid directly, completely bypassing traditional intermediaries. This decentralized approach ensures transparency, reduces bureaucracy, and gets help to those who need it most.

## ✨ Key Features

- 🆔 **Digital Identity Creation** - Refugees can register with personal details and emergency contacts
- ✅ **Identity Verification** - Authorized verifiers can validate refugee identities
- 💰 **Direct Aid Distribution** - Funds go directly to verified refugees without intermediaries
- 🔍 **Transparent Tracking** - All aid distributions are recorded on-chain
- 📍 **Location Updates** - Refugees can update their current location as they move
- 📊 **Real-time Statistics** - Track total refugees, aid distributed, and platform usage

## 🚀 Getting Started

### Prerequisites

```bash
clarinet --version
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ubansvincent/Refugee-ID-and-Fund-Access-Platform.git
```

2. Navigate to project directory:
```bash
cd Refugee-ID-and-Fund-Access-Platform
```

3. Check contract syntax:
```bash
clarinet check
```

## 📖 Usage Guide

### For Refugees 👥

#### 1. Register Your Identity
```clarity
(contract-call? .refugee-id-and-fund-access register-refugee 
  "John Doe" 
  u25 
  "Syria" 
  "Jordan Refugee Camp" 
  u4 
  "jane.doe@email.com"
)
```

#### 2. Update Your Location
```clarity
(contract-call? .refugee-id-and-fund-access update-location "New Safe Location")
```

### For Verifiers 🏛️

#### 1. Register as Verifier
```clarity
(contract-call? .refugee-id-and-fund-access register-verifier 
  "Dr. Sarah Smith" 
  "UN Refugee Agency"
)
```

#### 2. Verify Refugee Identity
```clarity
(contract-call? .refugee-id-and-fund-access verify-refugee 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### For Aid Organizations 🤝

#### 1. Deposit Funds
```clarity
(contract-call? .refugee-id-and-fund-access deposit-funds)
```

#### 2. Distribute Aid
```clarity
(contract-call? .refugee-id-and-fund-access distribute-aid 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  u1000000 
  "Emergency food assistance"
)
```

## 🔍 Read-Only Functions

### Check Refugee Profile
```clarity
(contract-call? .refugee-id-and-fund-access get-refugee-profile 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### View Platform Statistics
```clarity
(contract-call? .refugee-id-and-fund-access get-contract-stats)
```

### Check Verification Status
```clarity
(contract-call? .refugee-id-and-fund-access is-refugee-verified 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🛡️ Security Features

- ✅ **Identity Verification Required** - Only verified refugees can receive aid
- 🔐 **Authorized Verifiers Only** - Only registered verifiers can validate identities
- 💸 **Balance Checks** - Prevents over-distribution of funds
- 🚨 **Emergency Controls** - Contract owner can withdraw funds in emergencies

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 📊 Contract Statistics

The platform tracks:
- Total registered refugees
- Total aid distributed
- Current contract balance
- Number of aid distributions

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌟 Impact

This platform aims to:
- Reduce bureaucratic delays in aid distribution
- Increase transparency in humanitarian funding
- Empower refugees with digital identity ownership
- Enable direct peer-to-peer humanitarian assistance

---

**Built with ❤️ for humanitarian causes on the Stacks blockchain**
```

**Git Commit Message:**
```
feat: implement refugee ID and fund access platform MVP with identity verification and direct aid distribution
```

**GitHub Pull Request Title:**
```
🆔 Add Refugee ID and Fund Access Platform MVP
```

**GitHub Pull Request Description:**
```
## 🌍 Refugee ID and Fund Access Platform

This PR introduces a complete MVP for a humanitarian blockchain platform that enables displaced individuals to create verifiable digital identities and receive aid directly.

### ✨ Features Added

- **Digital Identity Registration** - Refugees can register with personal details
- **Identity Verification System** - Authorized verifiers can validate refugee identities  
- **Direct Aid Distribution** - Funds transfer directly to verified refugees
- **Transparent Tracking** - All distributions recorded on-chain
- **Location Updates** - Refugees can update their current location
- **Emergency Controls** - Contract owner emergency withdrawal capability

### 🔧 Technical Implementation

- Complete Clarity smart contract (150+ lines)
- Comprehensive error handling with custom error codes
- Data maps for refugees, verifiers, and aid distributions
- Read-only functions for querying platform statistics
- Security checks for authorization and fund availability

### 📋 Contract Functions

**Public Functions:**
- `register-refugee` - Register new refugee identity
- `register-verifier` - Register aid organization verifier
- `verify-refugee` - Verify refugee identity
- `distribute-aid` - Send aid directly to verified refugees
- `deposit-funds` - Add funds to aid pool
- `update-location` - Update refugee location

**Read-Only Functions:**
- `get-refugee-profile` - View refugee details
- `get-contract-stats` - Platform statistics
- `is-refugee-verified` - Check verification status

### 🛡️ Security Features

- Identity verification required for aid receipt
- Authorized verifiers only
- Balance validation
- Emergency withdrawal controls

Ready for deployment and testing! 🚀
