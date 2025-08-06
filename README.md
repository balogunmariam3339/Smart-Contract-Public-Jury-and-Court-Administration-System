# Smart Contract Public Jury and Court Administration System

A comprehensive blockchain-based court administration system built on Stacks using Clarity smart contracts. This system manages all aspects of court operations from jury selection to security protocols.

## System Overview

This system consists of five interconnected smart contracts that handle different aspects of court administration:

### 1. Jury Selection and Notification Contract (`jury-selection.clar`)
- Randomly selects citizens for jury duty from eligible pool
- Manages jury notifications and responses
- Tracks jury service history and exemptions
- Handles jury pool management for different case types

### 2. Court Calendar and Scheduling Contract (`court-calendar.clar`)
- Manages hearing dates and courtroom assignments
- Handles scheduling conflicts and rescheduling
- Tracks judge availability and case assignments
- Manages court session types and durations

### 3. Court Reporter and Transcription Contract (`court-reporter.clar`)
- Coordinates court reporting services
- Maintains hearing transcripts and records
- Manages reporter assignments and availability
- Handles transcript requests and distribution

### 4. Witness Subpoena Management Contract (`witness-subpoena.clar`)
- Issues and tracks subpoenas for court proceedings
- Manages witness availability and scheduling
- Handles subpoena compliance and enforcement
- Tracks witness compensation and expenses

### 5. Court Security and Safety Contract (`court-security.clar`)
- Manages security screening protocols
- Tracks security incidents and responses
- Handles visitor registration and access control
- Manages emergency procedures and evacuations

## Key Features

- **Decentralized Administration**: All court operations recorded on blockchain
- **Transparency**: Public access to appropriate court records
- **Efficiency**: Automated scheduling and notification systems
- **Security**: Immutable records and secure access controls
- **Compliance**: Built-in compliance checking and audit trails

## Data Structures

### Common Data Types
- **Case ID**: Unique identifier for court cases
- **Citizen ID**: Unique identifier for citizens/participants
- **Court Room**: Physical courtroom identifier
- **Date/Time**: Standardized timestamp format
- **Status Codes**: Standardized status tracking

### Access Control
- **Admin**: Full system administration rights
- **Judge**: Case management and scheduling rights
- **Clerk**: Administrative and scheduling rights
- **Public**: Read access to public records

## Installation and Setup

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite
5. Deploy contracts using `clarinet deploy`

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract interactions
- Edge case and error condition testing
- Performance and gas optimization tests

## Usage Examples

### Selecting Jury Pool
\`\`\`clarity
(contract-call? .jury-selection select-jury-pool case-id u12 u100)
\`\`\`

### Scheduling Court Hearing
\`\`\`clarity
(contract-call? .court-calendar schedule-hearing case-id judge-id courtroom-id hearing-date)
\`\`\`

### Issuing Subpoena
\`\`\`clarity
(contract-call? .witness-subpoena issue-subpoena case-id witness-id hearing-date)
\`\`\`

## Security Considerations

- All sensitive operations require proper authorization
- Immutable audit trails for all administrative actions
- Secure random number generation for jury selection
- Access control based on roles and permissions

## Compliance and Legal Framework

This system is designed to comply with:
- Due process requirements
- Jury selection fairness standards
- Court record retention policies
- Privacy and confidentiality regulations

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.
