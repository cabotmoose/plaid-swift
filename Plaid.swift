//
//  Plaid.swift
//  Plaid Swift Wrapper
//
//  Created by Cameron Smith on 4/20/15.
//  Copyright (c) 2015 Cameron Smith. All rights reserved.
//

import Foundation

struct Plaid {

    static var baseURL: String!
    static var clientID: String!
    static var secret: String!
    
    static func initializePlaid(clientID: String, secret: String, appStatus: BaseURL) {
        Plaid.clientID = clientID
        Plaid.secret = secret

        switch appStatus {
        case .Production:
            baseURL = "https://api.plaid.com/"
        case .Testing:
            baseURL = "https://tartan.plaid.com/"
        }
    }
}

let session = NSURLSession.sharedSession()

enum BaseURL {
    case Production
    case Testing
}

public enum Type {
    case Auth
    case Connect
    case Balance
}

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

public struct Account {
    let institutionName: String
    let id: String
    let user: String
    let balance: Double?
    let productName: String
    let lastFourDigits: String
    let limit: NSNumber?
    let routingNumber: String?
    let accountNumber: String?
    let wireRouting: String?
    
    public init (account: [String: AnyObject]) {
        let meta = account["meta"] as! [String: AnyObject]
        let accountBalance = account["balance"] as! [String: AnyObject]
        let numbers = account["numbers"] as? [String: AnyObject]
        
        institutionName = account["institution_type"] as! String
        id = account["_id"] as! String
        user = account["_user"] as! String
        balance = accountBalance["current"] as? Double
        productName = meta["name"] as! String
        lastFourDigits = meta["number"] as! String
        limit = meta["limit"] as? NSNumber
        routingNumber = numbers?["routing"] as? String
        accountNumber = numbers?["account"] as? String
        wireRouting = numbers?["wireRouting"] as? String
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
    
    let category: NSArray?
    
    public init(transaction: [String: AnyObject]) {
        let meta = transaction["meta"] as! [String: AnyObject]
        let location = meta["location"] as? [String: AnyObject]
        let coordinates = location?["coordinates"] as? [String: AnyObject]
        let score = transaction["score"] as? [String: AnyObject]
        let locationScore = score?["location"] as? [String: AnyObject]
        let type = transaction["type"] as? [String: AnyObject]
        
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

// MARK: - Add Connect or Auth User
func PS_addUser(userType: Type, username: String, password: String, pin: String?, institution: Institution, completion: (response: NSURLResponse?, accessToken: String, mfaType: String?, mfa:[[String: AnyObject]]?, accounts: [Account]?, transactions: [Transaction]?, error: NSError?) -> ()) {

    let institutionString = institutionToString(institution)
    let optionsDictionary: [String: AnyObject] = ["list": true]
    let optionsDictionaryString = dictionaryToString(optionsDictionary)
    
    var urlString: String?
    if pin != nil {
        urlString = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret)&username=\(username)&password=\(password.encodValue)&pin=\(pin!)&type=\(institutionString)&\(optionsDictionaryString.encodValue)"
    } else {
        urlString = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret)&username=\(username)&password=\(password.encodValue)&type=\(institutionString)&options=\(optionsDictionaryString.encodValue)"
    }
    
    let url = NSURL(string: urlString!)
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "POST"
    
    let task = session.dataTaskWithRequest(request, completionHandler: {
        data, response, error in
        var mfaDictionary: [[String: AnyObject]]?
        var type: String?
        
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            guard jsonResult?.valueForKey("code") as? Int != 1303 else { throw PlaidError.InstitutionNotAvailable }
            guard jsonResult!.valueForKey("code") as? Int != 1200 else {throw PlaidError.InvalidCredentials(jsonResult!.valueForKey("resolve") as! String)}
            guard jsonResult!.valueForKey("code") as? Int != 1005 else {throw PlaidError.CredentialsMissing(jsonResult!.valueForKey("resolve") as! String)}
            guard jsonResult!.valueForKey("code") as? Int != 1601 else {throw PlaidError.InstitutionNotAvailable}
            
            if let token = jsonResult?.valueForKey("access_token") as? String {
                if let mfaResponse = jsonResult!.valueForKey("mfa") as? [[String: AnyObject]] {
                    mfaDictionary = mfaResponse
                    if let typeMfa = jsonResult!.valueForKey("type") as? String {
                        type = typeMfa
                    }
                    completion(response: response, accessToken: token, mfaType: type, mfa: mfaDictionary, accounts: nil, transactions: nil, error: error)
                } else {
                    let acctsArray: [[String: AnyObject]] = jsonResult?.valueForKey("accounts") as! [[String: AnyObject]]
                    let accts = acctsArray.map{Account(account: $0)}
                    let trxnArray: [[String: AnyObject]] = jsonResult?.valueForKey("transactions") as! [[String: AnyObject]]
                    let trxns = trxnArray.map{Transaction(transaction: $0)}
                    
                    completion(response: response, accessToken: token, mfaType: nil, mfa: nil, accounts: accts, transactions: trxns, error: error)
                }
            }
        } catch {
            print("Error (PS_addUser): \(error)")
        }
    })

    task.resume()
}

// MARK: - MFA funcs

func PS_submitMFAResponse(accessToken: String, code: Bool?, response: String, completion: (response: NSURLResponse?, accounts: [Account]?, transactions: [Transaction]?, error: NSError?) -> ()) {
    var urlString: String?
    
    let optionsDictionary: [String: AnyObject] = ["send_method":["type":response]]
    let optionsDictionaryString = dictionaryToString(optionsDictionary)
    
    if code == true {
        urlString = "\(Plaid.baseURL!)connect/step?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&options=\(optionsDictionaryString.encodValue)"
        print("urlString: \(urlString!)")
    } else {
        urlString = "\(Plaid.baseURL!)connect/step?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&mfa=\(response.encodValue)"
    }
    
    let url = NSURL(string: urlString!)
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "POST"
    
    let task = session.dataTaskWithRequest(request, completionHandler: {
        data, response, error in
        
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            guard jsonResult?.valueForKey("code") as? Int != 1303 else { throw PlaidError.InstitutionNotAvailable }
            guard jsonResult?.valueForKey("code") as? Int != 1203 else { throw PlaidError.IncorrectMfa(jsonResult!.valueForKey("resolve") as! String)}
            guard jsonResult?.valueForKey("accounts") != nil else { throw JSONError.Empty }
            let acctsArray: [[String: AnyObject]] = jsonResult?.valueForKey("accounts") as! [[String: AnyObject]]
            let accts = acctsArray.map{Account(account: $0)}
            let trxnArray: [[String: AnyObject]] = jsonResult?.valueForKey("transactions") as! [[String: AnyObject]]
            let trxns = trxnArray.map{Transaction(transaction: $0)}
            
            completion(response: response, accounts: accts, transactions: trxns, error: error)
        } catch {
            print("MFA error (PS_submitMFAResponse): \(error)")
        }
    })

    task.resume()
}


// MARK: - Get balance
func PS_getUserBalance(accessToken: String, completion: (response: NSURLResponse?, accounts:[Account], error:NSError?) -> ()) {

    let urlString = "\(Plaid.baseURL!)balance?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)"
    let url = NSURL(string: urlString)
    
    let task = session.dataTaskWithURL(url!) {
        data, response, error in
        
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            print("jsonResult: \(jsonResult!)")
            guard jsonResult?.valueForKey("code") as? Int != 1303 else { throw PlaidError.InstitutionNotAvailable }
            guard jsonResult?.valueForKey("code") as? Int != 1105 else { throw PlaidError.BadAccessToken }
            guard let dataArray: [[String: AnyObject]] = jsonResult?.valueForKey("accounts") as? [[String : AnyObject]] else { throw JSONError.Empty }
            let userAccounts = dataArray.map{Account(account: $0)}
            completion(response: response, accounts: userAccounts, error: error)
            
        } catch {
            print("JSON parsing error (PS_getUserBalance): \(error)")
        }
    }

    task.resume()
}

// MARK: - Get transactions (Connect)
func PS_getUserTransactions(accessToken: String, showPending: Bool, beginDate: String?, endDate: String?, completion: (response: NSURLResponse?, transactions: [Transaction], error:NSError?) -> ()) {
    
    var optionsDictionary: [String: AnyObject] = ["pending": true]
    
    if let beginDate = beginDate {
        optionsDictionary["gte"] = beginDate
    }
    
    if let endDate = endDate {
        optionsDictionary["lte"] = endDate
    }
    
    let optionsDictionaryString = dictionaryToString(optionsDictionary)
    let urlString:String = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&\(optionsDictionaryString.encodValue)"
    let url: NSURL = NSURL(string: urlString)!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
        do {
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            guard jsonResult?.valueForKey("code") as? Int != 1303 else { throw PlaidError.InstitutionNotAvailable }
            guard let dataArray: [[String: AnyObject]] = jsonResult?.valueForKey("transactions") as? [[String: AnyObject]] else { throw JSONError.Empty }
            let userTransactions = dataArray.map{Transaction(transaction: $0)}
            completion(response: response, transactions: userTransactions, error: error)
        } catch {
            print("JSON parsing error (PS_getUserTransactions: \(error)")
        }
    }

    task.resume()
}


// MARK: - Helper funcs
enum JSONError: ErrorType {
    case Writing
    case Reading
    case Empty
}

enum PlaidError: ErrorType {
    case BadAccessToken
    case CredentialsMissing(String)
    case InvalidCredentials(String)
    case IncorrectMfa(String)
    case InstitutionNotAvailable
}


func plaidDateFormatter(date: NSDate) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateStr = dateFormatter.stringFromDate(date)

    return dateStr
}

func dictionaryToString(value: AnyObject) -> NSString {
    if NSJSONSerialization.isValidJSONObject(value) {
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(value, options: NSJSONWritingOptions.PrettyPrinted)
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        } catch _ as NSError {
            print("JSON Parsing error")
        }
    }

    return ""
}

func institutionToString(institution: Institution) -> String {
    var institutionString: String {
        switch institution {
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
        case .navy:
            return "nfcu"
        case .pnc:
            return "pnc"
        case .schwab:
            return "schwab"
        case .suntrust:
            return "suntrust"
        case .tdbank:
            return "td"
        case .us:
            return "us"
        case .usaa:
            return "usaa"
        case .wells:
            return "wells"
        }
    }
    return institutionString
}

extension String {
    var encodValue: String {
        return self.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }
}

extension NSString {
    var encodValue: String {
        return self.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }
}