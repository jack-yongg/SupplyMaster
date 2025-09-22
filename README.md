# SupplyMaster

SupplyMaster is a comprehensive supply chain tracking smart contract built on the Stacks blockchain using Clarity. It enables unified multi-industry product tracking, verification, and lifecycle management across the entire supply chain ecosystem.

## Overview

This smart contract provides a decentralized solution for tracking products from manufacturing to end consumer, ensuring transparency, authenticity, and accountability across all supply chain participants. The system supports multiple industries and enables real-time product status updates, ownership transfers, and verification processes.

## Features

- **Multi-Industry Support**: Track products across various industries with customizable industry classifications
- **Product Lifecycle Management**: Complete tracking from creation to delivery with status updates
- **Participant Authorization**: Role-based access control for manufacturers, distributors, retailers, and verifiers
- **Real-Time Event Tracking**: Comprehensive audit trail of all supply chain events
- **Product Verification**: Multi-party verification system with detailed verification records
- **Ownership Transfer**: Secure transfer of product ownership between authorized participants
- **Batch Tracking**: Support for batch numbers and expiry date management
- **Status Management**: Five-stage product status system (Created, In Transit, Delivered, Verified, Recalled)

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.0
- **Epoch**: 2.5
- **Contract Version**: 1.0.0
- **Testing Framework**: Vitest with Clarinet SDK

## Architecture

### Data Structures

#### Products Map
Stores comprehensive product information including:
- Product metadata (name, description, industry)
- Manufacturing details (manufacturer, creation timestamp)
- Current status and ownership
- Batch information and expiry dates

#### Supply Chain Events Map
Maintains an immutable audit trail of all product events:
- Event type and timestamp
- Location and actor information
- Detailed event descriptions

#### Authorized Participants Map
Manages access control for supply chain participants:
- Participant roles and authorization details
- Authorization timestamp and authorizing entity

#### Verifications Map
Tracks product verification records:
- Verification status and timestamps
- Verifier identity and detailed notes

### Status System

The contract implements a five-stage status system:

1. **CREATED** (u1): Product initially created by manufacturer
2. **IN_TRANSIT** (u2): Product being transported between participants
3. **DELIVERED** (u3): Product delivered to destination
4. **VERIFIED** (u4): Product verified by authorized verifier
5. **RECALLED** (u5): Product recalled due to issues

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd SupplyMaster
```

2. Navigate to the contract directory:
```bash
cd SupplyMaster_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Authorizing Participants

Only the contract owner can authorize new participants:

```clarity
(contract-call? .SupplyMaster authorize-participant
  'SP1234567890ABCDEF
  "Acme Manufacturing"
  "manufacturer")
```

### Creating Products

Authorized participants can create new products:

```clarity
(contract-call? .SupplyMaster create-product
  "Organic Apples"
  "Fresh organic apples from sustainable farms"
  "agriculture"
  "BATCH-2024-001"
  (some u1000000)) ;; expiry date as optional uint
```

### Transferring Product Ownership

Transfer products between authorized participants:

```clarity
(contract-call? .SupplyMaster transfer-product
  u1                    ;; product-id
  'SP0987654321FEDCBA   ;; new-owner
  "Distribution Center A")
```

### Updating Product Status

Update product status with location and notes:

```clarity
(contract-call? .SupplyMaster update-product-status
  u1                    ;; product-id
  u3                    ;; STATUS_DELIVERED
  "Retail Store XYZ"
  "Product delivered successfully to retail location")
```

### Verifying Products

Authorized verifiers can verify product authenticity:

```clarity
(contract-call? .SupplyMaster verify-product
  u1                    ;; product-id
  true                  ;; verification-status
  "Product passed all quality checks")
```

## Contract Functions Documentation

### Public Functions

#### authorize-participant
- **Purpose**: Authorize new supply chain participants
- **Access**: Contract owner only
- **Parameters**:
  - `participant` (principal): Address of participant to authorize
  - `name` (string-ascii 100): Participant name
  - `role` (string-ascii 50): Participant role
- **Returns**: `(response principal uint)`

#### create-product
- **Purpose**: Create new product in the supply chain
- **Access**: Authorized participants only
- **Parameters**:
  - `name` (string-ascii 100): Product name
  - `description` (string-ascii 500): Product description
  - `industry` (string-ascii 50): Industry classification
  - `batch-number` (string-ascii 50): Batch identifier
  - `expiry-date` (optional uint): Expiration date
- **Returns**: `(response uint uint)`

#### transfer-product
- **Purpose**: Transfer product ownership
- **Access**: Current product owner only
- **Parameters**:
  - `product-id` (uint): Product identifier
  - `new-owner` (principal): New owner address
  - `location` (string-ascii 100): Transfer location
- **Returns**: `(response bool uint)`

#### update-product-status
- **Purpose**: Update product status in supply chain
- **Access**: Product owner or contract owner
- **Parameters**:
  - `product-id` (uint): Product identifier
  - `new-status` (uint): New status code (1-5)
  - `location` (string-ascii 100): Current location
  - `notes` (string-ascii 300): Status update notes
- **Returns**: `(response bool uint)`

#### verify-product
- **Purpose**: Verify product authenticity and quality
- **Access**: Authorized participants only
- **Parameters**:
  - `product-id` (uint): Product identifier
  - `verification-status` (bool): Verification result
  - `notes` (string-ascii 300): Verification notes
- **Returns**: `(response bool uint)`

### Read-Only Functions

#### get-product
Returns complete product information for given product ID.

#### get-participant
Returns participant information for given principal.

#### get-supply-chain-event
Returns event details for given event ID.

#### get-verification
Returns verification record for product and verifier combination.

#### get-product-count
Returns total number of products created.

#### get-event-count
Returns total number of events recorded.

#### product-exists
Checks if product exists for given ID.

#### is-authorized-participant
Checks if principal is an authorized participant.

#### get-product-status-string
Returns human-readable status string for product.

## Deployment Guide

### Development Network (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract SupplyMaster
```

### Testnet Deployment

1. Configure Testnet settings in `settings/Testnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deploy --network testnet
```

### Mainnet Deployment

1. Configure Mainnet settings in `settings/Mainnet.toml`

2. Deploy using Clarinet:
```bash
clarinet deploy --network mainnet
```

## Security Considerations

### Access Control
- **Contract Owner Privileges**: Only the contract owner can authorize new participants
- **Participant Authorization**: All write operations require authorized participant status
- **Ownership Verification**: Product transfers require current ownership verification

### Data Integrity
- **Immutable Events**: All supply chain events are permanently recorded
- **Status Validation**: Product status updates are validated against defined constants
- **Participant Validation**: All operations verify participant authorization

### Best Practices
- **Role-Based Access**: Implement proper role separation (manufacturer, distributor, retailer, verifier)
- **Regular Audits**: Monitor participant authorizations and revoke if necessary
- **Event Monitoring**: Track all supply chain events for anomaly detection
- **Verification Requirements**: Implement multi-party verification for critical products

## Testing

The contract includes comprehensive tests using Vitest and Clarinet SDK:

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Error Codes

- `u400`: Invalid status
- `u401`: Unauthorized access
- `u402`: Invalid participant
- `u404`: Product not found
- `u409`: Product already exists

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For technical support and questions, please create an issue in the repository or contact the development team.