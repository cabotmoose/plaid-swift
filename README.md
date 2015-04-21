# plaid-swift
Swift wrapper for the Plaid API. See [Plaid docs](https://plaid.com/docs/) for more info. 

##Quick start
####1) Copy the Plaid.swift file into you project:

![Add Plaid.swift to your project](https://github.com/cabotmoose/plaid-swift/blob/master/images/stepOne.jpg)

####2) In your AppDelegate.swift file, initialize plaid-swift with your client_id and secret:

![Initialize plaid-swift](https://github.com/cabotmoose/plaid-swift/blob/master/images/stepTwo.jpg)

####3) Use plaid-swift functions (They all begin with "PS_") 

![Use plaid-swift functions](https://github.com/cabotmoose/plaid-swift/blob/master/images/stepThree.jpg)

###Notes
####Date bounding:
Currently not working
####Supported institutions:  
1) American Express  
2) Charles Schwab  
3) Chase  
4) Citi (connect only)  
5) Fidelity  
6) Wells Fargo  

####Upcoming institutions:
Basically all those that require MFA to add:  
1) Bank of America  
2) Citi (auth)  
3) US Bank  
4) USAA  
