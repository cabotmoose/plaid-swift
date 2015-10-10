# plaid-swift
Swift wrapper for the Plaid API. See [Plaid docs](https://plaid.com/docs/) for more info. 

##Quick start
#####1) Copy the Plaid.swift file into you project:

<img src="https://github.com/cabotmoose/plaid-swift/blob/master/images/stepOne.jpg" height="50%" width="50%">

#####2) In your AppDelegate.swift file, initialize plaid-swift with your client_id and secret:

![Initialize plaid-swift](https://github.com/cabotmoose/plaid-swift/blob/master/images/stepTwo.jpg)

> See [BaseURL](#baseURL) section below for more info
```swift
Plaid.initializePlaid(clientId: "Your client_id", secret: "Your secret", appStatus: .Testing or .Production)
```

#####3) Use plaid-swift functions (They all begin with "PS_") 

![Use plaid-swift functions](https://github.com/cabotmoose/plaid-swift/blob/master/images/stepThree.jpg)

> See [Functions](#functions)

##Usage
> *userType* and *institution* take an [Enum](#enums) as an input.

> *Institutions* and *Accounts* returned by plaid-swift functions are [Structs](#structs) with various properties associated with each. [See below for more info](#structs).


##Functions
####PS_addUser
```swift
PS_addUser(userType: Type, username: String, password: String, pin: String?, instiution: Institution) { (response, accessToken, mfaType, mfa, accounts, transactions, error) -> () in
	//NOTE: pin param only required for USAA 

	//Returns user access_token 

	//Returns MFA requirements if valid
}
```
####PS_getUserBalance
```swift
PS_getUserBalance(accessToken: String) { (response, accounts, error) -> () in
	//Returns array of Accounts 
}
```

####PS_getUserTransactions
```swift
PS_getUserTransactions(accessToken: String, showPending: Bool, beginDate: String?, endDate: String?) { (response, transactions, error) -> in 
	//Returns array of Transactions
}
```

##Enums
####BaseURL 
```swift
enum BaseURL {
    case Production //Endpoint: https://api.plaid.com
    case Testing    //Endpoint: https://tartan.plaid.com
}
```

####Institution 
```swift
public enum Institution {
    case amex
    case bofa
    case capone360
    case schwab
    case chase
    case citi
    case fidelity
    case navy
    case pnc
    case suntrust
    case tdbank
    case us
    case usaa
    case wells
}
```

####Type
```swift
public enum Type {
    case Auth
    case Connect
}
```

##Structs
####Institution
```swift
public struct Transaction {
	//Standard properties
    let account: String
    let id: String
    let amount: Double
    let date: String
    let name: String
    let pending: Bool
    
    //Optional properties
    let address: String?
    let city: String?
    let state: String?
    let zip: String?
    let storeNumber: String?
    let latitude: Double?
    let longitude: Double?
    let trxnType: String?
    let locationScoreAddress: Double?
    let locationScoreCity: Double?
    let locationScoreState: Double?
    let locationScoreZip: Double?
    let nameScore: Double?
    let category:NSArray?
    ...
}
```

####Account
```swift
public struct Account {
	//Standard properties
    let institutionName: String
    let id: String
    let user: String
    let balance: Double
    let productName: String
    let lastFourDigits: String
    //Optional properties
    let limit: NSNumber?
    let routingNumber: String? // Only for Auth endpoint
    let accountNumber: String? // Only for Auth endpoint
    let wireRouting: String? // Only for Auth endpoint
    ...
}
```

##Known Issues
####Date bounding:
Currently not working

####Supported institutions:  
1. American Express  
2. Bank of America 
3. Chase  
4. Citi  
5. Wells Fargo  
6. USAA (requires user PIN)
7. US Bank

####Untested institutions 
1. Charles Schwab
2. Fidelity
3. Navy Federal Credit Union
4. PNC
5. Suntrust
6. TD Bank

####Unsupported institutions (As of 10 Oct): 
These are institutions with Plaid endpoints but no actual data yet. Check [Plaid](https://plaid.com) for additional info. 

1. Capital One 360
