//
//  Plaid.swift
//  Plaid Swift Wrapper
//
//  Created by Cameron Smith on 4/20/15.
//  Copyright (c) 2015 Cameron Smith. All rights reserved.
//

import Foundation

struct Plaid {
    static var baseURL:String!
    static var clientId:String!
    static var secret:String!
    
    static func initializePlaid(clientId: String, secret: String, appStatus: BaseURL) {
        Plaid.clientId = clientId
        Plaid.secret = secret
        switch appStatus {
        case .Production:
            baseURL = "https://api.plaid.com/"
        case .Testing:
            baseURL = "https://tartan.plaid.com/"
        }
    }
}

enum BaseURL {
    case Production
    case Testing
}

public enum Type {
    case Auth
    case Connect
}

public enum Institution {
    case amex
    case bofa
    case capone360
    case schwab
    case chase
    case citi
    case fidelity
    case us
    case usaa
    case wells
}

public struct Account {
    let institutionName: String
    let id: String
    let user: String
    let balance: Double
    let productName: String
    let lastFourDigits: String
    let limit: NSNumber?
    
    public init (account: [String:AnyObject]) {
        let meta = account["meta"] as! [String:AnyObject]
        let accountBalance = account["balance"] as! [String:AnyObject]
        
        institutionName = account["institution_type"] as! String
        id = account["_id"] as! String
        user = account["_user"] as! String
        balance = accountBalance["current"] as! Double
        productName = meta["name"] as! String
        lastFourDigits = meta["number"] as! String
        limit = meta["limit"] as? NSNumber
    }
}

public struct Transaction {
    let account: String
    let id: String
    let amount: Double
    let date: String
    let name: String
    let pending: Bool
    
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
    
    public init(transaction: [String:AnyObject]) {
        let meta = transaction["meta"] as! [String:AnyObject]
        let location = meta["location"] as? [String:AnyObject]
        let coordinates = location?["coordinates"] as? [String:AnyObject]
        let score = transaction["score"] as? [String:AnyObject]
        let locationScore = score?["location"] as? [String:AnyObject]
        let type = transaction["type"] as? [String:AnyObject]
        
        account = transaction["_account"] as! String
        id = transaction["_id"] as! String
        amount = transaction["amount"] as! Double
        date = transaction["date"] as! String
        name = transaction["name"] as! String
        pending = transaction["pending"] as! Bool
        
        address = location?["address"] as? String
        city = location?["city"] as? String
        state = location?["state"] as? String
        zip = location?["zip"] as? String
        storeNumber = location?["store_number"] as? String
        latitude = coordinates?["lat"] as? Double
        longitude = coordinates?["lon"] as? Double
        
        trxnType = type?["primary"] as? String
        locationScoreAddress = locationScore?["address"] as? Double
        locationScoreCity = locationScore?["city"] as? Double
        locationScoreState = locationScore?["state"] as? Double
        locationScoreZip = locationScore?["zip"] as? Double
        nameScore = score?["name"] as? Double
        
        category = transaction["category"] as? NSArray
    }
    
}

//MARK: Add Connect or Auth User

func PS_addUser(userType: Type, username: String, password: String, instiution: Institution, completion: (response: NSURLResponse?, accessToken:String, error:NSError?) -> ()) {
    let baseURL = Plaid.baseURL!
    let clientId = Plaid.clientId!
    let secret = Plaid.secret!
    
    var institutionStr: String {
        switch instiution {
        case .amex:
            return "amex"
        case .bofa:
            return "bofa"
        case .capone360:
            return "capone360"
        case .chase:
            return "chase"
        case .citi:
            return "citi"
        case .fidelity:
            return "fidelity"
        case .schwab:
            return "schwab"
        case .us:
            return "us"
        case .usaa:
            return "usaa"
        case .wells:
            return "wells"
        }
    }
    
    let encodUsername = username.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    let encodPassword = password.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    
    if userType == .Auth {
        //let urlString:String = "\(baseURL)auth?client_id=\(clientId)&secret=\(secret)&username=\(encodUsername)&password=\(encodPassword)&type=\(institutionStr)"
        let urlString:String = "\(baseURL)auth?client_id=test_id&secret=test_secret&username=\(encodUsername)&password=\(encodPassword)&type=\(institutionStr)"
        let url:NSURL! = NSURL(string: urlString)
        var request = NSMutableURLRequest(URL: url)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        let task = session.dataTaskWithRequest(request, completionHandler: {
            data, response, error in
            var error:NSError?
            let jsonResult:NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary
            if let token:String = jsonResult?.valueForKey("access_token") as? String {
                completion(response: response, accessToken: token, error: error)
            }
        })
        task.resume()
        
    } else if userType == .Connect {
        let urlString:String = "\(baseURL)connect?client_id=\(clientId)&secret=\(secret)&username=\(encodUsername)&password=\(encodPassword)&type=\(institutionStr)"
        //let urlString:String = "\(baseURL)connect?client_id=test_id&secret=test_secret&username=\(encodUsername)&password=\(encodPassword)&type=\(institutionStr)"
        let url:NSURL! = NSURL(string: urlString)
        var request = NSMutableURLRequest(URL: url)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        let task = session.dataTaskWithRequest(request, completionHandler: {
            data, response, error in
            var error:NSError?
            let jsonResult:NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary
            if let token:String = jsonResult?.valueForKey("access_token") as? String {
                completion(response: response, accessToken: token, error: error)
            }
        })
        task.resume()
    }
}


//MARK: Get balance

func PS_getUserBalance(accessToken: String, completion: (response: NSURLResponse?, accounts:[Account], error:NSError?) -> ()) {
    let baseURL = Plaid.baseURL!
    let clientId = Plaid.clientId!
    let secret = Plaid.secret!
    
    let urlString:String = "\(baseURL)balance?client_id=\(clientId)&secret=\(secret)&access_token=\(accessToken)"
    let url:NSURL! = NSURL(string: urlString)
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url) {
        data, response, error in
        var error: NSError?
        let jsonResult:NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary
        let dataArray:[[String:AnyObject]] = jsonResult?.valueForKey("accounts") as! [[String : AnyObject]]
        let userAccounts = dataArray.map{Account(account: $0)}
        completion(response: response, accounts: userAccounts, error: error)
    }
    task.resume()
}

//MARK: Get transactions (Connect)

func PS_getUserTransactions(accessToken: String, showPending: Bool, beginDate: String?, endDate: String?, completion: (response: NSURLResponse?, transactions:[Transaction], error:NSError?) -> ()) {
    let baseURL = Plaid.baseURL!
    let clientId = Plaid.clientId!
    let secret = Plaid.secret!
    
    var optionsDict: [String:AnyObject] =
    [
        "pending": true
    ]
    
    if let beginDate = beginDate {
        optionsDict["gte"] = beginDate
    }
    
    if let endDate = endDate {
        optionsDict["lte"] = endDate
    }
    
    let optionsDictStr = dictToString(optionsDict)
    let encodOptionsDict = optionsDictStr.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    let urlString:String = "\(baseURL)connect?client_id=\(clientId)&secret=\(secret)&access_token=\(accessToken)&\(encodOptionsDict)"
    let url:NSURL = NSURL(string: urlString)!
    var request = NSMutableURLRequest(URL: url)
    var session = NSURLSession.sharedSession()
    request.HTTPMethod = "POST"
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url) {
        data, response, error in
        var error: NSError?
        let jsonResult:NSDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary
        let dataArray:[[String:AnyObject]] = jsonResult?.valueForKey("transactions") as! [[String:AnyObject]]
        let userTransactions = dataArray.map{Transaction(transaction: $0)}
        completion(response: response, transactions: userTransactions, error: error)
    }
    task.resume()
    
}


//MARK: Helper funcs

func plaidDateFormatter(date: NSDate) -> String {
    var dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateStr = dateFormatter.stringFromDate(date)
    return dateStr
}

func dictToString(value: AnyObject) -> NSString {
    if NSJSONSerialization.isValidJSONObject(value) {
        if let data = NSJSONSerialization.dataWithJSONObject(value, options: nil, error: nil) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        }
    }
    return ""
}
