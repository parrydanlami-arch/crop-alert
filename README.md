# CropAlert: Crop Disease Reporting System 🌾

A decentralized crop disease reporting and verification system built on the Stacks blockchain, enabling farmers and agricultural experts to share, verify, and track crop disease outbreaks in real-time.

## Overview

CropAlert is a blockchain-based agricultural monitoring system designed to help farming communities quickly identify, report, and respond to crop disease outbreaks. The platform leverages decentralized technology to create a trustworthy, transparent, and collaborative environment for crop health monitoring.

## 🌱 Key Features

### Disease Report Management
- **Real-time Reporting**: Farmers can instantly report crop disease outbreaks with detailed information
- **Geographic Tracking**: Location-based disease mapping for regional monitoring
- **Crop-Specific Alerts**: Disease reports categorized by crop types (wheat, corn, rice, soybeans, etc.)
- **Severity Assessment**: Multi-level severity rating system for disease impact evaluation
- **Time-stamped Records**: Immutable blockchain timestamps for all disease reports

### Expert Verification System  
- **Agricultural Expert Network**: Qualified agronomists and plant pathologists verify disease reports
- **Consensus-Based Validation**: Multiple expert verifications ensure report accuracy
- **Reputation Management**: Expert credibility tracking based on verification accuracy
- **False Report Prevention**: Economic incentives to prevent spam and misinformation

### Community Features
- **Alert Broadcasting**: Automatic notifications to nearby farmers about verified disease outbreaks
- **Treatment Recommendations**: Verified experts can provide treatment suggestions
- **Historical Tracking**: Long-term disease pattern analysis for predictive insights
- **Emergency Response**: Rapid response coordination for severe disease outbreaks

## 🔧 Technical Architecture

### Smart Contracts

#### 1. Disease Reporter Contract (`disease-reporter.clar`)
- **Reporter Registration**: Farmer and expert registration with identity verification
- **Disease Report Submission**: Comprehensive disease reporting functionality
- **Geographic Data Management**: Coordinate-based location tracking
- **Crop Type Classification**: Standardized crop categorization system
- **Report Status Tracking**: Pending, verified, and disputed report states

#### 2. Alert Verifier Contract (`alert-verifier.clar`)
- **Expert Registration**: Agricultural expert onboarding and verification
- **Verification Process**: Multi-expert consensus mechanism for report validation
- **Alert Generation**: Automated alert creation for verified disease outbreaks
- **Reputation System**: Expert credibility scoring and management
- **Treatment Database**: Verified treatment recommendation storage

## 📊 Data Structure

### Disease Report Fields
- **Report ID**: Unique identifier for each disease report
- **Reporter**: Principal address of the reporting farmer
- **Location**: Latitude and longitude coordinates
- **Crop Type**: Standardized crop classification
- **Disease Type**: Disease identification and classification
- **Severity Level**: Scale from 1 (mild) to 5 (severe)
- **Affected Area**: Size of affected farmland in hectares
- **Symptoms**: Detailed symptom description
- **Photo Evidence**: IPFS hash for disease photos
- **Timestamp**: Block height of report submission

### Verification Data
- **Verifier**: Principal address of expert verifier
- **Verification Status**: Approved, rejected, or needs more information
- **Expert Comments**: Professional assessment and recommendations
- **Treatment Suggestions**: Recommended intervention strategies
- **Confidence Level**: Expert confidence in disease identification

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI for contract development and testing
- Node.js and npm for running tests
- Stacks wallet for blockchain interactions
- Basic understanding of agricultural diseases

### Installation
```bash
git clone <repository-url>
cd crop-alert
npm install
```

### Local Development
```bash
# Check contract syntax
clarinet check

# Run comprehensive tests
npm test

# Start local development environment
clarinet integrate
```

### Contract Deployment
Deploy contracts to Stacks testnet or mainnet using Clarinet deployment tools.

## 💡 Usage Examples

### Register as Disease Reporter
```clarity
(contract-call? .disease-reporter register-reporter 
  "John Smith Farms"     ;; farm name
  "Corn specialist")     ;; expertise area
```

### Submit Disease Report
```clarity
(contract-call? .disease-reporter submit-disease-report
  40123456 -74567890     ;; coordinates (lat, lon * 1000000)
  "corn"                 ;; crop type
  "northern-leaf-blight" ;; disease type
  u4                     ;; severity (1-5 scale)
  u50                    ;; affected area in hectares
  "Brown lesions on leaves with distinctive cigar shape"
  "QmXxx...hash")        ;; IPFS hash for photos
```

### Expert Verification
```clarity
(contract-call? .alert-verifier verify-disease-report
  u1                     ;; report ID
  true                   ;; verification result
  "Confirmed northern leaf blight. Recommend immediate fungicide treatment."
  "Apply fungicide within 48 hours")  ;; treatment recommendation
```

### Query Nearby Alerts
```clarity
(contract-call? .alert-verifier get-alerts-in-radius
  40123456 -74567890     ;; center coordinates
  u50000)                ;; radius in meters
```

## 🔍 System Benefits

### For Farmers
1. **Early Warning System**: Get immediate alerts about disease outbreaks in your area
2. **Expert Consultation**: Access professional agricultural advice and treatment recommendations
3. **Collaborative Defense**: Coordinate with neighboring farms for disease management
4. **Historical Insights**: Track disease patterns over time for better farm planning
5. **Reduced Losses**: Rapid response capabilities minimize crop damage

### For Agricultural Experts
1. **Professional Network**: Connect with farming communities and fellow experts
2. **Impact Tracking**: Monitor the effectiveness of treatment recommendations
3. **Research Data**: Access valuable disease pattern data for research purposes
4. **Reputation Building**: Build credibility through accurate disease identification
5. **Knowledge Sharing**: Contribute expertise to help farming communities

### For the Agricultural Ecosystem
1. **Disease Surveillance**: Real-time monitoring of crop disease outbreaks
2. **Data Transparency**: Immutable records ensure data integrity
3. **Rapid Response**: Faster disease containment and treatment deployment
4. **Economic Protection**: Reduced agricultural losses through early intervention
5. **Research Foundation**: Comprehensive dataset for agricultural research

## 🛡️ Security & Trust

### Data Integrity
- All disease reports are cryptographically secured on the blockchain
- Immutable timestamps prevent report tampering
- Expert verifications create an auditable trail of decision-making

### Fraud Prevention
- Economic incentives discourage false reporting
- Expert reputation system ensures quality verifications
- Multiple verification requirements for critical alerts

### Privacy Considerations
- Location data is precise enough for regional alerts but protects farm-specific details
- Reporter identities are pseudonymized while maintaining accountability
- Sensitive information is stored off-chain with encrypted access

## 📈 Future Roadmap

### Phase 1: Core Platform (Current)
- Basic disease reporting and verification
- Expert network establishment
- Alert system implementation

### Phase 2: Enhanced Features
- Mobile app integration
- AI-powered disease identification
- Weather integration for risk assessment
- Treatment effectiveness tracking

### Phase 3: Ecosystem Expansion
- Integration with agricultural supply chains
- Insurance company partnerships
- Government agency collaboration
- International disease monitoring network

## 🤝 Contributing

We welcome contributions from:
- Agricultural experts and researchers
- Blockchain developers
- Farmers and agricultural practitioners
- UI/UX designers
- Data scientists

Please read our contributing guidelines and code of conduct before submitting contributions.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For technical support, agricultural questions, or partnership inquiries:
- Create an issue on GitHub
- Contact the development team
- Join our community discussions

---

**CropAlert**: Protecting crops through blockchain-powered community collaboration 🌾
