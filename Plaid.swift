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

    @available(*, deprecated, message="Use initializePlaid(clientID:_, secretKey:_, inProduction:_) instead.")
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

    static func initializePlaid(clientID clientID: String, secretKey: String, inProduction: Bool) {
        if !inProduction {
            Plaid.baseURL = "https://tartan.plaid.com/"
            Plaid.clientID = "test_id"
            Plaid.secret = "test_secret"
        }

        if inProduction {
            Plaid.baseURL = "https://api.plaid.com/"
            Plaid.clientID = clientID
            Plaid.secret = secretKey
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
    case Amex
    case Bofa
    case Capone360
    case Schwab
    case Chase
    case Citi
    case Fidelity
    case Navy
    case PNC
    case Suntrust
    case TDBank
    case US
    case USAA
    case Wells
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
    
    var URLString: String?

    if pin != nil {
        URLString = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret)&username=\(username)&password=\(password.encodValue)&pin=\(pin!)&type=\(institutionString)&\(optionsDictionaryString.encodValue)"
    } else {
        URLString = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret)&username=\(username)&password=\(password.encodValue)&type=\(institutionString)&options=\(optionsDictionaryString.encodValue)"
    }

    let request = NSMutableURLRequest(URL: NSURL(string: URLString!)!)
    request.HTTPMethod = "POST"
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
        var mfaDictionary: [[String: AnyObject]]?
        var type: String?
        
        do {
            let JSONResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary

            guard JSONResult?.valueForKey("code") as? Int != 1303 else {
                throw PlaidError.InstitutionNotAvailable
            }

            guard JSONResult!.valueForKey("code") as? Int != 1200 else {
                throw PlaidError.InvalidCredentials(JSONResult!.valueForKey("resolve") as! String)
            }

            guard JSONResult!.valueForKey("code") as? Int != 1005 else {
                throw PlaidError.CredentialsMissing(JSONResult!.valueForKey("resolve") as! String)
            }

            guard JSONResult!.valueForKey("code") as? Int != 1601 else {
                throw PlaidError.InstitutionNotAvailable
            }
            
            if let token = JSONResult?.valueForKey("access_token") as? String {
                if let mfaResponse = JSONResult!.valueForKey("mfa") as? [[String: AnyObject]] {
                    mfaDictionary = mfaResponse
                    if let typeMfa = JSONResult!.valueForKey("type") as? String {
                        type = typeMfa
                    }

                    completion(response: response, accessToken: token, mfaType: type, mfa: mfaDictionary, accounts: nil, transactions: nil, error: error)
                } else {
                    let acctsArray: [[String: AnyObject]] = JSONResult?.valueForKey("accounts") as! [[String: AnyObject]]
                    let accts = acctsArray.map{Account(account: $0)}
                    let trxnArray: [[String: AnyObject]] = JSONResult?.valueForKey("transactions") as! [[String: AnyObject]]
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
    var URLString: String?
    
    let optionsDictionary: [String: AnyObject] = ["send_method":["type":response]]
    let optionsDictionaryString = dictionaryToString(optionsDictionary)
    
    if code == true {
        URLString = "\(Plaid.baseURL!)connect/step?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&options=\(optionsDictionaryString.encodValue)"
        print("urlString: \(URLString!)")
    } else {
        URLString = "\(Plaid.baseURL!)connect/step?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&mfa=\(response.encodValue)"
    }

    let request = NSMutableURLRequest(URL: NSURL(string: URLString!)!)
    request.HTTPMethod = "POST"
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
        do {
            let JSONResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary

            guard JSONResult?.valueForKey("code") as? Int != 1303 else {
                throw PlaidError.InstitutionNotAvailable
            }

            guard JSONResult?.valueForKey("code") as? Int != 1203 else {
                throw PlaidError.IncorrectMfa(JSONResult!.valueForKey("resolve") as! String)
            }

            guard JSONResult?.valueForKey("accounts") != nil else {
                throw JSONError.Empty
            }

            let acctsArray: [[String: AnyObject]] = JSONResult?.valueForKey("accounts") as! [[String: AnyObject]]
            let accts = acctsArray.map{Account(account: $0)}
            let trxnArray: [[String: AnyObject]] = JSONResult?.valueForKey("transactions") as! [[String: AnyObject]]
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

    let URLString = "\(Plaid.baseURL!)balance?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)"

    let task = session.dataTaskWithURL(NSURL(string: URLString)!) { data, response, error in
        do {
            let JSONResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            print("JSONResult: \(JSONResult!)")

            guard JSONResult?.valueForKey("code") as? Int != 1303 else {
                throw PlaidError.InstitutionNotAvailable
            }

            guard JSONResult?.valueForKey("code") as? Int != 1105 else {
                throw PlaidError.BadAccessToken
            }

            guard let dataArray = JSONResult?.valueForKey("accounts") as? [[String : AnyObject]] else {
                throw JSONError.Empty
            }

            let userAccounts = dataArray.map { Account(account: $0)}

            completion(response: response, accounts: userAccounts, error: error)
        } catch {
            print("JSON Parsing error (PS_getUserBalance): \(error)")
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
    let URLString = "\(Plaid.baseURL!)connect?client_id=\(Plaid.clientID!)&secret=\(Plaid.secret!)&access_token=\(accessToken)&\(optionsDictionaryString.encodValue)"
    let URL = NSURL(string: URLString)!
    let request = NSMutableURLRequest(URL: URL)
    request.HTTPMethod = "POST"
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(URL) { data, response, error in
        do {
            let JSONResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
            guard JSONResult?.valueForKey("code") as? Int != 1303 else { throw PlaidError.InstitutionNotAvailable }
            guard let dataArray: [[String: AnyObject]] = JSONResult?.valueForKey("transactions") as? [[String: AnyObject]] else { throw JSONError.Empty }
            let userTransactions = dataArray.map{Transaction(transaction: $0)}
            completion(response: response, transactions: userTransactions, error: error)
        } catch {
            print("JSON parsing error (PS_getUserTransactions: \(error)")
        }
    }

    task.resume()
}


// MARK: - Helper Methods
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
    let dateString = dateFormatter.stringFromDate(date)

    return dateString
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
        case .Amex:
            return "amex"
        case .Bofa:
            return "bofa"
        case .Capone360:
            return "capone360"
        case .Chase:
            return "chase"
        case .Citi:
            return "citi"
        case .Fidelity:
            return "fidelity"
        case .Navy:
            return "nfcu"
        case .PNC:
            return "pnc"
        case .Schwab:
            return "schwab"
        case .Suntrust:
            return "suntrust"
        case .TDBank:
            return "td"
        case .US:
            return "us"
        case .USAA:
            return "usaa"
        case .Wells:
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